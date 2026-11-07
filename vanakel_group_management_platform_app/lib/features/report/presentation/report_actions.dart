import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/services/pdf_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../intervention/domain/intervention.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';

/// What counts as a report (completed or delayed work), the latest work first: a task finished just now is on top,
/// whatever date it was planned for. The Reports page and the dashboard show the same order.
List<Intervention> latestReports(Iterable<Intervention> interventions) => interventions
    .where((i) => i.status == InterventionStatus.completed || i.status == InterventionStatus.delayed)
    .toList()
  ..sort((a, b) => (b.updatedAt ?? b.scheduledDate).compareTo(a.updatedAt ?? a.scheduledDate));

/// Opens the PDF report of an intervention (what the user wants from a report, not the detail screen).
Future<void> openInterventionReport(BuildContext context, WidgetRef ref, Intervention item) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.pdfGenerating), duration: const Duration(seconds: 2)),
  );

  try {
    // Fetch data reliably using .future
    final buildings = await ref.read(buildingListProvider.future);
    final syndics = await ref.read(syndicListProvider.future);
    final professionals = await ref.read(professionalListProvider.future);

    final building = buildings.firstWhere(
      (b) => b['id']?.toString() == item.buildingId,
      orElse: () => null,
    );
    final syndic = syndics.firstWhere(
      (s) => s['id']?.toString() == item.syndicId,
      orElse: () => null,
    );
    final pro = professionals.firstWhere(
      (p) => p['id']?.toString() == item.proId,
      orElse: () => null,
    );

    final result = await PdfService.generateInterventionReport(
      intervention: item,
      building: building,
      professional: pro,
      syndic: syndic,
      lang: lang,
    );
    messenger.hideCurrentSnackBar();
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pdfNoViewer)));
    }
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.pdfError(e.toString())), backgroundColor: Colors.red),
    );
  }
}
