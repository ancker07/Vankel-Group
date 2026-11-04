import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

class TranslationHelper {
  /// Returns the localized field value based on the current locale
  /// [context] The BuildContext to resolve the current locale
  /// [enValue] The English translation field
  /// [frValue] The French translation field
  /// [nlValue] The Dutch translation field
  /// [fallback] The default field (usually French or original value)
  static String getLocalizedField({
    required BuildContext context,
    String? enValue,
    String? frValue,
    String? nlValue,
    required String fallback,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;

    String pick() {
      switch (languageCode) {
        case 'en':
          return enValue?.isNotEmpty == true ? enValue! : fallback;
        case 'nl':
          return nlValue?.isNotEmpty == true ? nlValue! : fallback;
        case 'fr':
        default:
          // By default or for French, try getting the French-specific value,
          // if not available, return the base field (which is usually French).
          return frValue?.isNotEmpty == true ? frValue! : fallback;
      }
    }

    final text = pick();
    // "No Title" is the placeholder the data models used for a missing title
    return (text.trim().isEmpty || text == 'No Title') ? AppLocalizations.of(context)!.noTitle : text;
  }

  /// An address for display; "No address" in the user's language when it is missing.
  /// ("No Address" is the old English placeholder the data models used to store.)
  static String address(BuildContext context, String? address) {
    final value = address?.trim() ?? '';
    return (value.isEmpty || value == 'No Address') ? AppLocalizations.of(context)!.noAddress : value;
  }
}
