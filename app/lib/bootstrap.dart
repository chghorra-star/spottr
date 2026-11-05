import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'data/local/database.dart';
import 'data/local/local_identity_store.dart';
import 'di/providers.dart';

/// The things that have to be known before the first frame.
///
/// Only one, so far, and it is here rather than in a provider because of a
/// mismatch: reading this installation's id is a database call, and every
/// repository needs it synchronously to stamp the rows it writes. Making the
/// repositories asynchronous to accommodate one string would reach the whole
/// way up through the controllers into the screens.
///
/// So it is read once, here, and injected. `installIdProvider` has no usable
/// default on purpose: a scope that builds a repository without this
/// override is a scope that would stamp somebody's training with the wrong
/// device, and the tie-break that makes the sync converge is exactly what
/// that breaks.
Future<List<Override>> bootstrap({AppDatabase? database}) async {
  // Overridden with a value rather than built by the provider, because the
  // provider cannot be asked for it until it exists. Nothing closes it:
  // opening the database is the process's lifetime.
  final db = database ?? AppDatabase(driftDatabase(name: 'spottr'));

  final installId = await LocalIdentityStore(db).installId();

  return [
    databaseProvider.overrideWithValue(db),
    installIdProvider.overrideWithValue(installId),
  ];
}
