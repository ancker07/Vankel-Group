import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../enums/user_role_enum.dart';
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
  final authState = ref.watch(authStateProvider);

  // Helper to convert Riverpod provider to Listenable for GoRouter
  final refreshListenable = ValueNotifier<AuthState>(authState);
  ref.listen(authStateProvider, (_, next) {
    refreshListenable.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isSplashScreen = state.uri.path == '/splash';
      final isOnboarding = state.uri.path == '/onboarding';
      final isLoginPage = state.uri.path == '/login';
      final isRegisterPage = state.uri.path == '/register';
      final isForgotPasswordPage = state.uri.path == '/forgot-password';

      final isAuthPage =
          isOnboarding || isLoginPage || isRegisterPage || isForgotPasswordPage;

      // 1. Initial State: Always stay on Splash Screen
      if (authState.status == AuthStatus.initial) {
        return isSplashScreen ? null : '/splash';
      }

      // 2. Authenticated: Move away from Auth/Splash pages to Dashboard
      if (authState.status == AuthStatus.authenticated) {
        if (isAuthPage || isSplashScreen) {
          if (authState.user?.role == UserRole.admin) {
            return '/admin/dashboard';
          } else if (authState.user?.role == UserRole.syndic) {
            return '/syndic/dashboard';
          } else if (authState.user?.role == UserRole.technician) {
            return '/technician/dashboard';
          }
        }
        return null;
      }

      // 3. Unauthenticated/Error: Move away from Dashboard/Splash to Onboarding
      if (authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        if (!isAuthPage) {
          return '/onboarding';
        }
      }

      return null;
    },
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
