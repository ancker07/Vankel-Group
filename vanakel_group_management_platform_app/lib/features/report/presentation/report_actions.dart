import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/translation_helper.dart';
import 'pdf_viewer_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../intervention/domain/intervention.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';

/// What counts as a report (completed or delayed work), the latest work first: a task finished just now is on top,
/// whatever date it was planned for. The Reports page and the dashboard show the same order.
List<Intervention> latestReports(Iterable<Intervention> interventions) => interventions
    .where((i) => i.status == InterventionStatus.completed || i.status == InterventionStatus.delayed)
    .toList()
  ..sort((a, b) => (b.updatedAt ?? b.scheduledDate).compareTo(a.updatedAt ?? a.scheduledDate));

/// Opens the PDF report of an intervention (what the user wants from a report, not the detail screen), inside the
/// app: many Android tablets have no PDF app, so handing it to another app showed nothing there.
Future<void> openInterventionReport(BuildContext context, WidgetRef ref, Intervention item) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final lang = Localizations.localeOf(context).languageCode;
  final title = TranslationHelper.getLocalizedField(
    context: context, enValue: item.titleEn, frValue: item.titleFr, nlValue: item.titleNl, fallback: item.title,
  );
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.pdfGenerating), duration: const Duration(seconds: 2)),
  );

  // The names on the report: the list already on the phone, else one quick request. A list this role may not
  // load, or a weak connection, only leaves a name out: it never stops (or holds up) the report.
  final repository = ref.read(interventionRepositoryProvider);
  Future<List<dynamic>> names(FutureProvider<List<dynamic>> provider, Future<List<dynamic>> Function() request) async {
    final known = ref.read(provider).value;
    if (known != null) return known;
    try {
      return await request().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Report: a list could not be loaded: $e');
      return const [];
    }
  }

  dynamic find(List<dynamic> items, String? id) =>
      id == null ? null : items.firstWhere((x) => x is Map && x['id']?.toString() == id, orElse: () => null);

  try {
    final lists = await Future.wait([
      names(buildingListProvider, repository.getBuildings),
      names(syndicListProvider, repository.getSyndics),
      names(professionalListProvider, repository.getProfessionals),
    ]);

    final bytes = await PdfService.buildInterventionReport(
      intervention: item,
      building: find(lists[0], item.buildingId),
      syndic: find(lists[1], item.syndicId),
      professional: find(lists[2], item.proId),
      lang: lang,
    );
    messenger.hideCurrentSnackBar();
    await PdfViewerScreen.open(navigator, bytes: bytes, fileName: PdfService.fileNameFor(item.id), title: title);
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.pdfError(e.toString())), backgroundColor: Colors.red),
    );
  }
}
