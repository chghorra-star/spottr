/// Decoding helpers for the enum names and JSON lists the local database
/// stores as text.
///
/// Every failure names the column and the offending value. A row Spottr
/// cannot make sense of is a bug or a downgrade, and either way the message
/// has to be enough to tell which.
library;

import 'dart:convert';

/// The enum value called [name], or a [FormatException] naming [column].
T enumByName<T extends Enum>(
  List<T> values,
  String name, {
  required String column,
}) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException(
    'Column $column holds "$name", which is not one of '
    '${values.map((v) => v.name).join(', ')}',
  );
}

/// The enum value called [name], or null if [name] is null.
T? enumByNameOrNull<T extends Enum>(
  List<T> values,
  String? name, {
  required String column,
}) =>
    name == null ? null : enumByName(values, name, column: column);

/// A JSON array of strings.
List<String> decodeStringList(String source, {required String column}) {
  final decoded = _decodeArray(source, column: column);
  return [
    for (final element in decoded)
      if (element is String)
        element
      else
        throw FormatException('Column $column holds a non-string element'),
  ];
}

/// A JSON array of ISO weekday numbers.
Set<int> decodeIntSet(String source, {required String column}) {
  final decoded = _decodeArray(source, column: column);
  return {
    for (final element in decoded)
      if (element is int)
        element
      else
        throw FormatException('Column $column holds a non-integer element'),
  };
}

/// A JSON array of enum names.
///
/// [skipUnknown] decides what an unrecognised name costs. It is false where
/// losing a value would change what Spottr prescribes — an injury, above
/// all — and true where the only cost is one fewer option.
Set<T> decodeEnumSet<T extends Enum>(
  String source,
  List<T> values, {
  required String column,
  bool skipUnknown = false,
}) {
  final names = decodeStringList(source, column: column);
  final decoded = <T>{};
  for (final name in names) {
    final match = values.where((value) => value.name == name).firstOrNull;
    if (match != null) {
      decoded.add(match);
    } else if (!skipUnknown) {
      throw FormatException(
        'Column $column holds "$name", which is not one of '
        '${values.map((v) => v.name).join(', ')}',
      );
    }
  }
  return decoded;
}

/// A JSON array of enum names, in declaration order so the text is stable.
String encodeEnumSet<T extends Enum>(Set<T> value, List<T> values) =>
    jsonEncode([
      for (final candidate in values)
        if (value.contains(candidate)) candidate.name,
    ]);

/// A JSON array of integers, ascending so the text is stable.
String encodeIntSet(Set<int> value) =>
    jsonEncode(value.toList()..sort());

/// A JSON array of strings, in the order given.
String encodeStringList(List<String> value) => jsonEncode(value);

List<Object?> _decodeArray(String source, {required String column}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException('Column $column is not valid JSON: ${error.message}');
  }
  if (decoded is! List) {
    throw FormatException('Column $column is not a JSON array');
  }
  return decoded;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
