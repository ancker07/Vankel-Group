import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'dependency_injection.dart';

void main() {
  setupDependencyInjection();
  runApp(const ProviderScope(child: VanakelApp()));
}