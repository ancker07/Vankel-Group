import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/intervention.dart';

class InterventionRepository extends Notifier<List<Intervention>> {
  @override
  List<Intervention> build() {
    return [
      Intervention(
        id: '1',
        title: 'Boiler Maintenance',
        address: 'Res. Palace - Apt 4B',
        description: 'Annual checkup required.',
        status: InterventionStatus.scheduled,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        tenantContact: '+32 470 12 34 56',
        codes: ['1234', 'Keybox 5'],
      ),
      Intervention(
        id: '2',
        title: 'Roof Repair',
        address: '10 Rue de la Paix',
        description: 'Leak detected in attic.',
        status: InterventionStatus.in_progress,
        scheduledDate: DateTime.now(),
        tenantContact: 'Syndic Office',
        codes: ['9988'],
      ),
      Intervention(
        id: '3',
        title: 'Painting Common Areas',
        address: '55 Ave Louise',
        description: 'Repaint ground floor hallway.',
        status: InterventionStatus.delayed,
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        tenantContact: 'Concierge',
        codes: [],
      ),
       Intervention(
        id: '4',
        title: 'Elevator Fix',
        address: '22 Rue Royal',
        description: 'Elevator stuck on 3rd floor.',
        status: InterventionStatus.completed,
        scheduledDate: DateTime.now().subtract(const Duration(days: 5)),
        tenantContact: 'Concierge',
        codes: [],
      ),
    ];
  }

  void updateStatus(String id, InterventionStatus status) {
    state = [
      for (final intervention in state)
        if (intervention.id == id) intervention.copyWith(status: status) else intervention,
    ];
  }
}

final interventionRepositoryProvider =
    NotifierProvider<InterventionRepository, List<Intervention>>(InterventionRepository.new);
