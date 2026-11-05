import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_provider.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
  awaitingOtp,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isSplashDone;
  final Map<String, dynamic>? pendingUserData;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isSplashDone = false,
    this.pendingUserData,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false, // `user: null` cannot clear it (null means "unchanged")
    String? errorMessage,
    bool? isSplashDone,
    Map<String, dynamic>? pendingUserData,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage ?? this.errorMessage,
      isSplashDone: isSplashDone ?? this.isSplashDone,
      pendingUserData: pendingUserData ?? this.pendingUserData,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  /// Error code (not a sentence) for "this account may not use the phone app"; the login screen shows it translated.
  static const mobileNotAllowed = 'MOBILE_ACCOUNT_NOT_ALLOWED';

  late AuthRepository _repository;

  @override
  AuthState build() {
    ref.keepAlive();
    
    // We watch the repository provider to ensure we stay updated if it changes
    // But since it's a simple Provider, it stays stable unless the whole app rebuilds
    _repository = ref.watch(authRepositoryProvider);
    
    // Trigger initial check status after splash delay, but only once
    if (!_isInitialized) {
      _init();
    }
    
    return AuthState();
  }

  bool _isInitialized = false;
  void _init() {
    _isInitialized = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      final user = state.user;
      if (state.status == AuthStatus.authenticated && user != null) {
        _repository.updateFcmToken(user.email, fcmToken).catchError((_) {});
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == AuthStatus.initial) {
        state = state.copyWith(isSplashDone: true);
        checkStatus();
      } else {
        state = state.copyWith(isSplashDone: true);
      }
    });
  }

  /// The profile of the saved session, as it was last received from the server.
  User? _savedUser() {
    final json = ref.read(authTokenServiceProvider).getUserJson();
    if (json == null) return null;
    try {
      return UserModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  int _restoreFailures = 0;

  /// Restores the saved session when the app starts.
  ///
  /// The user stays signed in until they press Logout. So the app opens signed in at once from the saved profile
  /// (also with no signal, or while the server is busy, e.g. when a notification opens the app), and only then asks
  /// the server. Only a clear answer from the server that the session is over ends it (see [_sessionIsGone]); no
  /// network problem, timeout, server error or odd answer ever does.
  Future<void> checkStatus() async {
    final tokenService = ref.read(authTokenServiceProvider);
    final token = tokenService.getToken();
    final email = tokenService.getEmail() ?? '';

    // No saved login at all: nothing to restore
    if (token == null) {
      if (state.status == AuthStatus.initial) {
        state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      }
      return;
    }

    // 1. Open signed in right away from the saved profile ...
    var restoredFromSaved = false;
    final saved = _savedUser();
    if (saved != null && saved.mayUseMobileApp && state.status == AuthStatus.initial) {
      state = state.copyWith(status: AuthStatus.authenticated, user: saved);
      restoredFromSaved = true;
    }

    // 2. ... then ask the server what is new (permissions, approval, name ...)
    User? fresh;
    Object? problem;
    try {
      fresh = await _repository.checkStatus(email);
    } catch (e) {
      problem = e;
    }

    // The user logged in / out by hand in the meantime: leave that alone
    final unchanged = restoredFromSaved
        ? state.status == AuthStatus.authenticated
        : (state.status == AuthStatus.initial || state.status == AuthStatus.unauthenticated);
    if (!unchanged) return;

    if (problem != null) {
      // No signal, a slow or busy server, an odd answer: never a reason to sign out
      if (!restoredFromSaved) _retryRestore();
      return;
    }

    if (fresh == null) {
      // The server says the session is over (e.g. an admin reset the password). Make sure it was not a one-off.
      if (!await _sessionIsGone(email)) {
        if (!restoredFromSaved) _retryRestore();
        return;
      }
      await tokenService.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      return;
    }

    // The phone app is for admins and technicians only (e.g. an old super admin session is closed)
    if (!fresh.mayUseMobileApp) {
      await _repository.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      return;
    }

    state = state.copyWith(status: AuthStatus.authenticated, user: fresh);

    // Sync FCM token
    try {
      final fcmToken = await NotificationService().getToken();
      if (fcmToken != null) {
        await _repository.updateFcmToken(email, fcmToken);
      }
    } catch (e) {}
  }

  /// No saved profile to open with (e.g. the first start after an update) and the server cannot be reached: try
  /// again a few times. The saved login is kept either way, so the next start tries again.
  void _retryRestore() {
    _restoreFailures++;
    if (_restoreFailures > 3) {
      if (state.status == AuthStatus.initial) state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    Future.delayed(const Duration(seconds: 4), () {
      if (state.status == AuthStatus.initial) checkStatus();
    });
  }

  /// True only when the server says "not logged in" twice in a row. Any other outcome (it answers "fine", cannot be
  /// reached, fails) means the session is not known to be over.
  Future<bool> _sessionIsGone(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      return await _repository.checkStatus(email) == null;
    } catch (_) {
      return false;
    }
  }

  bool _verifyingSession = false;

  /// Called by the HTTP client when a request is answered with 401. One odd answer must not sign anybody out:
  /// the session is only closed when the server confirms it twice that this login is no longer valid.
  Future<void> onUnauthorized() async {
    if (_verifyingSession || state.status != AuthStatus.authenticated) return;
    _verifyingSession = true;
    try {
      final tokenService = ref.read(authTokenServiceProvider);
      final email = tokenService.getEmail() ?? '';
      try {
        if (await _repository.checkStatus(email) != null) return; // still valid
      } catch (_) {
        return; // cannot tell (no signal, server busy): keep the session
      }
      if (await _sessionIsGone(email)) {
        await tokenService.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      }
    } finally {
      _verifyingSession = false;
    }
  }

  Future<void> login(String email, String password, String role) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repository.login(email, password, role);
      if (!user.mayUseMobileApp) {
        await _repository.logout();
        state = state.copyWith(status: AuthStatus.error, errorMessage: mobileNotAllowed);
        return;
      }
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
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repository.signup(userData);
      
      // If the backend didn't return a "real" user (id -1), it means OTP is pending
      if (user.id == -1) {
        state = state.copyWith(
          status: AuthStatus.awaitingOtp, 
          user: user,
          pendingUserData: userData,
        );
      } else {
        // Repository implementation already saves token and email
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        // Refresh profile to get accurate isApproved status
        await getProfile();
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.user == null) return;
    
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final email = state.user!.email;
      
      // Merge pending user data with verifyOtp call if needed
      // Actually AuthController.php verifyOtp takes firstName, lastName etc.
      // We should send the full data from pendingUserData
      final signupData = Map<String, dynamic>.from(state.pendingUserData ?? {});
      signupData['otp'] = otp;
      
      // Re-use current implementation or update it
      // The current repo verifyOtp takes (email, otp)
      // We need it to take the full registration details as per AuthController.php:94
      
      final user = await _repository.verifyOtp(
        email, 
        otp, 
        extraData: state.pendingUserData,
      );
      
      // If the backend verifyOtp handles the full creation, we are good.
      state = state.copyWith(status: AuthStatus.authenticated, user: user, pendingUserData: null);
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
    state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
