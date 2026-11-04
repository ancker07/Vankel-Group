import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Microphone button: the user speaks and the words are appended to [controller].
/// Afterwards the text can be polished with "Improve with AI".
class DictationButton extends StatefulWidget {
  final TextEditingController controller;

  const DictationButton({super.key, required this.controller});

  /// Languages to try for each app language, best first (Belgian variants first).
  static const _preferred = <String, List<String>>{
    'fr': ['fr_BE', 'fr_FR'],
    'nl': ['nl_BE', 'nl_NL'],
    'en': ['en_GB', 'en_US'],
  };

  /// The recognition language to use: the best match among the languages the phone
  /// really has installed. Asking for one that is not installed (e.g. nl_BE) makes
  /// recognition fail on many phones; null means "use the phone's own language".
  static String? chooseLocale(List<String> available, String languageCode) {
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();
    for (final wanted in _preferred[languageCode] ?? const <String>[]) {
      for (final id in available) {
        if (norm(id) == wanted.toLowerCase()) return id;
      }
    }
    for (final id in available) {
      if (norm(id).startsWith('${languageCode.toLowerCase()}_')) return id;
    }
    return null;
  }

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  /// Text that was in the field before this dictation started.
  String _baseText = '';

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<String?> _pickLocale(String languageCode) async {
    try {
      final available = (await _speech.locales()).map((l) => l.localeId).toList();
      return DictationButton.chooseLocale(available, languageCode);
    } catch (_) {
      return null; // let the phone choose
    }
  }

  void _say(String message, {bool settings = false}) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        action: settings
            ? SnackBarAction(
                label: l10n.openSettings,
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              )
            : null,
      ));
  }

  void _onError(SpeechRecognitionError error) {
    if (mounted) setState(() => _isListening = false);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (error.errorMsg) {
      case 'error_no_match':
      case 'error_speech_timeout':
        break; // nothing was said: not a failure
      case 'error_permission':
        _say(l10n.speechPermission, settings: true);
        break;
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        _say(l10n.speechNetwork);
        break;
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        _say(l10n.speechLanguage);
        break;
      default:
        _say(l10n.speechRetry);
    }
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
      // we do not declare the Bluetooth permissions, so do not ask for them (Android 12+)
      options: [SpeechToText.androidNoBluetooth],
    );

    if (!mounted) return;
    if (!available) {
      // Tell the user why: refused (or permanently blocked) microphone vs. no speech service
      final hasPermission = await _speech.hasPermission;
      if (!mounted) return;
      if (!hasPermission) {
        _say(l10n.speechPermission, settings: true);
      } else {
        _say(l10n.speechUnavailable);
      }
      return;
    }

    final locale = await _pickLocale(Localizations.localeOf(context).languageCode);
    if (!mounted) return;

    _baseText = widget.controller.text.trimRight();
    setState(() => _isListening = true);

    try {
      // Everything goes inside listenOptions: the plugin IGNORES the old-style
      // localeId / pauseFor / listenFor arguments when listenOptions is given.
      await _speech.listen(
        onResult: (result) {
          final spoken = result.recognizedWords;
          widget.controller.text = _baseText.isEmpty ? spoken : '$_baseText $spoken';
          widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: locale,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(minutes: 2),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
      _say(l10n.speechRetry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _isListening ? Colors.redAccent : AppTheme.zinc500;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red.withValues(alpha: 0.1) : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _isListening ? Colors.redAccent : AppTheme.zinc800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isListening ? Icons.mic : Icons.mic_none, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              _isListening ? l10n.stopDictation : l10n.dictate,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
