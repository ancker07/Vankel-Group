import 'package:dio/dio.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final AuthTokenService _tokenService;

  AuthRepositoryImpl(this._dio, this._tokenService);

  @override
  Future<User> login(String email, String password, String role) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password, 'role': role},
      );

      final token = response.data['token'];
      if (token != null) {
        await _tokenService.saveToken(token);
        await _tokenService.saveEmail(email);
      }

      return UserModel.fromJson(response.data['user']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<User> signup(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(ApiConstants.signup, data: userData);
      final user = UserModel.fromJson(response.data['user']).toEntity();
      if (response.data['token'] != null) {
        await _tokenService.saveToken(response.data['token']);
        await _tokenService.saveEmail(user.email);
      }
      return user;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await _dio.post(ApiConstants.sendOtp, data: {'email': email});
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<User> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otp': otp},
      );

      final token = response.data['token'];
      if (token != null) {
        await _tokenService.saveToken(token);
        await _tokenService.saveEmail(email);
      }

      return UserModel.fromJson(response.data['user']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<User?> checkStatus(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkStatus,
        data: {'email': email},
      );
      final isSuccess = response.data['success'] == true;
      if (!isSuccess) {
        return null;
      }

      final status = response.data['status']?.toString().toUpperCase();
      if (status != null && status != 'APPROVED') {
        return null;
      }

      final profileResponse = await _dio.post(
        ApiConstants.profileDetails,
        data: {'email': email},
      );
      final userJson = profileResponse.data['user'];
      if (userJson == null) {
        return null;
      }
      return UserModel.fromJson(userJson).toEntity();
    } on DioException catch (e) {
      // Handle both 401 (Unauthorized) and 422 (Unprocessable Entity)
      // If the backend has been reinstalled, old tokens can cause validation errors or missing user errors
      if (e.response?.statusCode == 401 || e.response?.statusCode == 422) {
        return null;
      }
      throw handleDioError(e);
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.post(
        ApiConstants.profileUpdate,
        data: updateData,
      );
      final user = UserModel.fromJson(response.data['user']).toEntity();
      // If email was updated, save it
      if (updateData.containsKey('email')) {
        await _tokenService.saveEmail(user.email);
      }
      return user;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<User> getProfile(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.profileDetails,
        data: {'email': email},
      );
      return UserModel.fromJson(response.data['user']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    await _tokenService.clearAll();
  }
}
