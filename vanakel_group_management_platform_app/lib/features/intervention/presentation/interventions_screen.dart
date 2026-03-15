import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final dateStr = DateFormat('M/d/yyyy').format(intervention.scheduledDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: intervention.status == InterventionStatus.delayed
              ? AppTheme.brandOrange.withValues(alpha: 0.3)
              : AppTheme.zinc800,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              // Top Map Section (Stylized Placeholder)
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900,
                      border: Border(bottom: BorderSide(color: AppTheme.zinc800)),
                    ),
                    child: Opacity(
                      opacity: 0.1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                        itemBuilder: (context, index) => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.zinc500, width: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.zinc950.withValues(alpha: 0.8),
                            AppTheme.zinc950,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(statusLabel, statusColor),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                            ),
                            if (intervention.urgency != null) ...[
                              const SizedBox(height: 6),
                              _buildBadge(intervention.urgency!, _getUrgencyColor(intervention.urgency)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Title & Address (Overlaying bottom of map area)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          intervention.title.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppTheme.brandGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${intervention.address}, ${intervention.city ?? ''}",
                                style: TextStyle(fontSize: 11, color: AppTheme.zinc300, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Map Pin Button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _openMap(intervention.address),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.zinc950.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.zinc800),
                        ),
                        child: const Icon(Icons.location_on, size: 16, color: AppTheme.brandGreen),
                      ),
                    ),
                  ),
                ],
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intervention.description,
                      style: TextStyle(fontSize: 13, color: AppTheme.zinc400, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (intervention.documents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: intervention.documents.length,
                          itemBuilder: (context, idx) => Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.zinc900,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.zinc800),
                            ),
                            child: const Icon(Icons.description_outlined, size: 16, color: AppTheme.zinc500),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Divider
                    Container(height: 1, color: AppTheme.zinc900),
                    const SizedBox(height: 16),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: AppTheme.zinc500),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  intervention.syndicName ?? 'UNASSIGNED',
                                  style: TextStyle(fontSize: 11, color: AppTheme.zinc500, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'VIEW SLIP',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.brandGreen, letterSpacing: 1.2),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 14, color: AppTheme.brandGreen),
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$encodedAddress";
    final appleMapsUrl = "https://maps.apple.com/?q=$encodedAddress";

    if (Platform.isAndroid) {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      }
    } else {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
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
