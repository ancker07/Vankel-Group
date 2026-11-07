import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vanakel_group_management_platform_app/core/providers/refresh_work_data.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/intervention_submitter.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/intervention_details_screen.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/interventions_screen.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';
import 'package:vanakel_group_management_platform_app/features/report/presentation/reports_screen.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

/// The real journey: Ongoing list -> task -> Completed / Delayed -> save -> back. The task must leave Ongoing and be
/// in Reports straight away, whatever the connection did.

enum _Net { ok, answerLost, offline }

/// The server's data, and how the connection to it behaves.
class _Backend {
  final Map<String, String> status = {'1': 'PENDING', '2': 'PENDING'};
  final Map<String, String> updatedAt = {};
  _Net net = _Net.ok;
  int listCalls = 0;
  bool slowList = false; // the list answers only after 20 seconds
  bool listFails = false;

  List<Intervention> list() {
    listCalls++;
    if (net == _Net.offline) throw Exception('no network');
    return [
      for (final e in status.entries)
        InterventionModel.fromJson({
          'id': int.parse(e.key), 'title': 'Task ${e.key}', 'description': 'd', 'status': e.value, 'urgency': 'LOW',
          'scheduled_date': '2026-01-0${e.key}T10:00:00Z',
          if (updatedAt[e.key] != null) 'updated_at': updatedAt[e.key],
        }).toEntity(),
    ];
  }
}

class _Repo implements InterventionRepository {
  final _Backend backend;
  _Repo(this.backend);
  @override
  Future<List<Intervention>> getInterventions() async {
    if (backend.slowList) await Future.delayed(const Duration(seconds: 20));
    if (backend.listFails) throw Exception('server busy');
    return backend.list();
  }
  @override
  Future<List<dynamic>> getBuildings() async => [];
  @override
  Future<List<dynamic>> getSyndics() async => [];
  @override
  Future<List<dynamic>> getProfessionals() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// The save itself goes through the real submitter, over this fake connection.
class _Adapter implements HttpClientAdapter {
  final _Backend backend;
  _Adapter(this.backend);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final fail = DioException(requestOptions: options, type: DioExceptionType.connectionError, error: const SocketException('no network'));
    if (backend.net == _Net.offline) throw fail;
    final fields = {for (final f in (options.data as FormData).fields) f.key: f.value};
    backend.status[options.path.split('/').last] = fields['status'] ?? 'PENDING';
    if (backend.net == _Net.answerLost) throw fail; // the server saved it, the phone never hears back
    return ResponseBody.fromString('{"message":"ok"}', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

class _Store implements SubmissionStore {
  List<Submission> items = [];
  @override
  Future<List<Submission>> load() async => List.of(items);
  @override
  Future<void> save(List<Submission> submissions) async => items = List.of(submissions);
}

class _Auth extends AuthNotifier {
  final bool technician;
  _Auth(this.technician);
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'U', 'email': 'u@t.be', 'role': technician ? 'PROFESSIONAL' : 'ADMIN', 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['interventions.view', 'interventions.update', if (!technician) 'interventions.reopen', 'reports.view'],
        }).toEntity(),
      );
}

/// Same shape as the real app: tabs that stay alive, and the task opened above them.
GoRouter _router() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/admin/interventions',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
          body: shell,
          floatingActionButton: FloatingActionButton(onPressed: () => shell.goBranch(1), child: const Text('REPORTS TAB')),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/interventions',
              builder: (context, state) => const InterventionsScreen(isAdmin: true),
              routes: [
                GoRoute(
                  path: 'details/:id',
                  parentNavigatorKey: root,
                  builder: (context, state) => InterventionDetailsScreen(interventionId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen())]),
        ],
      ),
    ],
  );
}

/// Lets the screens work; the test font is wider than a phone's, and pictures cannot load in a test.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    Object? e;
    while ((e = tester.takeException()) != null) {
      expect(e.toString(), anyOf(contains('overflowed'), contains('statusCode: 400')));
    }
  }
}

