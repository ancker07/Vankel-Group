import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/enums/user_role_enum.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/language_selector.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/mission/presentation/providers/mission_list_provider.dart';
import '../../features/mission/presentation/providers/mission_filter_provider.dart';
import '../../features/intervention/presentation/providers/intervention_list_provider.dart';
import '../../features/intervention/presentation/providers/intervention_filter_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

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

    final location = GoRouterState.of(context).matchedLocation;

    final notificationsAsync = ref.watch(notificationProvider);
    final unreadCount = notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

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
              // 1. Reset filters to show full results on refresh
              ref.read(missionFilterProvider.notifier).reset();
              ref.read(interventionFilterProvider.notifier).reset();
              
              // 2. Invalidate specific data providers
              ref.invalidate(missionListProvider);
              ref.invalidate(interventionListProvider);
              ref.invalidate(notificationProvider);
            },
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red,
              child: Icon(
                unreadCount > 0 
                  ? Icons.notifications 
                  : Icons.notifications_none_outlined,
                color: unreadCount > 0 ? AppTheme.brandGreen : null,
              ),
            ),
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
            if (authState.user?.role == UserRole.admin) ...[
              _buildDrawerItem(
                context,
                icon: Icons.business_outlined,
                label: l10n.management,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/dashboard/management');
                },
                isSelected: location == '/admin/dashboard/management',
              ),
              _buildDrawerItem(
                context,
                icon: Icons.assessment_outlined,
                label: l10n.reports,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/dashboard/reports');
                },
                isSelected: location == '/admin/dashboard/reports',
              ),
              _buildDrawerItem(
                context,
                icon: Icons.settings_backup_restore_outlined,
                label: l10n.maintenance,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/dashboard/maintenance');
                },
                isSelected: location == '/admin/dashboard/maintenance',
              ),
            ],
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
