import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/data/models/intervention_model.dart';
import 'package:vanakel_group_management_platform_app/features/mission/data/models/mission_model.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';
import 'package:vanakel_group_management_platform_app/shared/widgets/admin_badge.dart';

void main() {
  Widget host(bool show, Locale l) => MaterialApp(
        locale: l,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AdminBadge(show: show)),
      );

  testWidgets('badge shows only when assigned to an admin, in the selected language', (t) async {
    await t.pumpWidget(host(false, const Locale('en')));
    expect(find.text('ADMIN TASK'), findsNothing);

    for (final e in {'en': 'ADMIN TASK', 'fr': 'TÂCHE ADMIN', 'nl': 'ADMIN-TAAK'}.entries) {
      await t.pumpWidget(host(true, Locale(e.key)));
      await t.pumpAndSettle();
      expect(find.text(e.value), findsOneWidget, reason: e.key);
    }
  });

  test('models read assigned_to_admin from the API (default false)', () {
    final base = {'id': 1, 'title': 'T', 'description': 'D', 'status': 'PENDING', 'urgency': 'LOW'};
    expect(InterventionModel.fromJson({...base, 'assigned_to_admin': true}).assignedToAdmin, isTrue);
    expect(InterventionModel.fromJson(base).assignedToAdmin, isFalse);
    expect(MissionModel.fromJson({...base, 'assigned_to_admin': true}).assignedToAdmin, isTrue);
    expect(MissionModel.fromJson(base).assignedToAdmin, isFalse);
  });
}
