import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/intervention_submitter.dart';

class _MemoryStore implements SubmissionStore {
  List<Submission> items = [];
  @override
  Future<List<Submission>> load() async => List.of(items);
  @override
  Future<void> save(List<Submission> submissions) async => items = List.of(submissions);
}

/// One scripted answer per request; an answer is a status code, or a connection error.
class _Server implements HttpClientAdapter {
  final List<Object> script; // int status | 'offline'
  final List<Map<String, dynamic>> bodies;
  final List<RequestOptions> seen = [];
  int _next = 0;
  _Server(this.script, {this.bodies = const []});

  FormData get lastForm => seen.last.data as FormData;
  Map<String, String> fieldsOf(int i) => {for (final f in (seen[i].data as FormData).fields) f.key: f.value};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    seen.add(options);
    final answer = script[_next < script.length ? _next : script.length - 1];
    final body = _next < bodies.length ? bodies[_next] : <String, dynamic>{'message': 'ok'};
    _next++;
    if (answer == 'offline') {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError, error: const SocketException('no network'));
    }
    return ResponseBody.fromString(jsonEncode(body), answer as int, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<(InterventionSubmitter, _Server, _MemoryStore, Submission)> _setup(
  List<Object> script, {
  List<Map<String, dynamic>> bodies = const [],
  bool withFile = false,
}) async {
  final server = _Server(script, bodies: bodies);
  final store = _MemoryStore();
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api'))..httpClientAdapter = server;
  final submitter = InterventionSubmitter(dio, store, retryDelays: const [Duration.zero, Duration.zero, Duration.zero]);

  var files = <SubmissionFile>[];
  if (withFile) {
    final f = File('${Directory.systemTemp.path}/photo_${DateTime.now().microsecondsSinceEpoch}.jpg')..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => f.existsSync() ? f.deleteSync() : null);
    files = [SubmissionFile(field: 'photos[]', path: f.path, filename: 'photo.jpg')];
  }
  final submission = Submission(
    id: 'sub-1',
    userId: 7,
    interventionId: '19',
    fields: {'status': 'COMPLETED', 'save_mode': 'SUBMIT', 'admin_feedback': 'done'},
    files: files,
    createdAt: DateTime.now(),
  );
  return (submitter, server, store, submission);
}

void main() {
  test('1. a normal send just works', () async {
    final (submitter, server, store, submission) = await _setup([200]);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.sent);
    expect(server.seen.length, 1);
    expect(store.items, isEmpty);
    expect(server.fieldsOf(0)['_method'], 'PUT');
    expect(server.fieldsOf(0)['status'], 'COMPLETED');
  });

  test('2. a server hiccup or a lost connection is retried, with the same submission id every time', () async {
    final (submitter, server, _, submission) = await _setup([500, 'offline', 200]);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.sent);
    expect(server.seen.length, 3);
    expect({for (var i = 0; i < 3; i++) server.fieldsOf(i)['submission_id']}, {'sub-1'});
  });

  test('3. attachments the server refuses (too large / not allowed): the work is sent without them', () async {
    final (submitter, server, store, submission) = await _setup([413, 200], withFile: true);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.sentWithoutFiles);
    expect(result.skippedFiles, 1);
    expect(server.seen.first.data.files.length, 1);
    expect(server.seen.last.data.files, isEmpty);
    expect(store.items, isEmpty);
  });

  test('4. no connection at all: the work is kept on the phone, not lost and not an error', () async {
    final (submitter, server, store, submission) = await _setup(['offline'], withFile: true);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.queued);
    expect(result.isSafe, isTrue);
    expect(server.seen.length, 3); // it did try
    expect(store.items.single.id, 'sub-1');
    expect(store.items.single.files.length, 1, reason: 'the photos wait with it');
  });

  test('5. what is waiting on the phone is delivered once the connection is back', () async {
    final (submitter, server, store, submission) = await _setup(['offline']);
    await submitter.submit(submission);
    expect(await submitter.pendingCount(userId: 7), 1);

    // still offline: stays, nothing is lost
    expect(await submitter.flush(userId: 7), 0);
    expect(store.items.length, 1);

    // back online
    final online = InterventionSubmitter(
      Dio(BaseOptions(baseUrl: 'http://test/api'))..httpClientAdapter = _Server([200]),
      store,
      retryDelays: const [Duration.zero],
    );
    expect(await online.flush(userId: 7), 1);
    expect(store.items, isEmpty);
    expect(server.seen.isNotEmpty, isTrue);
  });

  test('6. a waiting submission is only sent by the user it belongs to', () async {
    final (submitter, _, store, submission) = await _setup(['offline']);
    await submitter.submit(submission);

    final online = InterventionSubmitter(
      Dio(BaseOptions(baseUrl: 'http://test/api'))..httpClientAdapter = _Server([200]),
      store,
      retryDelays: const [Duration.zero],
    );
    expect(await online.flush(userId: 99), 0);
    expect(store.items.length, 1, reason: 'kept for its owner');
    expect(await online.flush(userId: 7), 1);
  });

  test('7. "not assigned to you" can never work: reported with the server\'s message, not queued', () async {
    final (submitter, _, store, submission) = await _setup([403], bodies: [
      {'success': false, 'message': 'This intervention is not assigned to you.'},
    ]);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.rejected);
    expect(result.message, 'This intervention is not assigned to you.');
    expect(result.statusCode, 403);
    expect(store.items, isEmpty);
  });

  test('8. a real validation problem without attachments is reported, not retried forever', () async {
    final (submitter, server, store, submission) = await _setup([422], bodies: [
      {'message': 'Select the reason for the delay before sending to the admin.'},
    ]);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.rejected);
    expect(result.message, contains('reason for the delay'));
    expect(server.seen.length, 1);
    expect(store.items, isEmpty);
  });

  test('9. the server\'s warnings and an odd answer body never turn a save into a failure', () async {
    final (submitter, _, _, submission) = await _setup([200], bodies: [
      {'message': 'ok', 'warnings': ['notification to the admins'], 'report': 'not-a-map'},
    ]);
    final result = await submitter.submit(submission);

    expect(result.outcome, SubmitOutcome.sent);
    expect(result.warnings, ['notification to the admins']);
  });

  test('10. a missing photo file (cleaned up by the phone) does not stop the rest from being sent', () async {
    final (submitter, server, _, submission) = await _setup([200], withFile: true);
    File(submission.files.first.path).deleteSync();

    final result = await submitter.submit(submission);
    expect(result.outcome, SubmitOutcome.sent);
    expect(server.lastForm.files, isEmpty);
  });

  test('11. e-mail reports are not queued (the report must go out now): a lost connection is reported', () async {
    final (submitter, _, store, submission) = await _setup(['offline']);
    final result = await submitter.submit(submission, queueIfOffline: false);

    expect(result.outcome, SubmitOutcome.rejected);
    expect(store.items, isEmpty);
  });

  test('12. a damaged outbox entry round-trips through JSON', () {
    final s = Submission(
      id: 'x', userId: 1, interventionId: '5', fields: {'a': 'b'},
      files: const [SubmissionFile(field: 'files[]', path: '/tmp/a.pdf', filename: 'a.pdf')],
      createdAt: DateTime(2026, 11, 5), attempts: 2,
    );
    final back = Submission.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect((back.id, back.userId, back.fields['a'], back.files.single.filename, back.attempts), ('x', 1, 'b', 'a.pdf', 2));
  });
}
