import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/widgets/mission_action_bar.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

Widget _app(Locale locale, Widget bar) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: const SizedBox.expand(), bottomNavigationBar: bar),
    );

final _admin = UserModel.fromJson({
  'id': 1, 'name': 'A', 'email': 'a@t.be', 'role': 'ADMIN', 'portal': 'admin', 'status': 'APPROVED',
  'permissions': ['missions.view', 'missions.approve'],
}).toEntity();
final _technician = UserModel.fromJson({
  'id': 2, 'name': 'T', 'email': 't@t.be', 'role': 'PROFESSIONAL', 'portal': 'admin', 'status': 'APPROVED',
  'permissions': ['interventions.view'],
}).toEntity();

mission(String status) => MissionModel.fromJson({'id': 1, 'title': 'Leak', 'description': 'd', 'status': status, 'requested_by': 'SYNDIC'}).toEntity();

void main() {
  testWidgets('the approve & assign and reject buttons are pinned and work (English)', (tester) async {
    var approved = 0;
    var rejected = 0;
    await tester.pumpWidget(_app(const Locale('en'), MissionActionBar(onApprove: () => approved++, onReject: () => rejected++)));

    expect(find.text('APPROVE & ASSIGN'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approve-mission')));
    await tester.tap(find.byKey(const Key('reject-mission')));
    expect((approved, rejected), (1, 1));
  });

  testWidgets('the buttons follow the language', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr'), MissionActionBar(onApprove: () {}, onReject: () {})));
    expect(find.text('APPROUVER ET ASSIGNER'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('nl'), MissionActionBar(onApprove: () {}, onReject: () {})));
    await tester.pumpAndSettle();
    expect(find.text('GOEDKEUREN EN TOEWIJZEN'), findsOneWidget);
  });

  test('only an admin with the approve permission sees the buttons, and only for a mission waiting for a decision', () {
    expect(canReviewMission(_admin, mission('PENDING')), isTrue);
    expect(canReviewMission(_admin, mission('NEEDS_REVIEW')), isTrue);
    expect(canReviewMission(_admin, mission('APPROVED')), isFalse);
    expect(canReviewMission(_admin, mission('REJECTED')), isFalse);
    expect(canReviewMission(_technician, mission('PENDING')), isFalse);
    expect(canReviewMission(null, mission('PENDING')), isFalse);
  });
}
