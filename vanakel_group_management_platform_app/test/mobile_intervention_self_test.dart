import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/intervention_details_screen.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

Intervention _intervention({int? proId, bool admin = false}) => InterventionModel.fromJson({
      'id': 9, 'title': 'Leak', 'description': 'd', 'status': 'PENDING', 'urgency': 'LOW',
      if (proId != null) 'pro_id': proId,
      'assigned_to_admin': admin,
    }).toEntity();

class _Repo implements InterventionRepository {
  final Intervention i;
  _Repo(this.i);
  @override
  Future<Intervention> getInterventionById(String id) async => i;
  @override
  Future<List<dynamic>> getSyndics() async => [];
  @override
  Future<List<dynamic>> getBuildings() async => [];
  @override
  Future<List<dynamic>> getProfessionals() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Auth extends AuthNotifier {
  final String role;
  final List<String> permissions;
  _Auth(this.role, this.permissions);
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'Boss', 'email': 'a@t.be', 'role': role, 'portal': 'admin',
          'status': 'APPROVED', 'permissions': permissions,
        }).toEntity(),
      );
}

Future<void> _open(WidgetTester tester, Intervention i, String role, List<String> permissions) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      interventionRepositoryProvider.overrideWithValue(_Repo(i)),
      authStateProvider.overrideWith(() => _Auth(role, permissions)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InterventionDetailsScreen(interventionId: '9'),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _drainOverflow(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  Object? ex;
  while ((ex = tester.takeException()) != null) {
    expect(ex.toString(), contains('overflowed')); // test font is wider than a phone's
  }
}

void main() {
  const adminPerms = ['interventions.view', 'interventions.update', 'interventions.reopen', 'missions.approve', 'team.view'];

  testWidgets('admin: Do it myself assigns the task to them and shows the Admin task banner', (tester) async {
    await _open(tester, _intervention(proId: 2), 'ADMIN', adminPerms);
    expect(find.text('DO IT MYSELF'), findsOneWidget);
    expect(find.text('ADMIN TASK'), findsNothing); // currently a technician's task

    await tester.tap(find.text('DO IT MYSELF'));
    await tester.pump();
    expect(find.text('ASSIGNED TO YOU'), findsOneWidget);
    expect(find.text('ADMIN TASK'), findsOneWidget);

    await tester.tap(find.text('ASSIGNED TO YOU')); // second tap goes back to the technician
    await tester.pump();
    expect(find.text('DO IT MYSELF'), findsOneWidget);
    expect(find.text('ADMIN TASK'), findsNothing);
    await _drainOverflow(tester);
  });

  testWidgets('a task already assigned to an admin shows the banner', (tester) async {
    await _open(tester, _intervention(proId: 3, admin: true), 'ADMIN', adminPerms);
    expect(find.text('ADMIN TASK'), findsOneWidget);
    await _drainOverflow(tester);
  });

  testWidgets('technician: no Do it myself button', (tester) async {
    await _open(tester, _intervention(proId: 1), 'PROFESSIONAL', ['interventions.view', 'interventions.update']);
    expect(find.text('DO IT MYSELF'), findsNothing);
    await _drainOverflow(tester);
  });
}
