import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/providers/refresh_work_data.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/intervention_submitter.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention_repository.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_filter_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_list_provider.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/providers/intervention_provider.dart';

/// After "Register" / "Save" with Completed or Delayed, the task leaves Ongoing at once and never comes back,
/// whatever else is loading at that moment.

/// The server: a status per intervention. Each GET answers what the server had when the request arrived, after
/// [delay] (a slow network), so an answer can be out of date by the time it lands.
class _Server implements InterventionRepository {
  final Map<int, String> status = {1: 'PENDING', 2: 'PENDING'};
  Duration delay = Duration.zero;
  Completer<void>? holdNext; // when set, the next GET only answers once it completes (a request still on its way)

  @override
  Future<List<Intervention>> getInterventions() async {
    final snapshot = Map.of(status);
    final hold = holdNext;
    holdNext = null;
    if (hold != null) await hold.future;
    await Future.delayed(delay);
    return [
      for (final e in snapshot.entries)
        InterventionModel.fromJson({'id': e.key, 'title': 'T${e.key}', 'description': 'd', 'status': e.value, 'urgency': 'LOW'})
            .toEntity(),
    ];
  }

  @override
  Future<Intervention> getInterventionById(String id) async => (await getInterventions()).firstWhere((i) => i.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MemoryStore implements SubmissionStore {
  List<Submission> items = [];
  @override
  Future<List<Submission>> load() async => List.of(items);
  @override
  Future<void> save(List<Submission> submissions) async => items = List.of(submissions);
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 7, 'name': 'Tech', 'email': 't@t.be', 'role': 'PROFESSIONAL', 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['interventions.view', 'interventions.update'],
        }).toEntity(),
      );
}

/// The server answers every save with "saved".
class _OkAdapter implements HttpClientAdapter {
  int posts = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    posts++;
    await requestStream?.drain<void>();
    return ResponseBody.fromString(jsonEncode({'message': 'ok', 'intervention': null}), 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

late _Server server;
late _MemoryStore outbox;

ProviderContainer _app() {
  server = _Server();
  outbox = _MemoryStore();
  final c = ProviderContainer(overrides: [
    interventionRepositoryProvider.overrideWithValue(server),
    interventionSubmitterProvider.overrideWithValue(InterventionSubmitter(Dio(), outbox)),
    authStateProvider.overrideWith(_Auth.new),
  ]);
  // the Ongoing screen and the open detail screen are on screen
  c.listen(filteredInterventionListProvider, (_, _) {});
  c.listen(interventionDetailProvider('1'), (_, _) {});
  return c;
}

Set<String> _ongoing(ProviderContainer c) => c.read(filteredInterventionListProvider).value!.map((i) => i.id).toSet();

/// What the detail screen does after the server said "saved".
void _saved(ProviderContainer c, String status) {
  server.status[1] = status;
  c.read(interventionListProvider.notifier).markSaved('1', {'status': status, 'save_mode': 'NONE'});
  c.read(workDataRefresherProvider).afterChange();
}

Future<void> _settle() => Future.delayed(const Duration(milliseconds: 200));

void main() {
  for (final status in ['COMPLETED', 'DELAYED']) {
    group(status, () {
      test('leaves Ongoing right away and stays out after the refresh', () async {
        final c = _app();
        addTearDown(c.dispose);
        await c.read(interventionListProvider.future);
        expect(_ongoing(c), {'1', '2'});

        _saved(c, status);
        expect(_ongoing(c), {'2'}, reason: 'at once, before the server answers');
        await _settle();
        expect(_ongoing(c), {'2'});
      });

      test('a full reload that was already on its way (stale) does not bring it back', () async {
        final c = _app();
        addTearDown(c.dispose);
        await c.read(interventionListProvider.future);

        final stale = Completer<void>();
        server.holdNext = stale;
        c.invalidate(interventionListProvider); // e.g. the refresh button / an approved mission, just before
        c.read(filteredInterventionListProvider); // the request leaves with the old data
        await Future.delayed(Duration.zero);

        _saved(c, status);
        await _settle(); // the fresh answer is in
        expect(_ongoing(c), {'2'});
        stale.complete(); // ...and only then the old answer lands
        await _settle();
        expect(_ongoing(c), {'2'});
      });

      test('a quiet refresh that was already on its way (stale) does not bring it back', () async {
        final c = _app();
        addTearDown(c.dispose);
        await c.read(interventionListProvider.future);

        final stale = Completer<void>();
        server.holdNext = stale;
        unawaited(c.read(interventionListProvider.notifier).refreshQuietly()); // the 1-minute sync / a notification
        await Future.delayed(Duration.zero);

        _saved(c, status);
        await _settle();
        stale.complete();
        await _settle();
        expect(_ongoing(c), {'2'});
      });

      test('an older save still waiting on the phone does not put it back to in progress', () async {
        final c = _app();
        addTearDown(c.dispose);
        // earlier, offline: the technician saved a note with "In progress"
        outbox.items = [
          Submission(
            id: 'old', userId: 7, interventionId: '1',
            fields: const {'status': 'PENDING', 'admin_feedback': 'on my way', 'save_mode': 'NONE'},
            files: const [], createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];
        await c.read(interventionListProvider.future);
        expect(_ongoing(c), {'1', '2'});

        // now, online: Completed / Delayed is sent and saved by the server
        await c.read(interventionSubmitterProvider).supersede(interventionId: '1', userId: 7);
        _saved(c, status);
        await _settle();
        expect(_ongoing(c), {'2'});
        expect(outbox.items, isEmpty, reason: 'the old save must not be sent later and undo this one');
      });
    });
  }

  test('a reopened task (Completed -> In progress by an admin elsewhere) comes back on the next refresh', () async {
    final c = _app();
    addTearDown(c.dispose);
    await c.read(interventionListProvider.future);
    _saved(c, 'COMPLETED');
    await _settle();
    expect(_ongoing(c), {'2'});

    server.status[1] = 'PENDING';
    c.read(workDataRefresherProvider).lists();
    await _settle();
    expect(_ongoing(c), {'1', '2'});
  });

  test('a save that reaches the server clears the older ones waiting on the phone (their photos are kept)', () async {
    final store = _MemoryStore();
    final old = DateTime.now().subtract(const Duration(hours: 1));
    store.items = [
      Submission(id: 'a', userId: 7, interventionId: '1', fields: const {'status': 'PENDING'}, createdAt: old),
      Submission(
        id: 'b', userId: 7, interventionId: '1', fields: const {'status': 'PENDING', 'admin_feedback': 'x'},
        files: const [SubmissionFile(field: 'photos[]', path: '/nope.jpg', filename: 'p.jpg')], createdAt: old,
      ),
      Submission(id: 'c', userId: 7, interventionId: '2', fields: const {'status': 'PENDING'}, createdAt: old),
    ];
    final dio = Dio()..httpClientAdapter = _OkAdapter();
    final submitter = InterventionSubmitter(dio, store, retryDelays: const [Duration.zero]);

    final result = await submitter.submit(Submission(
      id: 'new', userId: 7, interventionId: '1', fields: const {'status': 'COMPLETED', 'save_mode': 'NONE'},
      createdAt: DateTime.now(),
    ));

    expect(result.outcome, SubmitOutcome.sent);
    expect(store.items.map((s) => s.id), ['b', 'c'], reason: 'the other intervention is untouched');
    final b = store.items.first;
    expect(b.fields, {'save_mode': 'NONE'}, reason: 'no old status left to send');
    expect(b.files, hasLength(1));
  });
}
