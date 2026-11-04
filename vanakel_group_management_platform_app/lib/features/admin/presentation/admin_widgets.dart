import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';

/// Shows [child] only if the logged-in user's role has [permission]
/// (any of [anyOf]). The server enforces the same permission on every call.
class PermissionGate extends ConsumerWidget {
  final List<String> anyOf;
  final Widget child;
  const PermissionGate({super.key, required this.anyOf, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final allowed = user != null && anyOf.any(user.can);
    if (allowed) return child;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 48, color: AppTheme.zinc500),
            const SizedBox(height: 12),
            Text(l10n.admForbidden, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

/// True when the current user can do [permission] (used to show / hide buttons).
bool canDo(WidgetRef ref, String permission) =>
    ref.watch(authStateProvider).user?.can(permission) ?? false;

void adminSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : AppTheme.zinc800,
    ));
}

Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.zinc900,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: Colors.red.shade400) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Error state with a retry button.
class AdminErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const AdminErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppTheme.zinc500),
          const SizedBox(height: 12),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ]),
      ),
    );
  }
}

class AdminEmptyView extends StatelessWidget {
  final IconData icon;
  const AdminEmptyView({super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(children: [
      const SizedBox(height: 120),
      Icon(icon, size: 48, color: AppTheme.zinc500),
      const SizedBox(height: 12),
      Center(child: Text(l10n.admNothingHere, style: const TextStyle(color: AppTheme.zinc400))),
    ]);
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AdminCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.zinc900,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
      );
}

/// Date + time in the app's current language.
String fmtDateTime(BuildContext context, DateTime? d) {
  if (d == null) return '';
  return DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm().format(d);
}
