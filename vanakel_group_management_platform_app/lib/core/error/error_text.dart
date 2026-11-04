import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'exceptions.dart';

/// Text for an error, in the user's language. Use this for every SnackBar / error view instead
/// of `'Error: $e'` (which printed the raw English exception text).
///
/// Messages the server wrote itself (validation errors, "invalid credentials"...) are already
/// in the user's language: the app sends Accept-Language with every request.
String errorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;

  if (error is NetworkException) return error.message == 'Connection timeout' ? l10n.errTimeout : l10n.errNoInternet;
  if (error is UnauthorizedException) return l10n.errUnauthorized;
  if (error is NotFoundException) return l10n.errNotFound;
  if (error is ServerException) return l10n.errServer;
  if (error is ValidationException) return _serverMessage(error) ?? l10n.errValidation;
  if (error is AppExceptions) return _serverMessage(error) ?? l10n.errUnknown;
  return l10n.errUnknown;
}

/// Same as [errorText] but with the "Error: ..." prefix, for places that show a title-less message.
String errorWithMessage(BuildContext context, Object error) =>
    AppLocalizations.of(context)!.errorWithMessage(errorText(context, error));

String? _serverMessage(AppExceptions error) {
  final message = error.message.trim();
  const generic = {'Server Error', 'Validation Error', 'Something went wrong', 'Unknown error occurred', ''};
  return generic.contains(message) ? null : message;
}
