import '../../../core/utils/app_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

class PushNotificationsScreen extends ConsumerWidget {
  const PushNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate(
      anyOf: const ['notifications.broadcast'],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.admPush.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
            bottom: TabBar(tabs: [Tab(text: l10n.admSendNotification), Tab(text: l10n.admHistory)]),
          ),
          body: const TabBarView(children: [_ComposeTab(), _HistoryTab()]),
        ),
      ),
    );
  }
}

class _ComposeTab extends ConsumerStatefulWidget {
  const _ComposeTab();

  @override
  ConsumerState<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends ConsumerState<_ComposeTab> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _allUsers = true;
  bool _important = false;
  bool _busy = false;
  final Set<int> _selected = {};

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    if (!_allUsers && _selected.isEmpty) {
      adminSnack(context, l10n.admSelectUsers, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).broadcast(
            title: _title.text.trim(),
            body: _body.text.trim(),
            important: _important,
            userIds: _allUsers ? null : _selected.toList(),
          );
      ref.invalidate(broadcastHistoryProvider);
      _title.clear();
      _body.clear();
      if (mounted) {
        setState(() {
          _selected.clear();
          _important = false;
        });
      }
      adminSnack(context, l10n.admNotificationSent);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l10n.admRequired : null;
    // Recipients can only be listed by users who may view users
    final canPickUsers = canDo(ref, 'users.view');

    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _title, decoration: InputDecoration(labelText: l10n.admBroadcastTitle), validator: required),
        const SizedBox(height: 12),
        TextFormField(
          controller: _body,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: l10n.admBroadcastBody),
          validator: required,
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.admTargetAll)),
            if (canPickUsers) ButtonSegment(value: false, label: Text(l10n.admTargetSpecific)),
          ],
          selected: {_allUsers},
          onSelectionChanged: (s) => setState(() => _allUsers = s.first),
        ),
        if (!_allUsers) _UserPicker(selected: _selected, onChanged: () => setState(() {})),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.admImportant),
          value: _important,
          onChanged: (v) => setState(() => _important = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _send,
          icon: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(l10n.admSendNotification),
        ),
      ]),
    );
  }
}

class _UserPicker extends ConsumerWidget {
  final Set<int> selected;
  final VoidCallback onChanged;
  const _UserPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(adminUsersProvider);
    return users.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      error: (e, _) => Padding(padding: const EdgeInsets.all(8), child: Text(e.toString())),
      data: (list) {
        final approved = list.where((u) => u.status == 'APPROVED').toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(l10n.admSelectedCount(selected.length), style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
          ),
          for (final u in approved)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(u.name),
              subtitle: Text(l10n.roleLabelFor(u.role, u.roleLabel), style: const TextStyle(fontSize: 11)),
              value: selected.contains(u.id),
              onChanged: (v) {
                v == true ? selected.add(u.id) : selected.remove(u.id);
                onChanged();
              },
            ),
        ]);
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(broadcastHistoryProvider);
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(broadcastHistoryProvider)),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.refresh(broadcastHistoryProvider.future),
        child: list.isEmpty
            ? const AdminEmptyView(icon: Icons.notifications_none)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final h = list[i];
                  return AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(h.body),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        StatusChip(
                          label: (h.target == 'all' ? l10n.admTargetAll : l10n.admTargetSpecific).toUpperCase(),
                          color: AppTheme.zinc400,
                        ),
                        StatusChip(label: l10n.admRecipients(h.successCount, h.totalRecipients), color: AppTheme.brandGreen),
                        Text(fmtDateTime(context, h.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.zinc500)),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
