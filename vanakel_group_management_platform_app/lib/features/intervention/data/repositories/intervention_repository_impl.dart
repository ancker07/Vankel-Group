import 'package:dio/dio.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/intervention.dart';
import '../../domain/intervention_repository.dart';
import '../models/intervention_model.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  final Dio _dio;

  InterventionRepositoryImpl(this._dio);

  @override
  Future<List<Intervention>> getInterventions() async {
    try {
      final response = await _dio.get(ApiConstants.interventions);
      final List<dynamic> data = response.data;
      return data
          .map((json) => InterventionModel.fromJson(json).toEntity())
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Intervention> getInterventionById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.interventions}/$id');
      return InterventionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Intervention> createIntervention(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.interventions, data: data);
      return InterventionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Intervention> updateIntervention(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.interventionUpdate.replaceFirst('{id}', id),
        data: data,
      );
      return InterventionModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> sendReport(String id, Map<String, dynamic> reportData) async {
    try {
      await _dio.post(
        ApiConstants.sendReport.replaceFirst('{id}', id),
        data: reportData,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<dynamic>> getBuildings() async {
    try {
      final response = await _dio.get(ApiConstants.buildings);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<dynamic>> getSyndics() async {
    try {
      final response = await _dio.get(ApiConstants.syndics);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
