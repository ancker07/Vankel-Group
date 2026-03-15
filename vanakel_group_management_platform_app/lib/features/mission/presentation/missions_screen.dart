import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/mission.dart';
import 'providers/mission_list_provider.dart';

class MissionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const MissionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final missionsAsync = ref.watch(missionListProvider);

    return missionsAsync.when(
        data: (missions) {
          final displayMissions = isAdmin
              ? missions
                  .where((m) => m.status == MissionStatus.pending)
                  .toList()
              : missions;

          return displayMissions.isEmpty
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
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isAdmin ? l10n.allCaughtUp : l10n.noRequestsYet,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enjoy your productive day!',
                        style: TextStyle(color: AppTheme.zinc500, fontSize: 14),
                      ),
                    ],
                  ).animate().fadeIn().scale(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(missionListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayMissions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final mission = displayMissions[index];
                      return _MissionCard(mission: mission, isAdmin: isAdmin);
                    },
                  ),
                );
        },
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
                    ref.read(missionListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
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
    final statusColor = _getStatusColor(mission.status);

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
              context.push('/admin/missions/details/${mission.id}');
            } else {
              context.push('/syndic/missions/details/${mission.id}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner for Source/AI
              if (mission.isAiDetected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: Colors.purple.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Text(
                        'AI DETECTED MISSION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.purpleAccent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(
                          mission.status.name.toUpperCase(),
                          statusColor,
                        ),
                        _buildUrgencyBadge(mission.urgency),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mission.title,
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
                            mission.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.zinc500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mission.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.zinc400,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.zinc500),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(mission.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.zinc500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isAdmin && mission.status == MissionStatus.pending)
                          Row(
                            children: [
                              _buildActionButton(
                                context,
                                ref,
                                Icons.check_circle_outline,
                                Colors.green,
                                () => _handleApprove(context, ref),
                              ),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                context,
                                ref,
                                Icons.cancel_outlined,
                                Colors.red,
                                () => _handleReject(context, ref),
                              ),
                            ],
                          )
                        else if (isAdmin)
                          Row(
                            children: [
                              Text(
                                'REVIEW',
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
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final result = await _showConfirmDialog(
      context: context,
      title: 'Approve Mission',
      content: 'Are you sure you want to approve this mission and turn it into an intervention?',
      mission: mission,
      isApprove: true,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).approveMission(
              mission.id,
              scheduledDate: result['date'],
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mission approved successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final result = await _showConfirmDialog(
      context: context,
      title: 'Reject Mission',
      content: 'Are you sure you want to reject this mission?',
      mission: mission,
      isApprove: false,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).rejectMission(mission.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mission rejected'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required Mission mission,
    required bool isApprove,
  }) {
    DateTime? selectedDate;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.zinc950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.zinc800),
          ),
          title: Row(
            children: [
              Icon(
                isApprove ? Icons.check_circle_outline : Icons.error_outline,
                color: isApprove ? AppTheme.brandGreen : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(color: AppTheme.zinc300),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.zinc800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MISSION',
                        style: TextStyle(
                          color: AppTheme.zinc500,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mission.documents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'REVIEW DOCUMENTS',
                    style: TextStyle(
                      color: AppTheme.zinc500,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...mission.documents.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.zinc900,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.zinc800),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: AppTheme.brandGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.fileName,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                if (isApprove) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'INTERVENTION DATE (OPTIONAL)',
                    style: TextStyle(
                      color: AppTheme.zinc500,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.brandGreen,
                                onPrimary: Colors.black,
                                surface: AppTheme.zinc900,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.zinc800),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: selectedDate != null ? AppTheme.brandGreen : AppTheme.zinc500,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate != null
                                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                : 'Select date...',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.white : AppTheme.zinc500,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedDate != null) ...[
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => selectedDate = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.zinc500)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'confirmed': true,
                'date': selectedDate?.toIso8601String(),
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? AppTheme.brandGreen : Colors.red,
                foregroundColor: isApprove ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildUrgencyBadge(MissionUrgency urgency) {
    Color color;
    String label;

    switch (urgency) {
      case MissionUrgency.urgent:
        color = Colors.redAccent;
        label = 'URGENT';
        break;
      case MissionUrgency.normal:
        color = Colors.blueAccent;
        label = 'NORMAL';
        break;
      case MissionUrgency.low:
        color = AppTheme.zinc500;
        label = 'LOW';
        break;
    }

    return _buildBadge(label, color);
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return AppTheme.brandOrange;
      case MissionStatus.needsReview:
        return Colors.amber;
      case MissionStatus.approved:
        return AppTheme.brandGreen;
      case MissionStatus.rejected:
        return Colors.red;
      case MissionStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
