import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:spottr/data/local/database.dart';
import 'package:spottr/di/providers.dart';
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
  return AppDatabase(NativeDatabase.memory());
}

/// The overrides a provider-level test needs to reach the data layer.
///
/// `installIdProvider` has no usable default: it is read from the database
/// at startup by `bootstrap()`, and a scope that builds a repository without
/// it would stamp rows with the wrong device. A fixed id here keeps those
/// tests deterministic and keeps the real one out of them.
List<Override> testOverrides(
  AppDatabase db, {
  String installId = 'test-device',
}) {
  return [
    databaseProvider.overrideWithValue(db),
    installIdProvider.overrideWithValue(installId),
  ];
}
