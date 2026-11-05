import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/error/exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_models.dart';

/// One repository for the admin features the website has and the mobile app
/// was missing. Every endpoint is permission-protected on the server, so the
/// app only decides what to show, never what is allowed.
class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---- Emails -----------------------------------------------------------
  Future<List<AdminEmail>> emails() => _run(() async {
        final r = await _dio.get('/emails');
        return _list(r.data['emails']).map(AdminEmail.fromJson).toList();
      });

  Future<AdminEmail> email(int id) => _run(() async {
        final r = await _dio.get('/emails/$id');
        return AdminEmail.fromJson(Map<String, dynamic>.from(r.data));
      });

  /// Fetches new mail from the server and processes it (can take a while).
  Future<void> syncEmails() => _run(() => _dio.post('/emails/sync',
      options: Options(receiveTimeout: const Duration(minutes: 5))));

  Future<void> ingestAll() => _run(() => _dio.post('/emails/ingest-all',
      options: Options(receiveTimeout: const Duration(minutes: 5))));

  Future<String> ingestEmail(int id) => _run(() async {
        final r = await _dio.post('/emails/$id/ingest');
        return r.data['status']?.toString() ?? 'OK';
      });

  Future<void> deleteEmail(int id) => _run(() => _dio.delete('/emails/$id'));

  Future<void> replyToEmail(int id, {required String body, required String account}) =>
      _run(() => _dio.post('/emails/$id/reply',
          data: FormData.fromMap({'body': body, 'account': account})));

  // ---- Contacts ---------------------------------------------------------
  Future<List<AdminContact>> contacts() => _run(() async {
        final r = await _dio.get('/contacts');
        return _list(r.data).map(AdminContact.fromJson).toList();
      });

  Future<void> deleteContact(int id) => _run(() => _dio.delete('/contacts/$id'));

  // ---- Team -------------------------------------------------------------
  Future<List<TeamMember>> team() => _run(() async {
        final r = await _dio.get('/team');
        return _list(r.data).map(TeamMember.fromJson).toList();
      });

  // ---- Users & roles ----------------------------------------------------
  Future<List<AdminUser>> users() => _run(() async {
        final r = await _dio.get('/users/all');
        return _list(r.data).map(AdminUser.fromJson).toList();
      });

  Future<List<AdminRole>> roles() => _run(() async {
        final r = await _dio.get('/roles');
        return _list(r.data).map(AdminRole.fromJson).toList();
      });

  Future<void> createUser({
    required String firstName,
    String lastName = '',
    String email = '',
    String username = '',
    required String password,
    required String role,
    String? phone,
    String? companyName,
  }) =>
      _run(() => _dio.post('/users', data: {
            'firstName': firstName,
            if (lastName.isNotEmpty) 'lastName': lastName,
            // technicians sign in with a username (no e-mail needed); everyone else with an e-mail
            if (username.isNotEmpty) 'username': username,
            if (email.isNotEmpty) 'email': email,
            'password': password,
            'role': role,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
          }));

  Future<void> approveUser(int id) => _run(() => _dio.post('/users/$id/approve'));
  Future<void> rejectUser(int id) => _run(() => _dio.post('/users/$id/reject'));
  Future<void> changeRole(int id, String role) =>
      _run(() => _dio.put('/users/$id/role', data: {'role': role}));
  Future<void> resetPassword(int id, String password) =>
      _run(() => _dio.post('/users/$id/reset-password', data: {'password': password}));
  Future<void> deleteUser(int id) => _run(() => _dio.delete('/users/$id'));

  // ---- System -----------------------------------------------------------
  Future<SystemStats> stats() => _run(() async {
        final r = await _dio.get('/superadmin/stats');
        return SystemStats.fromJson(Map<String, dynamic>.from(r.data));
      });

  Future<void> broadcast({
    required String title,
    required String body,
    required bool important,
    List<int>? userIds,
  }) =>
      _run(() => _dio.post('/superadmin/send-notification', data: {
            'title': title,
            'body': body,
            'target': userIds == null ? 'all' : 'specific',
            if (userIds != null) 'user_ids': userIds,
            'important': important,
          }));

  Future<List<BroadcastLog>> broadcastHistory() => _run(() async {
        final r = await _dio.get('/superadmin/notifications/history');
        return _list(r.data).map(BroadcastLog.fromJson).toList();
      });

  Future<AiSettings> aiSettings() => _run(() async {
        final r = await _dio.get('/settings/ai');
        return AiSettings.fromJson(Map<String, dynamic>.from(r.data));
      });

  Future<void> saveAiSettings({required String model, required String apiKey}) =>
      _run(() => _dio.post('/settings/ai', data: {'model': model, 'apiKey': apiKey}));

  // ---- Mission duplicate review ----------------------------------------
  Future<void> dismissDuplicate(String missionId) =>
      _run(() => _dio.post('/missions/$missionId/duplicate/dismiss'));
  Future<void> mergeDuplicate(String missionId) =>
      _run(() => _dio.post('/missions/$missionId/duplicate/merge'));
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(dioProvider)));

final emailsProvider = FutureProvider.autoDispose<List<AdminEmail>>(
    (ref) => ref.watch(adminRepositoryProvider).emails());
final emailDetailProvider = FutureProvider.autoDispose.family<AdminEmail, int>(
    (ref, id) => ref.watch(adminRepositoryProvider).email(id));
final contactsProvider = FutureProvider.autoDispose<List<AdminContact>>(
    (ref) => ref.watch(adminRepositoryProvider).contacts());
final teamProvider = FutureProvider.autoDispose<List<TeamMember>>(
    (ref) => ref.watch(adminRepositoryProvider).team());
final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>(
    (ref) => ref.watch(adminRepositoryProvider).users());
final adminRolesProvider = FutureProvider.autoDispose<List<AdminRole>>(
    (ref) => ref.watch(adminRepositoryProvider).roles());
final systemStatsProvider = FutureProvider.autoDispose<SystemStats>(
    (ref) => ref.watch(adminRepositoryProvider).stats());
final broadcastHistoryProvider = FutureProvider.autoDispose<List<BroadcastLog>>(
    (ref) => ref.watch(adminRepositoryProvider).broadcastHistory());
final aiSettingsProvider = FutureProvider.autoDispose<AiSettings>(
    (ref) => ref.watch(adminRepositoryProvider).aiSettings());
