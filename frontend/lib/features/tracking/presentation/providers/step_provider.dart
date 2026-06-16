import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/step_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final stepRepositoryProvider = Provider((ref) => StepRepository());

// Holds the live step count for today (updated in real-time from the background service)
final liveStepProvider = NotifierProvider<LiveStepNotifier, int>(() {
  return LiveStepNotifier();
});

// Holds live calories (estimated: steps * 0.04 kcal is a basic estimate)
final liveCaloriesProvider = Provider<double>((ref) {
  final steps = ref.watch(liveStepProvider);
  return steps * 0.04;
});

class LiveStepNotifier extends Notifier<int> {
  StreamSubscription? _subscription;

  @override
  int build() {
    _initAndListen();

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return 0;
  }

  Future<void> _initAndListen() async {
    // ── Step 1: Immediately restore the last-known count from SharedPreferences
    // so the UI shows real steps the moment the dashboard opens.
    final prefs = await SharedPreferences.getInstance();

    final lastDateStr = prefs.getString('last_step_date');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDateStr == null || lastDateStr == todayStr) {
      // Same day — restore last known count for immediate display
      final lastCount = prefs.getInt('last_step_count') ?? 0;
      if (lastCount > 0) {
        state = lastCount;
      }
    }
    // If it's a new day, state stays 0 (correct — new day, fresh count)

    // On Web, there is no background step service.
    if (kIsWeb) return;

    // ── Step 2: Listen to live updates forwarded from the background service
    // The background service owns the pedometer stream AND the 5-minute sync timer.
    // This listener only updates the UI display.
    final service = FlutterBackgroundService();
    _subscription = service.on('updateSteps').listen((event) {
      if (event == null) return;
      final todaySteps = event['steps'] as int? ?? 0;
      if (todaySteps >= 0) {
        state = todaySteps;
      }
    });
  }
}

final weeklyStepsProvider = FutureProvider<List<DailyStepData>>((ref) async {
  final repo = ref.watch(stepRepositoryProvider);
  return repo.getWeeklySteps();
});
