import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/router/mobile_access.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_filter_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';

/// "Ongoing interventions" is only the work in progress, for every role: never completed, never delayed.
Intervention _i(int id, String status) => InterventionModel.fromJson({
      'id': id, 'title': 'Task $id', 'description': 'd', 'status': status, 'urgency': 'LOW',
    }).toEntity();

class _Repo implements InterventionRepository {
  @override
  Future<List<Intervention>> getInterventions() async => [
        _i(1, 'PENDING'), _i(2, 'COMPLETED'), _i(3, 'DELAYED'), _i(4, 'PENDING'), _i(5, 'COMPLETED'),
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Auth extends AuthNotifier {
  final String role;
  _Auth(this.role);
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'U', 'email': 'u@t.be', 'role': role, 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['interventions.view', 'interventions.update', 'interventions.reopen'],
        }).toEntity(),
      );
}

ProviderContainer _container(String role) => ProviderContainer(overrides: [
      interventionRepositoryProvider.overrideWithValue(_Repo()),
      authStateProvider.overrideWith(() => _Auth(role)),
    ]);

void main() {
  for (final role in ['ADMIN', 'SUPERADMIN', 'PROFESSIONAL']) {
    test('$role: the Ongoing list holds only the interventions in progress', () async {
      final c = _container(role);
      addTearDown(c.dispose);
      await c.read(interventionListProvider.future);

      final shown = c.read(filteredInterventionListProvider).value!;
      expect(shown.map((i) => i.id).toSet(), {'1', '4'});
      expect(shown.every((i) => i.status == InterventionStatus.pending), isTrue);
      expect(c.read(authStateProvider).user!.seesOnlyOpenInterventions, isTrue, reason: 'no status tabs for anybody');
    });

    test('$role: even a leftover Completed / Delayed filter cannot bring them back', () async {
      final c = _container(role);
      addTearDown(c.dispose);
      await c.read(interventionListProvider.future);

      for (final status in [InterventionStatus.completed, InterventionStatus.delayed]) {
        c.read(interventionFilterProvider.notifier).updateStatus(status);
        expect(c.read(filteredInterventionListProvider).value, isEmpty);
      }
      c.read(interventionFilterProvider.notifier).updateStatus(null);
      expect(c.read(filteredInterventionListProvider).value!.length, 2);
    });
  }

  test('the counts only count work in progress', () async {
    final c = _container('ADMIN');
    addTearDown(c.dispose);
    await c.read(interventionListProvider.future);
    final counts = c.read(interventionStatusCountsProvider);
    expect(counts.pending, 2);
    expect(counts.completed, 0);
    expect(counts.delayed, 0);
    expect(counts.all, 2);
  });
}
