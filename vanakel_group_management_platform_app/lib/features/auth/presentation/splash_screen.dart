import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/user_role_enum.dart';
import 'providers/auth_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animation or a minimum splash time
    await Future.delayed(const Duration(seconds: 2));

    // The GoRouter redirect will handle navigation once authState changes
    // We don't need manual navigation here anymore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandGreen.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().fadeIn(duration: 800.ms).scale(duration: 800.ms),
            const SizedBox(height: 24),
            Text(
                  'Vanakel Group',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
                  'Effectively Manage with Ease',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
                )
                .animate(delay: 600.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
