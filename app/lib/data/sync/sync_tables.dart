/// The tables that replicate, **parents before children**.
///
/// The order is the push order, and it matters on the remote rather than
/// here: SQLite is not asked to enforce the foreign keys, Postgres is. On a
/// first sync to an empty server a `set_logs` row arriving before its
/// session is a rejected row, and the engine stops at the first table that
/// fails precisely so that cannot happen quietly.
///
/// A set would have been the obvious type and is the wrong one. Two tests
/// keep this list honest: one compares it against
/// `AppDatabase.syncableTableNames`, and one asks SQLite, through `PRAGMA
/// foreign_key_list`, whether every table really does come after the ones it
/// points at — because an order written down by hand goes stale and the
/// answer is already in the schema.
const List<String> spottrSyncTables = [
  'profiles',
  'plans',
  'plan_days',
  'plan_exercises',
  'sessions',
  'set_logs',
  'personal_records',
];
