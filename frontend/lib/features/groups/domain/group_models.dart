class Group {
  final int id;
  final String name;
  final String description;
  final String inviteCode;
  final String createdByUsername;
  final int memberCount;
  final int maxMembers;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.createdByUsername,
    required this.memberCount,
    required this.maxMembers,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        inviteCode: json['inviteCode'],
        createdByUsername: json['createdByUsername'],
        memberCount: json['memberCount'],
        maxMembers: json['maxMembers'],
      );
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final String name;
  final String? profilePicture;
  final int totalSteps;
  final int todaySteps;
  final double caloriesBurned;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.name,
    this.profilePicture,
    required this.totalSteps,
    required this.todaySteps,
    required this.caloriesBurned,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'],
        username: json['username'],
        name: json['name'],
        profilePicture: json['profilePicture'],
        totalSteps: json['totalSteps'],
        todaySteps: json['todaySteps'],
        caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      );
}

class Challenge {
  final int id;
  final int groupId;
  final String groupName;
  final String title;
  final String description;
  final String type; // STEPS or CALORIES
  final int targetValue;
  final String startDate;
  final String endDate;
  final String status;
  final String createdByUsername;
  final int participantCount;

  Challenge({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdByUsername,
    required this.participantCount,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'],
        groupId: json['groupId'],
        groupName: json['groupName'],
        title: json['title'],
        description: json['description'] ?? '',
        type: json['type'],
        targetValue: json['targetValue'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        status: json['status'],
        createdByUsername: json['createdByUsername'],
        participantCount: json['participantCount'],
      );
}

class ChallengeProgress {
  final String username;
  final String name;
  final String? profilePicture;
  final int currentProgress;
  final int targetValue;
  final String type;
  final double percentComplete;

  ChallengeProgress({
    required this.username,
    required this.name,
    this.profilePicture,
    required this.currentProgress,
    required this.targetValue,
    required this.type,
    required this.percentComplete,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) => ChallengeProgress(
        username: json['username'],
        name: json['name'],
        profilePicture: json['profilePicture'],
        currentProgress: json['currentProgress'],
        targetValue: json['targetValue'],
        type: json['type'],
        percentComplete: (json['percentComplete'] as num).toDouble(),
      );
}
