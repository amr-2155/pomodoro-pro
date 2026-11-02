/// Arabic voice matching for the tasbeeh.
///
/// Speech recognizers return wildly different spellings for the same
/// dhikr (diacritics, hamza forms, joined words, extra words). This
/// matcher normalizes both sides and counts how many times a dhikr was
/// actually said inside one finalized utterance.
class VoiceDhikrMatcher {
  const VoiceDhikrMatcher._();

  /// Spoken variants per dhikr index — normalized and space-free.
  /// Index matches [TasbeehService.dhikrOptions].
  static const Map<int, List<String>> _variants = {
    // أستغفر الله
    0: [
      'استغفرالله',
      'استغفراللهربي',
      'استغفرلله',
      'استغفر',
    ],
    // اللهم صلِّ على محمد
    1: [
      'اللهمصلعليمحمد',
      'اللهمصلىعليمحمد',
      'اللهمصلعلىمحمد',
      'صلىاللهعليمحمد',
      'صلاللهعليمحمد',
      'صلىاللهعلىمحمد',
      'اللهمصلعلىسيدنامحمد',
    ],
    // سبحان الله
    2: [
      'سبحانالله',
      'سبحاناللهوبحمده',
      'سبحان',
    ],
    // الحمد لله
    3: [
      'الحمدلله',
      'الحمدللهربالعالمين',
      'الحمد',
    ],
    // الله أكبر
    4: [
      'اللهكبر',
      'اللهواكبر',
      'اللهواكبروللهالحمد',
    ],
    // لا إله إلا الله
    5: [
      'لاالهالاالله',
      'لاالهالااللهوحدهلاشريكله',
      'لاالهالا',
    ],
  };

  /// Strips diacritics/tatweel, unifies letter forms and keeps Arabic
  /// letters only, then collapses whitespace.
  static String normalize(String input) {
    var s = input;
    // Diacritics, sukun, dagger alif, tatweel.
    s = s.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
    // Alef forms.
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // Alef maqsura / hamza on ya & waw.
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ئ', 'ي');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ٓ', '');
    // Taa marbuta reads as haa in most recitations.
    s = s.replaceAll('ة', 'ه');
    // Punctuation and anything not an Arabic letter/space.
    s = s.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), ' ');
    // Collapse whitespace.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Space-free normalized text — ASR sometimes joins or splits words
  /// differently than the written phrase.
  static String compact(String input) => normalize(input).replaceAll(' ', '');

  /// How many times the dhikr was said in [transcript].
  ///
  /// Counts the best matching variant (longest phrase wins so
  /// “سبحان الله وبحمده” is not double counted as the shorter one).
  static int count(String transcript, int dhikrIndex) {
    final text = compact(transcript);
    if (text.isEmpty) return 0;
    final list = _variants[dhikrIndex];
    if (list == null) return 0;
    var best = 0;
    for (final variant in list) {
      if (variant.isEmpty) continue;
      final n = _countNonOverlapping(text, variant);
      if (n > best) best = n;
    }
    return best;
  }

  static int _countNonOverlapping(String haystack, String needle) {
    var count = 0;
    var from = 0;
    while (true) {
      final i = haystack.indexOf(needle, from);
      if (i < 0) break;
      count++;
      from = i + needle.length;
    }
    return count;
  }

  /// Does [transcript] contain any known dhikr? Returns its index/score
  /// so the UI can tell the user what was heard when it was not the
  /// currently selected dhikr.
  static MapEntry<int, int>? detect(String transcript) {
    MapEntry<int, int>? best;
    for (final entry in _variants.keys) {
      final n = count(transcript, entry);
      if (n <= 0) continue;
      if (best == null || n > best.value) best = MapEntry(entry, n);
    }
    return best;
  }

  /// Human readable variants for UI hints.
  static List<String> hints(int dhikrIndex) => _variants[dhikrIndex] ?? const [];
}

/// Turns the transcript stream of one listening session into a stream of
/// increments — "how many repetitions were said *since last time*".
///
/// Why this exists: speech engines report the same utterance several times.
/// Android sends a growing partial result and then repeats it as final. The
/// Web Speech API (used by `speech_to_text` on the web) only ever reports
/// partial results — the plugin hard-codes `ResultType.partial` — so anything
/// that waits for `result.finalResult` never counts anything in a browser.
///
/// Counting the highest number of repetitions seen so far in the session and
/// emitting only the difference gives exactly one increment per spoken
/// repetition on every platform, while still tolerating engines that rewrite
/// the transcript as they refine it (a rewrite never counts twice because the
/// reported total is monotonic).
class VoiceCountTracker {
  VoiceCountTracker(this.dhikrIndex);

  /// Which dhikr is being counted, see [VoiceDhikrMatcher.count].
  final int dhikrIndex;

  int _reported = 0;

  /// Repetitions already reported for this session.
  int get total => _reported;

  /// Feeds a (partial or final) transcript and returns how many new
  /// repetitions should be added to the counter. Returns 0 when the
  /// transcript adds nothing new.
  int add(String transcript) {
    final text = VoiceDhikrMatcher.compact(transcript);
    if (text.isEmpty) return 0;
    final seen = VoiceDhikrMatcher.count(text, dhikrIndex);
    if (seen <= _reported) return 0;
    final delta = seen - _reported;
    _reported = seen;
    return delta;
  }

  /// Starts a fresh listening session.
  void reset() => _reported = 0;
}
