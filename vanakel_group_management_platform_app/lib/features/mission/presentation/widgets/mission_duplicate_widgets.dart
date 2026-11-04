import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/data/admin_repository.dart';
import '../../../admin/presentation/admin_widgets.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/mission.dart';
import '../providers/mission_list_provider.dart';

/// "Possible duplicate of mission #X" warning with Not-a-duplicate / Merge
/// actions for users who may approve missions.
class MissionDuplicateBanner extends ConsumerWidget {
  final Mission mission;
  const MissionDuplicateBanner({super.key, required this.mission});

  void _refresh(WidgetRef ref) {
    ref.invalidate(missionListProvider);
    ref.invalidate(missionDetailProvider(mission.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId = mission.possibleDuplicateOfId;
    final canReview = ref.watch(authStateProvider).user?.can('missions.approve') ?? false;
    if (otherId == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(adminRepositoryProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.brandOrange.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.copy_all_outlined, color: AppTheme.brandOrange, size: 20),
          const SizedBox(width: 8),
          Text(l10n.admDuplicateTitle.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.brandOrange, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 6),
        Text(l10n.admDuplicateBody(otherId, '${mission.duplicateScore ?? '?'}')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(
            onPressed: () => context.push('/admin/missions/details/$otherId'),
            child: Text('#$otherId'),
          ),
          if (canReview) ...[
            OutlinedButton(
              onPressed: () async {
                try {
                  await repo.dismissDuplicate(mission.id);
                  _refresh(ref);
                  adminSnack(context, l10n.admDuplicateDismissed);
                } catch (e) {
                  adminSnack(context, e.toString(), error: true);
                }
              },
              child: Text(l10n.admNotDuplicate),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await adminConfirm(context,
                    title: l10n.admMergeDuplicate, message: l10n.admMergeConfirm, confirmLabel: l10n.admMergeDuplicate);
                if (!ok || !context.mounted) return;
                try {
                  await repo.mergeDuplicate(mission.id);
                  _refresh(ref);
                  adminSnack(context, l10n.admMerged);
                  // this mission may be the one that was merged away
                  if (context.mounted) context.pop();
                } catch (e) {
                  adminSnack(context, e.toString(), error: true);
                }
              },
              child: Text(l10n.admMergeDuplicate),
            ),
          ],
        ]),
      ]),
    );
  }
}

/// Follow-up emails that were attached to this mission instead of creating duplicates.
class MissionFollowUpsSection extends StatelessWidget {
  final Mission mission;
  const MissionFollowUpsSection({super.key, required this.mission});

  String _reason(AppLocalizations l10n, String? r) {
    switch (r) {
      case 'reference':
        return l10n.admReasonReference;
      case 'thread':
        return l10n.admReasonThread;
      case 'building_title':
        return l10n.admReasonBuildingTitle;
      case 'merge':
        return l10n.admReasonMerge;
      default:
        return r ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mission.followUps.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      Text(l10n.admFollowUps.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.zinc500, letterSpacing: 1)),
      const SizedBox(height: 8),
      for (final f in mission.followUps)
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (f.subject != null) Text(f.subject!, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (f.summary != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(f.summary!, maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
              ),
            const SizedBox(height: 6),
            Text('${fmtDateTime(context, f.createdAt)} · ${l10n.admFollowUpVia(_reason(l10n, f.reason))}',
                style: const TextStyle(fontSize: 11, color: AppTheme.zinc500)),
          ]),
        ),
    ]);
  }
}
