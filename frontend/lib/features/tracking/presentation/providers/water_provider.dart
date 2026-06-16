import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  WaterIntakeState build() {
    final today = _getTodayDateStr();
    _loadState();
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

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateStr();
    
    final savedMl = prefs.getInt('water_intake_$today') ?? 0;
    final savedGoal = prefs.getInt('water_goal') ?? 2000;
    
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
    // Check if day changed
    if (state.dateStr != today) {
      newMl = 0;
    }

    newMl = (newMl + ml).clamp(0, 10000); // Max cap 10 liters
    
    await prefs.setInt('water_intake_$today', newMl);
    
    state = state.copyWith(
      currentMl: newMl,
      dateStr: today,
    );
  }

  Future<void> resetWater() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateStr();
    
    await prefs.setInt('water_intake_$today', 0);
    
    state = state.copyWith(
      currentMl: 0,
      dateStr: today,
    );
  }

  Future<void> updateGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', goal);
    
    state = state.copyWith(
      goalMl: goal,
    );
  }
}

final waterIntakeProvider = NotifierProvider<WaterIntakeNotifier, WaterIntakeState>(() {
  return WaterIntakeNotifier();
});
