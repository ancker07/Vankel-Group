import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'dependency_injection.dart';
import 'core/services/auth_token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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