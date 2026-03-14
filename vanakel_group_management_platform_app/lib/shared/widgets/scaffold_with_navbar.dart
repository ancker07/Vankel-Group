import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/enums/user_role_enum.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/language_selector.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          navigationShell.currentIndex == 0 
            ? l10n.dashboard.toUpperCase()
            : navigationShell.currentIndex == 1
              ? l10n.missions.toUpperCase()
              : navigationShell.currentIndex == 2
                ? l10n.interventions.toUpperCase()
                : l10n.profile.toUpperCase(),
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Invalidate common providers
              // Since this is generic, we can use ref to invalidate everything or specific ones
              // For now, let's invalidate mission and intervention lists
              // We'll import them if needed or use a more generic approach
              // Actually, simplified refresh:
              ref.invalidate(authStateProvider); // Example
            },
          ),
          const LanguageSelector(),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.zinc950,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                authState.user?.name ?? 'Admin User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                authState.user?.email ?? '',
                style: TextStyle(color: AppTheme.zinc400),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.brandGreen,
                child: Text(
                  (authState.user?.name ?? 'A').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              decoration: const BoxDecoration(
                color: AppTheme.zinc900,
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard_outlined,
              label: l10n.dashboard,
              onTap: () {
                Navigator.pop(context);
                navigationShell.goBranch(0);
              },
              isSelected: navigationShell.currentIndex == 0,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.notifications_none_outlined,
              label: l10n.notifications,
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              },
              isSelected: false,
            ),
            const Divider(color: AppTheme.zinc800, indent: 20, endIndent: 20),
            _buildDrawerItem(
              context,
              icon: Icons.logout_outlined,
              label: l10n.logout,
              onTap: () {
                Navigator.pop(context);
                ref.read(authStateProvider.notifier).logout();
              },
              isSelected: false,
            ),
          ],
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppTheme.zinc950,
        indicatorColor: AppTheme.brandGreen.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard, color: AppTheme.brandGreen),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment, color: AppTheme.brandGreen),
            label: l10n.missions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.build_outlined),
            selectedIcon: const Icon(Icons.build, color: AppTheme.brandGreen),
            label: l10n.interventions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: AppTheme.brandGreen),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.brandGreen : AppTheme.zinc500),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.zinc300,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppTheme.brandGreen.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
