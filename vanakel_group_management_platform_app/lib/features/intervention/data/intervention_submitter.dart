import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/dio_client.dart';
import '../domain/intervention_repository.dart';

/// A file that goes with a submission, kept as a path so the submission can be saved on the phone and sent later.
class SubmissionFile {
  final String field; // 'photos[]' or 'files[]'
  final String path;
  final String filename;
  const SubmissionFile({required this.field, required this.path, required this.filename});

  Map<String, dynamic> toJson() => {'field': field, 'path': path, 'filename': filename};
  factory SubmissionFile.fromJson(Map<String, dynamic> json) => SubmissionFile(
        field: json['field'] as String,
        path: json['path'] as String,
        filename: json['filename'] as String,
      );
}

/// Everything needed to save an intervention update (status, notes, delay, photos, documents), as plain data.
class Submission {
  final String id; // sent with every attempt: the server answers a repeat of a finished save with "done"
  final int? userId; // whose work it is; only that user's phone session sends it later
  final String interventionId;
  final Map<String, String> fields;
  final List<SubmissionFile> files;
  final DateTime createdAt;
  final int attempts;

  const Submission({
    required this.id,
    required this.userId,
    required this.interventionId,
    required this.fields,
    this.files = const [],
    required this.createdAt,
    this.attempts = 0,
  });

  Submission withAttempt() => Submission(
        id: id,
        userId: userId,
        interventionId: interventionId,
        fields: fields,
        files: files,
        createdAt: createdAt,
        attempts: attempts + 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'interventionId': interventionId,
        'fields': fields,
        'files': files.map((f) => f.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        id: json['id'] as String,
        userId: json['userId'] as int?,
        interventionId: json['interventionId'] as String,
        fields: Map<String, String>.from(json['fields'] as Map),
        files: (json['files'] as List).map((f) => SubmissionFile.fromJson(Map<String, dynamic>.from(f as Map))).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: (json['attempts'] as int?) ?? 0,
      );
}

enum SubmitOutcome {
  /// The server has it.
  sent,

  /// The server has the status and notes, but refused the attachments (too big / not allowed).
  sentWithoutFiles,

  /// No connection or the server is busy: saved on the phone, it is sent automatically later.
  queued,

  /// The server answered that this cannot be done (e.g. not assigned to this user): trying again will not help.
  rejected,
}

class SubmitResult {
  final SubmitOutcome outcome;
  final RegisterResult register;
  final int skippedFiles;
  final List<String> warnings; // things the server could not do after saving (notifications, a bad file)
  final String? message; // the server's own text, for [SubmitOutcome.rejected]
  final int? statusCode;

  const SubmitResult(
    this.outcome, {
    this.register = const RegisterResult(),
    this.skippedFiles = 0,
    this.warnings = const [],
    this.message,
    this.statusCode,
  });

  /// The work is safe: on the server, or saved on the phone and waiting to be sent.
  bool get isSafe => outcome != SubmitOutcome.rejected;
}

/// Where the submissions waiting to be sent are kept.
abstract class SubmissionStore {
  Future<List<Submission>> load();
  Future<void> save(List<Submission> submissions);
}

class PrefsSubmissionStore implements SubmissionStore {
  static const _key = 'intervention_outbox_v1';

  @override
  Future<List<Submission>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List).map((e) => Submission.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return []; // a damaged outbox must never break saving
    }
  }

  @override
  Future<void> save(List<Submission> submissions) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(submissions.map((s) => s.toJson()).toList()));
    } catch (e) {
      debugPrint('Outbox could not be saved: $e');
    }
  }
}

/// Saves an intervention update so that the technician's "complete / send to admin" does not end in an error:
///
///  1. the send is retried (network errors, timeouts, server hiccups),
///  2. if the server refuses the attachments (too big, not allowed) the status and notes are sent without them,
///  3. if there is still no connection or the server keeps failing, the work is kept on the phone and sent
///     automatically later (see [flush]),
///  4. every attempt carries the same submission id, so a repeat of a save that already went through is harmless.
///
/// Only an answer that means "this can never work" (not assigned to you, session over, a real validation
/// problem) is reported back as [SubmitOutcome.rejected], with the server's own message.
class InterventionSubmitter {
  final Dio _dio;
  final SubmissionStore _store;
  final List<Duration> _retryDelays;
  bool _flushing = false;

  InterventionSubmitter(
    this._dio,
    this._store, {
    List<Duration> retryDelays = const [Duration.zero, Duration(seconds: 2), Duration(seconds: 5)],
  }) : _retryDelays = retryDelays;

  static String newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';

  Future<SubmitResult> submit(Submission submission, {bool queueIfOffline = true}) async {
    try {
      return await _submit(submission, queueIfOffline);
    } catch (e) {
      // whatever else goes wrong (e.g. a damaged file path): the work must not be lost
      debugPrint('Submission fell back to the outbox: $e');
      if (queueIfOffline) {
        await _enqueue(submission);
        return const SubmitResult(SubmitOutcome.queued);
      }
      return const SubmitResult(SubmitOutcome.rejected);
    }
  }

  Future<SubmitResult> _submit(Submission submission, bool queueIfOffline) async {
    try {
      final response = await _sendWithRetries(submission, withFiles: true);
      return SubmitResult(SubmitOutcome.sent, register: response.register, warnings: response.warnings);
    } on DioException catch (first) {
      final status = first.response?.statusCode;

      // The attachments are the usual reason for "too large" (413) / "not valid" (422): send the work without them.
      if ((status == 413 || status == 422) && submission.files.isNotEmpty) {
        try {
          final response = await _sendWithRetries(submission, withFiles: false);
          return SubmitResult(
            SubmitOutcome.sentWithoutFiles,
            register: response.register,
            warnings: response.warnings,
            skippedFiles: submission.files.length,
          );
        } on DioException catch (second) {
          return _failure(second, submission, queueIfOffline);
        }
      }
      return _failure(first, submission, queueIfOffline);
    }
  }

