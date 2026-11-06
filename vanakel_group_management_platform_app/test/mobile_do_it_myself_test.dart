import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vanakel_group_management_platform_app/features/admin/data/admin_models.dart';
import 'package:vanakel_group_management_platform_app/features/admin/data/admin_repository.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission_repository.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/create_mission_screen.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/missions_screen.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_provider.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

Mission _mission(int id, String status, {Object? syndic}) => MissionModel.fromJson({
      'id': id, 'title': 'Mission $id', 'description': 'd', 'status': status,
      'sector': 'SOMETHING_UNKNOWN',
      if (syndic != null) 'syndic_id': syndic,
    }).toEntity();

class _Repo implements MissionRepository {
  FormData? saved;
  @override
  Future<List<Mission>> getMissions() async =>
      [_mission(1, 'NEEDS_REVIEW', syndic: 77), _mission(2, 'APPROVED')];
  String? approvedId;
  int? approvedAssignee;
  @override
  Future<Mission> approveMission(String id, {String? scheduledDate, int? assignedUserId}) async {
    approvedId = id;
    approvedAssignee = assignedUserId;
    return _mission(1, 'APPROVED');
  }
  @override
  Future<Mission> updateMissionWithFiles(String id, FormData data) async {
    saved = data;
    return _mission(1, 'NEEDS_REVIEW');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Like the real API: /users/all does NOT include the logged-in user.
class _Admin extends AdminRepository {
  _Admin() : super(Dio());
  @override
  Future<List<AdminUser>> users() async => const [
        AdminUser(id: 2, name: 'Tech One', email: 't@x.be', role: 'PROFESSIONAL', roleLabel: 'Technician', status: 'APPROVED'),
      ];
}

class _Interventions implements InterventionRepository {
  @override
  Future<List<dynamic>> getSyndics() async => [{'id': 5, 'company_name': 'Other'}];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Auth extends AuthNotifier {
  final List<String> permissions;
  _Auth(this.permissions);
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'Admin', 'email': 'a@t.be', 'role': 'ADMIN', 'portal': 'admin',
          'status': 'APPROVED', 'permissions': permissions,
        }).toEntity(),
      );
}

Future<_Repo> _open(WidgetTester tester, List<String> permissions) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final repo = _Repo();
  final router = GoRouter(initialLocation: '/admin/missions', routes: [
    GoRoute(
      path: '/admin/missions',
      builder: (_, __) => const Scaffold(body: MissionsScreen(isAdmin: true)),
      routes: [
        GoRoute(
          path: 'create',
          builder: (_, state) => CreateMissionScreen(mission: state.extra as Mission?),
        ),
      ],
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      missionRepositoryProvider.overrideWithValue(repo),
      interventionRepositoryProvider.overrideWithValue(_Interventions()),
      authStateProvider.overrideWith(() => _Auth(permissions)),
      adminRepositoryProvider.overrideWithValue(_Admin()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  return repo;
}

void main() {
  testWidgets('Approve & assign shows "Do it myself"; tapping it assigns the admin and approves for them', (tester) async {
    final repo = await _open(tester, ['missions.view', 'missions.approve']);

    await tester.pump(const Duration(seconds: 3));
    await tester.ensureVisible(find.text('APPROVE & ASSIGN'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('APPROVE & ASSIGN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('DO IT MYSELF'), findsOneWidget, reason: 'the approve dialog must offer Do it myself');
    await tester.tap(find.text('DO IT MYSELF'));
    await tester.pump();
    // (the test font is wider than a real phone's, so layout overflows are ignored; anything else is a failure)
    Object? ex;
    while ((ex = tester.takeException()) != null) {
      expect(ex.toString(), contains('overflowed'), reason: 'picking yourself must not break the dropdown');
    }
    expect(find.text('ASSIGNED TO YOU'), findsOneWidget);

    await tester.tap(find.text('APPROVE').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    Object? ex2;
    while ((ex2 = tester.takeException()) != null) {
      expect(ex2.toString(), contains('overflowed'));
    }
    expect(repo.approvedId, '1');
    expect(repo.approvedAssignee, 1, reason: 'the mission is assigned to the logged-in admin');
  });

  testWidgets('a technician list pick still works without the shortcut', (tester) async {
    final repo = await _open(tester, ['missions.view', 'missions.approve']);
    await tester.pump(const Duration(seconds: 3));
    await tester.ensureVisible(find.text('APPROVE & ASSIGN'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('APPROVE & ASSIGN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('APPROVE').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    Object? ex;
    while ((ex = tester.takeException()) != null) {
      expect(ex.toString(), contains('overflowed'));
    }
    expect(repo.approvedAssignee, isNull);
  });
}
