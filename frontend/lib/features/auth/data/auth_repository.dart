import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../tracking/data/step_repository.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userId = response.data['id']?.toString() ?? '';
        final username = response.data['username'] ?? '';
        
        final prefs = await SharedPreferences.getInstance();
        final previousUserId = prefs.getString('active_user_id');

        // If switching accounts, clear cached step baseline so new user starts fresh
        if (previousUserId != null && previousUserId != userId) {
          await prefs.remove('base_steps');
          await prefs.remove('last_step_count');
          await prefs.remove('last_step_date');
        }

        await prefs.setString('jwt_token', token);
        await prefs.setString('active_user_id', userId);
        await prefs.setString('active_username', username);
        
        DioClient.setAuthToken(token);
        
        // Fetch existing steps from backend for this user for today
        int initialTodaySteps = 0;
        try {
          initialTodaySteps = await StepRepository().fetchTodaySteps();
        } catch (_) {}

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        await prefs.setInt('last_step_count', initialTodaySteps);
        await prefs.setString('last_step_date', todayStr);

        // Notify background tracking service of user login
        FlutterBackgroundService().invoke('userLoggedIn', {
          'userId': userId,
          'username': username,
          'initialSteps': initialTodaySteps,
        });

        return response.data;
      } else {
        throw Exception('Failed to login');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to register');
      }

      // Auto-login after registration to acquire a JWT token
      await login(email, password);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('active_user_id');
    await prefs.remove('active_username');
    await prefs.remove('base_steps');
    await prefs.remove('last_step_count');
    await prefs.remove('last_step_date');
    DioClient.clearAuthToken();

    // Notify background tracking service of logout
    FlutterBackgroundService().invoke('userLoggedOut');
  }
  
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      DioClient.setAuthToken(token);
      return true;
    }
    return false;
  }
}
