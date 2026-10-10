# 068 isolated form-conflict feasibility spike

**Evidence, not delivery. Do not auto-cherry-pick.** No application source, route,
Person command, migration, acceptance feature, planning artifact or workflow was changed.
Phone is a map key in a hypothetical fixture, not a domain feature.

## Finding

The shared interaction can be small: **62 lines of pure coordinator + 40 lines of
stateless warning presentation** (including comments/blank lines). A 44-line render-only
form harness uses existing `CoreComponents.input`, `button`, `icon`, `to_form` and
schemaless Ecto changesets. No LiveComponent, process, dependency or persistence framework.
This is credible reuse for flat scalar existing-record forms, not proof of production
integration or an automatic default across every form.

## API and ownership

`ConflictSpike.Draft` has four fields: baseline, draft, latest, warning. Values are
complete flat maps of configured string-keyed fields. Baseline is the editing origin;
warning is a frozen snapshot of values explicitly offered for replacement.

| Operation | Contract |
| --- | --- |
| `new(values)` | Open/reset from current authorized data. |
| `edit(state, params)` | Accept configured draft keys only; clear confirmation. Reverting all changes resumes following latest. |
| `observe(state, latest)` | Untouched form follows latest; dirty draft/baseline stay. Never silently update a displayed warning. |
| `changes(state)` | Changed fields relative to baseline. No historical touched-field tracking. |
| `attempt(state, :save)` | `%{changes: patch, expected: baseline_for_changed_fields}`. |
| `attempt(state, :confirm)` | Same patch, overriding expected values only with the frozen warning. No warning means no extra authority. |
| `rejected(state, attempt, current)` | Keep draft, show authoritative conflict values. Include earlier conflicts still needing confirmation, not just the newest failed field. |
| `cancel(state, latest)` | Discard whole draft and warning, adopt latest; caller closes editor. No write. |

Suggested screen adapter sequence (not implemented as a routed LiveView):

1. Derive actor/record identity server-side and load fresh authorized data; open state.
2. On form change, cast typed comparable values, update draft, perform domain validation
   for field errors. On query refresh, call `observe` only for this form.
3. On Save, ingest final submitted draft then build `attempt(:save)`. On Save anyway,
   use the server-held state/warning, never a submitted expected-value map or force flag.
4. Prepare/dispatch the domain-specific command using changed fields and expectations.
   Authorization and validation run again for every attempt, including confirmation.
5. Domain stale result includes authorized authoritative current values: call `rejected`.
   Validation/authorization errors remain distinct; do not treat them as conflicts.
6. Success: use domain/read-your-writes contract and close/reset. Cancel: reconcile a
   fresh authorized read, call `cancel`, and close without dispatching any command.

The shared warning accepts id, values, labels and event names. It lists only conflicting
fields, keeps inputs visible, uses amber warning tokens/icon (not validation red), and
provides Save anyway / Cancel my changes. The harness associates each conflicting input
with the card using `aria-describedby`. Markup/escaping are tested, not visual layout.

## Proof and complexity

- Eight pure ExUnit tests: untouched following; dirty retention/reversion; stale save
  before notification; explicit vs ordinary Save; repeat race despite live observation;
  one/two-field conflicts; preservation of unedited and out-of-form fields; whole-draft
  cancellation; authorization/validation still enforced; race after preflight.
- Three Phoenix component tests: card/icon/buttons, escaped values, one/two conflicts,
  absence without conflict, real name-only/two-input forms and warning associations.
- `fake_record.ex`: 20-line pure atomic writer simulation. It demonstrates the required
  boundary; it does **not** establish that Memba currently supplies that boundary.
- `draft_test.exs`: 111 lines; `warning_test.exs`: 78; runner: 9. Total executable
  prototype/support/tests: **364 lines**. State/algorithms are linear in form field count;
  no dependency graph, persistence callback registry, retries, or merge engine.

Run pure tests with `elixir spikes/068-form-conflict/draft_test.exs`. After the existing
web test dependencies/app have compiled, run `spikes/068-form-conflict/run.sh` inside the
repo's devenv shell. The runner loads this checkout's existing test BEAM paths, without
starting Memba or databases. It is deliberately outside normal app compilation/tests;
`dev check` alone does not execute this spike.

See [prototype test output](evidence/prototype-tests.log) and
[initial full gate output](evidence/dev-check.log). Exact final-commit gate results are
reported at handoff separately; the initial gate started during spike construction and
is not an exact-final-state pass claim. Initial gate output: LiveQuery 19/19, app
1811/1811, responsive detector 16/16, browser 6 scenarios / 106 steps passed;
responsive screenshot check skipped by its change detector. Existing negative-path
Forbidden errors and asynchronous sandbox ownership warnings appeared in logs; no
failed tests and no unrelated fixes. Command: `MEMBA_POSTGRES_PORT=25468 ./bin/dev check`.

Development failures corrected within spike only: shell-expanded `-pa` paths were
interpreted as script filenames (quote the glob for Elixir); LazyHTML `filter` searches
root nodes, not descendants (use `query`); rendered button whitespace needs trimming.
Initial pure tests: 8/8. Initial component attempts: 3 failures then 1, final: 3/3.

## Limits / production obligations

- **Authoritative save race:** UI comparison or fresh projection read cannot protect the
  interval before write. Each owning domain must atomically compare expectations and
  persist/emit the intended change against authoritative state. Confirm is just another
  conditional command. Without that, this UI is misleading and must not ship.
- Flat value equality is an experimental assumption, **not a product/model decision**.
  The fake writer deliberately rejects any stale expectation, even identical target;
  changes away/back before the attempt are not detectable. Domain review must decide
  normalized equality, identical-target no-op and ABA/version semantics. The repeated
  race test does warn if a displayed newer value changes back to the original baseline.
- Casting/normalization must be consistent before comparison. Raw text vs typed values,
  nested collections, coupled fields and multi-aggregate edits are not solved here.
  Don't generalize those by adding switches pre-emptively.
- Snapshots must contain all configured fields and refer to the same record; schema
  changes, deletion and revoked access need explicit caller handling. Coordinator state
  and expected values must remain server-owned. Filtering keys is not authorization.
- A dirty multi-field form retains its whole visible draft, including untouched inputs;
  the patch omits untouched fields so their latest persisted values survive. No field
  merge UI. Same-as-baseline means unedited, even if the actor previously typed there.
- Confirmation is conservatively invalidated by any draft edit. Final browser event
  ordering, focused input DOM patching, Enter vs confirmation, reconnect, duplicate
  clicks, accessibility announcements and responsive rendering remain unproven.
- No real command/projector/PubSub integration, connected LiveView or browser test. No
  claim that the existing app has acquired this behavior or that the fake writer proves
  distributed/concurrent production correctness. No automatic retry or force-write.

## Recommendation

Reuse the **small state API, conditional-patch contract, warning component shape and
behavior tests** as design evidence. Reimplement/review in the proper production web
boundary, using the real domain command and projection barrier; establish the future
form default through that reviewed API and guidance, not app-wide migration.
Discard the fake writer and render harness. Do not copy its validation, concurrency or
no-op policy into Person. No ADR/product question is decided by this spike. Production
integration is blocked on domain semantics review, authoritative compare-and-write and
real LiveView/browser proof. Branch publication does not authorize delivery.
