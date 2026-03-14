import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention.dart';
import 'providers/intervention_list_provider.dart';
import '../../../shared/widgets/language_selector.dart';

class InterventionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const InterventionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionsAsync = ref.watch(interventionListProvider);

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        title: Text(isAdmin ? 'INTERVENTIONS' : 'HISTORY',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(interventionListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Filter
            },
          ),
          const LanguageSelector(),
        ],
      ),
      body: interventionsAsync.when(
        data: (interventions) => interventions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 48,
                        color: AppTheme.zinc800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No interventions found',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ).animate().fadeIn().scale(),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(interventionListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: interventions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _InterventionCard(
                      intervention: interventions[index],
                      isAdmin: isAdmin,
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(interventionListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterventionCard extends StatelessWidget {
  final Intervention intervention;
  final bool isAdmin;

  const _InterventionCard({required this.intervention, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(intervention.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc900, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            if (isAdmin) {
              context.push('/admin/interventions/details/${intervention.id}');
            } else {
              context.push('/syndic/interventions/details/${intervention.id}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(
                          intervention.status.name.toUpperCase().replaceAll('_', ' '),
                          statusColor,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.event_available, size: 12, color: AppTheme.zinc500),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(intervention.scheduledDate),
                              style: const TextStyle(fontSize: 11, color: AppTheme.zinc500, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      intervention.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.brandGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            intervention.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.zinc500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      intervention.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.zinc400,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isAdmin || intervention.codes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (intervention.codes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.zinc900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.vpn_key_outlined, size: 12, color: AppTheme.brandOrange),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${intervention.codes.length} ACCESS CODES',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.brandOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isAdmin)
                            Row(
                              children: [
                                Text(
                                  'VIEW SLIP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.brandGreen.withOpacity(0.8),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.brandGreen.withOpacity(0.8)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.scheduled:
        return Colors.blueAccent;
      case InterventionStatus.in_progress:
        return AppTheme.brandGreen;
      case InterventionStatus.delayed:
        return AppTheme.brandOrange;
      case InterventionStatus.completed:
        return AppTheme.zinc500;
    }
  }
}
