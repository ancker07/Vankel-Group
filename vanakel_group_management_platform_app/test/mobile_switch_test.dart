import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanakel_group_management_platform_app/core/api/dio_client.dart';
import 'package:vanakel_group_management_platform_app/core/providers/mobile_access_provider.dart';
import 'package:vanakel_group_management_platform_app/core/router/mobile_access.dart';
import 'package:vanakel_group_management_platform_app/core/services/auth_token_service.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/mobile_disabled_screen.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

/// A fake server: answers every request from [answer] and remembers the headers it received.
class _FakeServer implements HttpClientAdapter {
  final ({int status, Map<String, dynamic> body}) Function(RequestOptions) answer;
  final List<Map<String, dynamic>> seenHeaders = [];
  _FakeServer(this.answer);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    seenHeaders.add(Map<String, dynamic>.from(options.headers));
    final r = answer(options);
    return ResponseBody.fromString(jsonEncode(r.body), r.status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> _container(_FakeServer server) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  container.read(dioProvider).httpClientAdapter = server;
  return container;
}

void main() {
  test('every phone request says it comes from the phone app', () async {
    final server = _FakeServer((_) => (status: 200, body: {'ok': true}));
    final container = await _container(server);

    await container.read(dioProvider).get('/me');

    expect(server.seenHeaders.single['X-App'], 'mobile');
  });

  test('a "mobile switched off" answer turns the app off, an ordinary 503 does not', () async {
    var code = 'SOMETHING_ELSE';
    final server = _FakeServer((_) => (status: 503, body: {'success': false, 'code': code, 'message': 'x'}));
    final container = await _container(server);

    await expectLater(container.read(dioProvider).get('/me'), throwsA(isA<DioException>()));
    expect(container.read(mobileAccessProvider).disabled, isFalse);

    code = 'MOBILE_DISABLED';
    await expectLater(container.read(dioProvider).get('/me'), throwsA(isA<DioException>()));
    expect(container.read(mobileAccessProvider).disabled, isTrue);
  });

  test('re-checking brings the app back only when the server says it is on', () async {
    var on = false;
    final server = _FakeServer((_) => (status: 200, body: {'mobile_enabled': on}));
    final container = await _container(server);
    container.read(mobileAccessProvider.notifier).disable();

    expect(await container.read(mobileAccessProvider.notifier).recheck(), isFalse);
    expect(container.read(mobileAccessProvider).disabled, isTrue);

    on = true;
    expect(await container.read(mobileAccessProvider.notifier).recheck(), isTrue);
    expect(container.read(mobileAccessProvider).disabled, isFalse);
  });

  test('while the app is off every route leads to the switched-off screen, and back out when it is on', () {
    for (final path in ['/splash', '/login', '/admin/dashboard', '/admin/interventions/details/3', '/notifications']) {
      expect(mobileDisabledRedirect(path, true), mobileDisabledPath, reason: path);
      expect(mobileDisabledRedirect(path, false), isNull, reason: path);
    }
    expect(mobileDisabledRedirect(mobileDisabledPath, true), isNull);
    expect(mobileDisabledRedirect(mobileDisabledPath, false), '/splash');
  });

  testWidgets('the switched-off screen explains it, retries, and says when it is still off', (tester) async {
    final server = _FakeServer((_) => (status: 200, body: {'mobile_enabled': false}));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    container.read(dioProvider).httpClientAdapter = server;
    container.read(mobileAccessProvider.notifier).disable();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MobileDisabledScreen(),
      ),
    ));

    expect(find.text('Application mobile désactivée'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Toujours désactivée'), findsOneWidget);
    expect(container.read(mobileAccessProvider).disabled, isTrue);
  });
}
