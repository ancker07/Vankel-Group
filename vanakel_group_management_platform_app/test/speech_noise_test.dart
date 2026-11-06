import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/shared/speech/cloud_dictation.dart';

/// 16-bit mono 16 kHz audio with the given RMS (0..1), as noise-like samples.
Uint8List _audio(int ms, double rms, math.Random r) {
  final n = sampleRate * ms ~/ 1000;
  final data = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    final v = ((r.nextDouble() * 2 - 1) * rms * math.sqrt(3) * 32767).round().clamp(-32768, 32767);
    data.setInt16(i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

/// French and Dutch dictation cuts the microphone audio into sentences itself (English uses the phone's recognition).
/// These guard the case that used to fail: background noise (street, building site) hid every pause, so nothing was sent.
///
/// Plays: [leadMs] of background, [speechMs] of speech, then [tailMs] of background, in chunks of [chunkMs].
/// Returns the time (ms from the start) at which each segment was handed over for transcription.
List<int> _play({required double ambient, required double speech, int leadMs = 1000, int speechMs = 3000, int tailMs = 3000, int chunkMs = 100}) {
  final r = math.Random(1);
  final times = <int>[];
  var now = 0;
  final seg = SpeechSegmenter((_) => times.add(now));
  void play(int ms, double level) {
    for (var t = 0; t < ms; t += chunkMs) {
      now += chunkMs;
      seg.feed(_audio(chunkMs, level, r));
    }
  }

  play(leadMs, ambient);
  play(speechMs, speech);
  play(tailMs, ambient);
  return times;
}

void main() {
  test('quiet room: a sentence is sent shortly after the pause', () {
    final t = _play(ambient: 0.003, speech: 0.08);
    expect(t, isNotEmpty);
  });

  test('NOISY place (street / building site): a sentence is sent shortly after the pause', () {
    final t = _play(ambient: 0.02, speech: 0.10);
    expect(t, isNotEmpty);
    expect(t.first, lessThan(7000), reason: 'text must arrive within a few seconds of stopping to speak');
  });

  test('very noisy place', () {
    final t = _play(ambient: 0.04, speech: 0.15);
    expect(t, isNotEmpty);
    expect(t.first, lessThan(7000));
  });

  test('quiet speaker (soft voice, phone held away)', () {
    final t = _play(ambient: 0.002, speech: 0.012);
    expect(t, isNotEmpty);
  });

  test('speaking from the very first moment is still captured (speech rises and dips like syllables)', () {
    final r = math.Random(2);
    final times = <int>[];
    var now = 0;
    final seg = SpeechSegmenter((_) => times.add(now));
    for (var t = 0; t < 3000; t += 100) {
      now += 100;
      seg.feed(_audio(100, (t ~/ 100).isEven ? 0.12 : 0.05, r)); // talking at once, no quiet lead-in
    }
    for (var t = 0; t < 3000; t += 100) {
      now += 100;
      seg.feed(_audio(100, 0.003, r));
    }
    expect(times, isNotEmpty);
    expect(times.first, lessThan(5000));
  });

  test('background noise alone is never sent for transcription', () {
    final t = _play(ambient: 0.03, speech: 0.03, speechMs: 0); // no speech at all, just a noisy place
    expect(t, isEmpty);
  });

  test('works with different microphone chunk sizes', () {
    for (final chunk in [20, 64, 128, 256]) {
      final t = _play(ambient: 0.02, speech: 0.10, chunkMs: chunk);
      expect(t, isNotEmpty, reason: 'chunk $chunk ms');
      expect(t.first, lessThan(6500), reason: 'chunk $chunk ms');
    }
  });
}
