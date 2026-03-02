import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/mission_repository.dart';
import '../../data/repositories/mission_repository_impl.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MissionRepositoryImpl(dio);
});
