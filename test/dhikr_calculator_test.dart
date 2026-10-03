import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/utils/dhikr_calculator.dart';

void main() {
  group('DhikrCalculator.estimateSeconds (الوضع أ: كم يستغرق؟)', () {
    test('100 تكرار × 3 ث = 300 ثانية', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 100, secondsPerRep: 3),
        300,
      );
    });

    test('300 تكرار × 3 ث = 900 ثانية', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 300, secondsPerRep: 3),
        900,
      );
    });

    test('500 تكرار × 2.5 ث = 1250 ثانية', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 500, secondsPerRep: 2.5),
        1250,
      );
    });

    test('1000 تكرار × 3 ث = 3000 ثانية', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 1000, secondsPerRep: 3),
        3000,
      );
    });

    test('يعيد 0 مع تكرارات صفرية أو سالبة', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 0, secondsPerRep: 3),
        0,
      );
      expect(
        DhikrCalculator.estimateSeconds(repetitions: -5, secondsPerRep: 3),
        0,
      );
    });

    test('يعيد 0 مع سرعة صفرية أو سالبة', () {
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 100, secondsPerRep: 0),
        0,
      );
      expect(
        DhikrCalculator.estimateSeconds(repetitions: 100, secondsPerRep: -1),
        0,
      );
      expect(
        DhikrCalculator.estimateSeconds(
            repetitions: 100, secondsPerRep: double.nan),
        0,
      );
    });

    test('لا ينتج NaN أبدًا', () {
      final value =
          DhikrCalculator.estimateSeconds(repetitions: 100, secondsPerRep: 0);
      expect(value.isNaN, isFalse);
      expect(value.isInfinite, isFalse);
    });
  });

  group('DhikrCalculator.estimateRepetitions (الوضع ب: كم مرة؟)', () {
    test('10 دقائق بسرعة 3 ث = 200 مرة', () {
      expect(
        DhikrCalculator.estimateRepetitions(
          availableSeconds: 600,
          secondsPerRep: 3,
        ),
        200,
      );
    });

    test('30 ثانية بسرعة 2.5 ث = 12 مرة (تقريب للأسفل)', () {
      expect(
        DhikrCalculator.estimateRepetitions(
          availableSeconds: 30,
          secondsPerRep: 2.5,
        ),
        12,
      );
    });

    test('5 دقائق بسرعة 10 ث = 30 مرة', () {
      expect(
        DhikrCalculator.estimateRepetitions(
          availableSeconds: 300,
          secondsPerRep: 10,
        ),
        30,
      );
    });

    test('يعيد 0 مع مدة صفرية أو سرعة صفرية', () {
      expect(
        DhikrCalculator.estimateRepetitions(
          availableSeconds: 0,
          secondsPerRep: 3,
        ),
        0,
      );
      expect(
        DhikrCalculator.estimateRepetitions(
          availableSeconds: 600,
          secondsPerRep: 0,
        ),
        0,
      );
    });
  });

  group('DhikrCalculator.measureAverage (قياس السرعة الفعلية)', () {
    test('10 تكرارات في 28 ثانية = 2.8 ثانية/تكرار', () {
      expect(
        DhikrCalculator.measureAverage(
          measuredRepetitions: 10,
          totalSeconds: 28,
        ),
        closeTo(2.8, 1e-9),
      );
    });

    test('33 تكرار في 99 ثانية = 3 ثانية/تكرار', () {
      expect(
        DhikrCalculator.measureAverage(
          measuredRepetitions: 33,
          totalSeconds: 99,
        ),
        closeTo(3, 1e-9),
      );
    });

    test('يعيد 0 عند عدّ صفري', () {
      expect(
        DhikrCalculator.measureAverage(
          measuredRepetitions: 0,
          totalSeconds: 10,
        ),
        0,
      );
    });
  });

  group('DhikrCalculator.splitDuration / formatDuration', () {
    test('300 ثانية = 5 دقائق', () {
      expect(DhikrCalculator.splitDuration(300), const DurationParts(5, 0));
      expect(DhikrCalculator.formatDuration(300), '5 دقائق');
    });

    test('900 ثانية = 15 دقيقة', () {
      expect(DhikrCalculator.splitDuration(900), const DurationParts(15, 0));
      expect(DhikrCalculator.formatDuration(900), '15 دقيقة');
    });

    test('1250 ثانية = 20 دقيقة و50 ثانية', () {
      expect(
        DhikrCalculator.splitDuration(1250),
        const DurationParts(20, 50),
      );
      expect(DhikrCalculator.formatDuration(1250), '20 دقيقة و50 ثانية');
    });

    test('3000 ثانية = 50 دقيقة', () {
      expect(
        DhikrCalculator.splitDuration(3000),
        const DurationParts(50, 0),
      );
      expect(DhikrCalculator.formatDuration(3000), '50 دقيقة');
    });

    test('99 ثانية = دقيقة و39 ثانية', () {
      expect(DhikrCalculator.formatDuration(99), '1 دقيقة و39 ثانية');
    });

    test('قيم غير صالحة معروضة بـ —', () {
      expect(DhikrCalculator.formatDuration(0), '—');
      expect(DhikrCalculator.formatDuration(double.nan), '—');
    });

    test('formatSpeed بتنسيق 2.8 ثانية', () {
      expect(DhikrCalculator.formatSpeed(2.8), '2.8 ثانية');
      expect(DhikrCalculator.formatSpeed(3), '3 ثانية');
    });
  });
}
