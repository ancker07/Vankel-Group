import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/mobile_access_provider.dart';
import '../services/auth_token_service.dart';

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
    if (err.response?.statusCode == 401) {
      // Handle logout or refresh token logic
      _ref.read(authTokenServiceProvider).clearAll();
    }
    super.onError(err, handler);
  }
}
