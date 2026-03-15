import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/intervention_repository.dart';
import '../../data/repositories/intervention_repository_impl.dart';

final interventionRepositoryProvider = Provider<InterventionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return InterventionRepositoryImpl(dio);
});

final syndicListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(interventionRepositoryProvider).getSyndics();
});

final buildingListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(interventionRepositoryProvider).getBuildings();
});

final professionalListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(interventionRepositoryProvider).getProfessionals();
});
