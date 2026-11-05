import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/api/api_constants.dart';
import '../../core/api/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../speech/cloud_dictation.dart';
import '../speech/transcript_merger.dart';

/// Microphone button: the user speaks and the words are appended to [controller].
/// Afterwards the text can be polished with "Improve with AI".
class DictationButton extends ConsumerStatefulWidget {
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
  ConsumerState<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends ConsumerState<DictationButton> {
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
  int _networkErrors = 0;
  String? _locale;

  /// Keeps earlier words safe from whatever a recognition round reports next.
  final TranscriptMerger _merger = TranscriptMerger();

  /// Results of a finished round may still arrive; only the current round may write.
  int _round = 0;

  /// French and Dutch: server transcription (null = the device's recognition is in use).
  CloudDictation? _cloud;
  bool _isProcessing = false;
  bool _starting = false;

  /// Stop after this many rounds in a row without a single word (nobody is speaking).
  static const _maxSilentRounds = 3;

  @override
  void dispose() {
    _wantListening = false;
    _cloud?.abort();
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
        // Often a passing drop: start a new round a few times before giving up
        if (++_networkErrors <= 3) {
          _roundEnded();
          return;
        }
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

  void _appendText(String text) {
    final current = widget.controller.text.trimRight();
    final joined = current.isEmpty ? text : '$current $text';
    widget.controller.value = TextEditingValue(
      text: joined,
      selection: TextSelection.collapsed(offset: joined.length),
    );
  }

  /// French and Dutch use server transcription. False means: use the device's recognition.
  Future<bool> _startCloud(String languageCode) async {
    if (languageCode == 'en') return false;
    final l10n = AppLocalizations.of(context)!;
    final dio = ref.read(dioProvider);
    try {
      final status = await dio.get(ApiConstants.transcribeStatus);
      if (status.data['available'] != true) return false;
    } on DioException catch (e) {
      // no permission for it: device recognition. Merely offline: record now, upload when back.
      if (e.response != null) return false;
    }

    late final CloudDictation cloud;
    cloud = CloudDictation(
      transcribe: (wav) async {
        final response = await dio.post(
          ApiConstants.transcribe,
          data: FormData.fromMap({
            'language': languageCode,
            'audio': MultipartFile.fromBytes(
              wav,
              filename: 'speech.wav',
              contentType: DioMediaType('audio', 'wav'),
            ),
          }),
        );
        return (response.data['text'] ?? '').toString();
      },
      classify: (error) {
        final status = error is DioException ? error.response?.statusCode : null;
        if (status == 422 || status == 413) return SegmentFailure.skip;
        if (status == 401 || status == 403 || status == 503) return SegmentFailure.unavailable;
        return SegmentFailure.retry;
      },
      onText: (text) {
        if (mounted) _appendText(text);
      },
      onLost: () => _say(l10n.speechLost),
      onUnavailable: () {
        cloud.abort();
        if (mounted && identical(_cloud, cloud)) {
          _cloud = null;
          _startNative(languageCode);
        }
      },
    );

    final CloudStart started;
    try {
      started = await cloud.start();
    } catch (_) {
      cloud.abort();
      return false;
    }
    if (!mounted) {
      cloud.abort();
      return true;
    }
    if (started == CloudStart.denied) {
      _say(l10n.speechPermission, settings: true);
      return true;
    }
    _cloud = cloud;
    setState(() => _isListening = true);
    return true;
  }

  Future<void> _toggle() async {
    if (_starting || _isProcessing) return;

    final cloud = _cloud;
    if (cloud != null) {
      _cloud = null; // the user stopped: no fallback may restart the microphone
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      await cloud.stop();
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    if (!_wantListening) {
      _starting = true;
      try {
        final languageCode = Localizations.localeOf(context).languageCode;
        if (await _startCloud(languageCode)) return;
        if (mounted) await _startNative(languageCode);
      } finally {
        _starting = false;
      }
      return;
    }

    _giveUp();
    await _speech.stop();
  }

  Future<void> _startNative(String languageCode) async {
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

    _locale = await _pickLocale(languageCode);
    if (!mounted) return;

    _wantListening = true;
    _restartPending = false;
    _silentRounds = 0;
    _networkErrors = 0;
    await _listenOnce();
  }

  Future<void> _listenOnce() async {
    final l10n = AppLocalizations.of(context)!;
    _merger.startRound(widget.controller.text);
    final round = ++_round;
    _gotWordsThisRound = false;
    setState(() => _isListening = true);

    try {
      // Everything goes inside listenOptions: the plugin IGNORES the old-style
      // localeId / pauseFor / listenFor arguments when listenOptions is given.
      await _speech.listen(
        onResult: (result) {
          if (round != _round || !mounted) return; // late result of a finished round: already in the text
          final spoken = result.recognizedWords;
          if (spoken.trim().isNotEmpty) {
            _gotWordsThisRound = true;
            _networkErrors = 0;
          }
          final merged = _merger.apply(spoken, currentFieldText: widget.controller.text);
          if (merged == widget.controller.text) return;
          widget.controller.value = TextEditingValue(
            text: merged,
            selection: TextSelection.collapsed(offset: merged.length),
          );
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
              _isProcessing ? l10n.speechProcessing : (_isListening ? l10n.stopDictation : l10n.dictate),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
