import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../../features/mission/presentation/mission_details_screen.dart';
import '../../features/intervention/presentation/interventions_screen.dart';
import '../../features/intervention/presentation/intervention_details_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/auth/presentation/waiting_approval_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
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
      if (kDebugMode) {
        print('GoRouter Redirect: ${state.uri.path}, AuthStatus: ${authState.status}, User: ${authState.user?.email}');
      }
      final isSplashScreen = state.uri.path == '/splash';
      final isOnboarding = state.uri.path == '/onboarding';
      final isLoginPage = state.uri.path == '/login';
      final isRegisterPage = state.uri.path == '/register';
      final isForgotPasswordPage = state.uri.path == '/forgot-password';
      final isWaitingApprovalPage = state.uri.path == '/waiting-approval';

      final isAuthPage =
          isOnboarding || isLoginPage || isRegisterPage || isForgotPasswordPage;

      // 0. Splash State: Always stay on Splash Screen until done
      if (!authState.isSplashDone) {
        // If we are already on an Auth Page or Waiting Approval, don't force back to Splash
        if (isAuthPage || isWaitingApprovalPage) {
          return null;
        }
        return isSplashScreen ? null : '/splash';
      }

      // 1. Authenticated: Move away from Auth/Splash pages to Dashboard
      if (authState.status == AuthStatus.authenticated) {
        if (isAuthPage || isSplashScreen) {
          if (authState.user?.role == UserRole.admin) {
            if (authState.user?.isApproved != true) {
              return '/waiting-approval';
            }
            return '/admin/dashboard';
          } else if (authState.user?.role == UserRole.syndic) {
            if (authState.user?.isApproved != true) {
              return '/waiting-approval';
            }
            return '/syndic/dashboard';
          } else if (authState.user?.role == UserRole.technician) {
            if (authState.user?.isApproved != true) {
              return '/waiting-approval';
            }
            return '/technician/dashboard';
          }
        }

        // Handle unapproved redirection from any protected route
        if (authState.user?.isApproved != true && !isWaitingApprovalPage) {
          return '/waiting-approval';
        }

        // Handle approved user moving away from waiting screen
        if (authState.user?.isApproved == true && isWaitingApprovalPage) {
          if (authState.user?.role == UserRole.admin) {
            return '/admin/dashboard';
          } else if (authState.user?.role == UserRole.syndic) {
            return '/syndic/dashboard';
          } else {
            return '/technician/dashboard';
          }
        }

        return null;
      }

      // 2. Unauthenticated: Move away from protected pages to Onboarding
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isAuthPage && !isSplashScreen) {
          return '/onboarding';
        }
        // If we were on Splash and auto-login failed, go to onboarding
        if (isSplashScreen && authState.isSplashDone) {
          return '/onboarding';
        }
      }

      // 3. Error State: Move to login if we are stuck on splash or a protected page
      if (authState.status == AuthStatus.error) {
        if (isSplashScreen || !isAuthPage) {
          return '/login';
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
      GoRoute(
        path: '/waiting-approval',
        builder: (context, state) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
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
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MissionDetailsScreen(missionId: id);
                    },
                  ),
                ],
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
                    parentNavigatorKey: _rootNavigatorKey,
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
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
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateMissionScreen(),
                  ),
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MissionDetailsScreen(missionId: id);
                    },
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
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
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
                path: '/syndic/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
