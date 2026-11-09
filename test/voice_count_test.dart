import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/services/voice_count_service.dart';
import 'package:pomodoro_app/utils/voice_dhikr_matcher.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Index 2 = «سبحان الله» in TasbeehService.dhikrOptions.
const int subhanAllah = 2;

void main() {
  group('VoiceDhikrMatcher.normalize', () {
    test('يشيل التشكيل ويوحّد الألف والهمزات', () {
      expect(
        VoiceDhikrMatcher.normalize('سُبْحَانَ اللَّهِ'),
        'سبحان الله',
      );
      expect(VoiceDhikrMatcher.normalize('أستغفر الله'), 'استغفر الله');
    });

    test('يحوّل التاء المربوطة لهاء ويحذف التطويل', () {
      expect(VoiceDhikrMatcher.normalize('رحمــة'), 'رحمه');
    });
  });

  group('VoiceDhikrMatcher.count', () {
    test('يعدّ التكرار داخل نفس الجملة', () {
      expect(
        VoiceDhikrMatcher.count('سبحان الله سبحان الله سبحان الله', subhanAllah),
        3,
      );
    });

    test('يتعامل مع الكلمات الملتصقة كما يرجعها المحرك', () {
      expect(VoiceDhikrMatcher.count('سبحانالله', subhanAllah), 1);
    });

    test('لا يعدّ ذكرًا آخر', () {
      expect(VoiceDhikrMatcher.count('الحمد لله', subhanAllah), 0);
    });

    test('يتحمل أخطاء التعرّف من بعيد (سحبان / صبحان)', () {
      expect(VoiceDhikrMatcher.count('سحبان الله', subhanAllah), 1);
      expect(VoiceDhikrMatcher.count('صبحان الله', subhanAllah), 1);
      expect(VoiceDhikrMatcher.count('سبحن الله', subhanAllah), 1);
    });

    test('لا يقبل أبعد من خطأين', () {
      expect(VoiceDhikrMatcher.count('كزبان قلّة', subhanAllah), 0);
      expect(VoiceDhikrMatcher.count('xyz', subhanAllah), 0);
    });

    test('عبارات السياق موجودة لكل ذكر', () {
      for (var i = 0; i < 6; i++) {
        expect(VoiceDhikrMatcher.biasPhrases(i), isNotEmpty);
      }
    });
  });

  group('VoiceCountTracker', () {
    test('النتيجة الجزئية المتزايدة تُحسب مرة واحدة فقط', () {
      final tracker = VoiceCountTracker(subhanAllah);

      expect(tracker.add('سبحان'), 1);
      expect(tracker.add('سبحان الله'), 0);
      expect(tracker.add('سبحان الله'), 0);
      expect(tracker.total, 1);
    });

    test('التكرار التالي يضيف واحدًا فقط', () {
      final tracker = VoiceCountTracker(subhanAllah);

      expect(tracker.add('سبحان الله'), 1);
      expect(tracker.add('سبحان الله سبحان'), 1);
      expect(tracker.add('سبحان الله سبحان الله'), 0);
      expect(tracker.total, 2);
    });

    test('النتيجة النهائية التي تكرر الجزئية لا تُحسب مرتين', () {
      final tracker = VoiceCountTracker(subhanAllah);

      expect(tracker.add('سبحان الله'), 1);
      expect(tracker.add('سبحان الله'), 0);
      expect(tracker.total, 1);
    });

    test('إعادة صياغة النص لا تُنقص ولا تُضاعف العد', () {
      final tracker = VoiceCountTracker(subhanAllah);

      expect(tracker.add('سبحان الله'), 1);
      expect(tracker.add('سبحان الله وبحمده'), 0);
      expect(tracker.add('سبحان الله'), 0);
      expect(tracker.total, 1);
    });

    test('نص فاضي لا يعدّ شيئًا', () {
      final tracker = VoiceCountTracker(subhanAllah);
      expect(tracker.add(''), 0);
      expect(tracker.add('   '), 0);
      expect(tracker.total, 0);
    });

    test('reset يبدأ جلسة استماع جديدة من صفر', () {
      final tracker = VoiceCountTracker(subhanAllah);

      expect(tracker.add('سبحان الله'), 1);
      tracker.reset();
      expect(tracker.total, 0);
      expect(tracker.add('سبحان الله'), 1);
    });
  });

  group('VoiceCountService (منصة ترسل نتائج جزئية فقط)', () {
    test('العد يشتغل بدون أي نتيجة نهائية — سلوك Web Speech API', () async {
      final speech = _FakeSpeech();
      final service = VoiceCountService(speech: speech);
      var counted = 0;

      await service.start(
        dhikrIndex: subhanAllah,
        onCount: (times) => counted += times,
      );

      // The browser plugin always reports `ResultType.partial`.
      speech.emit('سبحان');
      speech.emit('سبحان الله');
      speech.emit('سبحان الله', finalResult: true);

      expect(counted, 1, reason: 'التكرار الواحد لازم يتحسب مرة واحدة');

      speech.emit('سبحان الله سبحان الله');
      expect(counted, 2);

      service.dispose();
    });

    test('يطلب لغة عربية صريحة حتى لو كانت لغة الجهاز إنجليزية', () async {
      final speech =
          _FakeSpeech(availableLocales: [LocaleName('en_US', 'English')]);
      final service = VoiceCountService(speech: speech);

      await service.start(dhikrIndex: subhanAllah, onCount: (_) {});

      expect(speech.lastLocale, 'ar-SA');

      service.dispose();
    });

    test('يستخدم لغة عربية الجهاز لو متاحة', () async {
      final speech =
          _FakeSpeech(availableLocales: [LocaleName('ar_EG', 'Arabic')]);
      final service = VoiceCountService(speech: speech);

      await service.start(dhikrIndex: subhanAllah, onCount: (_) {});

      expect(speech.lastLocale, 'ar_EG');

      service.dispose();
    });

    test('نتيجة متأخرة بعد إيقاف المايك لا تُحسب', () async {
      final speech = _FakeSpeech();
      final service = VoiceCountService(speech: speech);
      var counted = 0;

      await service.start(
        dhikrIndex: subhanAllah,
        onCount: (times) => counted += times,
      );
      await service.stop();
      speech.emit('سبحان الله');

      expect(counted, 0);

      service.dispose();
    });
  });
}

/// A recognizer that behaves like the Web Speech API: results are only ever
/// delivered as partials.
class _FakeSpeech extends SpeechToText {
  _FakeSpeech({List<LocaleName>? availableLocales})
      : availableLocales = availableLocales ?? [LocaleName('en_US', 'English')],
        super.withMethodChannel();

  final List<LocaleName> availableLocales;
  SpeechResultListener? _listener;

  String? lastLocale;
  bool _listening = false;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = const Duration(seconds: 2),
    List<SpeechConfigOption>? options,
  }) async =>
      true;

  @override
  Future<List<LocaleName>> locales() async => availableLocales;

  @override
  Future listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    lastLocale = listenOptions?.localeId ?? localeId;
    _listener = onResult;
    _listening = true;
    return true;
  }

  @override
  Future<void> stop() async => _listening = false;

  @override
  Future<void> cancel() async => _listening = false;

  void emit(String text, {bool finalResult = false}) {
    _listener?.call(SpeechRecognitionResult(
      [SpeechRecognitionWords(text, null, 1.0)],
      finalResult ? ResultType.finalResult.value : ResultType.partial.value,
    ));
  }
}
