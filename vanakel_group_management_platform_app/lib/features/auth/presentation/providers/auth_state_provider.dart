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
      state = state.copyWith(isSplashDone: true);
      checkStatus();
    });
    return AuthState();
  }

  Future<void> checkStatus() async {
    final tokenService = ref.read(authTokenServiceProvider);
    final token = tokenService.getToken();
    final email = tokenService.getEmail();

    // If no token or email exists in SharedPreferences, we are definitely unauthenticated
    if (token == null || email == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      return;
    }

    try {
      final user = await _repository.checkStatus(email);
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        
        // Sync FCM token on every startup
        try {
          final fcmToken = await NotificationService().getToken();
          if (fcmToken != null) {
            await _repository.updateFcmToken(email, fcmToken);
          }
        } catch (e) {
          // Non-blocking
        }
      } else {
        // If user is null, it means unauthorized or unprocessable (e.g. invalid token after reinstall)
        // Ensure the token/email are cleared locally
        await tokenService.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      }
    } catch (e) {
      // If we can't check status (e.g. no internet), but we have a token,
      // stay unauthenticated for safety to avoid being stuck on Splash
      state = state.copyWith(status: AuthStatus.unauthenticated);
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
