import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password, String role);
  Future<User> signup(Map<String, dynamic> userData);
  Future<void> sendOtp(String email);
  Future<User> verifyOtp(String email, String otp);
  Future<User?> checkStatus(String email);
  Future<User> updateProfile(Map<String, dynamic> updateData);
  Future<User> getProfile(String email);
  Future<void> changePassword(String email, String currentPassword, String newPassword);
  Future<void> logout();
}
