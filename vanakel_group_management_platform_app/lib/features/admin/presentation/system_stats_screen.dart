import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

class SystemStatsScreen extends ConsumerWidget {
  const SystemStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(systemStatsProvider);

    return PermissionGate(
      anyOf: const ['stats.view'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admSystem.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        body: stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(systemStatsProvider)),
          data: (s) {
            final tiles = [
              (l10n.admStatAdmins, s.get('total_admins'), Icons.admin_panel_settings_outlined),
              (l10n.admStatSyndics, s.get('total_syndics'), Icons.apartment_outlined),
              (l10n.admStatProfessionals, s.get('total_professionals'), Icons.engineering_outlined),
              (l10n.admStatPending, s.get('pending_registrations'), Icons.hourglass_top_outlined),
              (l10n.admStatEmails, s.get('total_emails'), Icons.mail_outline),
              (l10n.admStatBuildings, s.get('total_buildings'), Icons.business_outlined),
              (l10n.admStatInterventions, s.get('total_interventions'), Icons.build_outlined),
            ];
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(systemStatsProvider.future),
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  for (final t in tiles)
                    AdminCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Icon(t.$3, color: AppTheme.brandGreen),
                        Text('${t.$2}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                        Text(t.$1, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                      ]),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
