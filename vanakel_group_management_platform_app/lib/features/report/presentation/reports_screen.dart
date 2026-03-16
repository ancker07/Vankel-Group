import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../intervention/presentation/providers/intervention_list_provider.dart';
import '../../intervention/domain/intervention.dart';
import 'widgets/intervention_details_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/pdf_service.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final interventionsAsync = ref.watch(interventionListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.reports.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: interventionsAsync.when(
        data: (interventions) {
          // Filter: ONLY Completed and Delayed
          final allReports = interventions.where((i) => 
            i.status.name.toLowerCase() == 'completed' || 
            i.status.name.toLowerCase() == 'delayed'
          ).toList();

          // Sort: Newest first
          allReports.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

          final totalCount = interventions.length;
          final completedCount = allReports.length;

          final latestSlips = allReports.take(10).toList();
          
          final filteredHistory = allReports.where((i) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return i.title.toLowerCase().contains(q) || 
                   i.id.toLowerCase().contains(q) ||
                   i.address.toLowerCase().contains(q) || 
                   (i.city?.toLowerCase().contains(q) ?? false);
          }).toList();

          return CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatItem(l10n.total, totalCount.toString(), Colors.white),
                      const SizedBox(width: 12),
                      _buildStatItem(l10n.completed, completedCount.toString(), const Color(0xFF22C55E)),
                    ],
                  ),
                ),
              ),

              // Latest Slips Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Color(0xFF22C55E), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.latestSlips.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Latest Slips Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: latestSlips.length,
                    itemBuilder: (context, index) {
                      final item = latestSlips[index];
                      return _buildLatestSlipCard(item);
                    },
                  ),
                ),
              ),

              // Full History Title & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Colors.white30, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.fullHistory.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l10n.search,
                            hintStyle: const TextStyle(color: Colors.white30),
                            prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // History List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredHistory[index];
                    return _buildHistoryItem(item);
                  },
                  childCount: filteredHistory.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSlipCard(Intervention item) {
    final isDelayed = item.status.name.toLowerCase() == 'delayed';
    final themeColor = isDelayed ? Colors.orange : const Color(0xFF22C55E);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => InterventionDetailsSheet(intervention: item),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDelayed ? Colors.orange.withOpacity(0.2) : Colors.white10,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Technical Header / Background
              Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeColor.withOpacity(0.15),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.description_outlined,
                        size: 100,
                        color: themeColor.withOpacity(0.05),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(item.status),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: themeColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.address,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "#${item.id}",
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            _formatDate(item.scheduledDate),
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Intervention item) {
    final isDelayed = item.status.name.toLowerCase() == 'delayed';
    final themeColor = isDelayed ? Colors.orange : const Color(0xFF22C55E);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => InterventionDetailsSheet(intervention: item),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withOpacity(0.02),
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(item.status, small: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 10, color: themeColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.address,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_formatDate(item.scheduledDate)}  •  ID: ${item.id.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Generating PDF...'),
                                duration: Duration(seconds: 1)),
                          );

                          try {
                            // Fetch data reliably using .future
                            final buildings = await ref.read(buildingListProvider.future);
                            final syndics = await ref.read(syndicListProvider.future);
                            final professionals = await ref.read(professionalListProvider.future);

                            final building = buildings.firstWhere(
                              (b) => b['id']?.toString() == item.buildingId,
                              orElse: () => null,
                            );
                            final syndic = syndics.firstWhere(
                              (s) => s['id']?.toString() == item.syndicId,
                              orElse: () => null,
                            );
                            final pro = professionals.firstWhere(
                              (p) => p['id']?.toString() == item.proId,
                              orElse: () => null,
                            );

                            await PdfService.generateInterventionReport(
                              intervention: item,
                              building: building,
                              professional: pro,
                              syndic: syndic,
                              lang: Localizations.localeOf(context).languageCode,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error generating PDF: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            color: Colors.white24, size: 18),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          color: Colors.white10, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InterventionStatus status, {bool small = false}) {
    final isDelayed = status.name.toLowerCase() == 'delayed';
    final color = isDelayed ? Colors.orange : const Color(0xFF22C55E);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: small ? 8 : 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
