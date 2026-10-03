/// Pure, dependency-free math for the ذِكر time calculator.
/// Separated from the UI so every formula is unit-testable.
class DurationParts {
  final int minutes;
  final int seconds;
  const DurationParts(this.minutes, this.seconds);

  @override
  bool operator ==(Object other) =>
      other is DurationParts &&
      other.minutes == minutes &&
      other.seconds == seconds;

  @override
  int get hashCode => Object.hash(minutes, seconds);

  @override
  String toString() => 'DurationParts($minutes, $seconds)';
}

class DhikrCalculator {
  DhikrCalculator._();

  static bool _validReps(int repetitions) => repetitions > 0;
  static bool _validSpeed(double secondsPerRep) =>
      secondsPerRep.isFinite && secondsPerRep > 0;

  /// Mode A: time (seconds) needed for [repetitions] at [secondsPerRep].
  /// Returns 0 when inputs are invalid (never divides by zero, never
  /// produces negative or NaN results).
  static double estimateSeconds({
    required int repetitions,
    required double secondsPerRep,
  }) {
    if (!_validReps(repetitions) || !_validSpeed(secondsPerRep)) return 0;
    return repetitions * secondsPerRep;
  }

  /// Mode B: how many repetitions fit in [availableSeconds] at the
  /// given speed. Floor keeps the answer conservative; 0 when invalid.
  static int estimateRepetitions({
    required double availableSeconds,
    required double secondsPerRep,
  }) {
    if (!availableSeconds.isFinite ||
        availableSeconds <= 0 ||
        !_validSpeed(secondsPerRep)) {
      return 0;
    }
    return (availableSeconds / secondsPerRep).floor();
  }

  /// Personal speed measurement: average seconds per repetition.
  static double measureAverage({
    required int measuredRepetitions,
    required double totalSeconds,
  }) {
    if (!_validReps(measuredRepetitions) ||
        !totalSeconds.isFinite ||
        totalSeconds <= 0) {
      return 0;
    }
    return totalSeconds / measuredRepetitions;
  }

  /// Splits a total of seconds into whole minutes + remaining seconds.
  static DurationParts splitDuration(double totalSeconds) {
    if (!totalSeconds.isFinite || totalSeconds <= 0) {
      return const DurationParts(0, 0);
    }
    final rounded = totalSeconds.round();
    return DurationParts(rounded ~/ 60, rounded % 60);
  }

  /// Human-readable Arabic duration, e.g. "5 دقائق" / "20 دقيقة و50 ثانية".
  static String formatDuration(double totalSeconds) {
    if (!totalSeconds.isFinite || totalSeconds <= 0) return '—';
    final parts = splitDuration(totalSeconds);
    final texts = <String>[];
    if (parts.minutes > 0) {
      texts.add(_plural(parts.minutes, 'دقيقة', 'دقيقتان', 'دقائق'));
    }
    if (parts.seconds > 0) {
      texts.add(_plural(parts.seconds, 'ثانية', 'ثانيتان', 'ثوانٍ'));
    }
    return texts.isEmpty ? 'أقل من ثانية' : texts.join(' و');
  }

  /// Formats a seconds-per-repetition value, e.g. 2.8 → "2.8 ثانية".
  static String formatSpeed(double secondsPerRep) {
    if (!secondsPerRep.isFinite || secondsPerRep <= 0) return '—';
    final text = secondsPerRep == secondsPerRep.roundToDouble()
        ? secondsPerRep.toStringAsFixed(0)
        : secondsPerRep.toStringAsFixed(1);
    return '$text ثانية';
  }

  static String _plural(int n, String single, String dual, String threePlus) {
    if (n == 1) return '1 $single';
    if (n == 2) return dual;
    if (n >= 3 && n <= 10) return '$n $threePlus';
    return '$n $single';
  }
}
