import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      adminSnack(context, AppLocalizations.of(context)!.couldNotOpen(uri.toString()), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final team = ref.watch(teamProvider);

    return PermissionGate(
      anyOf: const ['team.view'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admTeam.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        body: team.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(teamProvider)),
          data: (list) => RefreshIndicator(
            onRefresh: () async => ref.refresh(teamProvider.future),
            child: list.isEmpty
                ? const AdminEmptyView(icon: Icons.groups_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _MemberCard(
                      member: list[i],
                      onCall: (m) => _launch(context, Uri(scheme: 'tel', path: m.phone)),
                      onMap: (m) => _launch(
                        context,
                        Uri.parse('https://www.google.com/maps/search/?api=1&query=${m.latitude},${m.longitude}'),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final void Function(TeamMember) onCall;
  final void Function(TeamMember) onMap;
  const _MemberCard({required this.member, required this.onCall, required this.onMap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminCard(
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppTheme.brandGreen,
          child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(member.email, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              member.hasLocation
                  ? l10n.admLastSeen(fmtDateTime(context, member.locationUpdatedAt))
                  : l10n.admNoLocation,
              style: const TextStyle(color: AppTheme.zinc500, fontSize: 11),
            ),
          ]),
        ),
        if (member.phone != null)
          IconButton(tooltip: l10n.admCall, icon: const Icon(Icons.call_outlined), onPressed: () => onCall(member)),
        if (member.hasLocation)
          IconButton(tooltip: l10n.admOpenMap, icon: const Icon(Icons.place_outlined), onPressed: () => onMap(member)),
      ]),
    );
  }
}