Future<ProviderContainer> _start(WidgetTester tester, _Backend backend, {bool technician = false, _Store? store}) async {
  tester.view.physicalSize = const Size(1600, 6000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = _Adapter(backend);
  final container = ProviderContainer(overrides: [
    interventionRepositoryProvider.overrideWithValue(_Repo(backend)),
    authStateProvider.overrideWith(() => _Auth(technician)),
    interventionSubmitterProvider.overrideWithValue(InterventionSubmitter(dio, store ?? _Store(), retryDelays: const [Duration.zero])),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: _router(),
      locale: const Locale('en'),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await _settle(tester);
  return container;
}

Finder _ongoingCard(String id) => find.descendant(of: find.byType(InterventionsScreen), matching: find.textContaining(RegExp('Task $id', caseSensitive: false), findRichText: true));

Future<void> _openTask(WidgetTester tester, String id) async {
  await tester.tap(_ongoingCard(id).first);
  await _settle(tester);
  expect(find.byType(InterventionDetailsScreen), findsOneWidget);
}

Future<void> _chooseCompleted(WidgetTester tester) async {
  final button = find.descendant(of: find.byType(InterventionDetailsScreen), matching: find.textContaining(RegExp('^completed\$', caseSensitive: false)));
  await tester.tap(button.first);
  await tester.pump();
}

Future<void> _save(WidgetTester tester, {bool technician = false}) async {
  final l10n = lookupAppLocalizations(const Locale('en'));
  if (technician) {
    await tester.tap(find.byIcon(Icons.send_outlined));
  } else {
    await tester.tap(find.byIcon(Icons.description_outlined).last);
    await _settle(tester);
    await tester.tap(find.text(l10n.saveOnly).last);
  }
  await _settle(tester);
  expect(find.byType(InterventionDetailsScreen), findsNothing, reason: 'the screen closes once the work is safe');
}

Future<void> _expectMoved(WidgetTester tester) async {
  expect(_ongoingCard('1'), findsNothing, reason: 'it must leave Ongoing');
  expect(_ongoingCard('2'), findsWidgets, reason: 'the other task stays');
  await tester.tap(find.text('REPORTS TAB'));
  await _settle(tester);
  expect(find.descendant(of: find.byType(ReportsScreen), matching: find.textContaining(RegExp('Task 1', caseSensitive: false))), findsWidgets, reason: 'it must be in Reports');
  expect(find.descendant(of: find.byType(ReportsScreen), matching: find.textContaining(RegExp('Task 2', caseSensitive: false))), findsNothing);
}

void main() {
  testWidgets('admin, good connection: Completed leaves Ongoing and is in Reports, fetched again from the server', (tester) async {
    final backend = _Backend();
    await _start(tester, backend);
    await _openTask(tester, '1');
    final before = backend.listCalls;
    await _chooseCompleted(tester);
    await _save(tester);
    expect(backend.status['1'], 'COMPLETED');
    expect(backend.listCalls, greaterThan(before), reason: 'the API is asked again for the latest data');
    await _expectMoved(tester);
  });

  testWidgets('technician, good connection: same', (tester) async {
    final backend = _Backend();
    await _start(tester, backend, technician: true);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    await _save(tester, technician: true);
    await _expectMoved(tester);
  });

  testWidgets('weak connection: the server saved it but the phone never got the answer', (tester) async {
    final backend = _Backend();
    await _start(tester, backend);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.net = _Net.answerLost;
    await _save(tester);
    expect(backend.status['1'], 'COMPLETED');
    await _expectMoved(tester);
  });

  testWidgets('no connection: kept on the phone, and the task already moves', (tester) async {
    final backend = _Backend();
    final store = _Store();
    await _start(tester, backend, store: store);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.net = _Net.offline;
    await _save(tester);
    expect(backend.status['1'], 'PENDING', reason: 'the server does not have it yet');
    expect(store.items, hasLength(1));
    await _expectMoved(tester);
  });

  testWidgets('saved offline, connection back: a reload from the server does not bring the task back', (tester) async {
    final backend = _Backend();
    final store = _Store();
    final container = await _start(tester, backend, store: store);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.net = _Net.offline;
    await _save(tester);

    backend.net = _Net.ok; // the server still says PENDING: the phone has not delivered it yet
    container.invalidate(interventionListProvider);
    await _settle(tester);
      await _expectMoved(tester);
  });

  testWidgets('slow server: the task leaves Ongoing at once, not after the list has come back', (tester) async {
    final backend = _Backend();
    await _start(tester, backend);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.slowList = true;
    await _save(tester);
    expect(_ongoingCard('1'), findsNothing);
    await tester.pump(const Duration(seconds: 25)); // nothing left running when the test ends
    expect(_ongoingCard('1'), findsNothing);
  });

  testWidgets('the list cannot be fetched right after the save: no error screen, the task has still moved', (tester) async {
    final backend = _Backend();
    await _start(tester, backend);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.listFails = true;
    await _save(tester);
    await _expectMoved(tester);
  });

  testWidgets('a change from elsewhere arrives without touching the phone, and nothing is replaced by a spinner', (tester) async {
    final backend = _Backend();
    final container = await _start(tester, backend);
    backend.status['2'] = 'COMPLETED'; // a technician finished it on another phone
    container.read(workDataRefresherProvider).lists();
    await tester.pump(); // first frame: no loading state
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await _settle(tester);
    expect(_ongoingCard('2'), findsNothing);
    expect(_ongoingCard('1'), findsWidgets);
  });

  testWidgets('a background refresh does not disturb the task being edited', (tester) async {
    final backend = _Backend();
    final container = await _start(tester, backend);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    container.read(workDataRefresherProvider).lists();
    await tester.pump();
    expect(find.byType(InterventionDetailsScreen), findsOneWidget);
    expect(find.descendant(of: find.byType(InterventionDetailsScreen), matching: find.byType(CircularProgressIndicator)), findsNothing);
    await _settle(tester);
    await _save(tester); // the choice made before the refresh is still what gets saved
    expect(backend.status['1'], 'COMPLETED');
  });

  testWidgets('Reports puts the task finished just now first, even if it was planned long ago', (tester) async {
    final backend = _Backend();
    await _start(tester, backend);
    backend.status['2'] = 'COMPLETED'; // planned later than task 1, finished earlier
    backend.updatedAt['2'] = '2026-03-01T10:00:00Z';
    final container = ProviderScope.containerOf(tester.element(find.byType(InterventionsScreen)));
    container.read(workDataRefresherProvider).lists();
    await _settle(tester);
    await _openTask(tester, '1');
    await _chooseCompleted(tester);
    backend.updatedAt['1'] = '2026-11-08T10:00:00Z';
    await _save(tester);
    await tester.tap(find.text('REPORTS TAB'));
    await _settle(tester);
    final titles = tester.widgetList<Text>(find.descendant(of: find.byType(ReportsScreen), matching: find.textContaining(RegExp('^Task', caseSensitive: false)))).map((t) => t.data).toList();
    expect(titles.first, 'Task 1');
  });

  test('a save made while the outbox is sending is not lost', () async {
    final store = _Store();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = _SavedDuringSend(store);
    final submitter = InterventionSubmitter(dio, store);
    store.items = [_submission('old')];
    expect(await submitter.flush(userId: 1), 1);
    expect(store.items.map((s) => s.id), ['during']);
  });
}

Submission _submission(String id) => Submission(
      id: id, userId: 1, interventionId: '1', fields: const {'status': 'COMPLETED'}, createdAt: DateTime(2026),
    );

class _SavedDuringSend implements HttpClientAdapter {
  final _Store store;
  _SavedDuringSend(this.store);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    store.items = [...store.items, _submission('during')];
    return ResponseBody.fromString('{}', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}
