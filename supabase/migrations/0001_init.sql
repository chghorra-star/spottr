-- Spottr's shared copy. M10.
--
-- Seven tables, one per syncable table in the app's Drift schema, and
-- nothing else. `rep_logs` and `form_events` are **absent on purpose**: per
-- rep traces and rule verdicts are thousands of rows per session, of no use
-- to another device, and the strongest form of "they stay on the phone" is
-- that the server has nowhere to put them. There is no table here for
-- landmarks, frames or video either, and there never will be — video never
-- leaves the device, and under this design it is never even stored.
--
-- `app/test/data/sync/supabase_schema_test.dart` compares this file against
-- drift's own metadata, column by column and type by type, because a
-- forgotten column is the likeliest mistake in it and nothing here can be
-- run from a Windows machine with no Supabase project. That test is the only
-- thing standing between this file and the first real sync.
--
-- Apply with `supabase db push`, or paste it into the SQL editor. It is
-- idempotent enough to re-run on an empty project and not idempotent at all
-- otherwise; a second migration goes in a second file.

-- ---------------------------------------------------------------------------
-- Replication order
-- ---------------------------------------------------------------------------

-- One sequence for the whole database, stamped onto every row on every
-- insert and update. This is the **cursor**: a client pulls rows whose
-- synced_seq is greater than the last one it saw.
--
-- A sequence rather than a timestamp, and the difference is not cosmetic.
-- `now()` in Postgres is the transaction's start time, so a batch of two
-- hundred upserted rows all carry the same value — and a client paging a
-- hundred at a time would take the first page, move its cursor to that
-- timestamp, ask for rows strictly after it, and silently never see the
-- other hundred. Somebody's training, missing from their second device, with
-- every sync reporting success.
create sequence if not exists public.sync_seq;

create or replace function public.stamp_sync_seq() returns trigger
language plpgsql as $$
begin
  -- Assigned here rather than defaulted, so an *update* advances it too. A
  -- row edited on another device has to reach every peer whose cursor is
  -- already past the value it had when it was first written.
  new.synced_seq := nextval('public.sync_seq');
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- The tables
-- ---------------------------------------------------------------------------

-- Every table is keyed by (user_id, id), not by id alone. The app's row ids
-- are generated on the device — derived from a plan revision, or from a
-- microsecond clock and a counter — so they are unique within one person's
-- data and carry no guarantee at all across two accounts. A single-column
-- primary key would make one user's session log collide with another's.
--
-- It also means every foreign key is composite, which buys something: a
-- child row can only ever point at a parent belonging to the same account.

create table public.profiles (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  goal text not null,
  days_per_week integer not null,
  session_minutes integer not null,
  level text not null,
  age_years integer,
  height_cm double precision,
  weight_kg double precision,
  sex text,
  injuries text not null,
  injury_notes text,
  location text not null,
  equipment text not null,
  coach_personality text not null,
  run_days text not null,
  disclaimer_accepted_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id)
);

create table public.plans (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  profile_id text not null,
  template_id text not null,
  goal text not null,
  created_at timestamptz not null,
  is_active boolean not null,
  run_days text not null,
  run_suggestion_keys text not null,
  notes text not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, profile_id) references public.profiles (user_id, id)
);

create table public.plan_days (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  plan_id text not null,
  weekday integer not null,
  day_type text not null,
  label_key text not null,
  precedes_run_day boolean not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, plan_id) references public.plans (user_id, id)
);

create table public.plan_exercises (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  plan_day_id text not null,
  order_index integer not null,
  exercise_id text not null,
  slot_pattern text not null,
  priority text not null,
  target_sets integer not null,
  template_sets integer not null,
  metric text not null,
  rest_seconds integer not null,
  seconds_per_rep double precision not null,
  target_reps_min integer,
  target_reps_max integer,
  target_hold_seconds integer,
  target_weight_kg double precision,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, plan_day_id) references public.plan_days (user_id, id)
);

create table public.sessions (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  plan_day_id text,
  started_at timestamptz not null,
  ended_at timestamptz,
  rating text,
  pain_reported boolean not null,
  notes text,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, plan_day_id) references public.plan_days (user_id, id)
);

create table public.set_logs (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  session_id text not null,
  plan_exercise_id text,
  exercise_id text not null,
  set_index integer not null,
  reps integer not null,
  weight_kg double precision,
  hold_seconds integer,
  form_score double precision,
  camera_angle text,
  completed_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, session_id) references public.sessions (user_id, id),
  foreign key (user_id, plan_exercise_id) references public.plan_exercises (user_id, id)
);

create table public.personal_records (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  exercise_id text not null,
  kind text not null,
  value double precision not null,
  achieved_at timestamptz not null,
  session_id text,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  device_id text not null,
  synced_seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, session_id) references public.sessions (user_id, id)
);

-- ---------------------------------------------------------------------------
-- Security, and the cursor index
-- ---------------------------------------------------------------------------

-- Applied in a loop rather than written out seven times. Row level security
-- is the only thing standing between one user's training log and everybody
-- else's, and the failure mode of repeating it per table is forgetting one
-- table — which looks like nothing at all until somebody notices they can
-- read a stranger's sessions. A loop cannot forget.
--
-- Three policies and not four. **There is no delete policy**, and delete is
-- revoked on top of that, because Spottr's deletes are soft: a row is
-- tombstoned so that every other device finds out, and a hard delete is
-- invisible to a peer that has not synced since. The server refusing to
-- delete is that rule made structural instead of merely intended.
do $$
declare
  target text;
begin
  foreach target in array array[
    'profiles',
    'plans',
    'plan_days',
    'plan_exercises',
    'sessions',
    'set_logs',
    'personal_records'
  ]
  loop
    execute format(
      'create trigger stamp_sync_seq before insert or update on public.%I '
      'for each row execute function public.stamp_sync_seq()', target);

    -- The pull is "my rows, in replication order, after this cursor".
    execute format(
      'create index %I on public.%I (user_id, synced_seq)',
      target || '_user_seq_idx', target);

    execute format('alter table public.%I enable row level security', target);

    execute format(
      'create policy "owner reads" on public.%I for select '
      'using (user_id = auth.uid())', target);

    -- with check, not using: this is what stops a client writing a row
    -- stamped with somebody else's user_id.
    execute format(
      'create policy "owner inserts" on public.%I for insert '
      'with check (user_id = auth.uid())', target);

    execute format(
      'create policy "owner updates" on public.%I for update '
      'using (user_id = auth.uid()) with check (user_id = auth.uid())',
      target);

    execute format('revoke all on table public.%I from anon', target);
    execute format(
      'grant select, insert, update on table public.%I to authenticated',
      target);
  end loop;
end;
$$;

grant usage on sequence public.sync_seq to authenticated;
