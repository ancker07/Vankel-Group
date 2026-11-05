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
}
