import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention_filter.dart';
import '../domain/intervention.dart';
import 'providers/intervention_filter_provider.dart';
import 'providers/intervention_provider.dart';
import 'providers/intervention_list_provider.dart';

class InterventionsScreen extends ConsumerWidget {
  final bool isAdmin;

  const InterventionsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredInterventionsAsync = ref.watch(filteredInterventionListProvider);
    final filter = ref.watch(interventionFilterProvider);
    final buildingsAsync = ref.watch(buildingListProvider);

    return Column(
      children: [
        _buildTopBar(ref, filter),
        _buildFilterBar(context, ref, filter, buildingsAsync),
        Expanded(
          child: filteredInterventionsAsync.when(
            data: (interventions) => interventions.isEmpty
                ? _buildEmptyState(filter.isActive)
                : RefreshIndicator(
                    onRefresh: () => ref.read(interventionListProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: interventions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _InterventionCard(
                          intervention: interventions[index],
                          isAdmin: isAdmin,
                        );
                      },
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
            error: (error, stack) => _buildErrorState(ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(WidgetRef ref, InterventionFilter filter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppTheme.zinc950,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: TextField(
          onChanged: (v) => ref.read(interventionFilterProvider.notifier).updateSearchQuery(v),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search interventions...',
            hintStyle: const TextStyle(color: AppTheme.zinc500, fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.zinc500),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: filter.searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.zinc500),
                  onPressed: () => ref.read(interventionFilterProvider.notifier).updateSearchQuery(''),
                )
              : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, InterventionFilter filter, AsyncValue<List<dynamic>> buildingsAsync) {
    return Container(
      height: 50,
      color: AppTheme.zinc950,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: filter.sectorId ?? 'Sector',
            isActive: filter.sectorId != null,
            onTap: () => _showSectorPicker(context, ref, filter),
            onClear: filter.sectorId != null ? () => ref.read(interventionFilterProvider.notifier).updateSector(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.urgency ?? 'Urgency',
            isActive: filter.urgency != null,
            onTap: () => _showUrgencyPicker(context, ref, filter),
            onClear: filter.urgency != null ? () => ref.read(interventionFilterProvider.notifier).updateUrgency(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.buildingId != null 
              ? (buildingsAsync.value?.firstWhere((b) => b['id'].toString() == filter.buildingId, orElse: () => null)?['address'] ?? 'Building')
              : 'Building',
            isActive: filter.buildingId != null,
            onTap: () => _showBuildingPicker(context, ref, filter, buildingsAsync),
            onClear: filter.buildingId != null ? () => ref.read(interventionFilterProvider.notifier).updateBuilding(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.scheduledDate != null ? DateFormat('MMM d, y').format(filter.scheduledDate!) : 'Date',
            isActive: filter.scheduledDate != null,
            onTap: () => _showDatePicker(context, ref, filter),
            onClear: filter.scheduledDate != null ? () => ref.read(interventionFilterProvider.notifier).updateDate(null) : null,
          ),
          if (filter.isActive) ...[
            const SizedBox(width: 12),
            Center(
              child: GestureDetector(
                onTap: () => ref.read(interventionFilterProvider.notifier).reset(),
                child: const Text(
                  'RESET',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => ref.read(interventionListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, color: AppTheme.brandOrange, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSectorPicker(BuildContext context, WidgetRef ref, InterventionFilter filter) {
    final sectors = ['ELECTRICITE', 'CARRELAGE', 'SANITAIRE', 'CHAUFFAGE', 'PLOMBERIE', 'PEINTURE', 'MENUISERIE', 'GENERAL', 'AUTRE'];
    _showPicker(context, 'Select Sector', sectors, filter.sectorId, (v) {
      ref.read(interventionFilterProvider.notifier).updateSector(v);
    });
  }

  void _showUrgencyPicker(BuildContext context, WidgetRef ref, InterventionFilter filter) {
    final values = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    _showPicker(context, 'Select Urgency', values, filter.urgency, (v) {
      ref.read(interventionFilterProvider.notifier).updateUrgency(v);
    });
  }

  void _showBuildingPicker(BuildContext context, WidgetRef ref, InterventionFilter filter, AsyncValue<List<dynamic>> buildingsAsync) {
    if (buildingsAsync.value == null) return;
    final items = buildingsAsync.value!.map((b) => {'id': b['id'].toString(), 'label': b['address'] as String}).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.zinc800, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Select Building', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: items.length,
                itemBuilder: (context, idx) => ListTile(
                  title: Text(items[idx]['label']!, style: TextStyle(color: filter.buildingId == items[idx]['id'] ? AppTheme.brandGreen : Colors.white)),
                  onTap: () {
                    ref.read(interventionFilterProvider.notifier).updateBuilding(items[idx]['id']);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, InterventionFilter filter) async {
    final date = await showDatePicker(
      context: context,
      initialDate: filter.scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.brandGreen, onPrimary: Colors.black, surface: AppTheme.zinc900, onSurface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      ref.read(interventionFilterProvider.notifier).updateDate(date);
    }
  }

  void _showPicker(BuildContext context, String title, List<String> options, String? current, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.zinc800, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: options.length,
                itemBuilder: (context, idx) {
                  final o = options[idx];
                  return ListTile(
                    title: Text(o, textAlign: TextAlign.center, style: TextStyle(color: current == o ? AppTheme.brandGreen : Colors.white)),
                    onTap: () {
                      onSelect(o);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.zinc900, shape: BoxShape.circle),
            child: Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppTheme.zinc800),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No matches found' : 'No interventions found',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${error.toString()}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(interventionListProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({required this.label, required this.isActive, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brandGreen.withValues(alpha: 0.1) : AppTheme.zinc900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppTheme.brandGreen : AppTheme.zinc800),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isActive ? AppTheme.brandGreen : AppTheme.zinc500,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 12, color: isActive ? AppTheme.brandGreen : AppTheme.zinc500),
                ),
              ],
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
