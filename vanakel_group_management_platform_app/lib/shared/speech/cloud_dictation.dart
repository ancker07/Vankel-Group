import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// Server speech-to-text for dictation: the microphone stream is cut into speech segments at
/// natural pauses; each is transcribed and appended exactly once, in the order spoken.
const int sampleRate = 16000;
const int _bytesPerMs = sampleRate * 2 ~/ 1000;
const int _maxSegmentMs = 15000;
const int _pauseMs = 800;
const int _minSpeechMs = 200;
const int _preRollMs = 300;

Uint8List wavFromPcm(Uint8List pcm) {
  final header = ByteData(44);
  void tag(int at, String value) {
    for (var i = 0; i < 4; i++) {
      header.setUint8(at + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .takeBytes();
}

/// Cuts 16-bit mono PCM into segments that contain speech; silence is not uploaded.
class SpeechSegmenter {
  final void Function(Uint8List pcm) onSegment;
  SpeechSegmenter(this.onSegment);

  BytesBuilder _buffer = BytesBuilder(copy: true);
  int _speechMs = 0;
  int _silenceMs = 0;
  bool _inSpeech = false;

  // The background level is learned from the audio itself: the quiet 10th percentile of the last
  // few seconds. A fixed or slowly-adapting floor mistook ordinary noise (street, building site,
  // a running machine) for speech, so no pause was ever found and nothing was sent for transcription.
  static const int _windowMs = 10000;
  final List<({double level, int ms})> _recent = [];
  int _recentMs = 0;

  /// Quiet background level of the last seconds of audio.
  double get backgroundLevel {
    if (_recent.isEmpty) return 0;
    final sorted = _recent.map((c) => c.level).toList()..sort();
    // never above a loud-street level: audio louder than that is speech (someone who starts talking at once)
    return math.min(0.03, sorted[((sorted.length - 1) * 0.1).floor()]);
  }

  void feed(Uint8List pcm) {
    _buffer.add(pcm);
    final ms = pcm.length ~/ _bytesPerMs;
    if (ms == 0) return;

    final level = _rms(pcm);
    _recent.add((level: level, ms: ms));
    _recentMs += ms;
    while (_recentMs > _windowMs && _recent.length > 1) {
      _recentMs -= _recent.removeAt(0).ms;
    }

    // Speech must stand clearly above the background; once speaking, a smaller margin keeps it going
    // (a brief dip or a noise spike does not break a word or a pause).
    final floor = backgroundLevel;
    final speaking = level > math.max(0.008, floor * 2.5) || (_inSpeech && level > math.max(0.006, floor * 2.0));
    _inSpeech = speaking;
    if (speaking) {
      _speechMs += ms;
      _silenceMs = 0;
    } else {
      _silenceMs += ms;
    }

    final total = _buffer.length ~/ _bytesPerMs;
    if (_speechMs >= _minSpeechMs && (_silenceMs >= _pauseMs || total >= _maxSegmentMs)) {
      flush();
    } else if (_speechMs < _minSpeechMs && _silenceMs >= 1000) {
      // Nothing said yet: keep only the moment before speech, so a first syllable is not cut.
      final all = _buffer.takeBytes();
      final keep = math.min(all.length, _preRollMs * _bytesPerMs);
      _buffer = BytesBuilder(copy: true)..add(Uint8List.sublistView(all, all.length - keep));
      _speechMs = 0;
      _silenceMs = 0;
    }
  }

  /// Sends what is buffered, if it holds speech.
  void flush() {
    final all = _buffer.takeBytes();
    final hadSpeech = _speechMs >= _minSpeechMs;
    _speechMs = 0;
    _silenceMs = 0;
    if (hadSpeech) onSegment(all);
  }

  static double _rms(Uint8List pcm) {
    final data = ByteData.sublistView(pcm);
    final samples = pcm.length ~/ 2;
    var sum = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    return math.sqrt(sum / samples);
  }
}

enum SegmentFailure { retry, skip, unavailable }

/// Uploads one segment at a time (keeps spoken order); retries for about a minute so short
/// network drops lose nothing, because the audio waits here meanwhile.
class SegmentQueue {
  final Future<String> Function(Uint8List) transcribe;
  final SegmentFailure Function(Object) classify;
  final void Function(String) onText;
  final void Function() onLost;
  final void Function() onUnavailable;
  final List<Duration> delays;

  SegmentQueue({
    required this.transcribe,
    required this.classify,
    required this.onText,
    required this.onLost,
    required this.onUnavailable,
    this.delays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
      Duration(seconds: 30),
    ],
  });

  final Queue<Uint8List> _items = Queue();
  bool _running = false;
  bool _stopped = false;
  Completer<void>? _idle;
  int _lostInARow = 0;

  void add(Uint8List item) {
    if (_stopped) return;
    _items.add(item);
    _run();
  }

  void cancel() {
    _stopped = true;
    _items.clear();
  }

  Future<void> whenIdle() {
    if (!_running) return Future.value();
    return (_idle ??= Completer<void>()).future;
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    while (_items.isNotEmpty && !_stopped) {
      await _process(_items.removeFirst());
    }
    _running = false;
    _idle?.complete();
    _idle = null;
  }

  Future<void> _process(Uint8List item) async {
    for (var attempt = 0;; attempt++) {
      try {
        final text = (await transcribe(item)).trim();
        _lostInARow = 0;
        if (text.isNotEmpty && !_stopped) onText(text);
        return;
      } catch (error) {
        final kind = classify(error);
        if (kind == SegmentFailure.unavailable) {
          cancel();
          onLost();
          onUnavailable();
          return;
        }
        if (kind == SegmentFailure.skip || attempt >= delays.length) {
          onLost();
          // Two in a row means the server route is not working: stop relying on it.
          if (++_lostInARow >= 2) {
            cancel();
            onUnavailable();
          }
          return;
        }
        await Future<void>.delayed(delays[attempt]);
        if (_stopped) return;
      }
    }
  }
}

enum CloudStart { started, denied }

class CloudDictation {
  final AudioRecorder _recorder = AudioRecorder();
  late final SegmentQueue _queue;
  late final SpeechSegmenter _segmenter;
  final void Function() _onUnavailable;
  StreamSubscription<Uint8List>? _subscription;

  CloudDictation({
    required Future<String> Function(Uint8List wav) transcribe,
    required SegmentFailure Function(Object) classify,
    required void Function(String) onText,
    required void Function() onLost,
    required void Function() onUnavailable,
  }) : _onUnavailable = onUnavailable {
    _queue = SegmentQueue(
      transcribe: transcribe,
      classify: classify,
      onText: onText,
      onLost: onLost,
      onUnavailable: onUnavailable,
    );
    _segmenter = SpeechSegmenter((pcm) => _queue.add(wavFromPcm(pcm)));
  }

  Future<CloudStart> start() async {
    if (!await _recorder.hasPermission()) return CloudStart.denied;
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
    ));
    _subscription = stream.listen(
      _segmenter.feed,
      // the microphone failed mid-way: hand over to the device's recognition
      onError: (Object _) => _onUnavailable(),
    );
    return CloudStart.started;
  }

  /// Stops listening; completes when every spoken segment has been delivered.
  Future<void> stop() async {
    await _closeMic();
    _segmenter.flush();
    await _queue.whenIdle();
    await _recorder.dispose();
  }

  /// Stops immediately: the screen is closing or another engine is taking over.
  void abort() {
    _queue.cancel();
    _closeMic().whenComplete(_recorder.dispose);
  }

  Future<void> _closeMic() async {
    try {
      await _recorder.stop(); // lets the last audio reach the stream
    } catch (_) {}
    await _subscription?.cancel();
    _subscription = null;
  }
}
