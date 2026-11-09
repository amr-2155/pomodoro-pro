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
      'استغفراللهالعظيم',
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
      'سبحاناللهالعظيم',
      'سبحاناللهوبحمدهسبحاناللهالعظيم',
      'سبحان',
    ],
    // الحمد لله
    3: [
      'الحمدلله',
      'الحمدللهربالعالمين',
      'الحمدللهعلىكلحال',
      'الحمد',
    ],
    // الله أكبر
    4: [
      'اللهكبر',
      'اللهاكبر',
      'اللهواكبر',
      'اللهواكبروللهالحمد',
    ],
    // لا إله إلا الله
    5: [
      'لاالهالاالله',
      'لاالهالااللهوحدهلاشريكله',
      'لاالهالااللهالملكالحقالمبين',
      'لاالهالا',
    ],
  };

  /// Spaced phrases to bias Android (API 33+) and iOS recognition toward
  /// the dhikr. Improves accuracy for quiet/far speech; ignored elsewhere.
  static const Map<int, List<String>> _biasPhrases = {
    0: ['أستغفر الله', 'استغفر الله', 'أستغفر الله ربي', 'أستغفر الله العظيم'],
    1: [
      'اللهم صل على محمد',
      'اللهم صلي على محمد',
      'صلى الله على محمد',
      'صل الله على محمد'
    ],
    2: ['سبحان الله', 'سبحان الله وبحمده', 'سبحان الله العظيم'],
    3: ['الحمد لله', 'الحمد لله رب العالمين', 'الحمد لله على كل حال'],
    4: ['الله أكبر', 'الله اكبر', 'الله أكبر ولله الحمد'],
    5: [
      'لا إله إلا الله',
      'لا اله الا الله',
      'لا إله إلا الله وحده لا شريك له'
    ],
  };

  /// Phrases to feed the recognizer as domain hints for [dhikrIndex].
  static List<String> biasPhrases(int dhikrIndex) =>
      _biasPhrases[dhikrIndex] ?? const [];

  /// Strips diacritics/tatweel, unifies letter forms and keeps Arabic
  /// letters only, then collapses whitespace.
  static String normalize(String input) {
    var s = input;
    // Diacritics, sukun, dagger alif, tatweel (full harakat range).
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
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
    if (best > 0) return best;
    // Far / noisy speech often produces a 1–2 letter recognition error
    // (e.g. «سحبان الله» for «سبحان الله»). Fall back to approximate
    // matching so a quiet repetition is never silently missed.
    for (final variant in list) {
      if (variant.isEmpty || variant.length < 5) continue;
      final allowed = variant.length >= 9 ? 2 : 1;
      final n = _countFuzzy(text, variant, allowed);
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

  /// Approximate occurrence count for noisy transcripts: finds windows
  /// whose edit distance to [needle] is within [maxDistance].
  static int _countFuzzy(String haystack, String needle, int maxDistance) {
    var count = 0;
    var from = 0;
    final needleLen = needle.length;
    while (from < haystack.length) {
      var bestIndex = -1;
      var bestDist = maxDistance + 1;
      var bestLen = needleLen;
      for (var windowLen = needleLen - maxDistance;
          windowLen <= needleLen + maxDistance;
          windowLen++) {
        if (windowLen <= 0) continue;
        for (var i = from; i + windowLen <= haystack.length; i++) {
          final window = haystack.substring(i, i + windowLen);
          final dist = _editDistanceAtMost(window, needle, maxDistance);
          if (dist != null && dist < bestDist) {
            bestDist = dist;
            bestIndex = i;
            bestLen = windowLen;
            if (dist == 0) break;
          }
        }
        if (bestDist == 0) break;
      }
      if (bestIndex < 0) break;
      count++;
      from = bestIndex + bestLen;
    }
    return count;
  }

  /// Levenshtein distance, returning `null` when it exceeds [atMost].
  /// Early-exits as soon as the minimal possible distance is exceeded
  /// that budget, so long windows stay fast.
  static int? _editDistanceAtMost(String a, String b, int atMost) {
    if ((a.length - b.length).abs() > atMost) return null;
    var prev = List<int>.generate(b.length + 1, (j) => j);
    var cur = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      cur[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var v = prev[j] + 1;
        final del = cur[j - 1] + 1;
        if (del < v) v = del;
        final sub = prev[j - 1] + cost;
        if (sub < v) v = sub;
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > atMost) return null;
      final tmp = prev;
      prev = cur;
      cur = tmp;
    }
    final d = prev[b.length];
    return d <= atMost ? d : null;
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
