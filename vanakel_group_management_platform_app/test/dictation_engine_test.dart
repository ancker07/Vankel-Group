import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/shared/speech/cloud_dictation.dart';
import 'package:vanakel_group_management_platform_app/shared/speech/transcript_merger.dart';

Uint8List tone(int ms, int amplitude) {
  final data = ByteData(ms * 32);
  for (var i = 0; i < ms * 16; i++) {
    data.setInt16(i * 2, i.isEven ? amplitude : -amplitude, Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  group('TranscriptMerger', () {
    String feed(TranscriptMerger m, List<String> results, String start) {
      var field = start;
      m.startRound(field);
      for (final r in results) {
        field = m.apply(r, currentFieldText: field);
      }
      return field;
    }

    test('growing partials and revisions replace only the current phrase', () {
      expect(feed(TranscriptMerger(), ['la', 'la fuite', 'les fuites dans la', 'les fuites dans la cave'], 'Note.'),
          'Note. les fuites dans la cave');
    });
    test('an empty result does not erase what was said (the disappearing text)', () {
      expect(feed(TranscriptMerger(), ['de lekkage is groot', ''], ''), 'de lekkage is groot');
    });
    test('an engine restarting the phrase keeps the earlier words', () {
      expect(feed(TranscriptMerger(), ['de lekkage in de kelder', 'we komen morgen'], ''),
          'de lekkage in de kelder we komen morgen');
    });
    test('a new round keeps previous rounds', () {
      final m = TranscriptMerger();
      final first = feed(m, ['bonjour madame'], '');
      expect(feed(m, ['la chaudière'], first), 'bonjour madame la chaudière');
    });
    test('user edits while speaking win', () {
      final m = TranscriptMerger()..startRound('');
      m.apply('hello world', currentFieldText: '');
      expect(m.apply('hello world again', currentFieldText: 'Edited'), 'Edited hello world again');
    });
    test('English: normal growth is unchanged', () {
      expect(feed(TranscriptMerger(), ['the', 'the leak', 'the leak is', 'the leak is fixed'], ''), 'the leak is fixed');
    });
  });

  group('SpeechSegmenter', () {
    test('cuts at a pause, keeps the audio, ignores silence', () {
      final out = <Uint8List>[];
      final s = SpeechSegmenter(out.add);
      for (var i = 0; i < 100; i++) {
        s.feed(tone(100, 0));
      }
      expect(out, isEmpty);
      for (var i = 0; i < 20; i++) {
        s.feed(tone(100, 8000));
      }
      for (var i = 0; i < 9; i++) {
        s.feed(tone(100, 0));
      }
      expect(out.length, 1);
      expect(out.first.length, greaterThanOrEqualTo(2900 * 32));
    });
    test('non-stop speech is capped and no audio is dropped', () {
      final out = <Uint8List>[];
      final s = SpeechSegmenter(out.add);
      for (var i = 0; i < 600; i++) {
        s.feed(tone(100, 8000));
      }
      s.flush();
      expect(out.length, greaterThan(1));
      expect(out.fold<int>(0, (n, b) => n + b.length), 60000 * 32);
    });
  });

  group('SegmentQueue', () {
    final item = (int n) => Uint8List.fromList([n]);
    SegmentQueue queue(Future<String> Function(Uint8List) fn, List<String> log) => SegmentQueue(
          transcribe: fn,
          classify: (e) => e as SegmentFailure,
          onText: log.add,
          onLost: () => log.add('LOST'),
          onUnavailable: () => log.add('UNAVAILABLE'),
          delays: const [Duration.zero, Duration.zero],
        );

    test('network failure then recovery: order kept, nothing lost or duplicated', () async {
      final log = <String>[];
      var fails = 2;
      final q = queue((b) async {
        if (b[0] == 1 && fails-- > 0) throw SegmentFailure.retry;
        return 'seg${b[0]}';
      }, log);
      q..add(item(1))..add(item(2));
      await q.whenIdle();
      expect(log, ['seg1', 'seg2']);
    });
    test('two unreadable segments in a row: switches to the device recognition', () async {
      final log = <String>[];
      final q = queue((_) async => throw SegmentFailure.skip, log);
      q..add(item(1))..add(item(2))..add(item(3));
      await q.whenIdle();
      expect(log, ['LOST', 'LOST', 'UNAVAILABLE']);
    });
    test('server unusable: switches over once and stops uploading', () async {
      final log = <String>[];
      final q = queue((_) async => throw SegmentFailure.unavailable, log);
      q..add(item(1))..add(item(2));
      await q.whenIdle();
      expect(log, ['LOST', 'UNAVAILABLE']);
    });
  });

  test('WAV header describes the audio', () {
    final wav = wavFromPcm(tone(10, 1));
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(wav.length, 44 + 320);
  });
}
