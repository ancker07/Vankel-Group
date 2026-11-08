import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Shows a PDF inside the app. Many Android tablets (and some phones) have no PDF app installed, so handing the
/// file to "another app" opened nothing there. This uses Android's own PDF renderer (built into every Android
/// version the app supports, 9 to 16) and needs no permission. Share / print / "open with" stay available.
class PdfViewerScreen extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final String title;

  const PdfViewerScreen({super.key, required this.bytes, required this.fileName, required this.title});

  static Future<void> open(NavigatorState navigator, {required Uint8List bytes, required String fileName, required String title}) {
    return navigator.push(MaterialPageRoute(
      builder: (_) => PdfViewerScreen(bytes: bytes, fileName: fileName, title: title),
    ));
  }

  Future<void> _share(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      debugPrint('PDF share failed: $e');
      if (context.mounted) await _openWith(context);
    }
  }

  Future<void> _print() async {
    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    } catch (e) {
      debugPrint('PDF print failed: $e');
    }
  }

  /// The file in the app's own cache folder, handed to a PDF app if the user has one (no storage permission).
  Future<void> _openWith(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path, type: 'application/pdf', uti: 'com.adobe.pdf');
      if (result.type != ResultType.done) messenger.showSnackBar(SnackBar(content: Text(l10n.pdfNoViewer)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pdfNoViewer)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: l10n.pdfShare, icon: const Icon(Icons.share_outlined), onPressed: () => _share(context)),
          IconButton(tooltip: l10n.pdfPrint, icon: const Icon(Icons.print_outlined), onPressed: _print),
          IconButton(tooltip: l10n.pdfOpenWith, icon: const Icon(Icons.open_in_new), onPressed: () => _openWith(context)),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: fileName,
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        loadingWidget: const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
        // the renderer could not show it on this device: the other ways still work
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.pdfCannotDisplay, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.zinc500)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(onPressed: () => _share(context), icon: const Icon(Icons.share_outlined), label: Text(l10n.pdfShare)),
                    OutlinedButton.icon(onPressed: () => _openWith(context), icon: const Icon(Icons.open_in_new), label: Text(l10n.pdfOpenWith)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
