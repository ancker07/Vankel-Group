import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Active Interventions' : 'Intervention History'),
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
        ],
      ),
      body: interventionsAsync.when(
        data: (interventions) => interventions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 64,
                      color: AppTheme.zinc800,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No interventions found',
                      style: TextStyle(color: AppTheme.zinc500),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(interventionListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: interventions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
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
    return GestureDetector(
      onTap: () {
        if (isAdmin) {
          context.push('/admin/interventions/details/${intervention.id}');
        } else {
          context.push('/syndic/interventions/details/${intervention.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          border: Border.all(color: AppTheme.zinc800),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(intervention.status),
                Text(
                  DateFormat('MMM d, y').format(intervention.scheduledDate),
                  style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              intervention.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTheme.zinc500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    intervention.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.zinc500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              intervention.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.zinc300),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              const Divider(color: AppTheme.zinc800),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (intervention.codes.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppTheme.zinc500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${intervention.codes.length} codes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.zinc500,
                          ),
                        ),
                      ],
                    ),
                  TextButton(
                    onPressed: () {
                      if (isAdmin) {
                        context.push(
                          '/admin/interventions/details/${intervention.id}',
                        );
                      } else {
                        context.push(
                          '/syndic/interventions/details/${intervention.id}',
                        );
                      }
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InterventionStatus status) {
    Color color;
    String label;

    switch (status) {
      case InterventionStatus.scheduled:
        color = Colors.blue;
        label = 'Scheduled';
        break;
      case InterventionStatus.in_progress:
        color = AppTheme.brandGreen;
        label = 'In Progress';
        break;
      case InterventionStatus.delayed:
        color = AppTheme.brandOrange;
        label = 'Delayed';
        break;
      case InterventionStatus.completed:
        color = AppTheme.zinc500;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
