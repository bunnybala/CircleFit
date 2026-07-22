import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Background isolate entry point ──────────────────────────────────────────
// This runs in a SEPARATE Dart isolate. It has NO access to Riverpod, DioClient,
// or any other in-memory state from the main app. All state must go through
// SharedPreferences or direct HTTP calls.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Load baseline ONCE at startup into local variables — never re-read inside listener
  final prefs = await SharedPreferences.getInstance();

  final savedBase = prefs.getInt('base_steps') ?? 0;
  final savedDateStr = prefs.getString('last_step_date');
  final startTodayStr = DateTime.now().toIso8601String().substring(0, 10);

  // Track in local vars — these persist for the lifetime of the service isolate
  int baseSteps = (savedDateStr != null && savedDateStr != startTodayStr) ? 0 : savedBase;
  String currentDateStr = startTodayStr;
  int currentTodaySteps = baseSteps == 0 ? 0 : (prefs.getInt('last_step_count') ?? 0);
  int restoredBackendSteps = prefs.getInt('last_step_count') ?? 0;
  DateTime lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Listen for user authentication state changes
  service.on('userLoggedOut').listen((event) async {
    baseSteps = 0;
    currentTodaySteps = 0;
    restoredBackendSteps = 0;
    await prefs.remove('base_steps');
    await prefs.remove('last_step_count');
    await prefs.remove('last_step_date');
    await prefs.remove('jwt_token');
    await prefs.remove('active_user_id');
    service.invoke('updateSteps', {'steps': 0, 'timestamp': DateTime.now().toIso8601String()});
  });

  service.on('userLoggedIn').listen((event) async {
    await prefs.reload();
    final initialSteps = (event != null && event['initialSteps'] != null)
        ? (event['initialSteps'] as int)
        : (prefs.getInt('last_step_count') ?? 0);
    restoredBackendSteps = initialSteps;
    baseSteps = 0; // Force re-anchoring baseline relative to restoredBackendSteps
    currentTodaySteps = restoredBackendSteps;
    service.invoke('updateSteps', {'steps': currentTodaySteps, 'timestamp': DateTime.now().toIso8601String()});
  });

  // ── Pedometer stream ──────────────────────────────────────────────────────
  try {
    Pedometer.stepCountStream.listen((StepCount event) async {
      final totalSensorSteps = event.steps;
      if (totalSensorSteps == 0) return;

      // Check if user is logged in before tracking/syncing steps
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        return;
      }

      // ── Midnight rollover check ───────────────────────────────────────────
      // Re-evaluate today's date on every event so the service detects
      // when midnight passes without restarting.
      final nowDateStr = DateTime.now().toIso8601String().substring(0, 10);
      if (nowDateStr != currentDateStr) {
        // It's a new day — reset the baseline to the current sensor value
        currentDateStr = nowDateStr;
        baseSteps = totalSensorSteps;
        currentTodaySteps = 0;
        restoredBackendSteps = 0;
        prefs.setInt('base_steps', baseSteps);
        prefs.setString('last_step_date', currentDateStr);
        prefs.setInt('last_step_count', 0);
        service.invoke('updateSteps', {'steps': 0, 'timestamp': event.timeStamp.toIso8601String()});
        return;
      }

      // ── Normal step calculation ───────────────────────────────────────────
      if (baseSteps == 0) {
        // First event of new session: lock baseline relative to restoredBackendSteps
        baseSteps = (totalSensorSteps - restoredBackendSteps).clamp(0, totalSensorSteps);
        prefs.setInt('base_steps', baseSteps);
        prefs.setString('last_step_date', currentDateStr);
      } else if (totalSensorSteps < baseSteps) {
        // Device rebooted: sensor counter reset below saved base
        baseSteps = (totalSensorSteps - restoredBackendSteps).clamp(0, totalSensorSteps);
        prefs.setInt('base_steps', baseSteps);
      }

      final todaySteps = (totalSensorSteps - baseSteps).clamp(0, 999999);
      currentTodaySteps = todaySteps;

      prefs.setInt('last_step_count', todaySteps);

      service.invoke('updateSteps', {
        'steps': todaySteps,
        'timestamp': event.timeStamp.toIso8601String(),
      });

      // Instantly sync steps to the backend database on sensor events (throttled to 10 seconds to avoid database locks)
      final now = DateTime.now();
      if (now.difference(lastSyncTime).inSeconds >= 10) {
        lastSyncTime = now;
        prefs.reload().then((_) {
          final currentToken = prefs.getString('jwt_token');
          if (currentToken != null && currentToken.isNotEmpty && todaySteps > 0) {
            _syncToBackend(steps: todaySteps, token: currentToken);
          }
        });
      }
    }, onError: (error) {
      print('Pedometer error in background: $error');
    });
  } catch (e) {
    print('Could not start pedometer in background: $e');
  }

  // ── Sync steps immediately on-demand (triggered by foreground app events) ──
  service.on('syncSteps').listen((event) async {
    await prefs.reload(); // Reload prefs to catch updates from the main isolate
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) return;
    if (currentTodaySteps > 0) {
      await _syncToBackend(steps: currentTodaySteps, token: token);
    }
  });
}

// ─── Direct HTTP sync (no Dio/DioClient — this is a background isolate) ──────
Future<void> _syncToBackend({required int steps, required String token}) async {
  try {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final calories = steps * 0.04;
    final distance = steps * 0.000762;

    // We use dart:io HttpClient directly since Dio/DioClient is not accessible
    // in this isolate.
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    // Read base URL from shared prefs, or use default
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('api_base_url') ?? 'http://127.0.0.1:8081/api';

    final request = await client.postUrl(Uri.parse('$baseUrl/steps/sync'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $token');

    final body =
        '[{"date":"$dateStr","steps":$steps,"calories":$calories,"distance":$distance}]';
    request.contentLength = body.length;
    request.write(body);

    final response = await request.close();
    if (response.statusCode == 200) {
      print('Background sync SUCCESS: $steps steps synced');
    } else {
      print('Background sync failed: HTTP ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('Background sync error: $e');
  }
}

// ─── Service initializer (called from main.dart) ──────────────────────────────
class TrackingService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'circlefit_tracking',
      'CircleFit Tracking Service',
      description: 'Keeps tracking your steps in the background.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (await Permission.activityRecognition.request().isGranted) {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'circlefit_tracking',
          initialNotificationTitle: 'CircleFit',
          initialNotificationContent: 'Tracking your steps...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: (ServiceInstance service) {
            return true;
          },
        ),
      );
      service.startService();
    }
  }

  /// Call this once after login so the background service can find the API base URL.
  static Future<void> saveApiBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', baseUrl);
  }
}
