import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

class StepRepository {
  final Dio _dio = DioClient.instance;

  /// Syncs today's step data to the backend.
  /// Loads the JWT token from SharedPreferences each time to handle the case
  /// where the call originates from a background isolate with no in-memory token.
  Future<void> syncSteps({
    required int steps,
    required double calories,
    required double distance,
  }) async {
    try {
      // Ensure the JWT token is set — critical for background isolate calls
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        print('Step sync skipped: no auth token');
        return;
      }
      DioClient.setAuthToken(token);

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _dio.post('/steps/sync', data: [
        {
          'date': dateStr,
          'steps': steps,
          'calories': calories,
          'distance': distance,
        }
      ]);
      print('Step sync SUCCESS: $steps steps saved');
    } on DioException catch (e) {
      // Silently fail — don't crash the app if sync fails
      print('Step sync failed: ${e.response?.statusCode} ${e.message}');
    }
  }
  Future<List<DailyStepData>> getWeeklySteps() async {
    try {
      final response = await _dio.get('/steps/weekly');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DailyStepData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load weekly steps');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch weekly step statistics');
    }
  }

  Future<int> fetchTodaySteps() async {
    try {
      final response = await _dio.get('/steps/today');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['steps'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

class DailyStepData {
  final DateTime date;
  final int steps;
  final double calories;
  final double distance;

  DailyStepData({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distance,
  });

  factory DailyStepData.fromJson(Map<String, dynamic> json) {
    return DailyStepData(
      date: DateTime.parse(json['date']),
      steps: json['steps'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
