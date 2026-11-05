import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_filter_provider.dart';

Mission _m(int id, String status, {int? assignee}) => MissionModel.fromJson({
      'id': id, 'title': 'M$id', 'description': 'd', 'status': status,
      if (assignee != null) 'assigned_user_id': assignee,
    }).toEntity();

void main() {
  test('by default only the missions waiting for a decision (not yet an intervention) are shown', () {
    const filter = MissionFilter();
    expect(filter.matches(_m(1, 'PENDING')), isTrue);
    expect(filter.matches(_m(2, 'NEEDS_REVIEW')), isTrue);
    expect(filter.matches(_m(3, 'APPROVED')), isFalse, reason: 'already converted to an intervention');
    expect(filter.matches(_m(4, 'APPROVED', assignee: 9)), isFalse, reason: 'already assigned');
    expect(filter.matches(_m(5, 'REJECTED')), isFalse);
  });

  test('picking a status still shows that status, assigned or not', () {
    const filter = MissionFilter(status: MissionStatus.approved);
    expect(filter.matches(_m(4, 'APPROVED', assignee: 9)), isTrue);
  });

  test('missions without an address stay visible, at the end of the list', () {
    Mission m(int id, String created, {String? address}) => MissionModel.fromJson({
          'id': id, 'title': 'M$id', 'description': 'd', 'status': 'PENDING', 'created_at': created,
          if (address != null) 'extracted_address': address,
        }).toEntity();

    final sorted = sortMissionsForList([
      m(1, '2026-11-06T10:00:00Z'),
      m(2, '2026-11-01T10:00:00Z', address: 'Rue Haute 1'),
      m(3, '2026-11-03T10:00:00Z', address: 'Rue Basse 2'),
      m(4, '2026-11-02T10:00:00Z', address: '  '),
    ]);
    expect(sorted.map((x) => x.id).toList(), ['3', '2', '1', '4']);
  });
}
