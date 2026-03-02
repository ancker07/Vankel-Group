import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mission.dart';
import '../providers/mission_provider.dart';

final missionDetailProvider = FutureProvider.family<Mission, String>((
  ref,
  missionId,
) async {
  // Temporary workaround: Fetch all missions and find the one with matching ID
  // This is needed because the backend doesn't implement /missions/{id} endpoint
  final repository = ref.watch(missionRepositoryProvider);
  final missions = await repository.getMissions();

  try {
    return missions.firstWhere((mission) => mission.id == missionId);
  } catch (e) {
    throw Exception('Mission with ID $missionId not found');
  }
});
