import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/intervention/domain/intervention.dart';

/// Builds the intervention report PDF on the phone and opens it.
///
/// Fonts: the PDF package's built-in fonts only cover a few Western characters
/// (typographic quotes, € and accented text from emails would come out blank),
/// so Roboto is bundled and embedded.
class PdfService {
  /// Removes characters no font can draw (emoji, zero-width, control chars).
  static String clean(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(' ', ' ')
        .replaceAll(
          RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}​-‍﻿\u0000-\u0008\u000B\u000C\u000E-\u001F]',
              unicode: true),
          '',
        )
        .trim();
  }

  /// The text in the language of the report (the title / description are stored in all three
  /// languages), else the original text.
  static String pick(String lang, {String? en, String? fr, String? nl, required String fallback}) {
    final value = {'en': en, 'fr': fr, 'nl': nl}[lang.toLowerCase()];
    return clean((value == null || value.trim().isEmpty) ? fallback : value);
  }

  static const _delayReasons = {
    'missing_part': {'en': 'Missing part', 'fr': 'Pièce manquante', 'nl': 'Ontbrekend onderdeel'},
    'no_access': {'en': 'No access', 'fr': 'Accès impossible', 'nl': 'Geen toegang'},
    'client_unavailable': {'en': 'Client unavailable', 'fr': 'Client indisponible', 'nl': 'Klant niet beschikbaar'},
    'waiting_validation': {'en': 'Waiting validation', 'fr': 'En attente de validation', 'nl': 'Wacht op goedkeuring'},
    'weather': {'en': 'Bad weather', 'fr': 'Mauvais temps', 'nl': 'Slecht weer'},
    'subcontractor': {'en': 'Subcontractor unavailable', 'fr': 'Sous-traitant indisponible', 'nl': 'Onderaannemer niet beschikbaar'},
    'other': {'en': 'Other', 'fr': 'Autre', 'nl': 'Andere'},
  };

  /// "no_access" -> "Accès impossible" / "Geen toegang" / "No access" (unknown values are kept).
  static String delayReasonLabel(String? reason, String lang) {
    final raw = clean(reason);
    final row = _delayReasons[raw.toLowerCase()];
    return row?[const {'fr': 'fr', 'nl': 'nl'}[lang.toLowerCase()] ?? 'en'] ?? raw;
  }

  static String _field(dynamic map, List<String> keys) {
    if (map is! Map) return '';
    for (final k in keys) {
      final v = clean(map[k]);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// "Intervention_Report_<id>.pdf" with only characters that are safe in a file name.
  static String fileNameFor(String id) {
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'Intervention_Report_${safe.isEmpty ? 'report' : safe}.pdf';
  }

  /// Builds the PDF document bytes (no file or UI access, so it can be tested).
  static Future<Uint8List> buildInterventionReport({
    required Intervention intervention,
    required dynamic building,
    required dynamic professional,
    required dynamic syndic,
    required String lang,
  }) async {
    final labels = _getLabels(lang);

    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    pw.MemoryImage? logo;
    try {
      logo = pw.MemoryImage((await rootBundle.load('assets/images/report_logo.jpeg')).buffer.asUint8List());
    } catch (_) {
      logo = null; // a missing logo must never block the report
    }

    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));

    // numeric pattern: needs no locale data (a named locale throws until intl is initialised)
    final dateFormat = DateFormat('dd/MM/yyyy');
    final syndicName = _field(syndic, ['company_name', 'companyName', 'name']).isNotEmpty
        ? _field(syndic, ['company_name', 'companyName', 'name'])
        : clean(intervention.syndicName ?? intervention.extractedSyndicName);
    final proName = _field(professional, ['company_name', 'companyName', 'name']).isNotEmpty
        ? _field(professional, ['company_name', 'companyName', 'name'])
        : clean(intervention.professionalName);
    final city = _field(building, ['city']).isNotEmpty ? _field(building, ['city']) : clean(intervention.city);
    final contact = [intervention.onSiteContactName, intervention.onSiteContactPhone, intervention.onSiteContactEmail]
        .map(clean)
        .where((e) => e.isNotEmpty)
        .join('  |  ');
    final isDelayed = intervention.status == InterventionStatus.delayed;
    final delayReason = delayReasonLabel(intervention.delayReason, lang);
    final delayDetails = clean(intervention.delayDetails);
    final adminNote = clean(intervention.adminFeedback);
    final title = pick(lang,
        en: intervention.titleEn, fr: intervention.titleFr, nl: intervention.titleNl, fallback: intervention.title);
    final description = pick(lang,
        en: intervention.descriptionEn,
        fr: intervention.descriptionFr,
        nl: intervention.descriptionNl,
        fallback: intervention.description);
    final documents = intervention.documents.map((d) => clean(d.fileName)).where((e) => e.isNotEmpty).toList();

    pw.Widget party(String title, String name, Map? source) {
      final lines = [
        name,
        _field(source, ['contact_person', 'contactPerson']),
        _field(source, ['email']),
        _field(source, ['phone']),
      ].where((e) => e.isNotEmpty).toList();
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionHeader(title),
            pw.SizedBox(height: 4),
            for (final l in lines) pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        maxPages: 200, // long email descriptions: the default of 20 pages would throw
        build: (context) => [
          // 1. Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logo != null ? pw.Image(logo, width: 60) : pw.SizedBox(width: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Vanakel Group (SRL)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Excelsiorlaan 36-38, 1930 Zaventem', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('+32 475 99 99 09 | info@vanakelgroup.be', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('www.vanakelgroup.be', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300, height: 32),

          // 2. Report summary
          pw.Text(labels['reportTitle']!,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
          pw.SizedBox(height: 16),
          pw.Text('${labels['slipId']!}: ${clean(intervention.id)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text('${labels['date']!}: ${dateFormat.format(intervention.scheduledDate)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text('${labels['status']!}: ${_translateStatus(intervention.status, lang)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 28),

          // 3. Intervention details
          _sectionHeader(labels['details']!),
          pw.SizedBox(height: 8),
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Paragraph(text: description, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          pw.SizedBox(height: 16),

          if (adminNote.isNotEmpty) ...[
            _sectionHeader(labels['adminNote']!),
            pw.SizedBox(height: 4),
            pw.Paragraph(text: adminNote, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
          ],

          if (isDelayed && (delayReason.isNotEmpty || delayDetails.isNotEmpty)) ...[
            _sectionHeader(labels['delay']!, color: PdfColors.orange800),
            pw.SizedBox(height: 4),
            if (delayReason.isNotEmpty)
              pw.Text('${labels['delayReason']!}: $delayReason', style: const pw.TextStyle(fontSize: 10)),
            if (delayDetails.isNotEmpty) pw.Paragraph(text: delayDetails, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
          ],

          if (contact.isNotEmpty) ...[
            _sectionHeader(labels['contact']!),
            pw.SizedBox(height: 4),
            pw.Text(contact, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
          ],

          // 4. Location
          _sectionHeader(labels['buildingInfo']!),
          pw.SizedBox(height: 8),
          pw.Text(clean(intervention.address), style: const pw.TextStyle(fontSize: 11)),
          if (city.isNotEmpty) pw.Text(city, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 20),

          // 5. Parties (kept together so the two columns never split over a page)
          if (syndicName.isNotEmpty || proName.isNotEmpty)
            pw.Wrap(children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (syndicName.isNotEmpty) party(labels['syndic']!, syndicName, syndic is Map ? syndic : null),
                  pw.SizedBox(width: 32),
                  if (proName.isNotEmpty) party(labels['professional']!, proName, professional is Map ? professional : null),
                ],
              ),
            ]),

          // 6. Attached documents (names only: files stay separate, like on the website)
          if (documents.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeader(labels['documents']!),
            pw.SizedBox(height: 4),
            for (final d in documents) pw.Text('- $d', style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            '${labels['page']!} ${context.pageNumber} ${labels['of']!} ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Builds the report, saves it in the temporary folder and opens it in the
  /// phone's PDF viewer. Returns the result so the caller can tell the user
  /// when no PDF app is installed (the file is still created).
  static Future<OpenResult> generateInterventionReport({
    required Intervention intervention,
    required dynamic building,
    required dynamic professional,
    required dynamic syndic,
    required String lang,
  }) async {
    final bytes = await buildInterventionReport(
      intervention: intervention,
      building: building,
      professional: professional,
      syndic: syndic,
      lang: lang,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${fileNameFor(intervention.id)}');
    await file.writeAsBytes(bytes, flush: true);

    return OpenFilex.open(file.path, type: 'application/pdf', uti: 'com.adobe.pdf');
  }

  static pw.Widget _sectionHeader(String title, {PdfColor color = PdfColors.grey700}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Container(height: 1, width: 40, color: PdfColors.orange700, margin: const pw.EdgeInsets.only(top: 2)),
      ],
    );
  }

  static Map<String, String> _getLabels(String lang) {
    switch (lang.toLowerCase()) {
      case 'fr':
        return {
          'reportTitle': "RAPPORT D'INTERVENTION",
          'slipId': "ID du bordereau",
          'date': "Date",
          'status': "Statut",
          'details': "Détails de l'intervention",
          'adminNote': "Observations techniques",
          'delay': "Motif du retard",
          'delayReason': "Motif",
          'contact': "Contact sur place",
          'buildingInfo': "Informations sur le bâtiment",
          'syndic': "Syndic",
          'professional': "Professionnel",
          'documents': "Documents joints",
          'page': "Page",
          'of': "sur",
        };
      case 'nl':
        return {
          'reportTitle': "INTERVENTIEVERSLAG",
          'slipId': "Slip ID",
          'date': "Datum",
          'status': "Status",
          'details': "Interventiegegevens",
          'adminNote': "Technische opmerkingen",
          'delay': "Reden van vertraging",
          'delayReason': "Reden",
          'contact': "Contact ter plaatse",
          'buildingInfo': "Gebouwinformatie",
          'syndic': "Syndicus",
          'professional': "Professional",
          'documents': "Bijgevoegde documenten",
          'page': "Pagina",
          'of': "van",
        };
      default:
        return {
          'reportTitle': "INTERVENTION REPORT",
          'slipId': "Slip ID",
          'date': "Date",
          'status': "Status",
          'details': "Intervention Details",
          'adminNote': "Technical Observations",
          'delay': "Reason for delay",
          'delayReason': "Reason",
          'contact': "On-site contact",
          'buildingInfo': "Building Information",
          'syndic': "Syndic",
          'professional': "Professional",
          'documents': "Attached documents",
          'page': "Page",
          'of': "of",
        };
    }
  }

  /// Same words as the app screens (a pending intervention is "In progress" everywhere).
  static String _translateStatus(InterventionStatus status, String lang) {
    const words = {
      InterventionStatus.pending: {'en': 'IN PROGRESS', 'fr': 'EN COURS', 'nl': 'IN UITVOERING'},
      InterventionStatus.delayed: {'en': 'DELAYED', 'fr': 'RETARDÉ', 'nl': 'VERTRAAGD'},
      InterventionStatus.completed: {'en': 'COMPLETED', 'fr': 'TERMINÉ', 'nl': 'VOLTOOID'},
    };
    final code = const {'fr': 'fr', 'nl': 'nl'}[lang.toLowerCase()] ?? 'en';
    return words[status]![code]!;
  }
}
