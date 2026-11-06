import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/data/admin_models.dart';
import '../../../admin/data/admin_repository.dart';

/// The people a mission can be assigned to when it is approved: approved technicians and admins
/// (the same list the website offers). Falls back to the team list if the users list is not available.
Future<List<AdminUser>> loadAssignableUsers(WidgetRef ref) async {
  bool assignable(String role, String status) =>
      (role == 'PROFESSIONAL' || role == 'ADMIN' || role == 'SUPERADMIN') && status == 'APPROVED';

  try {
    final users = await ref.read(adminRepositoryProvider).users();
    final list = users.where((u) => assignable(u.role, u.status)).toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

  try {
    final team = await ref.read(adminRepositoryProvider).team();
    return team
        .where((m) => assignable(m.role, m.status))
        .map((m) => AdminUser(
              id: m.id,
              name: m.name,
              email: m.email,
              phone: m.phone,
              role: m.role,
              roleLabel: m.role,
              status: m.status,
            ))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// "Assign to" drop-down used in the approve dialogs. [selectedId] null = nobody.
class AssigneePicker extends StatelessWidget {
  final List<AdminUser> users;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  /// The logged-in admin: shows a "Do it myself" shortcut that picks them.
  final int? selfId;

  const AssigneePicker({
    super.key,
    required this.users,
    required this.selectedId,
    required this.onChanged,
    this.selfId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = users.where((u) => u.id == selectedId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.assignToUser,
          style: const TextStyle(
            color: AppTheme.zinc500,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.zinc900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.zinc800),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: selectedId,
              isExpanded: true,
              dropdownColor: AppTheme.zinc900,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.zinc500),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.assignNone, style: const TextStyle(color: AppTheme.zinc500)),
                ),
                for (final u in users)
                  DropdownMenuItem<int?>(
                    value: u.id,
                    child: Text(
                      '${u.name} · ${l10n.roleLabelFor(u.role, u.roleLabel)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        if (selfId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(selectedId == selfId ? Icons.check_circle : Icons.person_pin_circle_outlined, size: 18),
                label: Text((selectedId == selfId ? l10n.assignedToYou : l10n.doItMyself).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: selectedId == selfId ? Colors.black : AppTheme.brandGreen,
                  backgroundColor: selectedId == selfId ? AppTheme.brandGreen : Colors.transparent,
                  side: const BorderSide(color: AppTheme.brandGreen),
                ),
                onPressed: () => onChanged(selectedId == selfId ? null : selfId),
              ),
            ),
          ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '${selected.name} · ${selected.loginLabel}',
              style: const TextStyle(color: AppTheme.zinc500, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
