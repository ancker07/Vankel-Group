import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mission/presentation/providers/mission_list_provider.dart';
import '../../intervention/presentation/providers/intervention_list_provider.dart';
import '../../mission/domain/mission.dart';
import '../../intervention/domain/intervention.dart';
import '../../../shared/widgets/language_selector.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final missionsAsync = ref.watch(missionListProvider);
    final interventionsAsync = ref.watch(interventionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(missionListProvider);
              ref.invalidate(interventionListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          const LanguageSelector(),
        ],
      ),
      body: missionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (missions) => interventionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (interventions) {
            // Calculate stats
            final pendingMissions = missions
                .where((m) => m.status == MissionStatus.pending)
                .length;
            final inProgressInterventions = interventions
                .where(
                  (i) =>
                      i.status == InterventionStatus.in_progress ||
                      i.status == InterventionStatus.scheduled,
                )
                .length;
            final delayedInterventions = interventions
                .where((i) => i.status == InterventionStatus.delayed)
                .length;
            final completedInterventions = interventions
                .where((i) => i.status == InterventionStatus.completed)
                .length;

            // Combine for recent activity (sort by date descending)
            final allActivity = [
              ...missions.map(
                (m) => _ActivityItem(
                  id: m.id,
                  type: 'mission',
                  title: m.title,
                  subtitle: m.address,
                  date: m.createdAt,
                  iconColor: AppTheme.brandOrange,
                  icon: Icons.assignment_outlined,
                ),
              ),
              ...interventions.map(
                (i) => _ActivityItem(
                  id: i.id,
                  type: 'intervention',
                  title: i.title,
                  subtitle: i.address,
                  date: i
                      .scheduledDate, // Use scheduledDate or createdAt if available
                  iconColor: AppTheme.brandGreen,
                  icon: Icons.engineering_outlined,
                ),
              ),
            ]..sort((a, b) => b.date.compareTo(a.date));

            final recentActivity = allActivity.take(5).toList();

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
                    const SizedBox(height: 32),
                    Text(
                      l10n.recentActivity,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (recentActivity.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No recent activity',
                            style: TextStyle(color: AppTheme.zinc500),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentActivity.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = recentActivity[index];
                          return GestureDetector(
                            onTap: () {
                              if (item.type == 'mission') {
                                context.go(
                                  '/admin/missions/details/${item.id}',
                                );
                              } else {
                                context.go(
                                  '/admin/interventions/details/${item.id}',
                                );
                              }
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
                                      item.icon,
                                      color: item.iconColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.zinc500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatTimeAgo(item.date),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.zinc500,
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
            );
          },
        ),
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

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

class _ActivityItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color iconColor;
  final IconData icon;

  _ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.iconColor,
    required this.icon,
  });
}
