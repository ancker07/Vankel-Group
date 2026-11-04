import '../domain/intervention.dart';

/// Who received the report e-mail after "Save & send" (the server answers this with the save).
class ReportOutcome {
  final List<String> sent;
  final List<String> failed;
  const ReportOutcome({required this.sent, required this.failed});

  bool get delivered => sent.isNotEmpty;
  bool get complete => sent.isNotEmpty && failed.isEmpty;

  factory ReportOutcome.fromJson(Map<String, dynamic> json) => ReportOutcome(
        sent: (json['sent'] as List? ?? []).map((e) => e.toString()).toList(),
        failed: (json['failed'] as List? ?? []).map((e) => (e is Map ? e['email'] : e).toString()).toList(),
      );
}

/// Result of saving an intervention: [report] is set when the report e-mail was asked for.
class RegisterResult {
  final ReportOutcome? report;
  const RegisterResult({this.report});
}

abstract class InterventionRepository {
  Future<List<Intervention>> getInterventions();
  Future<Intervention> getInterventionById(String id);
  Future<Intervention> createIntervention(Map<String, dynamic> data);
  Future<Intervention> updateIntervention(String id, Map<String, dynamic> data);
  Future<RegisterResult> registerIntervention(String id, dynamic data);
  Future<void> sendReport(String id, Map<String, dynamic> reportData);
  Future<List<dynamic>> getBuildings();
  Future<List<dynamic>> getSyndics();
  Future<List<dynamic>> getProfessionals();
  Future<String> improveNote(String text);
  Future<void> createMaintenancePlan(Map<String, dynamic> data);
}