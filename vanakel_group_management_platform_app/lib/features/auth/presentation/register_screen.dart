import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/auth_state_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  late String _selectedRole;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'SYNDIC';
    _companyController.text = 'Vanakel Group';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final companyName = _companyController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Split name into firstName and lastName
    final nameParts = name.split(' ');
    final firstName = nameParts.first;
    // Ensure lastName is not just a space to avoid 422 error
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ').trim()
        : '.';
    // If joining parts results in empty string, use fallback
    final finalLastName = lastName.isEmpty ? '.' : lastName;

    final userData = {
      'firstName': firstName,
      'lastName': finalLastName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': _selectedRole,
      'companyName': _selectedRole == 'ADMIN' ? 'Vanakel Group' : companyName,
    };

    await ref.read(authStateProvider.notifier).signup(userData);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listen for errors
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Unified Router handles navigation based on authStateProvider

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
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
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
                    ? 'Register to become a Vanakel Group Member.'
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
              if (_selectedRole != 'ADMIN')
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
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ).animate().fadeIn(delay: 570.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.zinc300,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: authState.status == AuthStatus.authenticating
                    ? null
                    : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.black,
                ),
                child: authState.status == AuthStatus.authenticating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(l10n.signUp),
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
