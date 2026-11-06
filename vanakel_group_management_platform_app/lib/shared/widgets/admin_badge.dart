import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Blue badge shown on every task / intervention that is assigned to an admin
/// (the admin does it themselves). Shows nothing when [show] is false.
class AdminBadge extends StatelessWidget {
  final bool show;
  const AdminBadge({super.key, required this.show});

  static const Color blue = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final label = AppLocalizations.of(context)!.adminTask.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: blue.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 11, color: blue),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: blue, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
