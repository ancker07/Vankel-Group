import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/mobile_access_provider.dart';
import '../services/auth_token_service.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authTokenServiceProvider).getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Tells the server this is the phone app (it can switch the whole app off)
    options.headers['X-App'] = 'mobile';
    // The server answers (validation errors, messages, e-mails) in the language chosen in the app
    options.headers['Accept-Language'] = _ref.read(localeProvider).languageCode;
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // The super admin switched the mobile app off: show the "switched off" screen instead of errors everywhere
    final body = err.response?.data;
    if (err.response?.statusCode == 503 && body is Map && body['code'] == 'MOBILE_DISABLED') {
      _ref.read(mobileAccessProvider.notifier).disable();
    }
    // A 401 on a signed-in session: the auth notifier checks with the server whether the login is really gone. The
    // saved login is never wiped here, so a single odd answer cannot sign the user out.
    if (err.response?.statusCode == 401 &&
        _ref.read(authTokenServiceProvider).getToken() != null &&
        !err.requestOptions.path.contains('/login')) {
      _ref.read(authStateProvider.notifier).onUnauthorized();
    }
    super.onError(err, handler);
  }
}
