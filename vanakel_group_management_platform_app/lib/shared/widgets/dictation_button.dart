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
  /// NOTE: SpeechToText() is ONE object shared by the whole app. It remembers the status / error
  /// callbacks of whoever called initialize() first, so every use must register its own again
  /// (see _attach); otherwise a second screen never hears "done" and the button stays stuck.
  final SpeechToText _speech = SpeechToText();

  /// What the user sees: the button is red.
  bool _isListening = false;

  /// What the user asked for: keep listening until they press stop (Android ends each recognition
  /// after a short pause; we start the next one so a longer note is not cut off).
  bool _wantListening = false;
  bool _restartPending = false;
  bool _gotWordsThisRound = false;
  int _silentRounds = 0;
  String? _locale;

  /// Text that was in the field before the current recognition round started.
  String _baseText = '';

  /// Stop after this many rounds in a row without a single word (nobody is speaking).
  static const _maxSilentRounds = 3;

  @override
  void dispose() {
    _wantListening = false;
    _speech.cancel();
    // do not leave callbacks pointing at a closed screen
    _speech.statusListener = null;
    _speech.errorListener = null;
    super.dispose();
  }

  void _attach() {
    _speech.statusListener = _onStatus;
    _speech.errorListener = _onError;
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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (error.errorMsg) {
      case 'error_no_match':
      case 'error_speech_timeout':
        // nothing (understandable) was said in this round: not a failure, the round just ended
        _roundEnded();
        return;
      case 'error_permission':
        _giveUp();
        _say(l10n.speechPermission, settings: true);
        return;
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        _giveUp();
        _say(l10n.speechNetwork);
        return;
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        _giveUp();
        _say(l10n.speechLanguage);
        return;
      case 'error_busy':
      case 'error_client':
        // the recogniser was still closing the previous round: try again shortly
        _roundEnded();
        return;
      default:
        _giveUp();
        _say(l10n.speechRetry);
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') _roundEnded();
  }

  /// Stops everything (error, or the user pressed stop).
  void _giveUp() {
    _wantListening = false;
    _restartPending = false;
    if (mounted) setState(() => _isListening = false);
  }

  /// One recognition round finished. If the user did not press stop, start the next round.
  void _roundEnded() {
    if (!mounted) return;
    if (!_wantListening) {
      if (_isListening) setState(() => _isListening = false);
      return;
    }
    if (_restartPending) return; // "notListening" and "done" both arrive
    _restartPending = true;

    _silentRounds = _gotWordsThisRound ? 0 : _silentRounds + 1;
    if (_silentRounds >= _maxSilentRounds) {
      _giveUp(); // nobody is talking: do not keep the microphone and the beeps going
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 350), () async {
      _restartPending = false;
      if (mounted && _wantListening && !_speech.isListening) await _listenOnce();
    });
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context)!;

    if (_wantListening) {
      _giveUp();
      await _speech.stop();
      return;
    }

    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
      // we do not declare the Bluetooth permissions, so do not ask for them (Android 12+)
      options: [SpeechToText.androidNoBluetooth],
    );
    _attach(); // initialize() keeps the FIRST caller's callbacks: register ours every time

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

    _locale = await _pickLocale(Localizations.localeOf(context).languageCode);
    if (!mounted) return;

    _wantListening = true;
    _restartPending = false;
    _silentRounds = 0;
    await _listenOnce();
  }

  Future<void> _listenOnce() async {
    final l10n = AppLocalizations.of(context)!;
    _baseText = widget.controller.text.trimRight();
    _gotWordsThisRound = false;
    setState(() => _isListening = true);

    try {
      // Everything goes inside listenOptions: the plugin IGNORES the old-style
      // localeId / pauseFor / listenFor arguments when listenOptions is given.
      await _speech.listen(
        onResult: (result) {
          final spoken = result.recognizedWords;
          if (spoken.isNotEmpty) _gotWordsThisRound = true;
          widget.controller.text = _baseText.isEmpty ? spoken : '$_baseText $spoken';
          widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: _locale,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(minutes: 2),
        ),
      );
    } catch (_) {
      _giveUp();
      _say(l10n.speechRetry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _isListening ? Colors.redAccent : AppTheme.zinc500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        // big enough to hit with a thumb (the touch target is at least 40 dp high)
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red.withValues(alpha: 0.1) : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isListening ? Colors.redAccent : AppTheme.zinc800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isListening ? Icons.mic : Icons.mic_none, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              _isListening ? l10n.stopDictation : l10n.dictate,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
