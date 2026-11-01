import 'dart:convert';
import 'dart:io';

import 'fixture.dart';

/// Loads fixtures from a file or a directory of `.json` files.
///
/// Sorted by name so a run is reproducible and two runs are comparable: a
/// report whose rows move around between runs is one nobody will diff.
List<PoseFixture> loadFixtures(String path) {
  final file = File(path);
  if (file.existsSync()) return [loadFixture(file)];

  final directory = Directory(path);
  if (!directory.existsSync()) {
    throw FileSystemException('no such file or directory', path);
  }

  final files = directory
      .listSync()
      .whereType<File>()
      .where((entry) => entry.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return [for (final entry in files) loadFixture(entry)];
}

/// Reads one fixture, naming the file in anything that goes wrong.
///
/// A fixture is data somebody recorded hours of video for, so a failure has
/// to say which file is at fault rather than reporting a decode error from
/// somewhere in a directory.
PoseFixture loadFixture(File file) {
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  }

  if (decoded is! Map<String, Object?>) {
    throw FormatException(
      '${file.path}: expected a fixture object, got ${decoded.runtimeType}',
    );
  }

  try {
    return PoseFixture.fromJson(decoded);
  } on FormatException catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  }
}

/// Writes [fixture] to `<directory>/<name>.json`.
///
/// Used by the extractor when it turns a video into landmarks, and by hand
/// when a synthetic case turns out to be worth keeping.
File writeFixture(PoseFixture fixture, String directory) {
  final file = File('$directory/${fixture.name}.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(fixture.toJson()));
  return file;
}
