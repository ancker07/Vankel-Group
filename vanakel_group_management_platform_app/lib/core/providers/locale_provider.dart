import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_constants.dart';
import '../api/dio_client.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const String _localeKey = 'selected_locale';

  @override
  Locale build() {
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'fr', 'nl'].contains(locale.languageCode)) return;

    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);

    // Persist to the backend so it can be used for all push/email notifications.
    await _postToServer(locale.languageCode);
  }

  /// Sends the language the user chose on this phone to the server. Called after every
  /// login / app start with a saved session, so notifications and e-mails keep following the
  /// language even if the change was made offline. Does nothing if the user never chose one
  /// (the default must not overwrite the language saved on the server).
  Future<void> syncToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode == null || !['en', 'fr', 'nl'].contains(languageCode)) return;
    await _postToServer(languageCode);
  }

  Future<void> _postToServer(String languageCode) async {
    try {
      await ref.read(dioProvider).post(
        ApiConstants.updateLocale,
        data: {'locale': languageCode},
      );
    } catch (e) {
      // Not logged in yet (e.g. during onboarding), or offline: the device
      // preference is still saved and syncToServer() runs again after login.
      if (kDebugMode) print('Locale sync skipped: $e');
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
