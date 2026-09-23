import '../services/database_service.dart';

/// Digits stay Latin everywhere per design spec ("50 دقيقة" not "٥٠ دقيقة").
/// Kept as identity so every existing call site remains valid.
String toArabicNumerals(String input) => input;

String formatDurationLocalized({
  required int hours,
  required int minutes,
  required int seconds,
}) {
  final isAr = DatabaseService.localeNotifier.value.languageCode == 'ar';
  final parts = <String>[];
  if (hours > 0) {
    parts.add(isAr ? '$hours ساعة' : '$hours h');
  }
  if (minutes > 0) {
    parts.add(isAr ? '$minutes دقيقة' : '$minutes min');
  }
  if (seconds > 0 || parts.isEmpty) {
    parts.add(isAr ? '$seconds ثانية' : '$seconds s');
  }
  final joined = isAr ? parts.join(' و ') : parts.join(' ');
  return toArabicNumerals(joined);
}

/// Smart human duration for goal values:
/// 25 -> "25 دقيقة" / "25 minutes"
/// 60 -> "1 ساعة"   / "1 hour"
/// 85 -> "1 ساعة و25 دقيقة" / "1 hour 25 minutes"
String formatMinutesSmart(int totalMinutes) {
  final isAr = DatabaseService.localeNotifier.value.languageCode == 'ar';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;

  String hourPart;
  String minPart;
  if (isAr) {
    hourPart = h == 1 ? 'ساعة' : '$h ساعات';
    minPart = '$m دقيقة';
  } else {
    hourPart = h == 1 ? 'hour' : 'hours';
    minPart = m == 1 ? 'minute' : 'minutes';
  }

  String result;
  if (h == 0) {
    result = isAr ? minPart : (m == 1 ? '1 minute' : '$m minutes');
  } else if (m == 0) {
    result = isAr ? hourPart : '$h $hourPart';
  } else {
    result = isAr
        ? '$hourPart و$minPart'
        : '${h == 1 ? '1' : h} $hourPart $m $minPart';
  }
  return toArabicNumerals(result);
}

/// Compact form for progress rows: "420 / 600 دقيقة".
String formatMinutesCompact(int totalMinutes) {
  final isAr = DatabaseService.localeNotifier.value.languageCode == 'ar';
  return toArabicNumerals(
      isAr ? '$totalMinutes دقيقة' : '$totalMinutes min');
}

/// Short unit label: "45 د" / "45min".
String fmtMin(int minutes) {
  final isAr = DatabaseService.localeNotifier.value.languageCode == 'ar';
  return isAr ? '$minutes د' : '${minutes}min';
}
