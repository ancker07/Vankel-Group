import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/presentation/widgets/intervention_delay_sheet.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

void main() {
  testWidgets('the delay sheet does not overflow when little height is left (keyboard open, small phone)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          // the same squeeze as in the error report: about 378 px of height for the whole sheet
          child: SizedBox(width: 360, height: 378, child: InterventionDelaySheet()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // a RenderFlex overflow would be reported here
    // the whole form is still reachable by scrolling
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
