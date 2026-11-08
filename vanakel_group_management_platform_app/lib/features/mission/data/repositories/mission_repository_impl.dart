import 'package:dio/dio.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/mission.dart';
import '../../domain/mission_repository.dart';
import '../models/mission_model.dart';

class MissionRepositoryImpl implements MissionRepository {
  final Dio _dio;

  MissionRepositoryImpl(this._dio);

  // the lists are always asked from the server itself, never from a cache on the way (proxy, CDN, WebView)
  static final _noCache = Options(headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'});

  @override
  Future<List<Mission>> getMissions() async {
    try {
      final response = await _dio.get(ApiConstants.missions, options: _noCache);
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
  Future<Mission> approveMission(String id, {String? scheduledDate, int? assignedUserId}) async {
    try {
      final response = await _dio.post(
        ApiConstants.approveMission.replaceFirst('{id}', id),
        data: {
          if (scheduledDate != null) 'scheduled_date': scheduledDate,
          // the technician (or admin) who gets the work: the server creates the intervention for them
          if (assignedUserId != null) 'assigned_user_id': assignedUserId,
        },
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
  Future<void> deleteMission(String id) async {
    try {
      await _dio.delete(ApiConstants.missionUpdate.replaceFirst('{id}', id));
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

  /// Uploads can take a while on mobile data and the server translates the text before answering.
  static final _uploadOptions = Options(
    sendTimeout: const Duration(minutes: 3),
    receiveTimeout: const Duration(minutes: 2),
  );

  @override
  Future<Mission> createMissionWithFiles(FormData data) async {
    try {
      final response = await _dio.post(ApiConstants.interventions, data: data, options: _uploadOptions);
      return MissionModel.fromJson(response.data['data']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Mission> updateMissionWithFiles(String id, FormData data) async {
    try {
      final response = await _dio.post(
          ApiConstants.missionUpdate.replaceFirst('{id}', id),
          data: data,
          options: _uploadOptions);
      return MissionModel.fromJson(response.data['mission']).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
