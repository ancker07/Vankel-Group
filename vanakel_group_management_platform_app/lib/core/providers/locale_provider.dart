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
    try {
      await ref.read(dioProvider).post(
        ApiConstants.updateLocale,
        data: {'locale': locale.languageCode},
      );
    } catch (e) {
      // Not logged in yet (e.g. during onboarding), or offline: the device
      // preference is still saved, and the backend value is synced again
      // the next time setLocale runs after login.
      if (kDebugMode) print('Locale sync skipped: $e');
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
