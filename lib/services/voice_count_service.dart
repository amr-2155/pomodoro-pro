import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/voice_dhikr_matcher.dart';

/// Where the voice listener currently is. The UI maps this to a compact
/// mic button state + one status line.
enum VoiceCountStatus { idle, starting, listening, unavailable, denied, error }

/// "Say it and it counts" — continuous speech recognition that feeds the
/// existing tasbeeh pipeline.
///
/// Counting rules:
///  * Every result is counted, partial or final. The web build of
///    `speech_to_text` never emits a final result (its web implementation
///    hard-codes `ResultType.partial`), so waiting for finals meant the
///    browser counted nothing at all.
///  * [VoiceCountTracker] de-duplicates, so an utterance that arrives first as
///    a growing partial and then again as a final is still counted once.
///  * One utterance may contain the dhikr several times
///    ("سبحان الله سبحان الله سبحان الله") and each repetition counts.
///  * Arabic is matched through [VoiceDhikrMatcher], which tolerates
///    diacritics, hamza forms and joined words as returned by Google /
///    Web Speech recognizers.
///  * Arabic is always requested explicitly: browsers default the recognizer
///    to their own UI language (usually `en-US`), and `locales()` on the web
///    only ever reports that default — so without an explicit `ar-*` tag an
///    Arabic dhikr can never be recognized.
class VoiceCountService extends ChangeNotifier {
  VoiceCountService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  /// Arabic locales to ask for, most common first.
  static const List<String> _arabicLocales = ['ar-SA', 'ar-EG', 'ar-AE', 'ar'];

  /// Fallback when the device reports no Arabic locale. Both Android and the
  /// browsers will fall back to their default recognizer language if the tag
  /// is unavailable, and if they cannot, `language-not-supported` is surfaced
  /// to the user instead of silently mis-recognizing Arabic.
  static const String _fallbackLocale = 'ar-SA';

  /// Silence before the recognizer session is recycled. Long enough that a
  /// normal breathing pause between repetitions is not cut off.
  static const Duration _pauseFor = Duration(seconds: 10);

  VoiceCountStatus _status = VoiceCountStatus.idle;
  String _transcript = '';
  String? _message;
  bool _initialized = false;
  bool _wantListening = false;
  bool _starting = false;

  /// True between a successful `listen()` and the engine's end event.
  /// Calling `start()` on a browser recognizer that is still active throws
  /// `InvalidStateError`, so this blocks duplicate session starts.
  bool _sessionActive = false;
  int _dhikrIndex = 2;
  String? _localeId;
  void Function(int times)? _onCount;
  Timer? _restartTimer;
  int _restartAttempts = 0;
  VoiceCountTracker _tracker = VoiceCountTracker(2);

  VoiceCountStatus get status => _status;
  String get transcript => _transcript;
  String? get message => _message;
  bool get isListening => _status == VoiceCountStatus.listening;
  bool get isActive =>
      _status == VoiceCountStatus.listening ||
      _status == VoiceCountStatus.starting;

  VoiceCountStatus _failureStatus = VoiceCountStatus.unavailable;

  // ── Public API ────────────────────────────────────────────────

  /// Starts continuous listening. [onCount] is called with the number of
  /// repetitions recognized since the previous call.
  Future<void> start({
    required int dhikrIndex,
    required void Function(int times) onCount,
  }) async {
    _dhikrIndex = dhikrIndex;
    _onCount = onCount;
    _message = null;
    _transcript = '';
    _restartAttempts = 0;
    _wantListening = true;
    _set(VoiceCountStatus.starting);

    final ready = await _ensureReady();
    if (!ready || !_wantListening) {
      if (!ready) _set(_failureStatus);
      return;
    }
    await _startSession();
  }

  /// Stops listening. Safe to call at any time.
  Future<void> stop() async {
    _wantListening = false;
    _sessionActive = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
    if (_status != VoiceCountStatus.unavailable &&
        _status != VoiceCountStatus.denied) {
      _set(VoiceCountStatus.idle);
    }
  }

