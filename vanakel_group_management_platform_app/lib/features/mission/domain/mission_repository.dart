import 'package:dio/dio.dart';
import '../domain/mission.dart';

abstract class MissionRepository {
  Future<List<Mission>> getMissions();
  Future<Mission> getMissionById(String id);
  Future<Mission> approveMission(String id, {String? scheduledDate});
  Future<Mission> rejectMission(String id);
  Future<Mission> createMission(Map<String, dynamic> data);
  Future<Mission> createMissionWithFiles(FormData data);
}
