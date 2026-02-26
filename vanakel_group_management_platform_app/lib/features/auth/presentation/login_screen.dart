import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/data/user_provider.dart';
import '../../../core/enums/user_role_enum.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'VANAKEL',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),

              const SizedBox(height: 48),

              if (_selectedRole == null) ...[
                Text(
                  l10n.login,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  l10n.selectRole,
                  style: TextStyle(color: AppTheme.zinc500),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),

                _buildModernRoleCard(
                  title: l10n.admin,
                  subtitle: 'Central Management & Control',
                  icon: Icons.shield_outlined,
                  onTap: () => setState(() => _selectedRole = 'ADMIN'),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 20),

                _buildModernRoleCard(
                  title: l10n.syndic,
                  subtitle: 'Property Overview & Requests',
                  icon: Icons.business_center_outlined,
                  onTap: () => setState(() => _selectedRole = 'SYNDIC'),
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 48),
              ] else ...[
                // Back Button & Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.zinc500,
                      ),
                      onPressed: () => setState(() => _selectedRole = null),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedRole == 'ADMIN'
                          ? 'Admin Portal'
                          : 'Syndic Access',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 32),

                // Illustration placeholder/Asset
                Center(
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.zinc950,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/auth_login.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.lock_person_outlined,
                          size: 60,
                          color: AppTheme.brandGreen.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 48),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(l10n.forgotPassword),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    if (_selectedRole == 'ADMIN') {
                      ref.read(userProvider.notifier).setRole(UserRole.admin);
                      context.go('/admin/dashboard');
                    } else if (_selectedRole == 'SYNDIC') {
                      ref.read(userProvider.notifier).setRole(UserRole.syndic);
                      context.go('/syndic/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(l10n.login),
                ).animate().fadeIn(delay: 400.ms).scale(),
              ],

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.dontHaveAccount} ',
                    style: const TextStyle(color: AppTheme.zinc500),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      _selectedRole != null
                          ? '/register?role=$_selectedRole'
                          : '/register',
                    ),
                    child: Text(l10n.createAccount),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          border: Border.all(color: AppTheme.zinc800),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.brandGreen, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.zinc500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.zinc500,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
