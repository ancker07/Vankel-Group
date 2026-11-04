import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/enums/user_role_enum.dart';
import 'package:vanakel_group_management_platform_app/features/auth/domain/entities/user.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission_repository.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_provider.dart';

/// A technician has no missions section: the list is empty and the server is never asked
/// (it would answer 403 and every screen reading the list would show an error).
class _Auth extends AuthNotifier {
  final User user;
  _Auth(this.user);
  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, user: user, isSplashDone: true);
}

class _CountingRepository implements MissionRepository {
  int calls = 0;
  @override
  Future<List<Mission>> getMissions() async {
    calls++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

User _user(List<String> permissions) => User(
      id: 1,
      name: 'Tom',
      email: 'tom@test.be',
      phone: '',
      role: UserRole.technician,
      isApproved: true,
      permissions: permissions,
    );

void main() {
  test('a technician (no missions.view) gets an empty list and no request is made', () async {
    final repository = _CountingRepository();
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(() => _Auth(_user(['interventions.view', 'interventions.update']))),
      missionRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    final missions = await container.read(missionListProvider.future);

    expect(missions, isEmpty);
    expect(repository.calls, 0);
  });

  test('a role with missions.view still loads the missions from the server', () async {
    final repository = _CountingRepository();
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(() => _Auth(_user(['missions.view', 'interventions.view']))),
      missionRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    await container.read(missionListProvider.future);

    expect(repository.calls, 1);
  });
}
