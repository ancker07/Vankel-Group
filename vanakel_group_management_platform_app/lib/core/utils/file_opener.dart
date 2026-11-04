import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/intervention/domain/document.dart';
import '../../l10n/app_localizations.dart';
import '../api/api_constants.dart';

/// Opens an uploaded file (photo, PDF, office document) in the phone's own app / browser.
/// Tells the user when it cannot be opened (it used to do nothing on some phones).
Future<void> openUploadedDocument(BuildContext context, Document document) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.tryParse(ApiConstants.getStorageUrl(document.filePath));

  var opened = false;
  if (uri != null) {
    try {
      // no canLaunchUrl(): it is false on Android 11+ unless every scheme is declared in the manifest
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpen(document.fileName)), backgroundColor: Colors.red));
  }
}
