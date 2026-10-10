# October 10 real-agent rehearsal: evidence, not adoption

**Result: the real-agent path executes; none of the three admitted jobs completed
acceptance of the whole contract. No 068/product implementation or publication
was attempted. Do not dispatch 068 with this adapter.**

Implementation and exact dispatch interface: [REAL_CANDIDATE.md](REAL_CANDIDATE.md).
The original scripted spike commits were preserved by clean cherry-picks:
`61e6f467c` → `d94a89558`; `1393143bf` → `b659820ba`.

## Retained artifacts

Durable host directory (outside this disposable worktree):

`/home/matt/.local/state/memba/unattended-delivery/2026-10-10-real-candidate-wf3xnsvjmk/`

It contains `rehearsal-{01,02,03}.tar.gz`, `discovery.json`, the Python test logs,
and the real supervisor crash receipt. Each rehearsal archive includes its
source Git repository, immutable approved contract, candidate, local checkpoint
Git repository, state, model prompts/responses, and per-command output/receipts.
Jobs 02/03 also retain their frozen controller source. Job 01 recorded the
controller digest but **did not freeze its source**; do not claim complete
executor reproducibility for that first attempt. This admission defect was
fixed before 02. The final repository controller hash matches 03's frozen copy:

`cb69dd28d4eba0f285dd459676702667ed95eb812db90ec73ff87f1ed40025b2`.

The original working directories are `/tmp/memba-real-candidate-rehearsal-01`
through `-03`; the archives, not `/tmp` longevity, preserve this evidence.
No production credentials are included in the candidates or archives.

## All admitted jobs count

Each job had the same declared finite caps: 24 model calls, 120 seconds per
operation, 30-minute absolute deadline, three restarts, $0.75 CLI per-call budget.
No cap was extended, no failed job was reset, no model was switched.
All calls used discovered `claude-sonnet-4-6`; the CLI also reports ancillary
Haiku usage in some envelopes. Cost figures are reported API-equivalent
estimates, not subscription charges or invoices.

| Job | Calls charged | Reported cost | Outcome |
| --- | ---: | ---: | --- |
| 01 | 6 | $0.345065 | Blocked: reviewer requested missing regression proof; controller incorrectly demanded a red for already-working characterization. |
| 02 | 4 | $0.158662 | Blocked: refactor proposal tried to edit tests/add behavior outside its phase capabilities. Nothing from that proposal was applied. |
| 03 | 17 | at least $1.615977 | Blocked: final builder call timed out after 120 seconds, with review findings outstanding. That timed-out call has no reported usage; its cost is unknown, not zero. |

Completion fraction is **0/3**, not “the third passed because its acceptance
example was green.” There were no manual candidate edits, restarts, provider
switches, acceptance changes or budget extensions inside these jobs. Workflow
code/prompt development and host probes between dispatches were manual developer
interventions; they are not autonomous learning by the runner. Development also
continued while 01's already-loaded controller was running; this is another
reason not to treat 01 as exact frozen-executor evidence.

## What 03 actually proved

Contract digest:
`428413ac5dd1bac522433cc85c101ae5341a1d8fa6eb9fded882438292e53a2e`.

One protected domain acceptance example:
`ReservationExample.test_reserve_then_refuse_oversell`. Its command and assertions
were unchanged throughout. The observed sequence was:

1. Actual acceptance assertion failure: reservation returned `False`, not `True`.
2. Builder-proposed unit test failed; minimal implementation made units green;
   refactor observation passed.
3. The **same complete acceptance example** failed again: overselling did not
   raise `ValueError`.
4. Another observed unit red → implementation → green/refactor cycle; the same
   acceptance example now passed.
5. Architecture/no-runtime-dependencies and accumulated unit-regression
   obligations ran on that exact candidate.
6. Independent read-only reviewer rejected **real source defects**, not supplied
   fixture dispositions: constructor aliased the caller's dict, invalid
   quantities were accepted, and required negative-case proof was missing.
7. Automatic repair added an actual failing ownership test, fixed the aliasing,
   reran units and the same acceptance example, and reran obligations/review.
8. Subsequent reviews continued to reject missing invalid-quantity behavior or
   regression proof. Another actual red→green repair fixed zero quantities.
9. The next builder invocation, while addressing the remaining negative-quantity/unknown-item
   proof findings, exceeded its per-operation limit. Its partial logs
   survive; it was not accepted and no continuation was manually requested.

The initial aliasing defect was deliberately seeded. The acceptance driver and
small source fixture were prepared by the developer with full knowledge of the
expected outcome. This is a synthetic domain canary, not a historical Memba
replay, prospective iteration result, or browser proof. The live reviewer did
find that seed, but this does not establish that it will find every defect.

## Development failures and corrective evidence

- The first policy test invocation failed because `candidate.py` did not yet
  exist; implementation then satisfied the tests.
- Codex restricted-read execution failed with ENOENT for ordinary executables;
  unrestricted mode was not substituted. Bubblewrap passed a separate real
  read-only/no-host-files/no-network probe.
- 01 exposed the green-characterization mistake. The regression test now proves
  that already-working proof does not require breaking working code.
- 02 exposed an overreaching refactor response. The controller still refuses
  those edits; a rejected proposal now receives bounded corrective feedback
  instead of applying it or granting more authority.
- The builder initially implemented later requirements speculatively. 03's
  inner-loop context projection prevented that in the observed trace; the full
  immutable contract still went to the unit-test builder and whole reviewer.
  This is observed improvement, not a general semantic guarantee.
- The first real supervisor test reached its fencing/recovery assertions but
  failed to read a root-owned `0600` service log. Systemd's append target was
  created as root. Dispatch now precreates the log as the job owner; the real
  crash test then passed. The transient unit may already have been garbage
  collected when the test's final stop runs; its “not loaded” diagnostic is
  retained rather than hidden.
- Final explicit Python run: **48 tests passed**, including the opt-in real
  supervisor kill test. Normal discovery has 47 passes and one explicit
  privileged-test skip. Scripted tests remain routing/containment evidence,
  not agent judgment.

The repository-wide `dev check` result and exact checked commit are reported in
the handoff and retained gate log, rather than prewritten here as a success.

## Specific blockers, not an implied launch approval

- 03 did not finish within its operation budget; its next ordinary builder call
  was still working after 120 seconds. Its remaining review findings are in the
  archive. This runner currently blocks on provider/operation timeout rather
  than autonomously retrying that uncertain model request.
- The parent's adoption of the final 068 contract has not occurred in this
  workstream. No draft plan was silently treated as authorized product scope.
- The implemented adapter is stdlib Python/unittest only. No Phoenix/Postgres/
  browser resource adapter or Cucumber AST/outline selector is validated here.
  Its `/usr`-only, read-only sandbox cannot run the existing Memba Nix/application
  environment as-is. Widening it to the credential-bearing host would violate
  the authority boundary, not complete the adapter.
- There is no release, production packaging, publication or deployment authority
  in this path. Existing Fabro runs were not restarted, removed or modified;
  the old task-broker delivery pipeline was not used as a substitute.

The parent owns review/integration and any later real 068 dispatch. These logs
support evaluating the new implementation; they do not authorize rollout or
turn incomplete work into a completed iteration.
