import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(aiSettingsProvider);
    return PermissionGate(
      anyOf: const ['settings.ai'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admAiSettings.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        body: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorView(error: e, onRetry: () => ref.invalidate(aiSettingsProvider)),
          data: (s) => _AiForm(initial: s),
        ),
      ),
    );
  }
}

class _AiForm extends ConsumerStatefulWidget {
  final AiSettings initial;
  const _AiForm({required this.initial});

  @override
  ConsumerState<_AiForm> createState() => _AiFormState();
}

class _AiFormState extends ConsumerState<_AiForm> {
  final _form = GlobalKey<FormState>();
  late final _model = TextEditingController(text: widget.initial.model);
  late final _key = TextEditingController(text: widget.initial.apiKey);
  bool _hide = true;
  bool _busy = false;

  @override
  void dispose() {
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).saveAiSettings(model: _model.text.trim(), apiKey: _key.text.trim());
      ref.invalidate(aiSettingsProvider);
      adminSnack(context, l10n.admSaved);
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
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _model, decoration: InputDecoration(labelText: l10n.admAiModel), validator: required),
        const SizedBox(height: 12),
        TextFormField(
          controller: _key,
          obscureText: _hide,
          decoration: InputDecoration(
            labelText: l10n.admAiApiKey,
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
          validator: required,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.admSave)),
      ]),
    );
  }
}
