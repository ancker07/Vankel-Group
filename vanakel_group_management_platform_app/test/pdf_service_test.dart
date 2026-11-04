import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/services/pdf_service.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/document.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';

int _pages(List<int> bytes) => RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes, allowInvalid: true)).length;

Intervention _intervention({String description = 'Court', InterventionStatus status = InterventionStatus.pending}) => Intervention(
      id: 'INT-1/2026',
      title: 'Panne ascenseur – bloc A',
      description: description,
      status: status,
      scheduledDate: DateTime(2026, 11, 4),
      address: 'Rue de la Loi 67, 1000 Bruxelles',
      adminFeedback: 'Câbles à vérifier é à ç',
      delayReason: 'NO_ACCESS',
      delayDetails: 'Locataire absent',
      onSiteContactName: 'Jean Dupont',
      onSiteContactPhone: '+32 470 00 00 00',
      documents: const [Document(id: '1', fileName: 'plan.pdf', filePath: 'documents/plan.pdf', fileType: 'application/pdf')],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a valid one-page PDF', () async {
    final bytes = await PdfService.buildInterventionReport(
      intervention: _intervention(),
      building: {'city': 'Bruxelles'},
      professional: {'company_name': 'Pro SRL', 'email': 'm@p.be'},
      syndic: {'company_name': 'Syndic SA', 'email': 'a@s.be'},
      lang: 'fr',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(_pages(bytes), 1);
  });

  test('a very long email description continues over many pages (no TooManyPages error)', () async {
    final long = List.generate(
      900,
      (i) => 'Ligne $i : l’ascenseur “bloc A” est en panne – coût 1 200 € 🙂 ${'texte ' * 20}',
    ).join('\n');
    final bytes = await PdfService.buildInterventionReport(
      intervention: _intervention(description: long, status: InterventionStatus.delayed),
      building: null,
      professional: null,
      syndic: null,
      lang: 'nl',
    );
    expect(_pages(bytes), greaterThan(20));
  });

  test('missing building / syndic / professional data never throws', () async {
    final bytes = await PdfService.buildInterventionReport(
      intervention: _intervention(),
      building: null,
      professional: {'company_name': null},
      syndic: 'not a map',
      lang: 'en',
    );
    expect(_pages(bytes), 1);
  });

  test('clean() strips emoji and zero-width characters but keeps accents and quotes', () {
    expect(PdfService.clean('Café 🙂 d’été​ “ok”'), 'Café  d’été “ok”');
    expect(PdfService.clean(null), '');
  });

  test('file name is safe for any intervention id', () {
    expect(PdfService.fileNameFor('INT-1/2026'), 'Intervention_Report_INT-1_2026.pdf');
    expect(PdfService.fileNameFor('../../x'), 'Intervention_Report__x.pdf');
    expect(PdfService.fileNameFor(''), 'Intervention_Report_report.pdf');
  });

  test('title, description and delay reason follow the selected language', () {
    expect(PdfService.pick('nl', en: 'Roof leak', fr: 'Fuite toiture', nl: 'Dakkanaal lek', fallback: 'orig'), 'Dakkanaal lek');
    expect(PdfService.pick('fr', en: 'Roof leak', fr: 'Fuite toiture', nl: 'Dakkanaal lek', fallback: 'orig'), 'Fuite toiture');
    expect(PdfService.pick('en', en: 'Roof leak', fr: 'Fuite toiture', nl: 'Dakkanaal lek', fallback: 'orig'), 'Roof leak');
    // a missing / blank translation falls back to the original text
    expect(PdfService.pick('nl', en: 'Roof leak', nl: '  ', fallback: 'Fuite d’origine'), 'Fuite d’origine');
    expect(PdfService.pick('de', fallback: 'orig'), 'orig');

    expect(PdfService.delayReasonLabel('no_access', 'fr'), 'Accès impossible');
    expect(PdfService.delayReasonLabel('NO_ACCESS', 'nl'), 'Geen toegang');
    expect(PdfService.delayReasonLabel('weather', 'en'), 'Bad weather');
    expect(PdfService.delayReasonLabel('something custom', 'fr'), 'something custom');
    expect(PdfService.delayReasonLabel(null, 'fr'), '');
  });
}
