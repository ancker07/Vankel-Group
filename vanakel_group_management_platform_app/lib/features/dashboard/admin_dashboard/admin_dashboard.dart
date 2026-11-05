import '../../auth/presentation/providers/auth_state_provider.dart';
import '../../../core/error/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mission/presentation/providers/mission_list_provider.dart';
import '../../intervention/presentation/providers/intervention_list_provider.dart';
import '../../mission/domain/mission.dart';
import '../../intervention/domain/intervention.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canSeeMissions = ref.watch(authStateProvider).user?.can('missions.view') ?? false;
    final missionsAsync = ref.watch(missionListProvider);
    final interventionsAsync = ref.watch(interventionListProvider);

    return missionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(errorWithMessage(context, err))),
      data: (missions) => interventionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(errorWithMessage(context, err))),
        data: (interventions) {
          // Calculate stats
          final pendingMissions = missions
              .where((m) => m.status == MissionStatus.pending)
              .length;
          final inProgressInterventions = interventions
              .where(
                (i) => i.status == InterventionStatus.pending,
              )
              .length;
          final delayedInterventions = interventions
              .where((i) => i.status == InterventionStatus.delayed)
              .length;
          final completedInterventions = interventions
              .where((i) => i.status == InterventionStatus.completed)
              .length;

          return RefreshIndicator(
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
                  Text(
                    l10n.overview,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      if (canSeeMissions)
                        _buildStatCard(
                          context,
                          title: l10n.newMissions,
                          value: pendingMissions.toString(),
                          icon: Icons.assignment_outlined,
                          color: AppTheme.brandGreen,
                        ),
                      _buildStatCard(
                        context,
                        title: l10n.inProgress,
                        value: inProgressInterventions.toString(),
                        icon: Icons.engineering_outlined,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.delayed,
                        value: delayedInterventions.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.brandOrange,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.completed,
                        value: completedInterventions.toString(),
                        icon: Icons.check_circle_outline,
                        color: AppTheme.zinc500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        border: Border.all(color: AppTheme.zinc800),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.zinc500,
            ),
          ),
        ],
      ),
    );
  }
}
