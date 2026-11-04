import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

/// Dates and relative times in the language the user selected in the app.
///
/// Never use `DateFormat('MMM d, y')` (or manual `${d.day}/${d.month}`) in a screen: without a
/// locale, intl falls back to English month names and US ordering.
class AppFormat {
  AppFormat._();

  static String _code(BuildContext context) => Localizations.localeOf(context).languageCode;

  /// Runs [build] with the selected language; if the date data of that language is not loaded
  /// (it is loaded at startup, see main.dart) it falls back to a neutral numeric format.
  static String _safe(BuildContext context, DateFormat Function(String locale) build, DateTime date) {
    try {
      return build(_code(context)).format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  /// 04/11/2026 — the numeric form used in lists (the same order in French, Dutch and English).
  static String date(BuildContext context, DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  /// 4 Nov 2026 / 4 nov. 2026 / 4 nov 2026
  static String dateMedium(BuildContext context, DateTime date) =>
      _safe(context, (l) => DateFormat.yMMMd(l), date);

  /// Wednesday 4 November 2026 / mercredi 4 novembre 2026 / woensdag 4 november 2026
  static String dateLong(BuildContext context, DateTime date) =>
      _safe(context, (l) => DateFormat.yMMMMEEEEd(l), date);

  /// 4 Nov 2026, 14:30 (24-hour clock in every language)
  static String dateTime(BuildContext context, DateTime date) =>
      _safe(context, (l) => DateFormat.yMMMd(l).add_Hm(), date);

  /// "5 min ago" / "il y a 5 min" / "5 min geleden"; older than a week: the date.
  static String timeAgo(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return diff.inSeconds < 5 ? l10n.timeNow : l10n.agoSeconds(diff.inSeconds);
    if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
    if (diff.inDays < 7) return l10n.agoDays(diff.inDays);
    return date(context, time);
  }
}
