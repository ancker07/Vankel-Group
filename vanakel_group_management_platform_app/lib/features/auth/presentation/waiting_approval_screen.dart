import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/auth_state_provider.dart';

class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  ConsumerState<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    // Start polling for status updates
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      ref.read(authStateProvider.notifier).getProfile();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      body: Stack(
        children: [
          // Background Aesthetics
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ).animate().fadeIn(duration: 1000.ms).blur(begin: const Offset(5, 5), end: const Offset(10, 10)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ).animate().fadeIn(duration: 1000.ms).blur(begin: const Offset(5, 5), end: const Offset(10, 10)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Logo
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.zinc950,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: AppTheme.zinc800),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandGreen.withOpacity(0.2),
                              blurRadius: 32,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 700.ms).scale(begin: const Offset(0.8, 0.8)),
                  ),
                  const SizedBox(height: 48),

                  // Title & Description
                  Column(
                    children: [
                      Text(
                        l10n.pendingApprovalTitle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.pendingApprovalDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.zinc500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  if (user != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.checkingStatusFor(user.email),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.brandGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],

                  const SizedBox(height: 48),

                  // Cards
                  _buildStatusCard(
                    icon: Icons.verified_user_outlined,
                    title: l10n.statusVerification,
                    description: l10n.statusVerificationDesc,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusCard(
                    icon: Icons.mail_outline,
                    title: l10n.emailConfirmation,
                    description: l10n.emailConfirmationDesc,
                    delay: 500.ms,
                  ),

                  const Spacer(),

                  // Bottom Info & Logout
                  Column(
                    children: [
                      const Text(
                        'NEED HELP? CONTACT@VANKEL.BE',
                        style: TextStyle(
                          color: AppTheme.zinc800,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => ref.read(authStateProvider.notifier).logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(l10n.signOut.toUpperCase()),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.zinc500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withOpacity(0.5),
        border: Border.all(color: AppTheme.zinc800),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.brandGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.zinc500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }
}
