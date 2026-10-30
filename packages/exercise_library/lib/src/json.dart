/// Parsing helpers shared by the catalog's JSON support.
///
/// Every failure names the field and the offending value, because a typo in
/// hand-authored catalog data should be obvious from the message alone.
library;

/// Parses [raw] as one of [values] by enum name.
T parseEnum<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is! String) {
    throw FormatException('$field: expected a string, got ${raw.runtimeType}');
  }
  for (final value in values) {
    if (value.name == raw) return value;
  }
  final allowed = values.map((v) => v.name).join(', ');
  throw FormatException('$field: unknown value "$raw". Expected one of: $allowed');
}

/// Parses [raw] as a set of enum values by name.
Set<T> parseEnumSet<T extends Enum>(
  List<T> values,
  Object? raw,
  String field,
) {
  if (raw == null) return {};
  if (raw is! List) {
    throw FormatException('$field: expected a list, got ${raw.runtimeType}');
  }
  return raw
      .map((item) => parseEnum(values, item, field))
      .toSet();
}

/// Parses [raw] as a list of strings.
List<String> parseStringList(Object? raw, String field) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw FormatException('$field: expected a list, got ${raw.runtimeType}');
  }
  return raw.map((item) {
    if (item is! String) {
      throw FormatException('$field: expected strings, got ${item.runtimeType}');
    }
    return item;
  }).toList();
}

/// Parses [raw] as a required string.
String parseString(Object? raw, String field) {
  if (raw is! String) {
    throw FormatException('$field: expected a string, got ${raw.runtimeType}');
  }
  return raw;
}

/// Parses [raw] as a number, accepting ints for doubles.
double parseDouble(Object? raw, String field, {double? fallback}) {
  if (raw == null && fallback != null) return fallback;
  if (raw is num) return raw.toDouble();
  throw FormatException('$field: expected a number, got ${raw.runtimeType}');
}

/// Parses [raw] as a bool, defaulting to [fallback] when absent.
bool parseBool(Object? raw, String field, {bool fallback = false}) {
  if (raw == null) return fallback;
  if (raw is bool) return raw;
  throw FormatException('$field: expected a bool, got ${raw.runtimeType}');
}
