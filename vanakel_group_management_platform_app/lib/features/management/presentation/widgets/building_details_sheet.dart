import 'package:flutter/material.dart';
import '../../../intervention/domain/intervention.dart';
import '../../../report/presentation/widgets/intervention_details_sheet.dart';
import '../../../../core/utils/translation_helper.dart';

class BuildingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> building;
  final Map<String, dynamic>? syndic;
  final List<Intervention> interventions;

  const BuildingDetailsSheet({
    super.key,
    required this.building,
    this.syndic,
    required this.interventions,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF09090B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Header Image
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        child: building['image_url'] != null
                            ? Image.network(building['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.apartment, size: 48, color: Colors.white10)))
                            : const Center(child: Icon(Icons.apartment, size: 48, color: Colors.white10)),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xFF09090B)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            building['address'] ?? 'No Address',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFF22C55E)),
                              const SizedBox(width: 6),
                              Text(
                                building['city'] ?? '',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Syndic Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SYNDIC CONTACT",
                          style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF18181B),
                              child: Icon(Icons.shield, color: Color(0xFF22C55E), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    syndic?['company_name'] ?? 'No Syndic Linked',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    syndic?['contact_person'] ?? '',
                                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // History Title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "INTERVENTION HISTORY",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),

              // History List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final intervention = interventions[index];
                    return _buildHistoryItem(context, intervention);
                  },
                  childCount: interventions.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, Intervention item) {
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
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
             _buildStatusBadge(item.status),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.getLocalizedField(
                      context: context,
                      enValue: item.titleEn,
                      frValue: item.titleFr,
                      nlValue: item.titleNl,
                      fallback: item.title,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.scheduledDate.day}/${item.scheduledDate.month}/${item.scheduledDate.year}",
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InterventionStatus status) {
    final isDelayed = status.name.toLowerCase() == 'delayed';
    final color = isDelayed ? Colors.orange : const Color(0xFF22C55E);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
