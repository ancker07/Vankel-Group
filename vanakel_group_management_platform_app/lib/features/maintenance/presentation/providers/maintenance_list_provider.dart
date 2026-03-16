import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/maintenance_plan.dart';
import 'maintenance_provider.dart';

class MaintenanceListNotifier extends AsyncNotifier<List<MaintenancePlan>> {
  @override
  Future<List<MaintenancePlan>> build() async {
    return ref.watch(maintenanceRepositoryProvider).getMaintenancePlans();
  }

  Future<void> deletePlan(String id) async {
    final repository = ref.read(maintenanceRepositoryProvider);
    try {
      await repository.deleteMaintenancePlan(id);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final maintenanceListProvider = AsyncNotifierProvider<MaintenanceListNotifier, List<MaintenancePlan>>(
  MaintenanceListNotifier.new,
);
