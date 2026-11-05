import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission_repository.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/missions_screen.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/providers/mission_provider.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

class _Repo implements MissionRepository {
  @override
  Future<List<Mission>> getMissions() async => [
        MissionModel.fromJson({'id': 1, 'title': 'Leak in hall', 'description': 'd', 'status': 'PENDING'}).toEntity(),
        MissionModel.fromJson({'id': 2, 'title': 'Already done', 'description': 'd', 'status': 'APPROVED'}).toEntity(),
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Admin extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        isSplashDone: true,
        user: UserModel.fromJson({
          'id': 1, 'name': 'Admin', 'email': 'a@t.be', 'role': 'ADMIN', 'portal': 'admin', 'status': 'APPROVED',
          'permissions': ['missions.view', 'missions.approve', 'missions.create', 'missions.update'],
        }).toEntity(),
      );
}

void main() {
  testWidgets('the real Missions screen: an admin sees the pending mission with Approve & assign / Reject', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        missionRepositoryProvider.overrideWithValue(_Repo()),
        authStateProvider.overrideWith(_Admin.new),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MissionsScreen(isAdmin: true)),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Leak in hall'), findsOneWidget);
    expect(find.text('Already done'), findsNothing, reason: 'converted missions are not in the default list');
    expect(find.text('APPROVE & ASSIGN'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
  });
}
