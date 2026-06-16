import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/profile/presentation/screens/profile_form_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/create_challenge_screen.dart';
import '../../features/groups/presentation/screens/challenge_detail_screen.dart';
import '../../features/tracking/presentation/screens/food_scanner_screen.dart';
import '../../features/tracking/presentation/screens/food_search_screen.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../shell/main_screen.dart';

class RefreshNotifier extends ChangeNotifier {
  RefreshNotifier(Ref ref) {
    ref.listen(profileProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refreshNotifier,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final isLoggedIn = token != null;
      
      final isAuthPath = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn) {
        return isAuthPath ? null : '/login';
      }

      if (isAuthPath) {
        return '/dashboard';
      }

      // If logged in and at root or dashboard, check if profile is complete
      // Note: We don't block the user from navigating, but we ensure they have a profile
      // before they use the app features if they are at the "entry" points.
      if (state.matchedLocation == '/dashboard' || state.matchedLocation == '/') {
        final profileAsync = ref.read(profileProvider);
        if (profileAsync.hasValue && profileAsync.value != null) {
          if (!profileAsync.value!.isComplete) {
             return '/profile-setup';
          }
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // Main shell routes
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileFormScreen()),
          GoRoute(path: '/scanner', builder: (context, state) => const FoodScannerScreen()),
          GoRoute(path: '/food-search', builder: (context, state) => const FoodSearchScreen()),
          GoRoute(path: '/groups', builder: (context, state) => const GroupsScreen()),
        ],
      ),

      // Full-screen routes
      GoRoute(path: '/groups/create', builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => GroupDetailScreen(
          groupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/groups/:id/challenge',
        builder: (context, state) => CreateChallengeScreen(
          groupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/challenges/:id',
        builder: (context, state) => ChallengeDetailScreen(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
