import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_filter_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';

class _Repository implements InterventionRepository {
  final List<Intervention> list;
  _Repository(this.list);
  @override
  Future<List<Intervention>> getInterventions() async => list;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Intervention _i(int id, String status, {String sector = 'GENERAL', String date = '2026-11-01'}) => InterventionModel.fromJson({
      'id': id,
      'title': 'Job $id',
      'status': status,
      'sector': sector,
      'scheduled_date': '${date}T10:00:00Z',
    }).toEntity();

class _Auth extends AuthNotifier {
  final String role;
  _Auth(this.role);
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'U', 'email': 'u@t.be', 'role': role, 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['interventions.view'],
        }).toEntity(),
      );
}

Future<ProviderContainer> _container(String role) async {
  final data = [
    for (var n = 1; n <= 4; n++) _i(n, 'PENDING', sector: n <= 2 ? 'PLUMBING' : 'GENERAL', date: '2026-11-0$n'),
    _i(5, 'DELAYED'),
    _i(6, 'COMPLETED', sector: 'PLUMBING'),
    _i(7, 'COMPLETED'),
  ];
  final container = ProviderContainer(overrides: [
    interventionRepositoryProvider.overrideWithValue(_Repository(data)),
    authStateProvider.overrideWith(() => _Auth(role)),
  ]);
  addTearDown(container.dispose);
  await container.read(interventionListProvider.future);
  return container;
}

void main() {
  test('the Ongoing list shows only work in progress, for admins too (no completed, no delayed)', () async {
    final container = await _container('ADMIN');

    final counts = container.read(interventionStatusCountsProvider);
    expect((counts.all, counts.pending, counts.delayed, counts.completed), (4, 4, 0, 0));
    expect(container.read(filteredInterventionListProvider).value!.length, 4);

    // a leftover Completed / Delayed status filter cannot bring those back
    container.read(interventionFilterProvider.notifier).updateStatus(InterventionStatus.completed);
    expect(container.read(filteredInterventionListProvider).value, isEmpty);
    container.read(interventionFilterProvider.notifier).updateStatus(InterventionStatus.delayed);
    expect(container.read(filteredInterventionListProvider).value, isEmpty);
    // switching the filter does not change the counts
    expect(container.read(interventionStatusCountsProvider).all, 4);
  });

  test('the other filters change the counts, the selected status does not', () async {
    final container = await _container('ADMIN');
    container.read(interventionFilterProvider.notifier).updateSector('PLUMBING');

    final counts = container.read(interventionStatusCountsProvider);
    expect((counts.all, counts.pending, counts.delayed, counts.completed), (2, 2, 0, 0));
  });

  test('the list is newest first', () async {
    final container = await _container('ADMIN');
    final ids = container.read(filteredInterventionListProvider).value!.map((i) => i.id).toList();
    final dates = container.read(filteredInterventionListProvider).value!.map((i) => i.scheduledDate).toList();
    expect(dates, orderedEquals([...dates]..sort((a, b) => b.compareTo(a))));
    expect(ids.first, isNot('1')); // the oldest of the pending ones is not first
  });

  test('a technician only has the interventions still to do', () async {
    final container = await _container('PROFESSIONAL');

    final counts = container.read(interventionStatusCountsProvider);
    expect((counts.all, counts.pending, counts.delayed, counts.completed), (4, 4, 0, 0));
    expect(container.read(filteredInterventionListProvider).value!.every((i) => i.status == InterventionStatus.pending), isTrue);
  });
}
