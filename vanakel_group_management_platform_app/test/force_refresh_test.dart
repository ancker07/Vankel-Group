import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanakel_group_management_platform_app/core/providers/refresh_work_data.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission_repository.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_filter_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_filter_provider.dart';

/// What a screen built with `.when(...)` shows (the dashboards use the defaults, the lists skipLoadingOnReload: false).
String _shown(AsyncValue<Object?> v) =>
    v.when(skipLoadingOnReload: false, data: (_) => 'data', loading: () => 'spinner', error: (_, __) => 'error');

/// The refresh button: whatever was on screen, the spinner shows until the server's latest data is in.

Intervention _i(int id, String status) => InterventionModel.fromJson({
      'id': id, 'title': 'Task $id', 'description': 'd', 'status': status, 'urgency': 'LOW',
      'scheduled_date': '2026-01-01T10:00:00Z',
    }).toEntity();

class _Server {
  String status = 'PENDING';
  int missions = 1;
  Completer<void>? gate; // when set, the server answers only once it completes
  bool fails = false;

  Future<void> wait() async {
    if (gate != null) await gate!.future;
    if (fails) throw Exception('server busy');
  }
}

class _Repo implements InterventionRepository {
  final _Server server;
  _Repo(this.server);
  @override
  Future<List<Intervention>> getInterventions() async {
    await server.wait();
    return [_i(1, server.status)];
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Missions implements MissionRepository {
  final _Server server;
  _Missions(this.server);
  @override
  Future<List<Mission>> getMissions() async {
    await server.wait();
    return [
      for (var n = 1; n <= server.missions; n++)
        MissionModel.fromJson({'id': n, 'title': 'M$n', 'description': 'd', 'status': 'PENDING', 'urgency': 'LOW'}).toEntity(),
    ];
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'U', 'email': 'u@t.be', 'role': 'admin', 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['interventions.view', 'missions.view'],
        }).toEntity(),
      );
}

void main() {
  late _Server server;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = _Server();
    container = ProviderContainer(overrides: [
      interventionRepositoryProvider.overrideWithValue(_Repo(server)),
      missionRepositoryProvider.overrideWithValue(_Missions(server)),
      authStateProvider.overrideWith(_Auth.new),
    ]);
    container.listen(interventionListProvider, (_, __) {});
    container.listen(missionListProvider, (_, __) {});
    await container.read(interventionListProvider.future);
    await container.read(missionListProvider.future);
  });

  tearDown(() => container.dispose());

  test('shows the spinner (no old data) until the latest data is in, then shows it', () async {
    server
      ..status = 'COMPLETED'
      ..missions = 3
      ..gate = Completer();

    var done = false;
    final refresh = container.read(workDataRefresherProvider).force().then((_) => done = true);
    await Future<void>.delayed(Duration.zero);

    // the dashboards, Ongoing and Missions all show the spinner, not the old list
    expect(_shown(container.read(interventionListProvider)), 'spinner');
    expect(_shown(container.read(missionListProvider)), 'spinner');
    expect(_shown(container.read(filteredInterventionListProvider)), 'spinner');
    expect(_shown(container.read(filteredMissionListProvider)), 'spinner');
    expect(done, isFalse, reason: 'the button keeps turning while the server has not answered');

    server.gate!.complete();
    await refresh;

    expect(container.read(interventionListProvider).value!.single.status, InterventionStatus.completed);
    expect(container.read(missionListProvider).value, hasLength(3));
  });

  test('a failing server shows its error (with retry), not the old data, and the button stops turning', () async {
    server.fails = true;
    await container.read(workDataRefresherProvider).force(); // does not throw

    expect(_shown(container.read(interventionListProvider)), 'error');
    expect(_shown(container.read(filteredInterventionListProvider)), 'error');
    expect(_shown(container.read(missionListProvider)), 'error');

    // retry once the server is back
    server
      ..fails = false
      ..status = 'DELAYED';
    await container.read(workDataRefresherProvider).force();
    expect(container.read(interventionListProvider).value!.single.status, InterventionStatus.delayed);
  });

  test('pull to refresh keeps the list on screen and completes with the latest data', () async {
    server
      ..status = 'COMPLETED'
      ..gate = Completer();
    final pull = container.read(workDataRefresherProvider).pull();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(interventionListProvider).value!.single.status, InterventionStatus.pending);

    server.gate!.complete();
    await pull;
    expect(container.read(interventionListProvider).value!.single.status, InterventionStatus.completed);
  });
}
