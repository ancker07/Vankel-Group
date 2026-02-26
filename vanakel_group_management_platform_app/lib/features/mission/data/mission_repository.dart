import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mission.dart';

class MissionRepository extends Notifier<List<Mission>> {
  @override
  List<Mission> build() {
    return [
      Mission(
        id: '1',
        title: 'Water Leak in Basement',
        description: 'Large puddle of water near the main boiler.',
        address: '123 Rue de la Loi, Brussels',
        status: MissionStatus.pending,
        urgency: MissionUrgency.urgent,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isAiDetected: true,
      ),
      Mission(
        id: '2',
        title: 'Broken Light in Hallway',
        description: 'Light fixture on 2nd floor is flickering.',
        address: '45 Ave Louise, Brussels',
        status: MissionStatus.pending,
        urgency: MissionUrgency.normal,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isAiDetected: false,
      ),
      Mission(
        id: '3',
        title: 'Intercom Malfunction',
        description: 'Tenants cannot hear visitors.',
        address: '88 Rue du Trone, Brussels',
        status: MissionStatus.approved,
        urgency: MissionUrgency.low,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isAiDetected: true,
      ),
    ];
  }

  void addMission(Mission mission) {
    state = [...state, mission];
  }

  void updateMissionStatus(String id, MissionStatus status) {
    state = [
      for (final mission in state)
        if (mission.id == id) mission.copyWith(status: status) else mission,
    ];
  }

  void deleteMission(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final missionRepositoryProvider =
    NotifierProvider<MissionRepository, List<Mission>>(MissionRepository.new);
