import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../features/intervention/domain/intervention.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateInterventionReport({
    required Intervention intervention,
    required dynamic building,
    required dynamic professional,
    required dynamic syndic,
    required String lang,
  }) async {
    final pdf = pw.Document();
    
    // Localization Mapping
    final labels = _getLabels(lang);
    
    // Load Logo
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/report_logo.jpeg')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // 1. Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logoImage, width: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Vanakel Group (SRL)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Excelsiorlaan 36-38, 1930 Zaventem", style: const pw.TextStyle(fontSize: 9)),
                  pw.Text("+32 475 99 99 09 | info@vanakelgroup.be", style: const pw.TextStyle(fontSize: 9)),
                  pw.Text("www.vanakelgroup.be", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300, height: 32),

          // 2. Report Summary
          pw.Text(labels['reportTitle']!, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("${labels['slipId']!}: ${intervention.id}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text("${labels['date']!}: ${DateFormat('dd/MM/yyyy').format(intervention.scheduledDate)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text("${labels['status']!}: ${_translateStatus(intervention.status, lang)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // 3. Intervention Details
          _buildSectionHeader(labels['details']!),
          pw.SizedBox(height: 8),
          pw.Text(intervention.title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(intervention.description, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          pw.SizedBox(height: 24),

          // 4. Location
          _buildSectionHeader(labels['buildingInfo']!),
          pw.SizedBox(height: 8),
          pw.Text(intervention.address, style: const pw.TextStyle(fontSize: 11)),

          pw.SizedBox(height: 32),

          // 5. Parties
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (syndic != null)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(labels['syndic']!),
                      pw.SizedBox(height: 4),
                      pw.Text(syndic['company_name'] ?? 'N/A', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(syndic['email'] ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              pw.SizedBox(width: 32),
              if (professional != null)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(labels['professional']!),
                      pw.SizedBox(height: 4),
                      pw.Text(professional['company_name'] ?? 'N/A', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(professional['email'] ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 32),
          child: pw.Text(
            '${labels['page']!} ${context.pageNumber} ${labels['of']!} ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    // Save and Open
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Intervention_Report_${intervention.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    
    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
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
          'buildingInfo': "Informations sur le bâtiment",
          'syndic': "Syndic",
          'professional': "Professionnel",
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
          'buildingInfo': "Gebouwinformatie",
          'syndic': "Syndicus",
          'professional': "Professional",
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
          'buildingInfo': "Building Information",
          'syndic': "Syndic",
          'professional': "Professional",
          'page': "Page",
          'of': "of",
        };
    }
  }

  static String _translateStatus(InterventionStatus status, String lang) {
    final name = status.name.toLowerCase();
    switch (lang.toLowerCase()) {
      case 'fr':
        if (name == 'completed') return 'TERMINÉ';
        if (name == 'delayed') return 'RETARDÉ';
        if (name == 'in_progress') return 'EN COURS';
        if (name == 'pending') return 'EN ATTENTE';
        return status.name.toUpperCase();
      case 'nl':
        if (name == 'completed') return 'VOLTOOID';
        if (name == 'delayed') return 'VERTRAAGD';
        if (name == 'in_progress') return 'IN UITVOERING';
        if (name == 'pending') return 'IN AFWACHTING';
        return status.name.toUpperCase();
      default:
        return status.name.toUpperCase();
    }
  }
}
