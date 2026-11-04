import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'app.dart';
import 'dependency_injection.dart';
import 'core/services/auth_token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Month / day names for every language of the app (DateFormat needs this loaded)
  await initializeDateFormatting();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService().initialize();
  final debugToken = await NotificationService().getToken();
  print('=========================================');
  print('CRITICAL: NEW FCM TOKEN: $debugToken');
  print('=========================================');

  final sharedPreferences = await SharedPreferences.getInstance();
  
  setupDependencyInjection();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const VanakelApp(),
    ),
  );
}