/// Null-safe readers for backend JSON.
///
/// The backend serialises SQLAlchemy rows directly, so fields can be missing,
/// null, or (for SQLite type affinity) a number where a string is expected.
/// Every model parses through these helpers instead of hard casts.
library;

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(asMap).toList();
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? asDouble(Object? value) {
  if (value is bool) return null;
  if (value is num) {
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }
  if (value is String) {
    final d = double.tryParse(value.trim());
    return (d != null && d.isFinite) ? d : null;
  }
  return null;
}

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

/// Non-empty trimmed string or null.
String? asText(Object? value) {
  final s = asString(value)?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

bool? asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return null;
}

/// Parses a backend timestamp.
///
/// The backend stores naive UTC (`datetime.utcnow()`) and FastAPI renders it
/// without an offset, e.g. `2026-10-26T11:29:49.082995`. Dart would read that
/// as *local* time, so a missing offset is treated as UTC.
DateTime? parseServerDate(Object? value) {
  final text = asText(value);
  if (text == null) return null;

  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(text);
  final normalized = hasZone ? text : '${text.replaceFirst(' ', 'T')}Z';
  return DateTime.tryParse(normalized)?.toUtc();
}
