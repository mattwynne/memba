# Problem: fresh sandbox Postgres role mismatch, and reset+seed against a reused Phoenix server poisons Commanded aggregates

Date: 2026-07-09

## Context

Running `./bin/dev gallery-walk` in a brand-new Fabro/agent sandbox for a design-gap review hit
two unrelated environment gotchas back to back, each costing real time to diagnose.

## Problem 1: `.devenv/state/postgres` was initialized under a different OS user

`devenv processes up -d postgres` reported `gave_up` after 5 restarts. The Postgres logs showed:

```
FATAL:  lock file "postmaster.pid" already exists
FATAL:  role "matt" does not exist
```

An orphaned `postgres` process (started by an earlier partial `devenv up`) held the data
directory's lock. Once that was killed, connecting still failed: the persisted
`.devenv/state/postgres` data directory's only superuser role was `dev`, not `matt` — the sandbox
container's `$USER` at some point in this environment's history didn't match the role the cluster
was initialized with, and devenv's Postgres module skips `initdb`/role creation when the data
directory already exists ("Skipping initialization").

**Fix (non-destructive):** start a standalone backend against the same data directory and create
the missing role without touching any existing data:

```
postgres --single -D .devenv/state/postgres postgres
# at the `backend>` prompt:
CREATE ROLE matt SUPERUSER LOGIN CREATEDB;
```

Then `devenv processes up -d postgres` succeeds normally. Do **not** delete
`.devenv/state/postgres` to "fix" this — the data directory is fine, only the role is missing.

Also needed: `mix local.hex --force && mix local.rebar --force` before `mix dev.setup`/`gallery-walk`
in a sandbox that has never run a full `bin/dev setup` — `gallery_walk()` in `bin/dev` does not call
`_setup`, so it assumes Hex/Rebar are already installed.

## Problem 2: reusing a still-running `phx.server` across two reset+seed cycles corrupts seed data

`./bin/dev gallery-walk` starts a fresh `mix phx.server` only if port 4000 isn't already reachable
(`gallery_server_reachable`). If a prior gallery-walk run's server is still alive (e.g. its
`trap stop_gallery_server EXIT` didn't fire because a scene failed via an uncaught error path) and
a second run reuses it, the **second** `/dev/test-support/reset` + `/dev/test-support/seed` cycle
fails on the very first `Membership.create_person` dispatch with `{:error, :already_created}` —
even though `select count(*) from membership_people` and the event store both show zero rows.

Root cause: `/dev/test-support/reset` truncates the Postgres event-store and read-model tables, but
only stops/restarts **projectors** (`stop_event_sourced_projectors!`/`start_event_sourced_projectors!`)
— it does not touch Commanded's per-aggregate GenServer processes. An aggregate process for a given
ID, once instantiated in a run's lifetime, stays alive in memory with its committed state; a DB
truncate underneath it is invisible to that process, so the *next* dispatch for the same ID sees a
non-nil aggregate and rejects the create as a duplicate. This will hit **every** seeded person, not
just a new one — reusing a live server for a second reset+seed cycle will reliably break `alice@example.com`'s
own seed step, not just anything newly added to `DevSeeds`.

**Fix:** don't reuse a `phx.server` across more than one reset+seed cycle. If a gallery-walk run
errors mid-scene, kill the leftover `beam.smp`/`phx.server` processes before the next attempt
rather than letting `gallery_server_reachable` silently reuse them.

## Suggested follow-up (not done here)

`/dev/test-support/reset` could also restart the aggregate supervisor (whatever Commanded registers
aggregate processes under), so repeated reset+seed cycles against one long-lived dev server behave
the same as a fresh server. Out of scope for this session — this note exists so the next person
doesn't have to re-diagnose it.
