import 'device_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/language_selector.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/mission/presentation/providers/mission_filter_provider.dart';
import '../../core/providers/refresh_work_data.dart';
import '../../features/intervention/presentation/providers/intervention_filter_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../core/api/api_constants.dart';
import '../../core/router/mobile_access.dart';

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

    // Branch index (fixed by the router's StatefulShellRoute) -> tab spec.
    // Same as the website: an admin has Missions + Interventions, a technician only Interventions.
    // Dashboard and Profile are always available.
    final tabs = [
      _NavTab(branchIndex: 0, title: l10n.dashboard, visible: true,
          icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: l10n.dashboard),
      _NavTab(branchIndex: 1, title: l10n.missions, visible: user?.seesMissions ?? false,
          icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: l10n.missions),
      _NavTab(branchIndex: 2, title: l10n.statusTabOngoing, visible: user?.seesInterventions ?? false,
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
          const _ForceRefreshButton(),
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
                authState.user?.name ?? l10n.userFallbackName,
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
            // Admin: Reports, End of mission, Inbox, Team, Users. Technician: nothing here (only the tabs).
            // Management, Maintenance, Contacts, Push, AI settings and System are not on the phone (see mobile_access.dart).
            if (user?.seesReports ?? false)
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
            if (user?.seesEndOfMission ?? false)
              _buildDrawerItem(
                context,
                icon: Icons.task_alt_outlined,
                label: l10n.endOfMission,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/dashboard/completed');
                },
                isSelected: location == '/admin/dashboard/completed',
              ),
            ..._adminTools(context, l10n, location, user),
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
      body: Column(children: [
        const DeviceStatusBanner(),
        Expanded(child: navigationShell),
      ]),
      bottomNavigationBar: Container(
        color: AppTheme.zinc950,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < visibleTabs.length; i++)
                  Expanded(
                    child: _buildNavItem(
                      visibleTabs[i],
                      isSelected: i == selectedIndex,
                      onTap: () {
                        final tab = visibleTabs[i];
                        navigationShell.goBranch(
                          tab.branchIndex,
                          initialLocation: tab.branchIndex == navigationShell.currentIndex,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Drawer entries for the admin areas (Inbox, Team, Users), by the same rules as the website.
  List<Widget> _adminTools(
    BuildContext context,
    AppLocalizations l10n,
    String location,
    User? user,
  ) {
    final items = <({String path, IconData icon, String label, bool visible})>[
      (path: '/admin/dashboard/emails', icon: Icons.mail_outline, label: l10n.admInbox, visible: user?.seesInbox ?? false),
      (path: '/admin/dashboard/team', icon: Icons.groups_outlined, label: l10n.admTeam, visible: user?.seesTeam ?? false),
      (path: '/admin/dashboard/users', icon: Icons.key_outlined, label: l10n.admUsers, visible: user?.seesUsers ?? false),
    ];
    return [
      for (final i in items)
        if (i.visible)
          _buildDrawerItem(
            context,
            icon: i.icon,
            label: i.label,
            onTap: () {
              Navigator.pop(context);
              context.push(i.path);
            },
            isSelected: location.startsWith(i.path),
          ),
    ];
  }

  /// One bottom-bar tab. The label is forced onto a single line and scaled
  /// down to fit, so long translations (FR/NL) can never wrap or overlap.
  Widget _buildNavItem(
    _NavTab tab, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppTheme.brandGreen : AppTheme.zinc400;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandGreen.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(isSelected ? tab.selectedIcon : tab.icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
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

/// Brings the Dashboard, Missions and Ongoing screens up to date from the server whatever happened before (the
/// automatic refresh failed, the tablet slept, data changed on another device): the screens show the spinner until
/// the latest data is in, and so does the button, which cannot be pressed again meanwhile.
class _ForceRefreshButton extends ConsumerStatefulWidget {
  const _ForceRefreshButton();

  @override
  ConsumerState<_ForceRefreshButton> createState() => _ForceRefreshButtonState();
}

class _ForceRefreshButtonState extends ConsumerState<_ForceRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    // the full lists, like the website after a refresh
    ref.read(missionFilterProvider.notifier).reset();
    ref.read(interventionFilterProvider.notifier).reset();
    ref.invalidate(notificationProvider);
    try {
      await ref.read(workDataRefresherProvider).force();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.refresh,
      onPressed: _loading ? null : _refresh,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandGreen),
            )
          : const Icon(Icons.refresh),
    );
  }
}
