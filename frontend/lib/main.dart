import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'core/network/dio_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/tracking/data/tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  
  // Configure Open Food Facts API User-Agent globally
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'CircleFit', url: 'https://circlefit.app');
  
  // Restore saved auth token so requests work after app restarts
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('jwt_token');
  if (savedToken != null) {
    DioClient.setAuthToken(savedToken);
  }

  if (!kIsWeb) {
    // Save the API base URL so the background isolate can read it for HTTP sync
    await TrackingService.saveApiBaseUrl(DioClient.baseUrl);
    await TrackingService.initializeService();
  }
  
  runApp(const ProviderScope(child: CircleFitApp()));
}

class CircleFitApp extends ConsumerWidget {
  const CircleFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CircleFit',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
