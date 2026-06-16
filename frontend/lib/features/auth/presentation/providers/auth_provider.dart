import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tracking/presentation/providers/step_provider.dart';
import '../../../tracking/presentation/providers/water_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state to fetch
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).login(email, password);
      
      // Invalidate previous cached user data to force a fresh fetch for the new user
      ref.invalidate(profileProvider);
      ref.invalidate(weeklyStepsProvider);
      ref.invalidate(liveStepProvider);
      ref.invalidate(waterIntakeProvider);
      ref.invalidate(myGroupsProvider);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).register(username, email, password);
      
      // Invalidate previous cached user data to force a fresh fetch for the new user
      ref.invalidate(profileProvider);
      ref.invalidate(weeklyStepsProvider);
      ref.invalidate(liveStepProvider);
      ref.invalidate(waterIntakeProvider);
      ref.invalidate(myGroupsProvider);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
