import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

/// Opens [uri] in another app (browser, dialer, mail, maps...). Returns false if nothing could open it.
///
/// Do NOT use canLaunchUrl() to decide: on Android 11+ it is false unless every scheme is listed in
/// the manifest, which made buttons do nothing. Just try, and tell the user when it fails.
Future<bool> launchExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Opens a link / phone number / e-mail address, with a visible message if it cannot be opened.
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context)!.couldNotOpenLink;
  if (!await launchExternal(uri)) {
    messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}
