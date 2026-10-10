# Stateful-builder continuation: actual results

The earlier commit `e9edc3869` and its **0/3** results remain intact. This note
records the continuation requested by the parent, not a retroactive success for
those jobs. Current interface: [SESSION_CANDIDATE.md](SESSION_CANDIDATE.md).

## Diagnosis from the old logs

The 17-visit job spent thirteen fresh builder invocations and three completed
reviewer invocations, then timed out during its next builder invocation. Four
builder visits were separate refactor requests; several returned no changes.
The prompt grew from a few KiB to roughly 96 KiB as complete-file responses and
history were resent. The instruction to add **one** next test caused separate
review cycles for ownership, zero quantities, then remaining negative/unknown
cases. The infrastructure forced reasoning to be reconstructed at every red.

The final timed-out invocation produced neither a completed provider envelope
nor usage. Its stdout/stderr were empty. Those facts establish a 120-second
executor timeout, **not** a diagnosed provider overload or billing failure.
Increasing that per-message cap would not fix the protocol.

The replacement has one stateful builder with three confined tools and a
controller-owned evidence loop. A complete builder visit includes all its unit
red/green/refactor and acceptance observations. Only coherent green crosses into
a separate review session. Native API/tool turns still occur: the completing
builder envelope reports **45 turns**, not one magical inference call. The
change removes orchestration handoffs and fresh context, not model reasoning.

## All new model jobs are preserved

Artifacts are retained outside the disposable worktree at:

`/home/matt/.local/state/memba/unattended-delivery/2026-10-10-session-candidate-wf3xnsvjmk/`

Archives include each admitted contract, source/checkpoint Git history, state,
frozen controller files, prompts, raw provider results and actual test outputs.
The matching Claude project JSONL transcripts are retained separately, including
read calls and rejected tool attempts. Runtime archives retain source/cache inputs
once and all operation logs/receipts; redundant disposable `work`/`home` copies
are omitted. `archive-sha256.txt` inventories the archives. The 51 existing Nix
store roots used by the recorded environment are retained through artifact-local
GC roots, so retiring this worktree does not immediately collect the runtime.
No runtime versions were installed or updated for that preservation.

| Job | Recorded terminal result | Visits / operations | Reported API-equivalent cost |
| --- | --- | ---: | ---: |
| session-canary-01 | Blocked: reviewer returned explanatory prose around JSON. Also exposed bulk implementation without unit red. | 2 / 14 | $0.200903 |
| session-canary-02 | Controller accepted functional candidate; post-run audit found bulk testing/implementation rather than successive outer obstacles. **Not qualifying outside-in evidence.** | 2 / 14 | $0.226296 |
| session-canary-03 | Blocked: declared outer-red learning evidence missing; working code was not broken to manufacture it. | 1 / 21 | $0.356325 |
| session-canary-04 | Same evidence block, despite functional green; separate release responsibility was also implemented prematurely. | 1 / 18 | $0.281760 |
| session-canary-05 | **Accepted, with required actual outer-red trace, two examples and both obligations.** | 2 / 39 | $0.893014 |
| memba-baseline-session-01 | Blocked: inherited file-size limit killed Erlang before test execution. | 1 / 14 | $0.331579 |
| memba-baseline-session-02 | **Accepted: two actual domain examples, one actual browser journey, dependency obligation, unchanged source.** | 2 / 8 | $0.143905 |

Do not interpret these evolving contracts/protocols as a homogeneous benchmark.
In particular, retain 02's real `candidate-accepted-non-production` state and the
subsequent adverse audit; do not rename it a successful BDD rehearsal. The
explicit outer-red learning criterion was introduced for later jobs. The
reserve/release example was expanded for 04/05 to expose independent
responsibilities; the original assertions were retained, not weakened.

Sonnet 4.6 was used for 01/02 and the read-only Memba jobs; Opus 4.6 was explicitly
selected **before admission** for 03–05. Both were discovered in the available
catalog. No admitted job changed provider/model, deadline, budget or contract.
Costs are provider-reported estimates, not invoices; ancillary CLI Haiku usage
is included where reported. Neither accepted job had human candidate edits,
manual restarts, manual continuation or altered criteria during execution.

## Completing development canary 05

- Contract: `252342454f93fef071b7e16a22d591973ede9bf3a142965937e5764765eae9c8`
- Final checkpoint: `ee8091fd5bfa94c31689f143b0900f0544423ea3`
- Builder session: `447462b5-8fa4-4d80-8e22-26891b4bb048`
- Reviewer session: `d6939dc6-f0d2-494f-8de6-3529bd42ff18`
- Builder visit: approximately 172 seconds; reviewer: approximately 37 seconds.
- Two fresh role invocations, **one builder conversation** throughout development.

The same first acceptance command observed three real assertion failures:

1. `stock.reserve('tea', 2)` returned False instead of True.
2. Overselling did not raise ValueError.
3. `stock.release('tea', 1)` returned False instead of True.

Each actual obstacle drove focused unit failure → targeted implementation →
unit green → the **same complete acceptance rerun**, inside that single builder
session. The second example then exposed invalid-reservation behavior and drove
another actual repair. Technical ownership/regression proof also drove unit
work. The controller finally reran both examples and both explicit obligations
at the unchanged final checkpoint. The independent read-only reviewer inspected
source/evidence and returned a structured accept with no outstanding findings.

