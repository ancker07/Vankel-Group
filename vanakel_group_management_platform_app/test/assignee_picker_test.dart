import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/admin/data/admin_models.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/widgets/assignee_picker.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

AdminUser _user(int id, String name, String role) => AdminUser(
      id: id,
      name: name,
      email: '${name.toLowerCase()}@technician.vankel',
      role: role,
      roleLabel: role == 'PROFESSIONAL' ? 'Technician' : 'Admin',
      status: 'APPROVED',
    );

Widget _app(Locale locale, List<AdminUser> users, int? selected, ValueChanged<int?> onChanged) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AssigneePicker(users: users, selectedId: selected, onChanged: onChanged)),
    );

void main() {
  testWidgets('the approve dialog shows the "link to user" drop-down and lets the admin pick a technician', (tester) async {
    int? picked;
    await tester.pumpWidget(_app(const Locale('en'), [_user(7, 'Jean', 'PROFESSIONAL')], null, (v) => picked = v));

    expect(find.text('Link to user (optional)'), findsOneWidget);
    expect(find.text('— No user —'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Jean').last);
    await tester.pumpAndSettle();

    expect(picked, 7);
  });

  testWidgets('the drop-down stays visible even when the list is empty, and follows the language', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr'), const [], null, (_) {}));
    expect(find.text('Lier à un utilisateur (optionnel)'), findsOneWidget);
    expect(find.text('— Aucun utilisateur —'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('nl'), const [], null, (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Koppelen aan gebruiker (optioneel)'), findsOneWidget);
  });

  testWidgets('the chosen person is shown under the drop-down', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), [_user(7, 'Jean', 'PROFESSIONAL')], 7, (_) {}));
    expect(find.textContaining('@jean'), findsOneWidget);
  });
}
