import '../entities/maintenance_plan.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenancePlan>> getMaintenancePlans();
  Future<void> createMaintenancePlan(MaintenancePlan plan);
  Future<void> updateMaintenancePlan(MaintenancePlan plan);
  Future<void> deleteMaintenancePlan(String id);
}