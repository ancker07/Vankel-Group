/// Merges what the device's recogniser reports into the text field without losing words.
///
/// Recognisers resend the whole current phrase with each result. Some engines also report an empty
/// result, or restart the phrase with only the newest words, which must not erase what was said.
class TranscriptMerger {
  String _committed = '';
  String _partial = '';
  String _lastWritten = '';

  /// Everything now in the field is safe; the next results are added after it.
  void startRound(String fieldText) {
    _committed = fieldText.trimRight();
    _partial = '';
    _lastWritten = fieldText;
  }

  /// Returns the new field text for a recogniser result.
  String apply(String spoken, {required String currentFieldText}) {
    // The user edited the field while speaking: their version wins.
    if (currentFieldText != _lastWritten) {
      _committed = currentFieldText.trimRight();
      _partial = '';
    }

    final words = spoken.trim();
    if (words.isEmpty) return _lastWritten = currentFieldText;

    if (_partial.isNotEmpty && _isNewPhrase(_partial, words)) {
      _committed = _join(_committed, _partial);
    }
    _partial = words;
    return _lastWritten = _join(_committed, _partial);
  }

  static String _join(String a, String b) => a.isEmpty ? b : '$a $b';

  /// A revision shares most of its words with the previous result; a new phrase shares few.
  static bool _isNewPhrase(String previous, String next) {
    final before = previous.toLowerCase().split(RegExp(r'\s+'));
    final after = next.toLowerCase().split(RegExp(r'\s+')).toSet();
    final shared = before.where(after.contains).length;
    final smaller = before.length < after.length ? before.length : after.length;
    if (before.length < 2) return false; // too little to judge: treat as a correction
    return shared * 2 < smaller || (after.length < before.length && shared == 0);
  }
}
