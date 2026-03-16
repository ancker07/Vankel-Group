import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../../data/repositories/maintenance_repository_impl.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MaintenanceRepositoryImpl(dio);
});