This was a synthetic fixture with deliberately missing behavior and a seeded
caller-dict alias. The fixture/test author knew the desired implementation; the
scope expansion and prompt/tool feedback changes between trials are disclosed
preparation advantages. This is not a representative prospective Memba coding
success or evidence that every reviewer finding will be correct. The successful
new-protocol trace needed no review repair, so live provider `--resume` after a
review rejection remains unproved here; controller routing/identity and process
recovery have separate tests.

## Memba runtime proof

Source was current local `origin/main`:
`42982cfb9bacafc6b4f971b0701a1eee6e629335`.
The initial/final candidate tree equals the approved Git tree exactly:
`49e3ee6e9e94eb25b4b83b4221a352b8f187cd4b`.
No product or test-driver edits were permitted.
The completing job's contract digest is
`6cfd9c2afe6e0cf57eda6940d39bb1612629d51ba2087a1377bf9688f17fc31d`,
and its candidate checkpoint is `00f95d4f4208754434addbd757fe130d0b5eb328`.

The completing systemd-supervised job observed and independently rechecked:

- `features/list_members.feature:7`: assigned roles in the member list;
- `features/list_members.feature:18`: a removed member had a role;
- `features/journeys/member_onboarding.feature:4`: actual Phoenix/Playwright
  invitation, sign-in, club navigation and return to a private message;
- `web/test/dependency_contract_test.exs`: explicit architecture obligation.

Domain execution used the existing ExUnit/Gherkin runner with actual selection
accounting (128 tests minus 127 excluded = **one**, not 128 claimed passes).
The browser runner executed **one scenario / 20 steps**, not a domain substitute
for navigation. All receipts bind the same source. PostgreSQL, Phoenix, browser,
mail-test resources, ports and generated assets were private to each namespace.
The real broker exercised this adapter; this was not merely an unsupervised
manual browser command pasted into a final report.

### Runtime failures retained, diagnosed and corrected

1. The first namespace probe failed because `initdb --no-locale` chose SQL_ASCII
   while Memba requested UTF-8. The adapter now explicitly initializes UTF-8.
2. Browser startup failed because `/usr/bin/which` pointed through the deliberately
   absent host `/etc/alternatives`. A synthetic single safe link fixed that
   dependency; host `/etc` was not mounted.
3. Erlang RPC failed because the synthetic hosts line made `candidate` an alias
   of `localhost`. A direct probe observed `:client@localhost` while the driver
   targeted `@candidate`. Making `candidate` its own canonical hosts entry fixed
   the real browser test without changing drivers or loosening assertions.
4. The first **supervised** Memba job then failed despite those successful runtime
   probes. Exact reproduction: under a 16 MiB `RLIMIT_FSIZE`, even
   `elixir --version` dies. `strace -f` showed:

   ```text
   memfd_create("vmem", MFD_CLOEXEC|MFD_EXEC) = 16
   ftruncate(16, 67108864) = -1 EFBIG (File too large)
   --- SIGXFSZ ---
   ```

   The old job is still blocked. A new contract declared a finite 128 MiB file
   cap for the 64 MiB OTP JIT allocation; this is not a timeout increase or a
   retrospective extension. The first broker also let the model repeat the
   infrastructure failure; the new zero-selection path durably blocks and
   invalidates the attempt instead of granting an agent retry loop.
5. Source was tightened to a read-only mount, with only private build/static
   outputs writable. The actual browser journey passed under that boundary.

These probes used no external network, host database, Docker daemon, production
secret mounts or existing Fabro run. All old failures remain in the logs.

## Checks, provenance and remaining limits

The final explicit suite includes both actual coordinator-kill tests, escaping
`setsid` descendants, durable budgets/session identities, pending-patch replay,
review-only recovery, stale attempts, read-only reviewer enforcement, actual
sandbox isolation, real Gherkin inherited tags/outline selection, exact counts,
and terminal zero-selection handling. Test doubles prove routing, not judgment.
The repository-wide `dev check` result/commit is in the handoff and validation
receipt, not prewritten as a success here.

The two successful jobs retain their exact frozen controller sources. Canary 05
used session-controller SHA256
`7d0a227b53b1eaa0f2aded0fbf2832aef8e1f20b998319f2e210d52383478c03`;
its runtime adapter is
`97d9fa9299d4c5f1f5184bc8f43271bf3e9fe06bfc5eb0cf98a043c43c15e94e`.
Subsequent final-code hardening adds server-side validation of observation enums
and edit argument types (not just the advisory MCP schema), and closes sandbox
stdin rather than inheriting the broker's input channel. Regression tests cover
the server-side guards and null stdin. Recovery-time review also reproduced
checkpoint/admission gaps: Git-ignored new files were absent from checkpoint
commits, and a root Python package initializer could shadow the trusted helper
when a frozen broker starts. Checkpoints now force-add source; admission rejects
root `__init__.*` and Git metadata capabilities, including archived initializers.
Prepared dependency cache digests were recorded but not enforced at execution;
they are now verified before each run. The preserved runtime-04 cache still
matches its original admission digest (checked without rerunning any job).
The failing and passing regression logs are retained. Neither existing successful
contract contains those reserved paths. These are final-code fixes, **not** new
live rehearsals; do not relabel archived frozen runners with the final byte identity.

A BB provider transport connection expired after 60 minutes during handoff work.
After reconnecting, all seven model-job states were reconciled and no candidate
services were loaded. That transport failure is not a canary failure. No admitted
job was rerun or given a budget reset during recovery.

No 068 code was implemented. Its final contract still needs parent adoption and
proper example activation/admission. No main push, production deployment,
credential change, old task-broker launch or existing Fabro-run rescue occurred.
This is a validated non-production development/runtime path for parent review,
not adoption of a production delivery system or a claim of end-to-end release.
