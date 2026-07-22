import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';

class WaterIntakeState {
  final int currentMl;
  final int goalMl;
  final String dateStr;

  WaterIntakeState({
    required this.currentMl,
    required this.goalMl,
    required this.dateStr,
  });

  WaterIntakeState copyWith({
    int? currentMl,
    int? goalMl,
    String? dateStr,
  }) {
    return WaterIntakeState(
      currentMl: currentMl ?? this.currentMl,
      goalMl: goalMl ?? this.goalMl,
      dateStr: dateStr ?? this.dateStr,
    );
  }
}

class WaterIntakeNotifier extends Notifier<WaterIntakeState> {
  final Dio _dio = DioClient.instance;

  @override
  WaterIntakeState build() {
    final today = _getTodayDateStr();
    fetchWaterLog();
    return WaterIntakeState(
      currentMl: 0,
      goalMl: 2000,
      dateStr: today,
    );
  }

  static String _getTodayDateStr() {
    final now = DateTime.now();
    return "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchWaterLog() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateStr();
    
    int savedMl = prefs.getInt('water_intake_$today') ?? 0;
    int savedGoal = prefs.getInt('water_goal') ?? 2000;

    try {
      final response = await _dio.get('/water');
      if (response.statusCode == 200 && response.data != null) {
        savedMl = response.data['amountMl'] as int? ?? 0;
        savedGoal = response.data['goalMl'] as int? ?? 2000;
        
        await prefs.setInt('water_intake_$today', savedMl);
        await prefs.setInt('water_goal', savedGoal);
      }
    } catch (e) {
      // Offline fallback to SharedPreferences
    }

    state = WaterIntakeState(
      currentMl: savedMl,
      goalMl: savedGoal,
      dateStr: today,
    );
  }

  Future<void> addWater(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateStr();

    int newMl = state.currentMl;
    if (state.dateStr != today) {
      newMl = 0;
    }

    newMl = (newMl + ml).clamp(0, 10000);
    await prefs.setInt('water_intake_$today', newMl);
    
    state = state.copyWith(
      currentMl: newMl,
      dateStr: today,
    );

    try {
      await _dio.post('/water/log', data: {
        'amountMl': newMl,
        'goalMl': state.goalMl,
      });
    } catch (_) {}
  }

  Future<void> resetWater() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateStr();
    
    await prefs.setInt('water_intake_$today', 0);
    
    state = state.copyWith(
      currentMl: 0,
      dateStr: today,
    );

    try {
      await _dio.post('/water/reset');
    } catch (_) {}
  }

  Future<void> updateGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', goal);
    
    state = state.copyWith(
      goalMl: goal,
    );

    try {
      await _dio.post('/water/log', data: {
        'amountMl': state.currentMl,
        'goalMl': goal,
      });
    } catch (_) {}
  }
}

final waterIntakeProvider = NotifierProvider<WaterIntakeNotifier, WaterIntakeState>(() {
  return WaterIntakeNotifier();
});
