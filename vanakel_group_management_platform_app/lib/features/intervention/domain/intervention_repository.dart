import '../domain/intervention.dart';

abstract class InterventionRepository {
  Future<List<Intervention>> getInterventions();
  Future<Intervention> getInterventionById(String id);
  Future<Intervention> createIntervention(Map<String, dynamic> data);
  Future<Intervention> updateIntervention(String id, Map<String, dynamic> data);
  Future<void> sendReport(String id, Map<String, dynamic> reportData);
  Future<List<dynamic>> getBuildings();
  Future<List<dynamic>> getSyndics();
}
