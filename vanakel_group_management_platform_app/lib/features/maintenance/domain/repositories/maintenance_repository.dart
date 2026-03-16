import '../entities/maintenance_plan.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenancePlan>> getMaintenancePlans();
  Future<void> deleteMaintenancePlan(String id);
}
