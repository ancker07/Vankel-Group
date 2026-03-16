import 'package:dio/dio.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/maintenance_plan.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../models/maintenance_plan_model.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final Dio _dio;

  MaintenanceRepositoryImpl(this._dio);

  @override
  Future<List<MaintenancePlan>> getMaintenancePlans() async {
    try {
      final response = await _dio.get(ApiConstants.maintenancePlans);
      final List<dynamic> data = response.data;
      return data
          .map((json) => MaintenancePlanModel.fromJson(json).toEntity())
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> deleteMaintenancePlan(String id) async {
    try {
      await _dio.delete('${ApiConstants.maintenancePlans}/$id');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
