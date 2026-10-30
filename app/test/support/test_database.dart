import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:spottr/data/local/database.dart';
import 'package:sqlite3/open.dart';

bool _configured = false;

/// Unit tests run on the host Dart VM, where `sqlite3_flutter_libs` is not
/// loaded. Windows ships `winsqlite3.dll` as part of the OS; Linux and macOS
/// resolve the usual sonames without help.
void configureSqliteForTests() {
  if (_configured) return;
  _configured = true;
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
}

/// A fresh in-memory database per test.
AppDatabase openTestDatabase() {
  configureSqliteForTests();
  return AppDatabase.forTesting(NativeDatabase.memory());
}
