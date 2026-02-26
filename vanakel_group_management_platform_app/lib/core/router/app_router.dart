import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/admin_dashboard/admin_dashboard.dart';
import '../../features/dashboard/syndic_dashboard/syndic_dashboard.dart';
import '../../features/mission/presentation/missions_screen.dart';
import '../../features/mission/presentation/create_mission_screen.dart';
import '../../features/intervention/presentation/interventions_screen.dart';
import '../../features/intervention/presentation/intervention_details_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../shared/layout/admin_layout.dart';
import '../../shared/layout/syndic_layout.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>();
final _syndicShellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return RegisterScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // Admin Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const AdminDashboard(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/missions',
                builder: (context, state) =>
                    const MissionsScreen(isAdmin: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/interventions',
                builder: (context, state) =>
                    const InterventionsScreen(isAdmin: true),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return InterventionDetailsScreen(interventionId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Syndic Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SyndicLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/syndic/dashboard',
                builder: (context, state) => const SyndicDashboard(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/syndic/missions',
                builder: (context, state) =>
                    const MissionsScreen(isAdmin: false),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateMissionScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/syndic/interventions',
                builder: (context, state) =>
                    const InterventionsScreen(isAdmin: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/syndic/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
