import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/mission.dart';
import '../data/mission_repository.dart';

class MissionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const MissionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionRepositoryProvider);
    // Filter missions based on role if needed.
    // For now, Admin sees all pending/approved. Syndic sees their own (mocked as all for now).
    // Let's filter: Admin sees 'pending' primarily in the Inbox.

    final displayMissions = isAdmin
        ? missions.where((m) => m.status == MissionStatus.pending).toList()
        : missions; // Syndic sees all history

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Missions Inbox' : 'My Requests'),
        actions: [
          if (!isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // TODO: Create Mission
              },
            ),
        ],
      ),
      body: displayMissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.zinc800,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin ? 'All caught up!' : 'No requests yet',
                    style: const TextStyle(color: AppTheme.zinc500),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayMissions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mission = displayMissions[index];
                return _MissionCard(mission: mission, isAdmin: isAdmin);
              },
            ),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  final Mission mission;
  final bool isAdmin;

  const _MissionCard({required this.mission, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(mission.id),
      direction: isAdmin ? DismissDirection.horizontal : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Reject
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reject Mission?'),
              content: const Text('This will delete the mission permanently.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Approve
          ref
              .read(missionRepositoryProvider.notifier)
              .updateMissionStatus(mission.id, MissionStatus.approved);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Mission Approved')));
          return false; // Don't dismiss from list visually immediately if we want to animate, but here we just update status which removes it from filter
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.brandGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.black),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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
                if (mission.isAiDetected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.purple[200],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Detected',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple[200],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildUrgencyBadge(mission.urgency),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mission.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mission.address,
              style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
            ),
            const SizedBox(height: 12),
            Text(
              mission.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.zinc300),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    mission.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: mission.status == MissionStatus.approved
                          ? AppTheme.brandGreen
                          : AppTheme.zinc500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildUrgencyBadge(MissionUrgency urgency) {
    Color color;
    String label;

    switch (urgency) {
      case MissionUrgency.urgent:
        color = Colors.red;
        label = 'Urgent';
        break;
      case MissionUrgency.normal:
        color = Colors.orange;
        label = 'Normal';
        break;
      case MissionUrgency.low:
        color = Colors.blue;
        label = 'Low';
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
