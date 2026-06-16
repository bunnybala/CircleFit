import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../../domain/user_profile.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  String _gender = 'Male';
  String _goal = 'Lose Weight';
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profileAsync = ref.watch(profileProvider);
      profileAsync.whenData((profile) {
        if (profile != null) {
          _nameController.text = profile.name ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _weightController.text = profile.weight?.toString() ?? '';
          _heightController.text = profile.height?.toString() ?? '';
          _calorieGoalController.text = profile.dailyCalorieGoal?.toString() ?? '';
          _gender = profile.gender ?? 'Male';
          _goal = profile.fitnessGoal ?? 'Lose Weight';
          _isInitialized = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _isUploadingImage = true);
      final success = await ref.read(profileProvider.notifier).uploadImage(image);
      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  int? _calculateRecommendedCalories() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || weight == null || height == null) return null;

    double bmr;
    if (_gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Assume 1.375 active multiplier (lightly active)
    double tdee = bmr * 1.375;
    
    double targetCalories = tdee;
    if (_goal == 'Lose Weight') {
      targetCalories -= 500;
    } else if (_goal == 'Build Muscle') {
      targetCalories += 300;
    }

    if (targetCalories < 1200) {
      targetCalories = 1200;
    }

    return targetCalories.round();
  }

  Future<void> _saveProfile(bool isEditing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(profileProvider.notifier).updateProfile({
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text),
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'gender': _gender,
      'fitnessGoal': _goal,
      'dailyCalorieGoal': int.tryParse(_calorieGoalController.text),
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (isEditing) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final isEditing = profileAsync.value?.isComplete ?? false;
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isEditing 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 20),
              onPressed: () => context.pop(),
            )
          : null,
        title: Text(
          isEditing ? 'Edit Profile' : 'Complete Your Profile',
          style: const TextStyle(
            color: Color(0xFF2D3142), 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (_) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarSection(profile),
                  const SizedBox(height: 24),
                  if (!isEditing) ...[
                    const Text(
                      'Welcome to CircleFit!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about yourself to personalize your fitness journey and get smart recommendations!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  _buildSectionHeader('Personal Details'),
                  const SizedBox(height: 12),
                  _buildCardContainer([
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age (years)',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = int.tryParse(v);
                              if (val == null || val <= 0 || val > 120) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val < 50 || val > 300) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val < 10 || val > 500) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGenderSelector(),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Fitness Goals & Nutrition'),
                  const SizedBox(height: 12),
                  _buildCardContainer([
                    _buildGoalSelector(),
                    const SizedBox(height: 8),
                    _buildCalorieRecommendationCard(),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _calorieGoalController,
                      label: 'Daily Calorie Goal (kcal)',
                      icon: Icons.local_fire_department_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = int.tryParse(v);
                        if (val == null || val < 500 || val > 10000) return 'Invalid';
                        return null;
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  _buildSaveButton(isEditing),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildAvatarSection(UserProfile? profile) {
    final hasImage = profile?.profilePicture != null && profile!.profilePicture!.isNotEmpty;
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
               child: Stack(
                 fit: StackFit.expand,
                 children: [
                   CircleAvatar(
                     backgroundColor: const Color(0xFFE8E7FD),
                     backgroundImage: hasImage ? NetworkImage(profile!.profilePicture!) : null,
                     child: !hasImage
                         ? const Icon(Icons.person, size: 55, color: Color(0xFF8B85FF))
                         : null,
                   ),
                   if (_isUploadingImage)
                     Container(
                       color: Colors.black45,
                       child: const Center(
                         child: SizedBox(
                           width: 24,
                           height: 24,
                           child: CircularProgressIndicator(
                             strokeWidth: 2.5,
                             color: Colors.white,
                           ),
                         ),
                       ),
                     ),
                 ],
               ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8585),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (val) {
        if (label.contains('Age') || label.contains('Height') || label.contains('Weight')) {
          setState(() {});
        }
      },
      style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFD),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final genders = [
      {'label': 'Male', 'icon': Icons.male},
      {'label': 'Female', 'icon': Icons.female},
      {'label': 'Other', 'icon': Icons.wc},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          children: genders.map((g) {
            final isSelected = _gender == g['label'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = g['label'] as String;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.08) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[200]!,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        g['icon'] as IconData,
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        g['label'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      {
        'label': 'Lose Weight',
        'desc': 'Maintain a calorie deficit to burn body fat.',
        'icon': Icons.trending_down,
      },
      {
        'label': 'Maintain Weight',
        'desc': 'Keep your energy balanced for overall health.',
        'icon': Icons.favorite_outline,
      },
      {
        'label': 'Build Muscle',
        'desc': 'Combine a calorie surplus with strength training.',
        'icon': Icons.fitness_center_outlined,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Goal',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        ...goals.map((g) {
          final isSelected = _goal == g['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _goal = g['label'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.05) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[200]!,
                  width: isSelected ? 1.8 : 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      g['icon'] as IconData,
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2D3142),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF6C63FF), size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalorieRecommendationCard() {
    final recommended = _calculateRecommendedCalories();
    if (recommended == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bolt, color: Color(0xFF6C63FF), size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Recommended Daily Intake',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$recommended kcal / day',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Calculated using Mifflin-St Jeor formula.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _calorieGoalController.text = recommended.toString();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveProfile(isEditing),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                isEditing ? 'Save Changes' : 'Save & Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
