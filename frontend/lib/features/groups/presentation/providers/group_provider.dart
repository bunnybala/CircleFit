import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/group_repository.dart';
import '../../domain/group_models.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

// ─── My Groups ────────────────────────────────────────────────────────────────

final myGroupsProvider =
    AsyncNotifierProvider<MyGroupsNotifier, List<Group>>(MyGroupsNotifier.new);

class MyGroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  FutureOr<List<Group>> build() =>
      ref.read(groupRepositoryProvider).getMyGroups();

  Future<void> createGroup(String name, String description) async {
    await ref.read(groupRepositoryProvider).createGroup(name, description);
    ref.invalidateSelf();
  }

  Future<void> joinGroup(String inviteCode) async {
    await ref.read(groupRepositoryProvider).joinGroup(inviteCode);
    ref.invalidateSelf();
  }

  Future<void> leaveGroup(int groupId) async {
    await ref.read(groupRepositoryProvider).leaveGroup(groupId);
    ref.invalidateSelf();
  }
}

// ─── Leaderboard sort toggle ──────────────────────────────────────────────────

final leaderboardSortProvider =
    NotifierProvider<_SortNotifier, String>(_SortNotifier.new);

class _SortNotifier extends Notifier<String> {
  @override
  String build() => 'total';
  void set(String val) => state = val;
}

// ─── Leaderboard (family) ─────────────────────────────────────────────────────

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, int>((ref, groupId) {
  final sortBy = ref.watch(leaderboardSortProvider);
  return ref.read(groupRepositoryProvider).getLeaderboard(groupId, sortBy);
});

// ─── Challenges (family — read) ───────────────────────────────────────────────

final challengesProvider =
    FutureProvider.family<List<Challenge>, int>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getChallengesByGroup(groupId);
});

// ─── Challenges mutations (stateful, per-group) ───────────────────────────────
// Separate notifier keyed by groupId used only for write operations.
// After a mutation, call ref.invalidate(challengesProvider(groupId)) to refresh.

class ChallengesNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createChallenge({
    required int groupId,
    required String title,
    required String description,
    required String type,
    required int targetValue,
    required String startDate,
    required String endDate,
  }) async {
    await ref.read(groupRepositoryProvider).createChallenge(
          groupId: groupId,
          title: title,
          description: description,
          type: type,
          targetValue: targetValue,
          startDate: startDate,
          endDate: endDate,
        );
    ref.invalidate(challengesProvider(groupId));
  }

  Future<void> joinChallenge(int challengeId, int groupId) async {
    await ref.read(groupRepositoryProvider).joinChallenge(challengeId);
    ref.invalidate(challengesProvider(groupId));
    ref.invalidate(challengeProgressProvider(challengeId));
  }
}

final challengesMutationProvider =
    AsyncNotifierProvider<ChallengesNotifier, void>(ChallengesNotifier.new);

// ─── Challenge Progress ───────────────────────────────────────────────────────

final challengeProgressProvider =
    FutureProvider.family<List<ChallengeProgress>, int>(
  (ref, challengeId) =>
      ref.read(groupRepositoryProvider).getChallengeProgress(challengeId),
);
