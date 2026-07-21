import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tracking/presentation/providers/step_provider.dart';
import '../../../tracking/presentation/providers/water_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _metricUnits = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final liveSteps = ref.watch(liveStepProvider);
    final waterState = ref.watch(waterIntakeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data found'));
          }

          final streak = profile.streakCount ?? 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF6C63FF),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          _buildProfileImage(context, profile.profilePicture),
                          const SizedBox(height: 12),
                          Text(
                            profile.name ?? profile.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/profile-setup'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Streak banner
                      _buildStreakCard(streak),
                      
                      // Daily stats and target progress
                      _buildDailyProgressCard(profile, liveSteps, waterState),
                      const SizedBox(height: 20),

                      // BMI details card
                      _buildBMICard(profile.height, profile.weight),
                      const SizedBox(height: 20),

                      // Achievements section
                      _buildAchievementsCard(profile, liveSteps, waterState),
                      const SizedBox(height: 20),

                      // General details
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailCard(
                        items: [
                          _DetailItem(Icons.cake_outlined, 'Age', '${profile.age ?? "--"} years'),
                          _DetailItem(Icons.height, 'Height', '${profile.height != null ? (_metricUnits ? "${profile.height} cm" : "${(profile.height! / 30.48).toStringAsFixed(1)} ft") : "--"}'),
                          _DetailItem(Icons.monitor_weight_outlined, 'Weight', '${profile.weight != null ? (_metricUnits ? "${profile.weight} kg" : "${(profile.weight! * 2.20462).toStringAsFixed(1)} lbs") : "--"}'),
                          _DetailItem(Icons.wc_outlined, 'Gender', profile.gender ?? "--"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Goal
                      const Text(
                        'Fitness Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildGoalCard(profile.fitnessGoal ?? "Not set"),
                      const SizedBox(height: 20),

                      // Settings toggles
                      const Text(
                        'Settings & Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsCard(),
                      const SizedBox(height: 20),

                      // Support & Info
                      const Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSupportCard(),
                      const SizedBox(height: 32),

                      // Logout
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, String? imageUrl) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(Icons.person, size: 55, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(int streakCount) {
    final hasStreak = streakCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasStreak ? const Color(0xFFFFECEC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasStreak ? const Color(0xFFFFC5C5) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasStreak ? const Color(0xFFFF7A7A).withOpacity(0.15) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: hasStreak ? const Color(0xFFFF5252) : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak ? '$streakCount Day Streak!' : 'No Active Streak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasStreak ? const Color(0xFFD32F2F) : const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasStreak
                      ? 'You are doing great! Keep logging details daily.'
                      : 'Track steps, food, and water to build a daily streak!',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasStreak ? const Color(0xFFE53935).withOpacity(0.8) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard(dynamic profile, int liveSteps, dynamic waterState) {
    final calorieGoal = (profile.dailyCalorieGoal ?? 2000).toDouble();
    final caloriesEaten = (profile.caloriesConsumed ?? 0.0).toDouble();
    final calorieProgress = calorieGoal > 0 ? (caloriesEaten / calorieGoal).clamp(0.0, 1.0) : 0.0;

    final waterGoal = (waterState.goalMl ?? 2000).toDouble();
    final waterConsumed = (waterState.currentMl ?? 0).toDouble();
    final waterProgress = waterGoal > 0 ? (waterConsumed / waterGoal).clamp(0.0, 1.0) : 0.0;

    final stepGoal = 10000.0;
    final stepProgress = (liveSteps / stepGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            title: 'Steps',
            subtitle: '$liveSteps / 10,000 steps',
            progress: stepProgress,
            color: Colors.blueAccent,
            icon: Icons.directions_walk,
          ),
          const SizedBox(height: 14),
          _buildProgressBar(
            title: 'Calories Eaten',
            subtitle: '${caloriesEaten.toInt()} / ${calorieGoal.toInt()} kcal',
            progress: calorieProgress,
            color: Colors.orangeAccent,
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 14),
          _buildProgressBar(
            title: 'Water Hydration',
            subtitle: '${waterConsumed.toInt()} / ${waterGoal.toInt()} ml',
            progress: waterProgress,
            color: Colors.cyan,
            icon: Icons.local_drink_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBMICard(double? height, double? weight) {
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return const SizedBox.shrink();
    }

    final bmi = weight / ((height / 100) * (height / 100));
    String category;
    Color categoryColor;
    String desc;

    if (bmi < 18.5) {
      category = 'Underweight';
      categoryColor = Colors.blue;
      desc = 'You should consider eating nutrient-rich foods to reach a healthy weight.';
    } else if (bmi < 25) {
      category = 'Normal';
      categoryColor = Colors.green;
      desc = 'Great job! You are in a healthy weight range. Maintain your active lifestyle!';
    } else if (bmi < 30) {
      category = 'Overweight';
      categoryColor = Colors.orange;
      desc = 'Adopting a balanced diet and regular cardio/strength sessions will help.';
    } else {
      category = 'Obese';
      categoryColor = Colors.red;
      desc = 'Focus on portion control, tracking calorie limits, and consistent steps.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_outlined, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Body Mass Index (BMI)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: categoryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildBmiSegment(Colors.blue, 'Under', bmi < 18.5)),
              const SizedBox(width: 4),
              Expanded(child: _buildBmiSegment(Colors.green, 'Normal', bmi >= 18.5 && bmi < 25)),
              const SizedBox(width: 4),
              Expanded(child: _buildBmiSegment(Colors.orange, 'Over', bmi >= 25 && bmi < 30)),
              const SizedBox(width: 4),
              Expanded(child: _buildBmiSegment(Colors.red, 'Obese', bmi >= 30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiSegment(Color color, String label, bool isActive) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? color : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(dynamic profile, int liveSteps, dynamic waterState) {
    final totalSteps = (profile.totalSteps ?? 0) + liveSteps;
    final waterConsumed = waterState.currentMl ?? 0;
    final streak = profile.streakCount ?? 0;

    final badges = [
      {
        'title': 'Hydration Hero',
        'desc': 'Logged water today',
        'icon': Icons.opacity,
        'unlocked': waterConsumed > 0,
        'color': Colors.cyan,
      },
      {
        'title': 'Step Pioneer',
        'desc': 'Walked over 5,000 steps',
        'icon': Icons.directions_run,
        'unlocked': totalSteps >= 5000,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Consistent Fit',
        'desc': 'Active daily streak',
        'icon': Icons.local_fire_department,
        'unlocked': streak > 0,
        'color': Colors.redAccent,
      },
      {
        'title': 'Nutri-Tracker',
        'desc': 'Logged calorie intake',
        'icon': Icons.restaurant_menu,
        'unlocked': (profile.caloriesConsumed ?? 0.0) > 0.0,
        'color': Colors.orangeAccent,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements & Badges',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((b) {
              final unlocked = b['unlocked'] as bool;
              final color = b['color'] as Color;
              return Tooltip(
                message: b['desc'] as String,
                child: Column(
                  children: [
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: unlocked ? color.withOpacity(0.12) : Colors.grey[100],
                         shape: BoxShape.circle,
                         border: Border.all(
                           color: unlocked ? color : Colors.transparent,
                           width: 1.5,
                         ),
                       ),
                       child: Icon(
                         b['icon'] as IconData,
                         color: unlocked ? color : Colors.grey[400],
                         size: 26,
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       b['title'] as String,
                       style: TextStyle(
                         fontSize: 10,
                         fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                         color: unlocked ? const Color(0xFF2D3142) : Colors.grey[400],
                       ),
                       textAlign: TextAlign.center,
                     ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required List<_DetailItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: const Color(0xFF6C63FF), size: 20),
            ),
            title: Text(
              item.label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Text(
              item.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(String goal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            goal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Daily reminders enabled' : 'Daily reminders disabled'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            title: const Text('Daily Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Get reminded to log steps, meals, & water', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF6C63FF), size: 20),
            ),
            activeColor: const Color(0xFF6C63FF),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          SwitchListTile.adaptive(
            value: _metricUnits,
            onChanged: (bool value) {
              setState(() {
                _metricUnits = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Switched to Metric units (kg, cm)' : 'Switched to Imperial units (lbs, ft)'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            title: const Text('Metric System', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Display details in kg/cm vs. lbs/ft', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.square_foot_outlined, color: Color(0xFF6C63FF), size: 20),
            ),
            activeColor: const Color(0xFF6C63FF),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          SwitchListTile.adaptive(
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark Mode is coming soon! Theme toggled in preview.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Sleek interface layout theme', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6C63FF), size: 20),
            ),
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSupportTile(Icons.help_outline, 'Help & Support', 'Get help with tracking & sync', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help desk is offline. Support: support@circlefit.com')),
            );
          }),
          Divider(height: 1, color: Colors.grey[100]),
          _buildSupportTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read our terms of service', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Policy is available at circlefit.com/privacy')),
            );
          }),
          Divider(height: 1, color: Colors.grey[100]),
          _buildSupportTile(Icons.info_outline, 'App Version', 'v1.0.4', null),
        ],
      ),
    );
  }

  Widget _buildSupportTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(authRepositoryProvider).logout();
          
          ref.invalidate(profileProvider);
          ref.invalidate(weeklyStepsProvider);
          ref.invalidate(liveStepProvider);
          ref.invalidate(waterIntakeProvider);
          ref.invalidate(myGroupsProvider);

          if (context.mounted) {
            context.go('/login');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFFF8585)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFFF8585),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
