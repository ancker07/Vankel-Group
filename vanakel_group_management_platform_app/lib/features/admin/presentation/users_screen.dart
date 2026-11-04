import '../../../core/utils/app_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

Color _statusColor(String s) {
  switch (s) {
    case 'APPROVED':
      return AppTheme.brandGreen;
    case 'PENDING':
      return AppTheme.brandOrange;
    case 'REJECTED':
      return Colors.red;
    default:
      return AppTheme.zinc400;
  }
}

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canCreate = canDo(ref, 'users.create');
    final canViewUsers = canDo(ref, 'users.view');
    final canViewRoles = canDo(ref, 'roles.manage');
    final tabs = [
      if (canViewUsers) Tab(text: l10n.admUsers),
      if (canViewRoles) Tab(text: l10n.admRolesTitle),
    ];

    return PermissionGate(
      anyOf: const ['users.view', 'roles.manage'],
      child: DefaultTabController(
        length: tabs.isEmpty ? 1 : tabs.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.admUsers.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
            bottom: tabs.length > 1 ? TabBar(tabs: tabs) : null,
          ),
          floatingActionButton: canCreate && canViewUsers
              ? FloatingActionButton(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.black,
                  tooltip: l10n.admCreateUser,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.zinc900,
                    builder: (_) => const _CreateUserSheet(),
                  ),
                  child: const Icon(Icons.person_add_alt_1),
                )
              : null,
          body: TabBarView(children: [
            if (canViewUsers) const _UsersList(),
            if (canViewRoles) const _RolesList(),
          ]),
        ),
      ),
    );
  }
}

class _UsersList extends ConsumerWidget {
  const _UsersList();

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() call, String okMessage) async {
    try {
      await call();
      ref.invalidate(adminUsersProvider);
      adminSnack(context, okMessage);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(adminUsersProvider);
    final canUpdate = canDo(ref, 'users.update');
    final repo = ref.read(adminRepositoryProvider);

    return users.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(adminUsersProvider)),
      data: (list) {
        final pending = list.where((u) => u.isPending).toList();
        final others = list.where((u) => !u.isPending).toList();
        Widget tile(AdminUser u) => AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                  StatusChip(label: l10n.accountStatusLabel(u.status).toUpperCase(), color: _statusColor(u.status)),
                  if (canUpdate && !u.isPending)
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'role') {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppTheme.zinc900,
                            builder: (_) => _RolePickerSheet(user: u),
                          );
                        } else if (v == 'password') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppTheme.zinc900,
                            builder: (_) => _ResetPasswordSheet(user: u),
                          );
                        } else if (v == 'delete') {
                          final ok = await adminConfirm(context,
                              title: l10n.admDeleteUser,
                              message: l10n.admDeleteUserConfirm(u.name),
                              confirmLabel: l10n.admDelete,
                              destructive: true);
                          if (ok && context.mounted) {
                            await _act(context, ref, () => repo.deleteUser(u.id), l10n.admUserDeleted);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'role', child: Text(l10n.admChangeRole)),
                        PopupMenuItem(value: 'password', child: Text(l10n.admResetPassword)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.admDeleteUser)),
                      ],
                    ),
                ]),
                Text(u.email, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                if (u.phone != null) Text(u.phone!, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                const SizedBox(height: 6),
                Text('${l10n.admRole}: ${l10n.roleLabelFor(u.role, u.roleLabel)}', style: const TextStyle(fontSize: 12)),
                if (u.isPending && canUpdate) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _act(context, ref, () => repo.approveUser(u.id), l10n.admUserApproved),
                        child: Text(l10n.approve),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _act(context, ref, () => repo.rejectUser(u.id), l10n.admUserRejected),
                        child: Text(l10n.reject),
                      ),
                    ),
                  ]),
                ],
              ]),
            );

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminUsersProvider.future),
          child: list.isEmpty
              ? const AdminEmptyView(icon: Icons.group_outlined)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (pending.isNotEmpty) ...[
                    Text(l10n.admPendingUsers.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.brandOrange, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ...pending.map(tile),
                    const SizedBox(height: 12),
                  ],
                  ...others.map(tile),
                ]),
        );
      },
    );
  }
}

