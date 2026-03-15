import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_provider.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isSplashDone;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isSplashDone = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isSplashDone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isSplashDone: isSplashDone ?? this.isSplashDone,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    // Trigger initial check status after splash delay
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == AuthStatus.initial) {
        state = state.copyWith(isSplashDone: true);
        checkStatus();
      } else {
        // If we already moved away from initial (e.g. login started), just mark splash as done
        state = state.copyWith(isSplashDone: true);
      }
    });
    return AuthState();
  }

  Future<void> checkStatus() async {
    final tokenService = ref.read(authTokenServiceProvider);
    final token = tokenService.getToken();
    final email = tokenService.getEmail();

    // If no token exists, we are unauthenticated (if we were still in initial)
    if (token == null || email == null) {
      if (state.status == AuthStatus.initial) {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      }
      return;
    }

    try {
      final user = await _repository.checkStatus(email);
      
      // GUARD: Only update if we haven't started a manual login or other action
      if (state.status != AuthStatus.initial && state.status != AuthStatus.unauthenticated) {
        return;
      }

      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        
        // Sync FCM token
        try {
          final fcmToken = await NotificationService().getToken();
          if (fcmToken != null) {
            await _repository.updateFcmToken(email, fcmToken);
          }
        } catch (e) {}
      } else {
        await tokenService.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      }
    } catch (e) {
      // Only set to unauthenticated if we were trying to auto-login from initial state
      if (state.status == AuthStatus.initial) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login(String email, String password, String role) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _repository.login(email, password, role);
      // Repository implementation already saves token and email
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Refresh profile to get accurate isApproved status
      await getProfile();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signup(Map<String, dynamic> userData) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _repository.signup(userData);
      // Repository implementation already saves token and email
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      
      // Refresh profile to get accurate isApproved status
      await getProfile();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _repository.verifyOtp(email, otp);
      // Repository implementation already saves token and email
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> getProfile() async {
    final email = ref.read(authTokenServiceProvider).getEmail();
    if (email == null) return;

    try {
      final user = await _repository.getProfile(email);
      state = state.copyWith(user: user);
    } catch (e) {
      // Handle profile fetch error
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final user = await _repository.updateProfile(updateData);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (state.user == null) return;
    try {
      await _repository.changePassword(
        state.user!.email,
        currentPassword,
        newPassword,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
