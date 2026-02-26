import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'SYNDIC';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.zinc300),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/auth_register.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person_add_outlined,
                        size: 70,
                        color: AppTheme.brandGreen.withOpacity(0.5),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.signUp,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                _selectedRole == 'ADMIN'
                    ? 'Register as a contractor to manage missions and interventions.'
                    : 'Register as a syndic to oversee properties and report issues.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.zinc500),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
              const SizedBox(height: 32),

              if (widget.initialRole == null) ...[
                const Text(
                  'Select Role',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelect(
                        label: l10n.syndic,
                        isSelected: _selectedRole == 'SYNDIC',
                        onTap: () => setState(() => _selectedRole = 'SYNDIC'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleSelect(
                        label: l10n.admin,
                        isSelected: _selectedRole == 'ADMIN',
                        onTap: () => setState(() => _selectedRole = 'ADMIN'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ],

              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              if (_selectedRole == 'ADMIN')
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.companyName,
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.1)
              else
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.propertyAddress,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  // TODO: Implement registration logic
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.signUp),
              ).animate().fadeIn(delay: 700.ms).scale(),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppTheme.zinc500),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Log In'),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelect({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandGreen.withOpacity(0.1)
              : AppTheme.zinc900,
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : AppTheme.zinc800,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.brandGreen : AppTheme.zinc400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
