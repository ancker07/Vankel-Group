import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Blue badge shown on every task / intervention that is assigned to an admin
/// (the admin does it themselves). Shows nothing when [show] is false.
/// [large] is a full-width banner, used inside cards and details (never on top of a map).
class AdminBadge extends StatelessWidget {
  final bool show;
  final bool large;
  const AdminBadge({super.key, required this.show, this.large = false});

  static const Color blue = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final label = AppLocalizations.of(context)!.adminTask.toUpperCase();
    final content = Row(
      mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, size: large ? 20 : 14, color: Colors.white),
        SizedBox(width: large ? 8 : 5),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: large ? 13 : 10,
                fontWeight: FontWeight.w900,
                letterSpacing: large ? 1.4 : 0.9)),
      ],
    );
    return Container(
      width: large ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 9, vertical: large ? 11 : 4),
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        boxShadow: large ? [BoxShadow(color: blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))] : null,
      ),
      child: content,
    );
  }
}
