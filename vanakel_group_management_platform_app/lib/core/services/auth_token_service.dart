import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthTokenService {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  final SharedPreferences _prefs;

  AuthTokenService(this._prefs);

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> saveEmail(String email) async {
    await _prefs.setString(_emailKey, email);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  String? getEmail() {
    return _prefs.getString(_emailKey);
  }

  Future<void> deleteToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> deleteEmail() async {
    await _prefs.remove(_emailKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_emailKey);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final authTokenServiceProvider = Provider<AuthTokenService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthTokenService(prefs);
});