class _RolesList extends ConsumerWidget {
  const _RolesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roles = ref.watch(adminRolesProvider);
    return roles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(adminRolesProvider)),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.refresh(adminRolesProvider.future),
        child: list.isEmpty
            ? const AdminEmptyView(icon: Icons.key_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  return AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(l10n.roleLabelFor(r.name, r.label), style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (r.full) StatusChip(label: l10n.admRoleFull.toUpperCase(), color: AppTheme.brandOrange),
                      ]),
                      if (r.description != null)
                        Text(r.description!, style: const TextStyle(color: AppTheme.zinc400, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('${l10n.admRoleUsersCount(r.usersCount)} · ${l10n.admPermissionsCount(r.permissionsCount)}',
                          style: const TextStyle(color: AppTheme.zinc500, fontSize: 11)),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}

class _RolePickerSheet extends ConsumerWidget {
  final AdminUser user;
  const _RolePickerSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roles = ref.watch(adminRolesProvider);
    return SafeArea(
      child: roles.when(
        loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 200, child: AdminErrorView(error: e, onRetry: () => ref.invalidate(adminRolesProvider))),
        data: (list) => ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.admChangeRole, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          for (final r in list)
            ListTile(
              title: Text(l10n.roleLabelFor(r.name, r.label)),
              subtitle: r.full && r.name != user.role ? Text(l10n.admRoleFull) : null,
              trailing: r.name == user.role ? const Icon(Icons.check, color: AppTheme.brandGreen) : null,
              enabled: r.assignable && !(r.full && r.name != user.role),
              onTap: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref.read(adminRepositoryProvider).changeRole(user.id, r.name);
                  ref.invalidate(adminUsersProvider);
                  ref.invalidate(adminRolesProvider);
                  navigator.pop();
                  adminSnack(context, l10n.admRoleUpdated);
                } catch (e) {
                  adminSnack(context, e.toString(), error: true);
                }
              },
            ),
        ]),
      ),
    );
  }
}

class _ResetPasswordSheet extends ConsumerStatefulWidget {
  final AdminUser user;
  const _ResetPasswordSheet({required this.user});

  @override
  ConsumerState<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends ConsumerState<_ResetPasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).resetPassword(widget.user.id, _password.text);
      if (!mounted) return;
      Navigator.pop(context);
      adminSnack(context, l10n.admPasswordReset);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${l10n.admResetPassword}: ${widget.user.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.admNewPasswordHint),
            validator: (v) => (v ?? '').length < 8 ? l10n.admPasswordTooShort : null,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.admSave)),
          ),
        ]),
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _role;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).createUser(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role!,
            phone: _phone.text.trim(),
          );
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminRolesProvider);
      if (!mounted) return;
      Navigator.pop(context);
      adminSnack(context, l10n.admUserCreated);
    } catch (e) {
      adminSnack(context, e.toString(), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roles = ref.watch(adminRolesProvider);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l10n.admRequired : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.admCreateUser, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _first, decoration: InputDecoration(labelText: l10n.admFirstName), validator: required)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _last, decoration: InputDecoration(labelText: l10n.admLastName), validator: required)),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (v) => (v == null || !v.contains('@')) ? l10n.admRequired : null,
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l10n.phoneLabel)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.admNewPasswordHint),
              validator: (v) => (v ?? '').length < 8 ? l10n.admPasswordTooShort : null,
            ),
            const SizedBox(height: 8),
            roles.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.admRole),
                items: [
                  for (final r in list)
                    DropdownMenuItem(
                      value: r.name,
                      enabled: r.assignable && !r.full,
                      child: Text(r.full ? '${l10n.roleLabelFor(r.name, r.label)} (${l10n.admRoleFull})' : l10n.roleLabelFor(r.name, r.label)),
                    ),
                ],
                onChanged: (v) => setState(() => _role = v),
                validator: (v) => v == null ? l10n.admRequired : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.admCreateUser)),
            ),
          ]),
        ),
      ),
    );
  }
}
