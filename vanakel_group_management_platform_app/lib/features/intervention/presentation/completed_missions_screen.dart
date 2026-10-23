import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/intervention.dart';
import 'providers/intervention_list_provider.dart';

/// "End of mission": every completed intervention, newest first.
/// Completed missions open read-only (only an admin can change them).
class CompletedMissionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const CompletedMissionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final interventionsAsync = ref.watch(interventionListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.endOfMission)),
      body: interventionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.zinc400))),
        data: (interventions) {
          final completed = interventions.where((i) => i.status == InterventionStatus.completed).toList()
            ..sort((a, b) => (b.completedAt ?? b.scheduledDate).compareTo(a.completedAt ?? a.scheduledDate));

          if (completed.isEmpty) {
            return Center(child: Text(l10n.noCompletedMissions, style: const TextStyle(color: AppTheme.zinc500)));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(interventionListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _CompletedTile(intervention: completed[index], isAdmin: isAdmin),
            ),
          );
        },
      ),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  final Intervention intervention;
  final bool isAdmin;

  const _CompletedTile({required this.intervention, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final title = TranslationHelper.getLocalizedField(
      context: context,
      enValue: intervention.titleEn,
      frValue: intervention.titleFr,
      nlValue: intervention.titleNl,
      fallback: intervention.title,
    );
    final date = DateFormat('dd/MM/yyyy').format(intervention.completedAt ?? intervention.scheduledDate);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/${isAdmin ? 'admin' : 'syndic'}/interventions/details/${intervention.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.brandGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(intervention.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    [date, if (intervention.professionalName != null) intervention.professionalName!].join(' · '),
                    style: const TextStyle(color: AppTheme.zinc500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline, size: 16, color: AppTheme.zinc500),
          ],
        ),
      ),
    );
  }
}
