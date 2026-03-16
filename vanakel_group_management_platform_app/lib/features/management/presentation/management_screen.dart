import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../intervention/domain/intervention.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';
import '../../intervention/presentation/providers/intervention_list_provider.dart';
import '../../mission/presentation/providers/mission_list_provider.dart';
import '../../../l10n/app_localizations.dart';

import 'widgets/building_details_sheet.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  String _searchQuery = '';
  String _selectedSyndicId = 'ALL';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buildingsAsync = ref.watch(buildingListProvider);
    final syndicsAsync = ref.watch(syndicListProvider);
    final interventionsAsync = ref.watch(interventionListProvider);
    final missionsAsync = ref.watch(missionListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.management.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: interventionsAsync.when(
        data: (interventions) => missionsAsync.when(
          data: (missions) => buildingsAsync.when(
            data: (buildings) => syndicsAsync.when(
              data: (syndics) {
                // 1. Group activity by building (Completed interventions + Approved missions)
                final buildingActivityCount = <String, int>{};
                for (final i in interventions) {
                  final bId = i.buildingId;
                  if (bId != null && i.status.name.toLowerCase() == 'completed') {
                    buildingActivityCount[bId] = (buildingActivityCount[bId] ?? 0) + 1;
                  }
                }
                for (final m in missions) {
                  final bId = m.buildingId;
                  if (bId != null && m.status.name.toLowerCase() == 'approved') {
                    buildingActivityCount[bId] = (buildingActivityCount[bId] ?? 0) + 1;
                  }
                }

                // 2. Filter buildings
                final filteredBuildings = buildings.where((b) {
                  final bId = b['id'].toString();
                  // Must have activity
                  final count = buildingActivityCount[bId] ?? 0;
                  if (count == 0) return false;

                  // Syndic Filter
                  if (_selectedSyndicId != 'ALL' && b['linked_syndic_id'].toString() != _selectedSyndicId) {
                    return false;
                  }

                  // Search Filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final address = (b['address'] ?? '').toString().toLowerCase();
                    final city = (b['city'] ?? '').toString().toLowerCase();
                    final syndic = syndics.firstWhere((s) => s['id'].toString() == b['linked_syndic_id'].toString(), orElse: () => null);
                    final syndicName = (syndic?['company_name'] ?? '').toString().toLowerCase();

                    if (!address.contains(q) && !city.contains(q) && !syndicName.contains(q)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                return Column(
                  children: [
                    // Search & Filter Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Search Bar
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
                          const SizedBox(height: 12),
                          // Syndic Filter Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSyndicId,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF18181B),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30),
                                items: [
                                  const DropdownMenuItem(value: 'ALL', child: Text('All Syndics', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                                  ...syndics.map((s) => DropdownMenuItem(
                                        value: s['id'].toString(),
                                        child: Text(s['company_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      )),
                                ],
                                onChanged: (val) => setState(() => _selectedSyndicId = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grid/List of Buildings
                    Expanded(
                      child: filteredBuildings.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredBuildings.length,
                              itemBuilder: (context, index) {
                                final b = filteredBuildings[index];
                                final bId = b['id'].toString();
                                final syndic = syndics.firstWhere((s) => s['id'].toString() == b['linked_syndic_id'].toString(), orElse: () => null);
                                 final count = buildingActivityCount[bId] ?? 0;
                                 final bInterventions = interventions.where((i) => i.buildingId == bId).toList();

                                 return _buildPropertyCard(b, syndic, count, bInterventions);
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
              error: (err, stack) => Center(child: Text('Error syndics: $err')),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
            error: (err, stack) => Center(child: Text('Error buildings: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
          error: (err, stack) => Center(child: Text('Error missions: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
        error: (err, stack) => Center(child: Text('Error interventions: $err')),
      ),
    );
  }

  Widget _buildPropertyCard(dynamic building, dynamic syndic, int count, List<Intervention> bInterventions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => BuildingDetailsSheet(
                building: building,
                syndic: syndic,
                interventions: bInterventions,
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        building['address'] ?? 'No Address',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count Activities',
                        style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  building['city'] ?? '',
                  style: const TextStyle(color: Colors.white30, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.business, size: 14, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      syndic?['company_name'] ?? 'No Syndic',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text(
            'No properties found',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
