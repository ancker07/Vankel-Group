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
import '../../core/api/api_constants.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    final location = GoRouterState.of(context).matchedLocation;

    final notificationsAsync = ref.watch(notificationProvider);
    final unreadCount =
        notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

    final user = authState.user;
    bool can(String permission) => user?.can(permission) ?? false;

    // Branch index (fixed by the router's StatefulShellRoute) -> tab spec.
    // Missions/Interventions are only offered if the user's role grants the
    // matching permission; Dashboard and Profile are always available.
    final tabs = [
      _NavTab(branchIndex: 0, title: l10n.dashboard, visible: true,
          icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: l10n.dashboard),
      _NavTab(branchIndex: 1, title: l10n.missions, visible: can('missions.view'),
          icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: l10n.missions),
      _NavTab(branchIndex: 2, title: l10n.interventions, visible: can('interventions.view'),
          icon: Icons.build_outlined, selectedIcon: Icons.build, label: l10n.interventions),
      _NavTab(branchIndex: 3, title: l10n.profile, visible: true,
          icon: Icons.person_outline, selectedIcon: Icons.person, label: l10n.profile),
    ];
    final visibleTabs = tabs.where((t) => t.visible).toList();
    final currentTab = tabs.firstWhere(
      (t) => t.branchIndex == navigationShell.currentIndex,
      orElse: () => tabs.first,
    );
    var selectedIndex = visibleTabs.indexOf(currentTab);
    if (selectedIndex == -1) selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTab.title.toUpperCase(),
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
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                authState.user?.email ?? '',
                style: TextStyle(color: AppTheme.zinc400),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.brandGreen,
                backgroundImage: authState.user?.profileImageUrl != null && authState.user!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(ApiConstants.getStorageUrl(authState.user!.profileImageUrl))
                    : null,
                child: authState.user?.profileImageUrl == null || authState.user!.profileImageUrl!.isEmpty
                    ? Text(
                        (authState.user?.name ?? 'A').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              decoration: const BoxDecoration(color: AppTheme.zinc900),
            ),
            if (authState.user?.role == UserRole.admin && can('buildings.view'))
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
            if (authState.user?.role == UserRole.admin && can('reports.view'))
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
            if (authState.user?.role == UserRole.admin && can('maintenance.view'))
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
            // End of mission: completed missions, for everyone
            Builder(builder: (context) {
              final path = authState.user?.role == UserRole.syndic
                  ? '/syndic/dashboard/completed'
                  : '/admin/dashboard/completed';
              return _buildDrawerItem(
                context,
                icon: Icons.task_alt_outlined,
                label: l10n.endOfMission,
                onTap: () {
                  Navigator.pop(context);
                  context.push(path);
                },
                isSelected: location == path,
              );
            }),
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
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final tab = visibleTabs[index];
          navigationShell.goBranch(
            tab.branchIndex,
            initialLocation: tab.branchIndex == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppTheme.zinc950,
        indicatorColor: AppTheme.brandGreen.withOpacity(0.2),
        destinations: visibleTabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon, color: AppTheme.brandGreen),
                  label: t.label,
                ))
            .toList(),
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
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.brandGreen : AppTheme.zinc500,
      ),
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

class _NavTab {
  final int branchIndex;
  final String title;
  final bool visible;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavTab({
    required this.branchIndex,
    required this.title,
    required this.visible,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
