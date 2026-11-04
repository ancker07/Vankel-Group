import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, AdminContact c) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await adminConfirm(context,
        title: l10n.admDelete, message: l10n.admDeleteConfirm, confirmLabel: l10n.admDelete, destructive: true);
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminRepositoryProvider).deleteContact(c.id);
      ref.invalidate(contactsProvider);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contacts = ref.watch(contactsProvider);
    final canManage = canDo(ref, 'contacts.manage');

    return PermissionGate(
      anyOf: const ['contacts.view'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admContacts.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        body: contacts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(contactsProvider)),
          data: (list) => RefreshIndicator(
            onRefresh: () async => ref.refresh(contactsProvider.future),
            child: list.isEmpty
                ? const AdminEmptyView(icon: Icons.chat_bubble_outline)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return AdminCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                            if (canManage)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _delete(context, ref, c),
                              ),
                          ]),
                          Text(c.email, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                          if (c.subject != null) ...[
                            const SizedBox(height: 6),
                            Text(c.subject!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                          const SizedBox(height: 6),
                          Text(c.message),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text(fmtDateTime(context, c.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppTheme.zinc500)),
                            if (c.missionId != null)
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.assignment_outlined, size: 14),
                                label: Text('#${c.missionId}', style: const TextStyle(fontSize: 11)),
                                onPressed: () => context.push('/admin/missions/details/${c.missionId}'),
                              ),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
