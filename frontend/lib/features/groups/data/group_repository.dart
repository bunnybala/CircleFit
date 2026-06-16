import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/group_models.dart';
import '../domain/chat_message.dart';

class GroupRepository {
  final Dio _dio = DioClient.instance;

  Future<Group> createGroup(String name, String description) async {
    try {
      final res = await _dio.post('/groups', data: {'name': name, 'description': description});
      return Group.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<Group> joinGroup(String inviteCode) async {
    try {
      final res = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
      return Group.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      await _dio.delete('/groups/$groupId/leave');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<List<Group>> getMyGroups() async {
    final res = await _dio.get('/groups/my');
    return (res.data as List).map((e) => Group.fromJson(e)).toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard(int groupId, String sortBy) async {
    final res = await _dio.get('/groups/$groupId/leaderboard', queryParameters: {'sortBy': sortBy});
    return (res.data as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<Challenge> createChallenge({
    required int groupId,
    required String title,
    required String description,
    required String type,
    required int targetValue,
    required String startDate,
    required String endDate,
  }) async {
    final res = await _dio.post('/challenges', data: {
      'groupId': groupId,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'startDate': startDate,
      'endDate': endDate,
    });
    return Challenge.fromJson(res.data);
  }

  Future<void> joinChallenge(int challengeId) async {
    await _dio.post('/challenges/$challengeId/join');
  }

  Future<List<Challenge>> getChallengesByGroup(int groupId) async {
    final res = await _dio.get('/challenges/group/$groupId');
    return (res.data as List).map((e) => Challenge.fromJson(e)).toList();
  }

  Future<List<ChallengeProgress>> getChallengeProgress(int challengeId) async {
    final res = await _dio.get('/challenges/$challengeId/progress');
    return (res.data as List).map((e) => ChallengeProgress.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getChatHistory(int groupId, int page, int size) async {
    final res = await _dio.get('/groups/$groupId/chat/history', queryParameters: {
      'page': page,
      'size': size,
    });
    return (res.data as List).map((e) => ChatMessage.fromJson(e)).toList();
  }
}
