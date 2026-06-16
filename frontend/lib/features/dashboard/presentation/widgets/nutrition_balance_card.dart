import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tracking/presentation/providers/step_provider.dart';

class NutritionBalanceCard extends ConsumerWidget {
  const NutritionBalanceCard({super.key});

  // Calculate dynamic BMR based on user profile using the Mifflin-St Jeor Equation
  double _calculateBMR(dynamic profile) {
    const double defaultBMR = 1800.0;
    if (profile == null) return defaultBMR;

    final int? age = profile.age as int?;
    final double? height = profile.height != null ? (profile.height as num).toDouble() : null; // cm
    final double? weight = profile.weight != null ? (profile.weight as num).toDouble() : null; // kg
    final String? gender = profile.gender as String?;

    if (age == null || height == null || weight == null) {
      return defaultBMR;
    }

    if (gender != null && (gender.toLowerCase().startsWith('f') || gender.toLowerCase().startsWith('w'))) {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final liveSteps = ref.watch(liveStepProvider);
    final liveCalories = ref.watch(liveCaloriesProvider); // Active steps calories

    return profileState.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final double bmr = _calculateBMR(profile);
        final double eaten = (profile.caloriesConsumed ?? 0.0).toDouble();
        final double burned = bmr + liveCalories; // BMR + Pedometer active burn

        // Net balance: positive = surplus, negative = deficit
        final double netBalance = eaten - burned;
        final double calorieGoal = (profile.dailyCalorieGoal ?? 2000.0).toDouble();

        // Macro estimates (Carbs 45%, Protein 25%, Fats 30%)
        final double carbsGrams = (eaten * 0.45) / 4;
        final double proteinGrams = (eaten * 0.25) / 4;
        final double fatsGrams = (eaten * 0.30) / 9;

        final double targetCarbs = (calorieGoal * 0.45) / 4;
        final double targetProtein = (calorieGoal * 0.25) / 4;
        final double targetFats = (calorieGoal * 0.30) / 9;

        final double carbsProgress = targetCarbs > 0 ? (carbsGrams / targetCarbs).clamp(0.0, 1.0) : 0.0;
        final double proteinProgress = targetProtein > 0 ? (proteinGrams / targetProtein).clamp(0.0, 1.0) : 0.0;
        final double fatsProgress = targetFats > 0 ? (fatsGrams / targetFats).clamp(0.0, 1.0) : 0.0;

        // Scale factors for the Deficit/Surplus gauge needle (-1000 to +1000 range)
        const double maxGaugeRange = 1000.0;
        final double pointerAlignment = (netBalance / maxGaugeRange).clamp(-1.0, 1.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.scale, color: Color(0xFF6C63FF), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Energy & Macronutrients',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // SECTION 1: Calorie Balance Gauge
              const Text(
                'Energy Balance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Custom Drawn Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  // Gauge track background
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF48CFAD), // Green (Deficit)
                          Colors.white,      // Balance Center
                          Color(0xFFFF8585), // Red (Surplus)
                        ],
                        stops: [0.1, 0.5, 0.9],
                      ),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  // Center zero divider
                  Positioned(
                    child: Container(
                      width: 3,
                      height: 20,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  // Floating Pointer Needle
                  Align(
                    alignment: Alignment(pointerAlignment, 0.0),
                    child: Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3142),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Gauge Description labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deficit', style: TextStyle(color: Color(0xFF48CFAD), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    netBalance < 0
                        ? '${netBalance.abs().toInt()} kcal deficit'
                        : netBalance > 0
                            ? '${netBalance.toInt()} kcal surplus'
                            : 'Perfectly balanced',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: netBalance < 0
                          ? const Color(0xFF48CFAD)
                          : netBalance > 0
                              ? const Color(0xFFFF8585)
                              : Colors.grey.shade600,
                    ),
                  ),
                  const Text('Surplus', style: TextStyle(color: Color(0xFFFF8585), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // SECTION 2: Macronutrient Estimates
              const Text(
                'Daily Macro Estimates',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 1. Protein Bar (Coral)
              _buildMacroSlider(
                label: 'Protein (25%)',
                grams: proteinGrams.toInt(),
                target: targetProtein.toInt(),
                progress: proteinProgress,
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 12),

              // 2. Carbs Bar (Blue)
              _buildMacroSlider(
                label: 'Carbohydrates (45%)',
                grams: carbsGrams.toInt(),
                target: targetCarbs.toInt(),
                progress: carbsProgress,
                color: const Color(0xFF6C63FF),
              ),
              const SizedBox(height: 12),

              // 3. Fats Bar (Yellow)
              _buildMacroSlider(
                label: 'Fats (30%)',
                grams: fatsGrams.toInt(),
                target: targetFats.toInt(),
                progress: fatsProgress,
                color: const Color(0xFFFFD93D),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required int grams,
    required int target,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
            ),
            Text(
              '$grams g / $target g',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Gray slider track
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Glowing filled slider track
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
