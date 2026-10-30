import 'package:intl/intl.dart';

/// Display helpers. All server times are UTC and shown in the phone's local
/// time zone.
class Fmt {
  Fmt._();

  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _shortDay = DateFormat('M/d');

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value.toLocal());

  static String shortDay(DateTime? value) =>
      value == null ? '' : _shortDay.format(value.toLocal());

  /// "just now", "5 min ago", "3 h ago", "2 days ago".
  static String ago(DateTime? value, {DateTime? now}) {
    if (value == null) return 'never';
    final diff = (now ?? DateTime.now().toUtc()).difference(value.toUtc());
    if (diff.isNegative || diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }

  /// Formats a reading: integers without decimals, otherwise 1–2 decimals.
  static String number(double? value, {int decimals = 1}) {
    if (value == null) return '—';
    if (value == value.roundToDouble() && value.abs() < 1e9) {
      return NumberFormat.decimalPattern().format(value.round());
    }
    return NumberFormat.decimalPatternDigits(decimalDigits: decimals)
        .format(value);
  }

  static String withUnit(double? value, String? unit, {int decimals = 1}) {
    final n = number(value, decimals: decimals);
    if (value == null || unit == null || unit.trim().isEmpty) return n;
    return '$n ${unit.trim()}';
  }
}
