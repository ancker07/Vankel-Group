import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/dashboard/admin_dashboard/admin_dashboard.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission_repository.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_provider.dart';
import 'package:vanakel_group_management_platform_app/features/report/presentation/report_actions.dart';
import 'package:vanakel_group_management_platform_app/features/report/presentation/widgets/latest_reports_section.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

Intervention _i(int id, String status, {String? updated, String title = ''}) => InterventionModel.fromJson({
      'id': id, 'title': title.isEmpty ? 'Task $id' : title, 'description': 'd', 'status': status, 'urgency': 'LOW',
      'address': 'Street $id',
      'scheduled_date': '2026-01-01T10:00:00Z',
      if (updated != null) 'updated_at': updated,
    }).toEntity();

class _Repo implements InterventionRepository {
  final List<Intervention> list;
  _Repo(this.list);
  @override
  Future<List<Intervention>> getInterventions() async => list;
  @override
  Future<List<dynamic>> getBuildings() async => [];
  @override
  Future<List<dynamic>> getSyndics() async => [];
  @override
  Future<List<dynamic>> getProfessionals() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Missions implements MissionRepository {
  @override
  Future<List<Mission>> getMissions() async => [];
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
          'id': 1, 'name': 'U', 'email': 'u@t.be', 'role': role, 'portal': 'admin', 'status': 'APPROVED', 'permissions': permissions,
        }).toEntity(),
      );
}

const _admin = ['interventions.view', 'interventions.update', 'interventions.reopen', 'reports.view', 'missions.view'];

/// Eight reports (task 1 the oldest ... task 8 the latest) and two tasks still in progress.
final _data = [
  for (var n = 1; n <= 8; n++) _i(n, n.isEven ? 'DELAYED' : 'COMPLETED', updated: '2026-03-0${n}T10:00:00Z'),
  _i(20, 'PENDING', updated: '2026-09-01T10:00:00Z'),
  _i(21, 'PENDING', updated: '2026-09-02T10:00:00Z'),
];

Future<void> _open(WidgetTester tester, List<Intervention> list, {String role = 'ADMIN', List<String> permissions = _admin, String lang = 'en', Size size = const Size(1080, 2340)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      interventionRepositoryProvider.overrideWithValue(_Repo(list)),
      missionRepositoryProvider.overrideWithValue(_Missions()),
      authStateProvider.overrideWith(() => _Auth(role, permissions)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(initialLocation: '/admin/dashboard', routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const Scaffold(body: AdminDashboard()),
          routes: [GoRoute(path: 'reports', builder: (context, state) => const Scaffold(body: Text('REPORTS PAGE')))],
        ),
      ]),
      locale: Locale(lang),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the dashboard shows the five latest reports, newest first, never work in progress', (tester) async {
    await _open(tester, _data);
    final titles = tester.widgetList<Text>(find.textContaining(RegExp(r'^Task \d+$'))).map((t) => t.data).toList();
    expect(titles, ['Task 8', 'Task 7', 'Task 6', 'Task 5', 'Task 4']);
  });

  testWidgets('View all leads to the Reports page', (tester) async {
    await _open(tester, _data);
    await tester.ensureVisible(find.text('View all'));
    await tester.tap(find.text('View all'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('REPORTS PAGE'), findsOneWidget);
  });

  testWidgets('a tap on a report starts the PDF and stays on the dashboard, no detail screen', (tester) async {
    await _open(tester, _data);
    await tester.tap(find.text('Task 8'));
    await tester.pump();
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.pdfGenerating), findsOneWidget);
    expect(find.byType(AdminDashboard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('no reports yet: says so, and View all is still there', (tester) async {
    await _open(tester, [_i(20, 'PENDING')]);
    expect(find.text('No reports yet'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('a technician, who has no Reports page, does not get the section', (tester) async {
    await _open(tester, _data, role: 'PROFESSIONAL', permissions: ['interventions.view', 'interventions.update']);
    expect(find.byType(LatestReportsSection), findsNothing);
  });

  for (final lang in ['en', 'fr', 'nl']) {
    testWidgets('$lang: small phone, very long texts: nothing overflows and the title follows the language', (tester) async {
      final long = 'A very long intervention title that keeps going and going ' * 3;
      await _open(tester, [
        for (var n = 1; n <= 5; n++) _i(n, 'COMPLETED', title: long, updated: '2026-03-0${n}T10:00:00Z'),
      ], lang: lang, size: const Size(960, 1600));
      final l10n = lookupAppLocalizations(Locale(lang));
      expect(find.text(l10n.latestReports), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'nothing on the dashboard overflows');
    });
  }

  test('the same order and the same reports as the Reports page', () {
    final ids = latestReports(_data).map((i) => i.id).toList();
    expect(ids, ['8', '7', '6', '5', '4', '3', '2', '1']);
  });
}
