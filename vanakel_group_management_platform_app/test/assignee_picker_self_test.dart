import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/admin/data/admin_models.dart';
import 'package:vanakel_group_management_platform_app/features/mission/presentation/widgets/assignee_picker.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

void main() {
  const me = AdminUser(id: 1, name: 'Admin', email: 'a@x.com', role: 'ADMIN', roleLabel: 'Admin', status: 'APPROVED');
  const tech = AdminUser(id: 2, name: 'Tech', email: 't@x.com', role: 'PROFESSIONAL', roleLabel: 'Technician', status: 'APPROVED');

  Widget host(int? selected, int? selfId, ValueChanged<int?> onChanged, [Locale locale = const Locale('en')]) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AssigneePicker(users: const [me, tech], selectedId: selected, selfId: selfId, onChanged: onChanged),
        ),
      );

  testWidgets('"Do it myself" picks the admin, shows "Assigned to you", and a second tap clears it', (t) async {
    int? selected;
    late StateSetter set;
    await t.pumpWidget(StatefulBuilder(builder: (c, s) {
      set = s;
      return host(selected, 1, (v) => set(() => selected = v));
    }));
    expect(find.text('DO IT MYSELF'), findsOneWidget);

    await t.tap(find.text('DO IT MYSELF'));
    await t.pump();
    expect(selected, 1);
    expect(find.text('ASSIGNED TO YOU'), findsOneWidget);

    await t.tap(find.text('ASSIGNED TO YOU'));
    await t.pump();
    expect(selected, isNull);
  });

  testWidgets('no shortcut without a self id (technicians)', (t) async {
    await t.pumpWidget(host(null, null, (_) {}));
    expect(find.text('DO IT MYSELF'), findsNothing);
  });

  testWidgets('shortcut text is translated in French and Dutch', (t) async {
    await t.pumpWidget(host(null, 1, (_) {}, const Locale('fr')));
    await t.pumpAndSettle();
    expect(find.text("JE M'EN CHARGE"), findsOneWidget);
    await t.pumpWidget(host(null, 1, (_) {}, const Locale('nl')));
    await t.pumpAndSettle();
    expect(find.text('IK DOE HET ZELF'), findsOneWidget);
  });
}
