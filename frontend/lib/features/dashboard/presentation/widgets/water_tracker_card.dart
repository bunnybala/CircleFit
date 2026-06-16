import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tracking/presentation/providers/water_provider.dart';

class WaterTrackerCard extends ConsumerStatefulWidget {
  const WaterTrackerCard({super.key});

  @override
  ConsumerState<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends ConsumerState<WaterTrackerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Repeating controller for the active wave ripple
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterIntakeProvider);
    final current = waterState.currentMl;
    final goal = waterState.goalMl;
    final progress = (current / goal).clamp(0.0, 1.0);

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
                  Icon(Icons.water_drop, color: Color(0xFF48CFAD), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Hydration Tracker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                tooltip: 'Reset daily count',
                onPressed: () {
                  _showResetConfirmation(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Liquid Bubble Container
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing sphere boundary
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF5F7FB),
                      border: Border.all(
                        color: const Color(0xFF48CFAD).withOpacity(0.2),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF48CFAD).withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Animated Liquid Wave clipped to a circle
                  ClipPath(
                    clipper: _CircleClipper(),
                    child: Container(
                      width: 114,
                      height: 114,
                      color: const Color(0xFFE8F8F5),
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedProgress, child) {
                              return CustomPaint(
                                painter: _WaterWavePainter(
                                  wavePhase: _waveController.value * 2 * math.pi,
                                  waterHeightProgress: animatedProgress,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // Centered percentage overlay inside the bubble
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: progress > 0.45 ? Colors.white : const Color(0xFF6C63FF),
                      shadows: [
                        if (progress > 0.45)
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Level details and Quick Add buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$current ml',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily Goal: $goal ml',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildQuickAddButton(
                          label: '+250ml',
                          icon: Icons.local_cafe_outlined,
                          onPressed: () {
                            ref.read(waterIntakeProvider.notifier).addWater(250);
                            _showSplashFeedback(context, 'Added 250ml! ☕');
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildQuickAddButton(
                          label: '+500ml',
                          icon: Icons.local_drink_outlined,
                          onPressed: () {
                            ref.read(waterIntakeProvider.notifier).addWater(500);
                            _showSplashFeedback(context, 'Added 500ml! 🍼');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSplashFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF48CFAD),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tracker?'),
        content: const Text('Do you want to reset your daily water logs back to 0 ml?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8585),
            ),
            onPressed: () {
              ref.read(waterIntakeProvider.notifier).resetWater();
              Navigator.pop(context);
              _showSplashFeedback(context, 'Hydration reset successfully.');
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Clip path to round the custom waves to match the circular container
class _CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom Painter to draw animated layers of sine waves
class _WaterWavePainter extends CustomPainter {
  final double wavePhase;
  final double waterHeightProgress; // 0.0 to 1.0

  _WaterWavePainter({
    required this.wavePhase,
    required this.waterHeightProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Shader for Wave 1 (Translucent back layer, Blue -> Purple gradient)
    final Paint wave1Paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x9948CFAD), Color(0x996C63FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    // Shader for Wave 2 (Denser foreground layer, Mint Teal -> Navy Blue gradient)
    final Paint wave2Paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xCC34BC9D), Color(0xCC5D52E6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    // Calculate dynamic Y center line for waves based on progress
    final baselineY = height - (waterHeightProgress * height);

    // Sine wave details
    const double amplitude1 = 6.0; // wave height
    const double frequency1 = 0.055; // wave density/frequency
    
    const double amplitude2 = 5.0;
    const double frequency2 = 0.08;

    // Wave 1 Path
    final Path path1 = Path();
    path1.moveTo(0, baselineY);
    for (double x = 0; x <= width; x++) {
      final y = baselineY + math.sin((x * frequency1) + wavePhase) * amplitude1;
      path1.lineTo(x, y);
    }
    path1.lineTo(width, height);
    path1.lineTo(0, height);
    path1.close();
    canvas.drawPath(path1, wave1Paint);

    // Wave 2 Path
    final Path path2 = Path();
    path2.moveTo(0, baselineY);
    for (double x = 0; x <= width; x++) {
      final y = baselineY + math.cos((x * frequency2) - wavePhase + math.pi/4) * amplitude2;
      path2.lineTo(x, y);
    }
    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();
    canvas.drawPath(path2, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waterHeightProgress != waterHeightProgress;
  }
}
