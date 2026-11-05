import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/data/admin_models.dart';
import '../../../admin/data/admin_repository.dart';

/// The people a mission can be assigned to when it is approved: approved technicians and admins
/// (the same list the website offers). Empty when the list cannot be loaded.
Future<List<AdminUser>> loadAssignableUsers(WidgetRef ref) async {
  try {
    final users = await ref.read(adminUsersProvider.future);
    return users
        .where((u) => (u.role == 'PROFESSIONAL' || u.role == 'ADMIN') && u.status == 'APPROVED')
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

  const AssigneePicker({
    super.key,
    required this.users,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (users.isEmpty) return const SizedBox.shrink();

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
      ],
    );
  }
}
