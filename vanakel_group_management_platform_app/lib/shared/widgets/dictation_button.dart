import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Microphone button: the user speaks and the words are appended to [controller].
/// Afterwards the text can be polished with "Improve with AI".
class DictationButton extends StatefulWidget {
  final TextEditingController controller;

  const DictationButton({super.key, required this.controller});

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

  String _localeId(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'nl':
        return 'nl_BE';
      case 'en':
        return 'en_GB';
      default:
        return 'fr_BE';
    }
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );

    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.speechUnavailable), backgroundColor: Colors.red),
      );
      return;
    }

    _baseText = widget.controller.text.trimRight();
    setState(() => _isListening = true);

    await _speech.listen(
      localeId: _localeId(context),
      listenOptions: SpeechListenOptions(partialResults: true, listenMode: ListenMode.dictation),
      pauseFor: const Duration(seconds: 5),
      listenFor: const Duration(minutes: 2),
      onResult: (result) {
        final spoken = result.recognizedWords;
        widget.controller.text = _baseText.isEmpty ? spoken : '$_baseText $spoken';
        widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
      },
    );
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
