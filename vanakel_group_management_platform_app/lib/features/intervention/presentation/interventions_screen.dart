import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention.dart';
import 'providers/intervention_list_provider.dart';

class InterventionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const InterventionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionsAsync = ref.watch(interventionListProvider);

    return interventionsAsync.when(
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
    final statusLabel = _getStatusLabel(intervention.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: intervention.status == InterventionStatus.delayed
              ? AppTheme.brandOrange.withOpacity(0.4)
              : AppTheme.zinc900,
          width: 2,
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Urgency + Date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildBadge(statusLabel, statusColor),
                        if (intervention.urgency != null)
                          _buildBadge(
                            intervention.urgency!,
                            _getUrgencyColor(intervention.urgency),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.event_available,
                            size: 12, color: AppTheme.zinc500),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y')
                              .format(intervention.scheduledDate),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.zinc500,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
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
                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.brandGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [intervention.address, intervention.city]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', '),
                        style: const TextStyle(
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
                const SizedBox(height: 12),
                // Description
                Text(
                  intervention.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.zinc400,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.zinc900),
                const SizedBox(height: 12),
                // Footer: contact + VIEW SLIP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (intervention.onSiteContactName != null &&
                        intervention.onSiteContactName!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 12, color: AppTheme.zinc500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                intervention.onSiteContactName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.zinc500,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
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
                        Icon(Icons.arrow_forward_ios,
                            size: 10,
                            color: AppTheme.brandGreen.withOpacity(0.8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
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
        border: Border.all(color: color.withOpacity(0.3)),
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

  String _getStatusLabel(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return 'PENDING';
      case InterventionStatus.delayed:
        return 'DELAYED';
      case InterventionStatus.completed:
        return 'COMPLETED';
    }
  }

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return AppTheme.zinc500;   // gray — matches web's zinc badge
      case InterventionStatus.delayed:
        return AppTheme.brandOrange; // orange
      case InterventionStatus.completed:
        return AppTheme.brandGreen;  // green
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toUpperCase()) {
      case 'LOW':
        return AppTheme.zinc500;
      case 'MEDIUM':
        return Colors.blueAccent;
      case 'HIGH':
        return AppTheme.brandOrange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return AppTheme.zinc500;
    }
  }
}
