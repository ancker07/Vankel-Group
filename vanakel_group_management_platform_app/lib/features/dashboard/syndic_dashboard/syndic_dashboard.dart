import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mission/presentation/providers/mission_list_provider.dart';
import '../../intervention/presentation/providers/intervention_list_provider.dart';
import '../../intervention/domain/intervention.dart';
import '../../../core/utils/translation_helper.dart';

class SyndicDashboard extends ConsumerWidget {
  const SyndicDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final interventionsAsync = ref.watch(interventionListProvider);

    return interventionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (interventions) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(missionListProvider);
          ref.invalidate(interventionListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandGreen.withOpacity(0.2),
                      AppTheme.brandBlack,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.brandGreen.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.needIntervention,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.createRequestDesc,
                            style: const TextStyle(
                              color: AppTheme.zinc300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/syndic/missions/create');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(l10n.request),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.myInterventions,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (interventions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No interventions found',
                      style: TextStyle(color: AppTheme.zinc500),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: interventions.length > 5
                      ? 5
                      : interventions.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = interventions[index];
                    return GestureDetector(
                      onTap: () {
                        context.go(
                          '/syndic/interventions/details/${item.id}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.zinc950,
                          border: Border.all(color: AppTheme.zinc800),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.zinc900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.build_outlined,
                                color: AppTheme.zinc500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    TranslationHelper.getLocalizedField(
                                      context: context,
                                      enValue: item.titleEn,
                                      frValue: item.titleFr,
                                      nlValue: item.titleNl,
                                      fallback: item.title,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.zinc500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  item.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(
                                    item.status,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                item.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(item.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return Colors.blue;
      case InterventionStatus.delayed:
        return AppTheme.brandOrange;
      case InterventionStatus.completed:
        return AppTheme.zinc500;
    }
  }
}
