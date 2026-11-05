import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/providers/reset_user_data.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';

/// Answers with the interventions of whoever is "signed in" right now.
class _Repository implements InterventionRepository {
  List<Intervention> current = [];
  @override
  Future<List<Intervention>> getInterventions() async => current;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Intervention _intervention(int id, String title) => InterventionModel.fromJson({
      'id': id,
      'title': title,
      'status': 'PENDING',
    }).toEntity();

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, isSplashDone: true);
  void signInAs(int id) => state = state.copyWith(
        user: UserModel.fromJson({'id': id, 'name': 'U$id', 'email': 'u$id@t.be', 'role': 'ADMIN', 'portal': 'admin', 'status': 'APPROVED'}).toEntity(),
      );
  void signOut() => state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
}

void main() {
  test('another account sees its own interventions, never the previous account\'s cached list', () async {
    final repository = _Repository();
    final container = ProviderContainer(overrides: [
      interventionRepositoryProvider.overrideWithValue(repository),
      authStateProvider.overrideWith(_Auth.new),
    ]);
    addTearDown(container.dispose);

    // the admin's phone session
    repository.current = [_intervention(1, 'Admin sees this'), _intervention(2, 'And this')];
    expect((await container.read(interventionListProvider.future)).length, 2);

    // a technician logs in on the same phone: the server would only return his own one ...
    repository.current = [_intervention(9, 'Technician job')];
    // ... but without a reset the cached list of the admin is still what the app shows
    expect((await container.read(interventionListProvider.future)).length, 2, reason: 'this is the bug: stale data');

    resetUserData((p) => container.invalidate(p));

    final list = await container.read(interventionListProvider.future);
    expect(list.map((i) => i.id), ['9']);
  });

  test('logging out really clears the signed-in user', () {
    final container = ProviderContainer(overrides: [authStateProvider.overrideWith(_Auth.new)]);
    addTearDown(container.dispose);
    final auth = container.read(authStateProvider.notifier) as _Auth;

    auth.signInAs(5);
    expect(container.read(authStateProvider).user?.id, 5);

    auth.signOut();
    expect(container.read(authStateProvider).user, isNull);
    expect(container.read(authStateProvider).status, AuthStatus.unauthenticated);
  });
}
