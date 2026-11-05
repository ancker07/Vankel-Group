import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanakel_group_management_platform_app/core/error/exceptions.dart';
import 'package:vanakel_group_management_platform_app/core/services/auth_token_service.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/repositories/auth_repository_impl.dart';

class _Server implements HttpClientAdapter {
  final ({int status, Map<String, dynamic> body}) Function(RequestOptions) answer;
  final List<RequestOptions> requests = [];
  _Server(this.answer);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final r = answer(options);
    return ResponseBody.fromString(jsonEncode(r.body), r.status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<(AuthRepositoryImpl, AuthTokenService, _Server)> _setup(({int status, Map<String, dynamic> body}) Function(RequestOptions) answer) async {
  SharedPreferences.setMockInitialValues({});
  final tokens = AuthTokenService(await SharedPreferences.getInstance());
  final server = _Server(answer);
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api'))..httpClientAdapter = server;
  return (AuthRepositoryImpl(dio, tokens), tokens, server);
}

void main() {
  test('a technician logs in with a username, and the app remembers the account e-mail, not the username', () async {
    final (repo, tokens, server) = await _setup((o) => (
          status: 200,
          body: {
            'success': true,
            'token': 'abc',
            'user': {
              'id': 5,
              'name': 'Jean',
              'email': 'jean@technician.vankel',
              'role': 'PROFESSIONAL',
              'portal': 'admin',
              'status': 'APPROVED',
              'permissions': ['interventions.view'],
            },
          },
        ));

    final user = await repo.login('jean', 'password123', 'PROFESSIONAL');

    expect(server.requests.first.data['username'], 'jean'); // what was typed goes to the login request ...
    expect(tokens.getEmail(), 'jean@technician.vankel'); // ... but the stored account e-mail is the real one
    expect(user.email, 'jean@technician.vankel');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('only a 401 ends the saved session; a validation error (422) does not sign the user out', () async {
    var status = 401;
    final (repo, _, __) = await _setup((o) => (status: status, body: {'message': 'x'}));

    expect(await repo.checkStatus('jean'), isNull); // really unauthenticated

    status = 422;
    await expectLater(repo.checkStatus('jean'), throwsA(isA<AppExceptions>()));
  });
}
