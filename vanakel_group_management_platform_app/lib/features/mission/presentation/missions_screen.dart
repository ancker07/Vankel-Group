import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/mission.dart';
import 'providers/mission_list_provider.dart';
import 'providers/mission_filter_provider.dart';
import '../../../core/utils/translation_helper.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  final bool isAdmin;

  const MissionsScreen({super.key, required this.isAdmin});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredMissionsAsync = ref.watch(filteredMissionListProvider);
    final filter = ref.watch(missionFilterProvider);
    final missions = ref.watch(missionListProvider).value ?? [];

    return Column(
      children: [
        _buildFilterBar(missions, filter),
        Expanded(
          child: filteredMissionsAsync.when(
            skipLoadingOnReload: false,
            data: (filteredMissions) {
              if (filteredMissions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppTheme.zinc900,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          filter.isActive
                              ? Icons.search_off
                              : Icons.check_circle_outline,
                          size: 48,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        filter.isActive
                            ? 'No missions match your filters'
                            : (widget.isAdmin ? l10n.allCaughtUp : l10n.noRequestsYet),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (filter.isActive)
                        TextButton(
                          onPressed: () => ref.read(missionFilterProvider.notifier).reset(),
                          child: const Text('Clear Filters', style: TextStyle(color: AppTheme.brandGreen)),
                        ),
                    ],
                  ).animate().fadeIn().scale(),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(missionListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMissions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final mission = filteredMissions[index];
                    return _MissionCard(mission: mission, isAdmin: widget.isAdmin);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Error: ${error.toString()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(missionListProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry Fetching Missions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<Mission> missions, MissionFilter filter) {
    if (_searchController.text != filter.searchQuery) {
      _searchController.text = filter.searchQuery;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        border: Border(bottom: BorderSide(color: AppTheme.zinc900, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.zinc900,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.zinc800, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(missionFilterProvider.notifier).updateSearchQuery(value),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search missions...',
                hintStyle: const TextStyle(color: AppTheme.zinc500, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.brandGreen),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: AppTheme.zinc500),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(missionFilterProvider.notifier).updateSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: filter.urgency?.name.toUpperCase() ?? 'Urgency',
                  icon: Icons.priority_high,
                  isSelected: filter.urgency != null,
                  onSelected: () => _showUrgencyPicker(filter),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.status != null ? _getStatusLabel(filter.status!) : 'Status',
                  icon: Icons.info_outline,
                  isSelected: filter.status != null,
                  onSelected: () => _showStatusPicker(filter),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.sector ?? 'Sector',
                  icon: Icons.category_outlined,
                  isSelected: filter.sector != null,
                  onSelected: () => _showSectorPicker(missions, filter),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.buildingId != null 
                    ? (missions.firstWhere((m) => m.buildingId == filter.buildingId, orElse: () => missions.first).address)
                    : 'Building',
                  icon: Icons.business_outlined,
                  isSelected: filter.buildingId != null,
                  onSelected: () => _showBuildingPicker(missions, filter),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.date != null 
                    ? "${filter.date!.day}/${filter.date!.month}/${filter.date!.year}"
                    : 'Date',
                  icon: Icons.calendar_today_outlined,
                  isSelected: filter.date != null,
                  onSelected: () => _showDatePicker(context, filter),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUrgencyPicker(MissionFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Urgency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('All urgencies', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        ref.read(missionFilterProvider.notifier).updateUrgency(null);
                        Navigator.pop(context);
                      },
                    ),
                    ...MissionUrgency.values.map((u) => ListTile(
                      title: Text(u.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        ref.read(missionFilterProvider.notifier).updateUrgency(u);
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return 'Pending Request';
      case MissionStatus.approved:
        return 'Accepted';
      case MissionStatus.rejected:
        return 'Rejected';
      case MissionStatus.completed:
        return 'Completed';
      case MissionStatus.needsReview:
        return 'Needs Review';
    }
  }

  void _showStatusPicker(MissionFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('All statuses', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        ref.read(missionFilterProvider.notifier).updateStatus(null);
                        Navigator.pop(context);
                      },
                    ),
                    ...MissionStatus.values.where((s) => 
                      s == MissionStatus.pending || 
                      s == MissionStatus.approved || 
                      s == MissionStatus.rejected
                    ).map((s) => ListTile(
                      title: Text(_getStatusLabel(s), style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        ref.read(missionFilterProvider.notifier).updateStatus(s);
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSectorPicker(List<Mission> missions, MissionFilter filter) {
    final sectors = missions.map((m) => m.sector).whereType<String>().toSet().toList();
    sectors.sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Sector', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('All sectors', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        ref.read(missionFilterProvider.notifier).updateSector(null);
                        Navigator.pop(context);
                      },
                    ),
                    if (sectors.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No sectors available', style: TextStyle(color: AppTheme.zinc500)),
                      )
                    else
                      ...sectors.map((s) => ListTile(
                        title: Text(s, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          ref.read(missionFilterProvider.notifier).updateSector(s);
                          Navigator.pop(context);
                        },
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingPicker(List<Mission> missions, MissionFilter filter) {
    final buildingIds = missions.map((m) => m.buildingId).whereType<String>().toSet().toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter by Building', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('All buildings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  ref.read(missionFilterProvider.notifier).updateBuilding(null);
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: buildingIds.isEmpty
                  ? const Center(
                      child: Text('No buildings available', style: TextStyle(color: AppTheme.zinc500)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: buildingIds.length,
                      itemBuilder: (context, index) {
                        final id = buildingIds[index];
                        final address = missions.firstWhere((m) => m.buildingId == id).address;
                        return ListTile(
                          title: Text(address, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            ref.read(missionFilterProvider.notifier).updateBuilding(id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, MissionFilter filter) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: filter.date ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
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
    if (picked != null) {
      ref.read(missionFilterProvider.notifier).updateDate(DateTime(picked.year, picked.month, picked.day));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen.withOpacity(0.1) : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : AppTheme.zinc800,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? AppTheme.brandGreen : AppTheme.zinc500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.zinc400,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.brandGreen),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final bool isAdmin;

  const _MissionCard({required this.mission, required this.isAdmin});

  @override
  ConsumerState<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<_MissionCard> {
  bool _isExpanded = false;

  // Helper to get status label from _MissionsScreenState
  String _getStatusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return 'Pending Request';
      case MissionStatus.approved:
        return 'Accepted';
      case MissionStatus.rejected:
        return 'Rejected';
      case MissionStatus.completed:
        return 'Completed';
      case MissionStatus.needsReview:
        return 'Needs Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.mission.status);

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
            if (widget.isAdmin) {
              context.push('/admin/missions/details/${widget.mission.id}');
            } else {
              context.push('/syndic/missions/details/${widget.mission.id}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner for Source/AI
              if (widget.mission.isAiDetected)
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
              
              // Map Visualization Area
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900,
                      border: Border(bottom: BorderSide(color: AppTheme.zinc800.withOpacity(0.5))),
                    ),
                    child: ClipRRect(
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.map_outlined,
                              size: 40,
                              color: AppTheme.zinc800,
                            ),
                          ),
                          // Overlay Map Image (Placeholder for now, but stylized)
                          Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              "https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop",
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Grid Overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: MapGridPainter(),
                            ),
                          ),
                        ],
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
                            AppTheme.zinc950.withOpacity(0.8),
                            AppTheme.zinc950,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Map Pin Action
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _openMap(widget.mission.address),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.brandGreen.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.location_on, size: 16, color: AppTheme.brandGreen),
                      ),
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(
                          _getStatusLabel(widget.mission.status),
                          statusColor,
                        ),
                        _buildUrgencyBadge(widget.mission.urgency),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      TranslationHelper.getLocalizedField(
                        context: context,
                        enValue: widget.mission.titleEn,
                        frValue: widget.mission.titleFr,
                        nlValue: widget.mission.titleNl,
                        fallback: widget.mission.title,
                      ),
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
                            widget.mission.address,
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final localizedDescription = TranslationHelper.getLocalizedField(
                          context: context,
                          enValue: widget.mission.descriptionEn,
                          frValue: widget.mission.descriptionFr,
                          nlValue: widget.mission.descriptionNl,
                          fallback: widget.mission.description,
                        );
                        final hasLongDescription = localizedDescription.length > 60;
                        return GestureDetector(
                          onTap: () {
                            if (hasLongDescription) {
                              setState(() => _isExpanded = !_isExpanded);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.zinc900.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.zinc800.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizedDescription,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.zinc400,
                                    height: 1.6,
                                  ),
                                  maxLines: _isExpanded ? null : 2,
                                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                ),
                                if (hasLongDescription) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _isExpanded ? 'Show less' : 'Read more',
                                        style: const TextStyle(
                                          color: AppTheme.brandGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        size: 14,
                                        color: AppTheme.brandGreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 14, color: AppTheme.zinc500),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.mission.syndicName ?? widget.mission.extractedSyndicName ?? 'No Syndic',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.zinc500,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.zinc500),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(widget.mission.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.zinc500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (widget.isAdmin && (widget.mission.status == MissionStatus.pending || widget.mission.status == MissionStatus.needsReview)) ...[
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
                              const SizedBox(width: 12),
                            ],
                            // Global Details Button
                            ElevatedButton(
                              onPressed: () {
                                if (widget.isAdmin) {
                                  context.push('/admin/missions/details/${widget.mission.id}');
                                } else {
                                  context.push('/syndic/missions/details/${widget.mission.id}');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.zinc900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: AppTheme.zinc800),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'DETAILS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 10),
                                ],
                              ),
                            ),
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

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress");
    final appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$encodedAddress");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
    }
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
      mission: widget.mission,
      isApprove: true,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).approveMission(
              widget.mission.id,
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
      mission: widget.mission,
      isApprove: false,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).rejectMission(widget.mission.id);
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

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.zinc800.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const double step = 20;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
