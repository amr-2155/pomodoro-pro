import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/widgets/completion_celebration.dart';

// The reflection strip shows planned vs actual elapsed time after a
// session. The decision of WHETHER to show is pure logic, so it is tested
// here as a unit (no widget inflation, no FakeAsync pitfalls).
void main() {
  group('SessionReflection.compare', () {
    test('returns null when actual time is unknown', () {
      expect(
        SessionReflection.compare(plannedMinutes: 25, actualMinutes: null),
        isNull,
      );
    });

    test('returns null when planned is invalid', () {
      expect(
        SessionReflection.compare(plannedMinutes: 0, actualMinutes: 30),
        isNull,
      );
    });

    test('returns null when the difference is noise (<4% and <1 min)', () {
      // planned 25, actual 25 -> identical
      expect(
        SessionReflection.compare(plannedMinutes: 25, actualMinutes: 25),
        isNull,
      );
      // planned 50, one minute over is 2% -> noise
      expect(
        SessionReflection.compare(plannedMinutes: 50, actualMinutes: 50),
        isNull,
      );
    });

    test('ran long by more than one minute -> reflection surfaced', () {
      final r = SessionReflection.compare(plannedMinutes: 25, actualMinutes: 30);
      expect(r, isNotNull);
      expect(r!.ranLong, isTrue);
      expect(r.deltaMinutes, 5);
      expect(r.ranFullLength, isFalse);
    });

    test('finished faster -> reflection surfaced, not ranLong', () {
      final r = SessionReflection.compare(plannedMinutes: 25, actualMinutes: 20);
      expect(r, isNotNull);
      expect(r!.ranLong, isFalse);
      expect(r.deltaMinutes, -5);
    });

    test('took at least double the plan -> ranFullLength', () {
      final r = SessionReflection.compare(plannedMinutes: 10, actualMinutes: 21);
      expect(r, isNotNull);
      expect(r!.ranFullLength, isTrue);
    });
  });
}
