import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/enums/user_role_enum.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final AuthTokenService _tokenService;

  AuthRepositoryImpl(this._dio, this._tokenService);

  @override
  Future<User> login(String email, String password, String role) async {
    try {
      // Send the device token with the login itself so the server registers
      // this phone for push even if the follow-up sync below fails.
      String? deviceToken;
      try {
        deviceToken = await NotificationService()
            .getToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

      final response = await _dio.post(
        ApiConstants.login,
        data: {
          if (role == 'PROFESSIONAL') 'username': email else 'email': email,
          'password': password,
          'role': role,
          'app': 'mobile', // the phone app only lets admins and technicians in
          if (deviceToken != null && deviceToken.isNotEmpty) 'fcm_token': deviceToken,
        },
      );

      final loggedIn = UserModel.fromJson(response.data['user']).toEntity();
      await _tokenService.saveUserJson(Map<String, dynamic>.from(response.data['user'] as Map));
      // Remember the account's real e-mail, not what was typed: a technician types a username, and a
      // username sent where an e-mail is expected used to make the next app start look like a bad session.
      final accountEmail = loggedIn.email.isNotEmpty ? loggedIn.email : email;

      final token = response.data['token'];
      if (token != null) {
        await _tokenService.saveToken(token);
        await _tokenService.saveEmail(accountEmail);
        
        // Sync FCM token (retry once; the token can be late right after install)
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final fcmToken = await NotificationService().getToken();
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await updateFcmToken(accountEmail, fcmToken);
              break;
            }
          } catch (e) {
            if (kDebugMode) print('SYNC: FCM sync attempt ${attempt + 1} failed: $e');
          }
          await Future.delayed(const Duration(seconds: 3));
        }

        // Sync the onboarding-selected language now that we're authenticated
        try {
          final prefs = await SharedPreferences.getInstance();
          final languageCode = prefs.getString('selected_locale');
          if (languageCode != null) {
            await _dio.post(ApiConstants.updateLocale, data: {'locale': languageCode});
          }
        } catch (e) {
          // Non-blocking
        }
      }

      return loggedIn;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<User> signup(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(ApiConstants.signup, data: userData);
      final userJson = response.data['user'];
      final token = response.data['token'];

      if (token != null) {
        await _tokenService.saveToken(token);
      }

      if (userJson != null) {
        final user = UserModel.fromJson(userJson).toEntity();
        await _tokenService.saveEmail(user.email);
        
        // Sync FCM token
        if (token != null) {
          try {
            final fcmToken = await NotificationService().getToken();
            if (fcmToken != null) {
              await updateFcmToken(user.email, fcmToken);
            }
          } catch (e) {
            // Non-blocking
          }
        }
        
        return user;
      }

      // If no user returned (e.g. pending OTP), return a placeholder user for now
      // so the UI can proceed to wait or OTP state.
      // But based on our backend fix, ADMIN will return a user.
      return User(
        id: -1,
        name: userData['firstName'] + ' ' + userData['lastName'],
        email: userData['email'],
        phone: userData['phone'],
        role: _parseRoleForSignup(userData['role']),
        isApproved: false,
      );
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
  Future<User> verifyOtp(String email, String otp, {Map<String, dynamic>? extraData}) async {
    try {
      final data = {
        'email': email,
        'otp': otp,
        if (extraData != null) ...extraData,
      };
      
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: data,
      );

      final token = response.data['token'];
      if (token != null) {
        await _tokenService.saveToken(token);
        await _tokenService.saveEmail(email);

        // Sync FCM token
        try {
          final fcmToken = await NotificationService().getToken();
          if (fcmToken != null) {
            await updateFcmToken(email, fcmToken);
          }
        } catch (e) {
          // Non-blocking
        }
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

      // Even if not approved, we want the profile to show the waiting screen
      // unless it's explicitly rejected or something else.
      // But for now, if success is true, we want the profile.
      final profileResponse = await _dio.post(
        ApiConstants.profileDetails,
        data: {'email': email},
      );
      final userJson = profileResponse.data['user'];
      if (userJson == null) {
        return null;
      }
      final profile = Map<String, dynamic>.from(userJson as Map);
      await _tokenService.saveUserJson(profile);
      return UserModel.fromJson(profile).toEntity();
    } on DioException catch (e) {
      // Only a 401 means the session is really over. A validation error (422) is a request problem, not a
      // reason to sign the user out.
      if (e.response?.statusCode == 401) {
        return null;
      }
      throw handleDioError(e);
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> updateData) async {
    try {
      dynamic data = updateData;

      // Handle image upload if path is provided
      if (updateData.containsKey('image_path')) {
        final Map<String, dynamic> map = Map.from(updateData);
        final String imagePath = map.remove('image_path');

        final formData = FormData.fromMap(map);
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(imagePath)),
        );
        data = formData;
      }

      final response = await _dio.post(
        ApiConstants.profileUpdate,
        data: data,
        options: Options(sendTimeout: const Duration(minutes: 2), receiveTimeout: const Duration(minutes: 1)),
      );
      final user = UserModel.fromJson(response.data['user']).toEntity();
      await _tokenService.saveUserJson(Map<String, dynamic>.from(response.data['user'] as Map));
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
      await _tokenService.saveUserJson(Map<String, dynamic>.from(response.data['user'] as Map));
      return UserModel.fromJson(response.data['user']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        ApiConstants.changePassword,
        data: {
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> updateFcmToken(String email, String token) async {
    try {
      if (kDebugMode) print('SYNC: Updating FCM token for $email...');
      await _dio.post(
        ApiConstants.updateFcmToken,
        data: {'email': email, 'fcm_token': token},
      );
      if (kDebugMode) print('SYNC: FCM token updated successfully.');
    } on DioException catch (e) {
      if (kDebugMode) print('SYNC: Failed to update FCM token: ${e.message}');
      throw handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    // Detach this phone from the account so the next user doesn't get its pushes
    try {
      await _dio.post(ApiConstants.updateFcmToken, data: {'fcm_token': ''});
    } catch (_) {}
    await _tokenService.clearAll();
  }

  UserRole _parseRoleForSignup(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'SYNDIC':
        return UserRole.syndic;
      case 'TECHNICIAN':
      case 'PROFESSIONAL':
        return UserRole.technician;
      default:
        return UserRole.technician;
    }
  }
}
