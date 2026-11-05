import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  // Debug builds only: one short line per call with its status, and the server's message when it fails
  // (the stock logger printed neither the status code nor the error text).
  if (kDebugMode) dio.interceptors.add(_DebugLogInterceptor());

  return dio;
});

class _DebugLogInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('API ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    final message = data is Map ? (data['message'] ?? data['error'] ?? data) : data;
    debugPrint('API ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.method} '
        '${err.requestOptions.path} -> $message');
    handler.next(err);
  }
}
