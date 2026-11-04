import '../../../core/utils/app_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

Color _ingestionColor(String? s) {
  switch (s) {
    case 'PROCESSED':
      return AppTheme.brandGreen;
    case 'NEEDS_REVIEW':
    case 'DEFERRED':
      return AppTheme.brandOrange;
    case 'ERROR':
      return Colors.red;
    default:
      return AppTheme.zinc400;
  }
}

class EmailsScreen extends ConsumerStatefulWidget {
  const EmailsScreen({super.key});

  @override
  ConsumerState<EmailsScreen> createState() => _EmailsScreenState();
}

class _EmailsScreenState extends ConsumerState<EmailsScreen> {
  String _query = '';
  bool _syncing = false;

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      await ref.read(adminRepositoryProvider).syncEmails();
      ref.invalidate(emailsProvider);
      adminSnack(context, l10n.admSyncDone);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _ingestAll() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      await ref.read(adminRepositoryProvider).ingestAll();
      ref.invalidate(emailsProvider);
      adminSnack(context, l10n.admSyncDone);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emails = ref.watch(emailsProvider);
    final canManage = canDo(ref, 'emails.manage');

    return PermissionGate(
      anyOf: const ['emails.view'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admInbox.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          actions: [
            if (canManage)
              _syncing
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      tooltip: l10n.admSync,
                      icon: const Icon(Icons.sync),
                      onPressed: _sync,
                    ),
            if (canManage && !_syncing)
              IconButton(
                tooltip: l10n.admIngestAll,
                icon: const Icon(Icons.auto_awesome),
                onPressed: _ingestAll,
              ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.admSearchEmails,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: emails.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(emailsProvider)),
              data: (list) {
                final shown = _query.isEmpty
                    ? list
                    : list
                        .where((m) =>
                            (m.subject ?? '').toLowerCase().contains(_query) ||
                            m.sender.toLowerCase().contains(_query) ||
                            m.fromAddress.toLowerCase().contains(_query))
                        .toList();
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(emailsProvider.future),
                  child: shown.isEmpty
                      ? const AdminEmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _EmailTile(email: shown[i]),
                        ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmailTile extends StatelessWidget {
  final AdminEmail email;
  const _EmailTile({required this.email});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminCard(
      onTap: () => context.push('/admin/dashboard/emails/${email.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(email.sender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: email.isRead ? FontWeight.w500 : FontWeight.w800)),
          ),
          Text(fmtDateTime(context, email.receivedAt),
              style: const TextStyle(fontSize: 11, color: AppTheme.zinc500)),
        ]),
        const SizedBox(height: 4),
        Text(email.subject ?? l10n.admNoSubject,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(email.body.replaceAll(RegExp(r'\s+'), ' '),
            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          StatusChip(
            label: (email.ingestionStatus == null ? l10n.admNotIngested : l10n.ingestionStatusLabel(email.ingestionStatus)).toUpperCase(),
            color: _ingestionColor(email.ingestionStatus),
          ),
          if (email.threadCount > 1)
            StatusChip(label: l10n.admThreadMessages(email.threadCount), color: AppTheme.zinc400),
          if (email.attachments.isNotEmpty)
            StatusChip(label: '${email.attachments.length} 📎', color: AppTheme.zinc400),
        ]),
      ]),
    );
  }
}

class EmailDetailScreen extends ConsumerWidget {
  final int emailId;
  const EmailDetailScreen({super.key, required this.emailId});

  Future<void> _ingest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final status = await ref.read(adminRepositoryProvider).ingestEmail(emailId);
      ref.invalidate(emailDetailProvider(emailId));
      ref.invalidate(emailsProvider);
      adminSnack(context, l10n.admIngestResult(status));
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await adminConfirm(context,
        title: l10n.admDeleteEmail, message: l10n.admDeleteConfirm, confirmLabel: l10n.admDelete, destructive: true);
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminRepositoryProvider).deleteEmail(emailId);
      ref.invalidate(emailsProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    }
  }

  void _reply(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc900,
      builder: (_) => _ReplySheet(emailId: emailId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(emailDetailProvider(emailId));
    final canManage = canDo(ref, 'emails.manage');

    return PermissionGate(
      anyOf: const ['emails.view'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admInbox.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          actions: [
            if (canManage) ...[
              IconButton(tooltip: l10n.admIngest, icon: const Icon(Icons.auto_awesome), onPressed: () => _ingest(context, ref)),
              IconButton(tooltip: l10n.admDelete, icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref)),
            ],
          ],
        ),
        floatingActionButton: canManage
            ? FloatingActionButton.extended(
                backgroundColor: AppTheme.brandGreen,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.reply),
                label: Text(l10n.admReply),
                onPressed: () => _reply(context),
              )
            : null,
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(emailDetailProvider(emailId))),
          data: (email) {
            final messages = email.thread.isNotEmpty ? email.thread : [email];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(email.subject ?? l10n.admNoSubject,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  StatusChip(
                    label: (email.ingestionStatus == null ? l10n.admNotIngested : l10n.ingestionStatusLabel(email.ingestionStatus)).toUpperCase(),
                    color: _ingestionColor(email.ingestionStatus),
                  ),
                ]),
                if (email.ingestionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${l10n.admIngestionStatus}: ${email.ingestionReason}',
                        style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                for (final m in messages) _MessageCard(message: m),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AdminEmail message;
  const _MessageCard({required this.message});

  Future<void> _open(BuildContext context, EmailAttachment a) async {
    final uri = Uri.tryParse(ApiConstants.getStorageUrl(a.filePath));
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) adminSnack(context, AppLocalizations.of(context)!.couldNotOpen(a.fileName), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.sender, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (message.fromName != null)
          Text(message.fromAddress, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
        Text(fmtDateTime(context, message.receivedAt), style: const TextStyle(color: AppTheme.zinc500, fontSize: 11)),
        const Divider(height: 20, color: Colors.white10),
        SelectableText(message.body.isEmpty ? '—' : message.body),
        if (message.attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.admAttachments.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.zinc500, letterSpacing: 1)),
          for (final a in message.attachments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file, size: 18),
              title: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _open(context, a),
            ),
        ],
      ]),
    );
  }
}

class _ReplySheet extends ConsumerStatefulWidget {
  final int emailId;
  const _ReplySheet({required this.emailId});

  @override
  ConsumerState<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<_ReplySheet> {
  final _body = TextEditingController();
  String _account = 'no-reply';
  bool _sending = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (_body.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminRepositoryProvider).replyToEmail(widget.emailId, body: _body.text.trim(), account: _account);
      if (!mounted) return;
      Navigator.pop(context);
      adminSnack(context, l10n.admSent);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.admReply, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _account,
          decoration: InputDecoration(labelText: l10n.admReplyFrom),
          items: const [
            DropdownMenuItem(value: 'no-reply', child: Text('no-reply@vanakelgroup.com')),
            DropdownMenuItem(value: 'redirection', child: Text('Redirection@vanakelgroup.com')),
          ],
          onChanged: (v) => setState(() => _account = v ?? _account),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(labelText: l10n.admMessage),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(l10n.admSend),
          ),
        ),
      ]),
    );
  }
}
