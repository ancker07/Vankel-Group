import 'package:dio/dio.dart';

abstract class AppExceptions implements Exception {
  final String message;
  final int? statusCode;

  AppExceptions(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppExceptions {
  NetworkException([super.message = 'No Internet Connection', super.statusCode]);
}

class ServerException extends AppExceptions {
  ServerException([super.message = 'Server Error', super.statusCode]);
}

class ValidationException extends AppExceptions {
  final Map<String, dynamic>? errors;
  ValidationException([super.message = 'Validation Error', super.statusCode, this.errors]);
}

class UnauthorizedException extends AppExceptions {
  UnauthorizedException([super.message = 'Unauthorized', super.statusCode]);
}

class NotFoundException extends AppExceptions {
  NotFoundException([super.message = 'Not Found', super.statusCode]);
}

class GenericException extends AppExceptions {
  GenericException([super.message = 'Something went wrong', super.statusCode]);
}

AppExceptions handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException('Connection timeout');
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      var message = (data is Map ? data['message'] : null)?.toString() ?? 'Server Error';
      // Laravel validation: show the first field error (e.g. "file must not be greater than 10240 kilobytes")
      final fieldErrors = data is Map ? data['errors'] : null;
      if (statusCode == 422 && fieldErrors is Map && fieldErrors.isNotEmpty) {
        final first = fieldErrors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
      
      if (statusCode == 401) return UnauthorizedException(message, statusCode);
      if (statusCode == 404) return NotFoundException(message, statusCode);
      if (statusCode == 422) return ValidationException(message, statusCode, data is Map ? Map<String, dynamic>.from(data['errors'] ?? {}) : null);
      if (statusCode != null && statusCode >= 500) return ServerException(message, statusCode);
      
      return GenericException(message, statusCode);
    default:
      return GenericException('Unknown error occurred');
  }
}
