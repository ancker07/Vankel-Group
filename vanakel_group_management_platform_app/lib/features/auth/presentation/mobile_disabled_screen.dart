import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/mobile_access_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Shown on every screen of the phone app while the super admin has the mobile app switched off.
/// It checks again by itself every 30 seconds and when the user presses the button.
class MobileDisabledScreen extends ConsumerStatefulWidget {
  const MobileDisabledScreen({super.key});

  @override
  ConsumerState<MobileDisabledScreen> createState() => _MobileDisabledScreenState();
}

class _MobileDisabledScreenState extends ConsumerState<MobileDisabledScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _stillOff = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      if (!silent) _stillOff = false;
    });
    final on = await ref.read(mobileAccessProvider.notifier).recheck();
    if (!mounted) return; // back in the app: this screen is gone
    setState(() {
      _checking = false;
      _stillOff = !on && !silent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false, // there is nothing to go back to while the app is off
      child: Scaffold(
        backgroundColor: AppTheme.brandBlack,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phonelink_off_outlined, size: 72, color: AppTheme.brandOrange),
                  const SizedBox(height: 24),
                  Text(
                    l10n.mobileDisabledTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.mobileDisabledMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.zinc400, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checking ? null : () => _check(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(l10n.mobileDisabledRetry, style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  if (_stillOff) ...[
                    const SizedBox(height: 12),
                    Text(l10n.mobileDisabledStillOff, style: const TextStyle(color: AppTheme.brandOrange, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