  /// One-shot test: listens once, returns what was heard and how many times
  /// the dhikr occurred in it.
  ///
  /// Finishes on the first final result, after ~1.2s of silence when only
  /// partial results arrive (the web never sends a final), or after 12s.
  Future<({String heard, int times})> listenOnce({
    required int dhikrIndex,
  }) async {
    _dhikrIndex = dhikrIndex;
    final ready = await _ensureReady();
    if (!ready) return (heard: '', times: 0);

    final completer = Completer<({String heard, int times})>();
    var heard = '';
    Timer? debounce;
    Timer? hardTimeout;

    void finish() {
      if (completer.isCompleted) return;
      debounce?.cancel();
      hardTimeout?.cancel();
      completer.complete((
        heard: heard,
        times: VoiceDhikrMatcher.count(heard, dhikrIndex),
      ));
    }

    // No final result on the web: settle when the transcript stops growing.
    void settle() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 1200), () async {
        try {
          await _speech.stop();
        } catch (_) {}
        finish();
      });
    }

    try {
      await _speech.stop();
    } catch (_) {}

    hardTimeout = Timer(const Duration(seconds: 12), () async {
      try {
        await _speech.stop();
      } catch (_) {}
      finish();
    });

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            heard = text;
            settle();
          }
          if (result.finalResult) finish();
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId ?? _fallbackLocale,
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      finish();
    }

    final value = await completer.future;
    debounce?.cancel();
    hardTimeout.cancel();
    // The one-shot test must not leave the recognizer (and the browser's
    // recording indicator) active behind the continuous session.
    try {
      await _speech.stop();
    } catch (_) {}
    return value;
  }

  @override
  void dispose() {
    _wantListening = false;
    _restartTimer?.cancel();
    try {
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  // ── Internals ─────────────────────────────────────────────────

  Future<bool> _ensureReady() async {
    if (_initialized) return _speech.isAvailable;
    try {
      final ok = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        // Do not let the plugin synthesize a "final" result from the last
        // partial two seconds after a stop: we already count partials, and
        // the synthesized final would arrive during the *next* session.
        finalTimeout: const Duration(milliseconds: 1),
      );
      _initialized = ok;
      if (ok) {
        _localeId = await _resolveLocale();
        return true;
      }
      _failureStatus = VoiceCountStatus.unavailable;
      _message = 'التعرّف على الصوت غير متاح على هذا الجهاز.';
      return false;
    } catch (_) {
      // MissingPluginException on Windows/Linux or blocked browsers.
      _initialized = false;
      _failureStatus = VoiceCountStatus.unavailable;
      _message = 'العدّ الصوتي متاح على أندرويد وآيفون ومتصفح كروم.';
      return false;
    }
  }

  Future<String?> _resolveLocale() async {
    if (_localeId != null) return _localeId;
    if (kIsWeb) {
      // Web Speech starts on the browser UI language and `locales()` only
      // reports that one value, so probing it can never find Arabic. Ask for
      // Arabic directly.
      _localeId = _fallbackLocale;
      return _localeId;
    }
    try {
      final locales = await _speech.locales();
      for (final tag in _arabicLocales) {
        for (final l in locales) {
          if (l.localeId.toLowerCase() == tag.toLowerCase()) {
            _localeId = l.localeId;
            return _localeId;
          }
        }
      }
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('ar')) {
          _localeId = l.localeId;
          return _localeId;
        }
      }
    } catch (_) {}
    _localeId = _fallbackLocale;
    return _localeId;
  }

  Future<void> _startSession() async {
    if (!_wantListening || !_initialized) return;
    // A session is already running (e.g. a duplicate restart request, or a
    // one-shot test that has not finished yet).
    if (_starting || _sessionActive || _speech.isListening) {
      _sessionActive = true;
      _set(VoiceCountStatus.listening);
      return;
    }
    _starting = true;
    _tracker = VoiceCountTracker(_dhikrIndex);
    try {
      await _speech.listen(
        onResult: _handleResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId ?? _fallbackLocale,
          // No `listenFor`: keep listening until the engine recycles itself
          // (silence) or the user turns the mic off.
          pauseFor: _pauseFor,
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
      _sessionActive = true;
      if (_wantListening) {
        _set(VoiceCountStatus.listening);
      }
    } catch (_) {
      _sessionActive = false;
      if (!_wantListening) return;
      // Calling start() on an already-active recognizer is not fatal.
      if (_speech.isListening) return;
      _restartAttempts++;
      if (_restartAttempts >= 5) {
        _message = 'تعذّر تشغيل المايك. جرّب تحديث الصفحة أو إعادة فتح التطبيق.';
        _stopWith(VoiceCountStatus.error);
        return;
      }
      _scheduleRestartIfNeeded(
        delay: Duration(milliseconds: 400 + 200 * _restartAttempts),
      );
    } finally {
      _starting = false;
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    // Late results can arrive after the user turned the mic off or after a
    // fatal error; they must not be counted.
    if (!_wantListening) return;
    final heard = result.recognizedWords.trim();
    if (heard.isEmpty) return;

    _transcript = heard;
    // Any result proves the session is alive: allow future restarts.
    _restartAttempts = 0;

    final added = _tracker.add(heard);
    if (added > 0) {
      _message = '✓ ${VoiceDhikrMatcher.normalize(heard)}';
      _onCount?.call(added);
    } else if (result.finalResult && _tracker.total == 0) {
      // A finalized utterance that counted nothing: explain why, once.
      final match = VoiceDhikrMatcher.detect(heard);
      _message = match != null
          ? 'سمعت ذكرًا مختلفًا — اختر الذكر الصحيح أو أعد المحاولة.'
          : 'لم أسمع الذكر بوضوح… ارفع صوتك قليلًا.';
    }
    notifyListeners();
  }

  void _handleStatus(String status) {
    if (!_wantListening) return;
    if (status == 'listening') {
      _restartAttempts = 0;
      _set(VoiceCountStatus.listening);
    } else if (status == 'done' ||
        status == 'notListening' ||
        status == 'doneNoResult') {
      // The engine ended this session; a fresh `listen()` is allowed now.
      _sessionActive = false;
      _scheduleRestartIfNeeded(delay: const Duration(milliseconds: 350));
    }
  }

  void _handleError(SpeechRecognitionError error) {
    if (!_wantListening) return;
    final code = error.errorMsg.toLowerCase();

    // Silence / no match: recycle quietly.
    if (code.contains('no_match') ||
        code.contains('no-speech') ||
        code.contains('speech_timeout') ||
        code == 'aborted') {
      _scheduleRestartIfNeeded(delay: const Duration(milliseconds: 400));
      return;
    }

    if (code.contains('network')) {
      _message = 'العدّ الصوتي بيحتاج إنترنت على الجهاز ده — اتأكد من الاتصال.';
      _stopWith(VoiceCountStatus.error);
      return;
    }

    if (code.contains('permission') ||
        code == 'not-allowed' ||
        code == 'service-not-allowed') {
      _message = 'لازم تسمح للمتصفح/التطبيق باستخدام المايك.';
      _stopWith(VoiceCountStatus.denied);
      return;
    }

    if (code.contains('language_not_available') ||
        code.contains('language_unavailable') ||
        code == 'language-not-supported') {
      _message =
          'التعرّف على العربي مش متاح على الجهاز ده — ثبّت اللغة العربية أو جرّب كروم.';
      _stopWith(VoiceCountStatus.unavailable);
      return;
    }

    if (code == 'audio-capture' || code.contains('audio_error')) {
      _message = 'مش لاقي مايك شغّال — وصّل مايك وجرّب تاني.';
      _stopWith(VoiceCountStatus.error);
      return;
    }

    if (error.permanent) {
      _message = 'توقّف المايك: ${error.errorMsg}';
      _stopWith(VoiceCountStatus.error);
      return;
    }

    _scheduleRestartIfNeeded(delay: const Duration(milliseconds: 500));
  }

  void _scheduleRestartIfNeeded({Duration delay = Duration.zero}) {
    if (!_wantListening || !_initialized) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(delay, () async {
      if (!_wantListening || !_initialized) return;
      // Restarts that keep failing (no listening status, no results) are
      // bounded; a healthy session resets the counter on every result.
      if (_restartAttempts >= 6) {
        _message = 'توقّف الاستماع — اضغط المايك للتشغيل من جديد.';
        _wantListening = false;
        _set(VoiceCountStatus.idle);
        return;
      }
      await _startSession();
    });
  }

  void _stopWith(VoiceCountStatus status) {
    _wantListening = false;
    _sessionActive = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    // Release the microphone so the browser stops showing the recording dot.
    try {
      _speech.cancel();
    } catch (_) {}
    _set(status);
  }

  void _set(VoiceCountStatus status) {
    _status = status;
    notifyListeners();
  }
}
