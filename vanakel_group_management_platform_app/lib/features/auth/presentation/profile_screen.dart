import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/user_role_enum.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/auth_state_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.zinc950,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.brandGreen.withOpacity(0.2),
                      AppTheme.brandBlack,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'profile_pic',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.brandGreen,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: AppTheme.zinc800,
                            backgroundImage: user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                            child: user.profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppTheme.zinc500,
                                  )
                                : null,
                          ),
                        ),
                      ).animate().scale(
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 4),
                      _buildRoleBadge(user.role),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(l10n.information),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoTile(Icons.email_outlined, 'Email', user.email),
                    _buildInfoTile(Icons.phone_outlined, 'Phone', user.phone),
                    _buildInfoTile(
                      Icons.info_outline,
                      'Bio',
                      user.bio ?? 'No bio provided.',
                    ),
                  ]),
                  const SizedBox(height: 24),

                  if (user.role == UserRole.admin) ...[
                    _buildSectionTitle(l10n.businessDetails),
                    const SizedBox(height: 16),
                    _buildInfoCard([
                      _buildInfoTile(
                        Icons.business_outlined,
                        l10n.companyName,
                        user.companyName ?? 'Vanakel Group',
                      ),
                    ]),
                  ] else ...[
                    _buildSectionTitle(l10n.propertyOverview),
                    const SizedBox(height: 16),
                    _buildInfoCard([
                      _buildInfoTile(
                        Icons.apartment_outlined,
                        l10n.managedProperties,
                        '${user.propertyCount ?? 0} ${l10n.activeAssets}',
                      ),
                    ]),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.security),
                  const SizedBox(height: 16),
                  _buildActionTile(Icons.lock_outline, l10n.changePassword, () {
                    _showChangePasswordDialog(context);
                  }),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final rolePath = user.role == UserRole.admin
                          ? '/admin'
                          : '/syndic';
                      context.push('$rolePath/profile/edit');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(l10n.editProfile),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(l10n.logout),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandGreen.withOpacity(0.3)),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.brandGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(children: children),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.zinc500, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.zinc500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.brandGreen, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.zinc500),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  void _showChangePasswordDialog(BuildContext context) {
    // TODO: Implement change password with API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password feature coming soon')),
    );
  }
}