  Future<SubmitResult> _failure(DioException e, Submission submission, bool queueIfOffline) async {
    if (_retryable(e)) {
      if (queueIfOffline) {
        await _enqueue(submission);
        return const SubmitResult(SubmitOutcome.queued);
      }
      return SubmitResult(SubmitOutcome.rejected, statusCode: e.response?.statusCode);
    }
    return SubmitResult(SubmitOutcome.rejected, message: _serverMessage(e), statusCode: e.response?.statusCode);
  }

  /// No answer at all (offline, timeout) or the server itself is in trouble: worth trying again later.
  bool _retryable(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return true;
    return status >= 500 || status == 408 || status == 429;
  }

  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String && message.trim().isNotEmpty ? message : null;
  }

  Future<_Answer> _sendWithRetries(Submission submission, {required bool withFiles}) async {
    for (var attempt = 0; attempt < _retryDelays.length; attempt++) {
      if (_retryDelays[attempt] > Duration.zero) await Future.delayed(_retryDelays[attempt]);
      try {
        return await _post(submission, withFiles: withFiles);
      } on DioException catch (e) {
        if (!_retryable(e) || attempt == _retryDelays.length - 1) rethrow;
      }
    }
    throw StateError('unreachable');
  }

  Future<_Answer> _post(Submission submission, {required bool withFiles}) async {
    final form = FormData();
    form.fields
      ..add(const MapEntry('_method', 'PUT'))
      ..add(MapEntry('submission_id', submission.id))
      ..addAll(submission.fields.entries.map((e) => MapEntry(e.key, e.value)));

    if (withFiles) {
      for (final file in submission.files) {
        if (!await File(file.path).exists()) continue; // the phone cleaned it up: send the rest
        form.files.add(MapEntry(file.field, await MultipartFile.fromFile(file.path, filename: file.filename)));
      }
    }

    final response = await _dio.post(
      '/interventions/${submission.interventionId}',
      data: form,
      options: Options(sendTimeout: const Duration(minutes: 2), receiveTimeout: const Duration(minutes: 1)),
    );
    return _Answer.from(response.data);
  }

  // ---- the outbox ------------------------------------------------------------------------------------------

  Future<void> _enqueue(Submission submission) async {
    final list = await _store.load();
    list.removeWhere((s) => s.id == submission.id);
    list.add(submission);
    if (list.length > 50) list.removeRange(0, list.length - 50);
    await _store.save(list);
  }

  Future<int> pendingCount({int? userId}) async =>
      (await _store.load()).where((s) => userId == null || s.userId == userId).length;

  /// Sends what is waiting on the phone for [userId]. Called when the app starts, comes back to the screen and
  /// every minute. Returns how many were delivered.
  Future<int> flush({required int userId}) async {
    if (_flushing) return 0;
    _flushing = true;
    var delivered = 0;
    try {
      final all = await _store.load();
      final keep = <Submission>[];
      var stop = false;

      for (final submission in all) {
        if (stop || submission.userId != userId) {
          keep.add(submission); // someone else's, or the session is not usable right now
          continue;
        }
        switch (await _flushOne(submission)) {
          case _Flush.done:
            delivered++;
          case _Flush.keep:
            if (DateTime.now().difference(submission.createdAt) < const Duration(days: 7)) keep.add(submission.withAttempt());
          case _Flush.drop:
            break;
          case _Flush.stop:
            stop = true;
            keep.add(submission);
        }
      }
      await _store.save(keep);
    } catch (e) {
      debugPrint('Outbox flush failed: $e');
    } finally {
      _flushing = false;
    }
    return delivered;
  }

  Future<_Flush> _flushOne(Submission submission) async {
    try {
      await _post(submission, withFiles: true);
      return _Flush.done;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) return _Flush.stop; // signed out: keep everything until the user is back
      if ((status == 413 || status == 422) && submission.files.isNotEmpty) {
        try {
          await _post(submission, withFiles: false);
          return _Flush.done;
        } on DioException catch (second) {
          return _retryable(second) ? _Flush.keep : _Flush.drop;
        }
      }
      return _retryable(e) ? _Flush.keep : _Flush.drop; // 403 / 404 / 422: it can never work, do not keep trying
    } catch (_) {
      return _Flush.keep;
    }
  }
}

enum _Flush { done, keep, drop, stop }

class _Answer {
  final RegisterResult register;
  final List<String> warnings;
  const _Answer(this.register, this.warnings);

  /// Reads the server's answer without ever failing: a save that went through is a success whatever the body looks like.
  factory _Answer.from(dynamic body) {
    try {
      if (body is Map) {
        final report = body['report'] is Map ? ReportOutcome.fromJson(Map<String, dynamic>.from(body['report'] as Map)) : null;
        final warnings = (body['warnings'] is List) ? (body['warnings'] as List).map((e) => e.toString()).toList() : <String>[];
        return _Answer(RegisterResult(report: report), warnings);
      }
    } catch (_) {}
    return const _Answer(RegisterResult(), []);
  }
}

final interventionSubmitterProvider = Provider<InterventionSubmitter>((ref) {
  return InterventionSubmitter(ref.watch(dioProvider), PrefsSubmissionStore());
});
