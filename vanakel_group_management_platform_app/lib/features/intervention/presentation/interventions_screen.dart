import '../../../shared/widgets/pull_to_refresh_fill.dart';
import '../../../shared/widgets/admin_badge.dart';
import '../../../core/services/map_service.dart';
import '../../../core/utils/app_labels.dart';
import '../../../core/error/error_text.dart';
import '../../../core/utils/app_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/translation_helper.dart';
import '../domain/intervention_filter.dart';
import '../domain/intervention.dart';
import 'providers/intervention_filter_provider.dart';
import 'providers/intervention_provider.dart';
import '../../../core/providers/refresh_work_data.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/router/mobile_access.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';

class InterventionsScreen extends ConsumerStatefulWidget {
  final bool isAdmin;

  const InterventionsScreen({super.key, required this.isAdmin});

  @override
  ConsumerState<InterventionsScreen> createState() => _InterventionsScreenState();
}

class _InterventionsScreenState extends ConsumerState<InterventionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredInterventionsAsync = ref.watch(filteredInterventionListProvider);
    final filter = ref.watch(interventionFilterProvider);
    final buildingsAsync = ref.watch(buildingListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildTopBar(filter, l10n),
        // only the work in progress is listed, for every role (like the website): no status tabs
        if (!(ref.watch(authStateProvider).user?.seesOnlyOpenInterventions ?? false)) const _StatusTabs(),
        _buildFilterBar(filter, buildingsAsync, l10n),
        Expanded(
          child: filteredInterventionsAsync.when(
            skipLoadingOnReload: false,
            data: (interventions) {
              if (interventions.isEmpty) {
                return PullToRefreshFill(
                  onRefresh: () => ref.read(workDataRefresherProvider).pull(),
                  child: _buildEmptyState(filter.isActive, l10n),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => ref.read(workDataRefresherProvider).pull(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: interventions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _InterventionCard(
                      intervention: interventions[index],
                      isAdmin: widget.isAdmin,
                      // an admin is shown which interventions a technician has sent for review
                      canVerify: ref.watch(authStateProvider).user?.can('interventions.reopen') ?? false,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            ),
            error: (error, stack) => _buildErrorState(error, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(InterventionFilter filter, AppLocalizations l10n) {
    if (_searchController.text != filter.searchQuery) {
      _searchController.text = filter.searchQuery;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        border: Border(bottom: BorderSide(color: AppTheme.zinc900, width: 1)),
      ),
      child: Container(
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
          onChanged: (v) => ref.read(interventionFilterProvider.notifier).updateSearchQuery(v),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: l10n.searchInterventions,
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
                    ref.read(interventionFilterProvider.notifier).updateSearchQuery('');
                  },
                )
              : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(InterventionFilter filter, AsyncValue<List<dynamic>> buildingsAsync, AppLocalizations l10n) {
    return Container(
      height: 50,
      color: AppTheme.zinc950,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: filter.sectorId != null ? l10n.sectorLabel(filter.sectorId!) : l10n.sector,
            isActive: filter.sectorId != null,
            onTap: () => _showSectorPicker(context, filter, l10n),
            onClear: filter.sectorId != null ? () => ref.read(interventionFilterProvider.notifier).updateSector(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.urgency != null ? l10n.urgencyLabel(filter.urgency!) : l10n.urgency,
            isActive: filter.urgency != null,
            onTap: () => _showUrgencyPicker(context, filter, l10n),
            onClear: filter.urgency != null ? () => ref.read(interventionFilterProvider.notifier).updateUrgency(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.buildingId != null 
              ? (buildingsAsync.value?.firstWhere((b) => b['id'].toString() == filter.buildingId, orElse: () => null)?['address'] ?? l10n.building)
              : l10n.building,
            isActive: filter.buildingId != null,
            onTap: () => _showBuildingPicker(context, filter, buildingsAsync, l10n),
            onClear: filter.buildingId != null ? () => ref.read(interventionFilterProvider.notifier).updateBuilding(null) : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter.scheduledDate != null ? AppFormat.dateMedium(context, filter.scheduledDate!) : l10n.date,
            isActive: filter.scheduledDate != null,
            onTap: () => _showDatePicker(context, filter),
            onClear: filter.scheduledDate != null ? () => ref.read(interventionFilterProvider.notifier).updateDate(null) : null,
          ),
          if (filter.isActive) ...[
            const SizedBox(width: 12),
            Center(
              child: GestureDetector(
                onTap: () => ref.read(interventionFilterProvider.notifier).reset(),
                child: Text(
                  l10n.clearFilters.toUpperCase(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSectorPicker(BuildContext context, InterventionFilter filter, AppLocalizations l10n) {
    final sectors = ['ELECTRICITE', 'CARRELAGE', 'SANITAIRE', 'CHAUFFAGE', 'PLOMBERIE', 'PEINTURE', 'MENUISERIE', 'GENERAL', 'AUTRE'];
    _showPicker(context, l10n.selectSector, sectors, filter.sectorId, (v) {
      ref.read(interventionFilterProvider.notifier).updateSector(v);
    }, l10n);
  }

  void _showUrgencyPicker(BuildContext context, InterventionFilter filter, AppLocalizations l10n) {
    final values = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    _showPicker(context, l10n.selectUrgency, values, filter.urgency, (v) {
      ref.read(interventionFilterProvider.notifier).updateUrgency(v);
    }, l10n);
  }

  void _showBuildingPicker(BuildContext context, InterventionFilter filter, AsyncValue<List<dynamic>> buildingsAsync, AppLocalizations l10n) {
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
            Text(l10n.selectBuilding, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Future<void> _showDatePicker(BuildContext context, InterventionFilter filter) async {
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

  void _showPicker(BuildContext context, String title, List<String> options, String? current, Function(String) onSelect, AppLocalizations l10n) {
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
                  String displayLabel = o;
                  if (title == l10n.selectUrgency) {
                    displayLabel = l10n.urgencyLabel(o);
                  } else if (title == l10n.selectSector) {
                    displayLabel = l10n.sectorLabel(o);
                  }
                  
                  return ListTile(
                    title: Text(displayLabel, textAlign: TextAlign.center, style: TextStyle(color: current == o ? AppTheme.brandGreen : Colors.white)),
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

  Widget _buildEmptyState(bool isFiltered, AppLocalizations l10n) {
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
            isFiltered ? l10n.noMatchesFound : l10n.noInterventionsFound,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildErrorState(Object error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(errorWithMessage(context, error), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(workDataRefresherProvider).force(), // the spinner shows, not the old error
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.retry),
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
  final bool canVerify;

  const _InterventionCard({required this.intervention, required this.isAdmin, this.canVerify = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(intervention.status);
    final statusLabel = l10n.interventionStatusLabel(intervention.status);
    final dateStr = AppFormat.date(context, intervention.scheduledDate);

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
          onTap: () async {
            // taken before leaving: after a save this card is gone from the list (and its context with it)
            final container = ProviderScope.containerOf(context, listen: false);
            await context.push(isAdmin
                ? '/admin/interventions/details/${intervention.id}'
                : '/syndic/interventions/details/${intervention.id}');
            // Back on Ongoing: always show the server's latest (a task completed or delayed is gone), whatever
            // happened in between (saved, saved offline, changed on another device, the tablet slept...)
            container.read(workDataRefresherProvider).lists();
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
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.map_outlined,
                            size: 40,
                            color: AppTheme.zinc800,
                          ),
                        ),
                        // Overlay Map Image (Stylized)
                        Opacity(
                          opacity: 0.15,
                          child: Image.network(
                            "https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop",
                            width: double.infinity,
                            height: 160,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBadge(statusLabel, statusColor),
                            if (canVerify && intervention.submittedAt != null) ...[
                              const SizedBox(height: 6),
                              _buildBadge(l10n.verifySubmission, AppTheme.brandOrange),
                            ],
                          ],
                        ),
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
                              _buildBadge(l10n.urgencyLabel(intervention.urgency!), _getUrgencyColor(intervention.urgency)),
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
                          TranslationHelper.getLocalizedField(
                            context: context,
                            enValue: intervention.titleEn,
                            frValue: intervention.titleFr,
                            nlValue: intervention.titleNl,
                            fallback: intervention.title,
                          ).toUpperCase(),
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
                                "${TranslationHelper.address(context, intervention.address)}, ${intervention.city ?? ''}",
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
                      onTap: () => _openMap(context, intervention.address),
                      child: Tooltip(
                        message: l10n.openGps,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.navigation, size: 22, color: Colors.black),
                        ),
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
                    if (intervention.assignedToAdmin) ...[const AdminBadge(show: true, large: true), const SizedBox(height: 14)],
                    Text(
                      TranslationHelper.getLocalizedField(
                        context: context,
                        enValue: intervention.descriptionEn,
                        frValue: intervention.descriptionFr,
                        nlValue: intervention.descriptionNl,
                        fallback: intervention.description,
                      ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // who the work is assigned to (green) or "Unassigned", as on the website
                              _infoLine(
                                Icons.person_outline,
                                (intervention.professionalName ?? '').trim().isNotEmpty
                                    ? intervention.professionalName!
                                    : l10n.unassigned,
                                highlight: (intervention.professionalName ?? '').trim().isNotEmpty,
                              ),
                              const SizedBox(height: 6),
                              _infoLine(
                                Icons.shield_outlined,
                                intervention.syndicName ?? intervention.extractedSyndicName ?? l10n.noSyndic,
                              ),
                              if ((intervention.onSiteContactName ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _infoLine(Icons.support_agent_outlined, intervention.onSiteContactName!),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              l10n.viewSlip,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.brandGreen, letterSpacing: 1.2),
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

  Widget _infoLine(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: highlight ? AppTheme.brandGreen : AppTheme.zinc500),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: highlight ? AppTheme.brandGreen : AppTheme.zinc500, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Navigation to the address (see MapService.openDirections: several fallbacks + a visible message).
  Future<void> _openMap(BuildContext context, String address) => MapService.openDirections(context, address);

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

/// All / Ongoing Interventions / Delayed / Completed, each with its count: the same tabs as the website.
class _StatusTabs extends ConsumerWidget {
  const _StatusTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(interventionFilterProvider).status;
    final counts = ref.watch(interventionStatusCountsProvider);

    final tabs = <({InterventionStatus? status, String label, IconData icon, Color color})>[
      (status: null, label: l10n.statusTabAll, icon: Icons.schedule, color: AppTheme.zinc300),
      (status: InterventionStatus.pending, label: l10n.statusTabOngoing, icon: Icons.schedule, color: Colors.blue),
      (status: InterventionStatus.delayed, label: l10n.statusTabDelayed, icon: Icons.schedule, color: AppTheme.brandOrange),
      (status: InterventionStatus.completed, label: l10n.statusTabCompleted, icon: Icons.check_circle_outline, color: AppTheme.brandGreen),
    ];

    return Container(
      height: 56,
      color: AppTheme.zinc950,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = selected == tab.status;
          return GestureDetector(
            onTap: () => ref.read(interventionFilterProvider.notifier).updateStatus(tab.status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active
                    ? (tab.status == null ? AppTheme.zinc800 : tab.color.withValues(alpha: 0.2))
                    : AppTheme.zinc950,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? (tab.status == null ? AppTheme.zinc500 : tab.color.withValues(alpha: 0.5))
                      : AppTheme.zinc800,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 14, color: active ? tab.color : AppTheme.zinc500),
                  const SizedBox(width: 8),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? (tab.status == null ? Colors.white : tab.color) : AppTheme.zinc500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts.of(tab.status)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : AppTheme.zinc500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
