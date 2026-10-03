import 'package:flutter/services.dart';

/// Helpers so every number field in the app accepts Arabic-Indic digits
/// (٠١٢٣٤٥٦٧٨٩), Persian digits (۰۱۲۳۴۵۶۷۸۹) and Latin digits (0-9),
/// while free-text fields (names, tasks, quotes...) accept Arabic,
/// English, numbers and letters with no restriction.

// Arabic-Indic digits U+0660..U+0669, Persian digits U+06F0..U+06F9.
const String _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Converts any Arabic-Indic / Persian digits in [input] to Latin digits.
String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final arIndex = _arabicIndicDigits.indexOf(char);
    if (arIndex >= 0) {
      buffer.write(arIndex);
      continue;
    }
    final faIndex = _persianDigits.indexOf(char);
    if (faIndex >= 0) {
      buffer.write(faIndex);
      continue;
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Parses an int after normalizing Arabic/Persian digits. Returns null
/// when the text is not a valid positive integer.
int? parseLocalizedInt(String raw) {
  final normalized = normalizeDigits(raw.trim());
  if (normalized.isEmpty) return null;
  final value = int.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return value;
}

/// Parses a double after normalizing Arabic/Persian digits and accepting
/// both '.' and ',' as decimal separators. Returns null when invalid.
double? parseLocalizedDouble(String raw) {
  final normalized = normalizeDigits(raw.trim()).replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

class AppInputFormatters {
  /// Like [FilteringTextInputFormatter.digitsOnly] but also allows
  /// Arabic-Indic and Persian digits so users can type in either language.
  static final TextInputFormatter digitsOnlyLocalized =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'));

  /// For decimal fields (speed, minutes): localized digits plus '.' and ','.
  static final TextInputFormatter decimalLocalized =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]'));
}
