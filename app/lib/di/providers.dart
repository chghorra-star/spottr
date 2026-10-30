import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';

/// The app's single database handle.
///
/// Tests override this with an in-memory executor; see
/// `test/support/test_database.dart`.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
