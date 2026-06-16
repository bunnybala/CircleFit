import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tracking/presentation/providers/step_provider.dart';
import '../../../tracking/data/step_repository.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/nutrition_balance_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _selectedBarIndex;
  Timer? _foregroundSyncTimer;

  @override
  void initState() {
    super.initState();
    // 1. Immediately trigger an automatic sync when the app is opened
    _triggerSync();

    // 2. Set up a 1-minute periodic sync timer when the app is open (foreground)
    _foregroundSyncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _triggerSync();
    });
  }

  @override
  void dispose() {
    _foregroundSyncTimer?.cancel();
    super.dispose();
  }

  void _triggerSync() {
    if (kIsWeb) return;
    final service = FlutterBackgroundService();
    service.invoke('syncSteps');
  }

  String _getWeekdayName(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  List<DailyStepData> _getCompletedWeeklyData(List<DailyStepData> rawData) {
    final today = DateTime.now();
    final Map<String, DailyStepData> map = {
      for (var d in rawData) d.date.toIso8601String().substring(0, 10): d
    };

    final List<DailyStepData> completed = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = date.toIso8601String().substring(0, 10);
      if (map.containsKey(key)) {
        completed.add(map[key]!);
      } else {
        completed.add(DailyStepData(
          date: date,
          steps: 0,
          calories: 0.0,
          distance: 0.0,
        ));
      }
    }
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final liveSteps = ref.watch(liveStepProvider);
    final liveCalories = ref.watch(liveCaloriesProvider);
    final weeklyStepsAsync = ref.watch(weeklyStepsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('CircleFit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          )
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Failed to load profile.'));

          final stepGoal = 10000;
          final stepProgress = (liveSteps / stepGoal).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(weeklyStepsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_greeting()}, ${profile.name ?? profile.username}! 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep pushing your limits!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Big Step Counter Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF48CFAD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Today's Steps",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        // Circular progress indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CustomPaint(
                                painter: _CircleProgressPainter(progress: stepProgress),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$liveSteps',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'of $stepGoal',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: stepProgress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(stepProgress * 100).toInt()}% of daily goal',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildWeeklyChartCard(weeklyStepsAsync, stepGoal),

                  const SizedBox(height: 20),

                  const WaterTrackerCard(),

                  const SizedBox(height: 20),

                  const NutritionBalanceCard(),

                  const SizedBox(height: 20),

                  // Metric cards grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        title: 'Burned',
                        value: '${liveCalories.toInt()}',
                        unit: 'kcal',
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFFF6B6B),
                      ),
                      _buildMetricCard(
                        title: 'Eaten',
                        value: '${(profile.caloriesConsumed ?? 0).toInt()}',
                        unit: 'kcal',
                        icon: Icons.restaurant,
                        color: Colors.orange,
                      ),
                      _buildMetricCard(
                        title: 'Distance',
                        value: (liveSteps * 0.000762).toStringAsFixed(2),
                        unit: 'km',
                        icon: Icons.map_outlined,
                        color: const Color(0xFF48CFAD),
                      ),
                      _buildMetricCard(
                        title: 'Streak',
                        value: '${profile.streakCount ?? 0}',
                        unit: 'days',
                        icon: Icons.bolt,
                        color: const Color(0xFFFFD93D),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tracking status banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sensors, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Step tracking is active · Syncs every 1 minute while open',
                            style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'search_food',
            onPressed: () => context.push('/food-search'),
            backgroundColor: const Color(0xFF48CFAD),
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Search Food', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'scan_food',
            onPressed: () => context.push('/scanner'),
            backgroundColor: const Color(0xFF6C63FF),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text('Scan Food', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard(AsyncValue<List<DailyStepData>> weeklyStepsAsync, int stepGoal) {
    return weeklyStepsAsync.when(
      data: (rawData) {
        final completedData = _getCompletedWeeklyData(rawData);
        
        // Calculate average steps
        final totalSteps = completedData.map((d) => d.steps).fold(0, (a, b) => a + b);
        final avgSteps = completedData.isEmpty ? 0 : (totalSteps / completedData.length).round();

        // Find max steps to scale heights dynamically
        final maxStepsInWeek = completedData.map((d) => d.steps).fold(1, (a, b) => a > b ? a : b);
        final maxScale = math.max(maxStepsInWeek, stepGoal);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: Color(0xFF6C63FF), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Weekly Activity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                    ],
                  ),
                  Text(
                    'Daily Avg: $avgSteps steps',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF48CFAD)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Dynamic details overlay / tooltip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _selectedBarIndex != null
                        ? '${_getWeekdayName(completedData[_selectedBarIndex!].date)}: ${completedData[_selectedBarIndex!].steps} steps'
                        : 'Tap on any bar to see daily steps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedBarIndex != null ? const Color(0xFF6C63FF) : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Chart column layout
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(completedData.length, (index) {
                    final dayData = completedData[index];
                    final barHeightFactor = (dayData.steps / maxScale).clamp(0.01, 1.0);
                    final isSelected = _selectedBarIndex == index;
                    final reachedGoal = dayData.steps >= stepGoal;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBarIndex = isSelected ? null : index;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Grey bar background track
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0EFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    // Active colored bar filled up to the height factor
                                    FractionallySizedBox(
                                      heightFactor: barHeightFactor,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isSelected
                                                ? [const Color(0xFFFF8585), const Color(0xFFFFD93D)]
                                                : reachedGoal
                                                    ? [const Color(0xFF48CFAD), const Color(0xFF6C63FF)]
                                                    : [const Color(0xFF8B85FF), const Color(0xFF6C63FF)],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            if (isSelected)
                                              BoxShadow(
                                                color: const Color(0xFFFF8585).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getWeekdayName(dayData.date).substring(0, 3),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      ),
      error: (err, stack) => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'Failed to load weekly activity: $err',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Custom painter for the circular step progress
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
