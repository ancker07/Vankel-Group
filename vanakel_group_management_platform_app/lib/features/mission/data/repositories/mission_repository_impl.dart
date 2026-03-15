import 'package:dio/dio.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/mission.dart';
import '../../domain/mission_repository.dart';
import '../models/mission_model.dart';

class MissionRepositoryImpl implements MissionRepository {
  final Dio _dio;

  MissionRepositoryImpl(this._dio);

  @override
  Future<List<Mission>> getMissions() async {
    try {
      final response = await _dio.get(ApiConstants.missions);
      final List<dynamic> data = response.data;
      return data
          .map((json) => MissionModel.fromJson(json).toEntity())
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> getMissionById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.missions}/$id');
      return MissionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> approveMission(String id, {String? scheduledDate}) async {
    try {
      final response = await _dio.post(
        ApiConstants.approveMission.replaceFirst('{id}', id),
        data: scheduledDate != null ? {'scheduled_date': scheduledDate} : null,
      );
      return MissionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> rejectMission(String id) async {
    try {
      final response = await _dio.post(
        ApiConstants.rejectMission.replaceFirst('{id}', id),
      );
      return MissionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> createMission(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiConstants
            .interventions, // Missions are created through interventions endpoint with type=mission
        data: {...data, 'type': 'mission'},
      );
      return MissionModel.fromJson(response.data['data']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> createMissionWithFiles(FormData data) async {
    try {
      final response = await _dio.post(ApiConstants.interventions, data: data);
      return MissionModel.fromJson(response.data['data']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
