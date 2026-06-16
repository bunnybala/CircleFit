class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? name;
  final int? age;
  final double? height;
  final double? weight;
  final String? gender;
  final String? fitnessGoal;
  final int? dailyCalorieGoal;
  final String? profilePicture;
  final int? totalSteps;
  final double? caloriesBurned;
  final double? caloriesConsumed;
  final int? streakCount;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.fitnessGoal,
    this.dailyCalorieGoal,
    this.profilePicture,
    this.totalSteps,
    this.caloriesBurned,
    this.caloriesConsumed,
    this.streakCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      name: json['name'],
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      gender: json['gender'],
      fitnessGoal: json['fitnessGoal'],
      dailyCalorieGoal: json['dailyCalorieGoal'],
      profilePicture: json['profilePicture'],
      totalSteps: json['totalSteps'],
      caloriesBurned: json['caloriesBurned']?.toDouble(),
      caloriesConsumed: json['caloriesConsumed']?.toDouble(),
      streakCount: json['streakCount'],
    );
  }

  bool get isComplete => name != null && name!.trim().isNotEmpty;
}
