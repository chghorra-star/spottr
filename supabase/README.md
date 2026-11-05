# The shared copy

Spottr is local-first and stays that way. Everything works with no account:
the plan is generated on the device, the camera coach runs on the device, and
the log is a SQLite file. Sync is what makes a second device show the same
training, and it is the only reason any of this exists.

**Nothing here has ever been run.** This project is developed on Windows
against no Supabase project, so `migrations/0001_init.sql` is in exactly the
position the Podfile was in before M9: written carefully, reviewed, pinned by
a test, and never executed. The first `supabase db push` is where it finds
out.

What the test pins is in `app/test/data/sync/supabase_schema_test.dart`: that
the seven tables here are exactly the seven the app replicates, column by
column and type by type against drift's own metadata; that row level security
is applied to all of them from one list rather than seven times over; that
nothing can be hard deleted; and that the diagnostic tables are absent. What
it cannot pin is whether the SQL parses.

## What is not here

`rep_logs` and `form_events` — per-rep traces and rule verdicts — are
deliberately absent. They are thousands of rows per session, invaluable for
debugging and for building harness fixtures, and of no use to another device.

There is no table for frames, landmarks or video, and there will not be.
Video never leaves the device, and under Spottr's design it is never stored
at all.

## Applying it

```bash
supabase link --project-ref <ref>
supabase db push
```

Or paste the file into the SQL editor. It is written to run once on an empty
project; a change goes in a second numbered file rather than an edit to this
one.

## What the app needs back

Two values, which are not secrets and are not in this repository:

- the project URL, e.g. `https://<ref>.supabase.co`
- the `anon` public key

They are passed in at build time rather than committed, because the
repository is public. The anon key is designed to be shipped in a client —
row level security is what protects the data, not the key — but a key in a
public repository is still a key somebody can point at your project's auth
endpoint, which is a bill rather than a breach.

## The one decision worth knowing about

The cursor is a sequence, not a timestamp. `now()` in Postgres is the
transaction's start time, so every row in an upserted batch carries the same
value — and a client paging through a hundred at a time would take the first
page, move its cursor to that timestamp, ask for rows strictly after it, and
never see the rest. That failure is somebody's training missing from their
second device, with every sync reporting success.

`updated_at` is still a clock, because it is the author's clock and the
conflict rule compares it. The two are different things and the schema keeps
them apart: `updated_at` says when the edit was made, `synced_seq` says what
order the server learned about it.
