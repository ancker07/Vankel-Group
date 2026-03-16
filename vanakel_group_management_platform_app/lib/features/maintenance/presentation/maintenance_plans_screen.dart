import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';
import 'providers/maintenance_list_provider.dart';
import '../../maintenance/domain/entities/maintenance_plan.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/translation_helper.dart';
import 'widgets/maintenance_plan_form_sheet.dart';

class MaintenancePlansScreen extends ConsumerWidget {
  const MaintenancePlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(maintenanceListProvider);
    final buildingsAsync = ref.watch(buildingListProvider);
    final syndicsAsync = ref.watch(syndicListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.maintenance.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: plansAsync.when(
        data: (plans) => buildingsAsync.when(
          data: (buildings) => syndicsAsync.when(
            data: (syndics) {
              if (plans.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final building = buildings.firstWhere(
                    (b) => b['id'].toString() == plan.buildingId,
                    orElse: () => null,
                  );
                  final syndic = syndics.firstWhere(
                    (s) => s['id'].toString() == plan.syndicId || (building != null && s['id'].toString() == building['linked_syndic_id'].toString()),
                    orElse: () => null,
                  );

                  return _buildMaintenanceCard(plan, building, syndic, context, ref);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
            error: (err, stack) => Center(child: Text('Error syndics: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
          error: (err, stack) => Center(child: Text('Error buildings: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
        error: (err, stack) => Center(child: Text('Error plans: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        child: const Icon(Icons.add, color: Color(0xFFF97316)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const MaintenancePlanFormSheet(),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenancePlan plan, dynamic building, dynamic syndic, BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.frequency.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFF97316), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
                Text(
                  "Next: ${_formatDate(plan.startDate)}",
                  style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              TranslationHelper.getLocalizedField(
                context: context,
                enValue: plan.titleEn,
                frValue: plan.titleFr,
                nlValue: plan.titleNl,
                fallback: plan.title,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              TranslationHelper.getLocalizedField(
                context: context,
                enValue: plan.descriptionEn,
                frValue: plan.descriptionFr,
                nlValue: plan.descriptionNl,
                fallback: plan.description.isEmpty ? 'Routine maintenance plan.' : plan.description,
              ),
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white24),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    building?['address'] ?? 'No Address',
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shield, size: 14, color: Colors.white24),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    syndic?['company_name'] ?? 'No Syndic',
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.edit_outlined,
                    label: "Edit",
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => MaintenancePlanFormSheet(plan: plan),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.delete_outline,
                    label: "Delete",
                    color: Colors.redAccent,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF09090B),
                          title: const Text('Delete Plan?', style: TextStyle(color: Colors.white)),
                          content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await ref.read(maintenanceListProvider.notifier).deletePlan(plan.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, Color color = Colors.white24, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color == Colors.white24 ? Colors.white54 : color),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color == Colors.white24 ? Colors.white54 : color, 
                fontSize: 11, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restore, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            'No maintenance plans',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first plan to start tracking',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
