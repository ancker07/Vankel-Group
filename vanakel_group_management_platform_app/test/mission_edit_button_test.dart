import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  @override
  Future<Mission> updateMissionWithFiles(String id, FormData data) async {
    saved = data;
    return _mission(1, 'NEEDS_REVIEW');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
  testWidgets('card Edit opens the form; a mission without address saves without erasing its syndic', (tester) async {
    final repo = await _open(tester, ['missions.view', 'missions.update']);

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull, reason: 'unknown sector / syndic must not crash the form');
    expect(find.byType(CreateMissionScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mission 1'), findsOneWidget);

    final submit = find.byWidgetPredicate((w) => w is ElevatedButton).last;
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repo.saved, isNotNull, reason: 'empty address and unlisted syndic must not block saving');
    final fields = Map.fromEntries(repo.saved!.fields);
    expect(fields['_method'], 'PUT');
    expect(fields['syndicId'], '77');
    expect(fields['onSiteContactName'], '');
  });

  testWidgets('no Edit button without the permission', (tester) async {
    await _open(tester, ['missions.view']);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
