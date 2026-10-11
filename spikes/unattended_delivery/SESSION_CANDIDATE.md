# Stateful builder and Memba runtime adapter

**Non-production implementation path; not publication authority.** Supersedes the
per-red fresh-model protocol in [REAL_CANDIDATE.md](REAL_CANDIDATE.md), without
removing its code, commits or failed jobs. [SESSION_REHEARSAL.md](SESSION_REHEARSAL.md)
records every new trial, including failures and the two completing rehearsals.

## OpenAI Sol integration (explicit new-contract choice)

`model_backend: "pi-sol"` selects the trusted `sol_adapter.mjs` Pi SDK integration.
Both the builder and ordinary independent reviewer use **exactly**
`openai-codex/gpt-6.1-sol`, via `openai-codex-responses` at the existing OAuth
backend. No catalog, default-model or CLI fallback is permitted. Historical
contracts/jobs are not migrated or reopened; the legacy CLI code below remains
for preserved evidence and process-double regression tests, not authorization to
call Claude/Gemini. Ensemble review is a separate explicitly authorized activity.

The `sol_provider` declaration binds SDK package/dependency tree digest, absolute
Node binary/hash, exact model metadata digest, provider/API/backend URL, thinking
level and finite `max_turns` (<=160 requests/visit). Newly reviewed contracts use
`token_policy: "accounting-only"`, with no cumulative token execution stop. Legacy
contracts retain their explicit `visit_token_limit` (<=2M aggregate tokens/visit);
missing, mixed or unknown policy declarations are rejected, never migrated.
SDK/Node identities are verified
before admission and each visit; catalog identity is checked before requests.
The native SSE `response.model` is captured and checked, not inferred from the
model catalog or harness's requested-model field. Changed/missing identity
fails closed and raw evidence is retained. Existing source/contract/runtime,
path, same-selector/same-example, final proof and independent review gates remain.

Pi is created with an explicit resource loader with **no** extension, skill,
settings, context-file, theme or prompt discovery, and no built-in tools. Only
custom `inspect/edit/observe` definitions bridge to the frozen Python broker;
reviewers receive only `inspect`, and the broker independently rejects writes or
observations in review phase. Outgoing requests reject native shell/filesystem,
web/search or extra tool definitions. Tools execute sequentially so checkpoint
and observation transitions cannot race. This is capability containment, not a
claim that the trusted authenticated SDK process itself is an OS sandbox: it
needs provider network/auth access. Candidate checks still use the unchanged
network-isolated read-only runtime, and the owned Node/broker descendants remain
under the existing process group/systemd cgroup limits.

The builder's persisted Pi session ID/file is retained through resumes and
bound to the contract/provider/model; review starts with an empty fresh session.
No replacement builder, implicit context migration, auto-compaction or model
switch is allowed. Provider and agent retries are disabled, transport is SSE
(no websocket retry/fallback), and timeout/cancellation preserves events,
sessions, token usage and owned-process reaping. A dead broker rejects both
pending and future calls rather than leaving a request waiting.

**No supported hard CLI dollar flag exists on this integration.** `visit_usd`
must be **null**, not a claimed $10 enforcement. Visits/operations/time/resources
and request bounds remain enforced. Tokens remain fully reported, including cache;
only legacy contracts stop the next request at their token threshold. Dollar
charges remain null unless actually provider-reported. Pi's rate-derived costs
are separately labelled estimates; subscription usage is not inferred to be
free or equal to those estimates. Partial/error usage stays incomplete. The
`.events.jsonl`, `.usage.json`, `.visit.json` and Pi session files retain native
identity, request/tools, tokens, estimates and final result separately. `provider_usage`
is added to state without converting estimates into the reported-dollar ledger.

An OpenAI contract and new admission must be reviewed/approved explicitly; an
old source draft's cancelled release is not authority to launch this path.

## The simplification

One continuous builder session owns its development thinking. It directly uses three
capabilities through a small trusted MCP broker:

- `inspect`: read candidate files, contract, observations and `@evidence`.
- `edit`: exact targeted replacement in approved files; checkpoint immediately.
- `observe`: run the approved unit, selected-example or technical-obligation
  command in the isolated runtime; return actual output and controller receipt.

A test invocation or edit is **not another model session**. The builder stays in
one conversation through red → unit TDD → green → refactor → the same acceptance
rerun. The controller does not choose a unit-test task or request a refactor
agent. It gates implementation on actual current-snapshot unit failure and
requires the same outer observation after unit green. Behavior-preserving
refactors require green unit evidence and remain subject to review. Missing
characterization proof must not manufacture a red.

After coherent green, the controller independently reruns **every** contract
example and technical obligation on the same candidate, then starts one separate
read-only reviewer session. Repair goes back to the same builder session UUID
(persisted Pi session, or historical CLI `--resume`), not a new planner or task packet. An interrupted review resumes
review, not implementation. `candidate-accepted-non-production` requires a
source/contract-bound structured reviewer acceptance with no unresolved findings.

For an explicitly approved audit-first baseline, `review_before_edits: true`
closes all builder edit capabilities (including refactors) until an independent,
exact-candidate reviewer returns concrete repair findings. The controller then
persists repair authorization and resumes the same builder; ordinary unit-red
and approved-path guards still apply. This is opt-in, not the default development
loop, and does not prescribe a reviewer verdict.

The trusted broker is a narrow tool boundary, not another agent. Historically,
native Claude tools were disabled
with `--tools ''`; only the explicit MCP server is enabled, with restricted mode,
no other MCP configs, no hooks/skills and no project/user settings. There is no
host shell or credential-reading tool. Reviewer calls to edit/observe are denied
by the broker, not merely discouraged in a prompt. Inspect cannot escape the
candidate directory. Claude authentication stays with the trusted installed CLI;
credentials are not copied into the model's candidate/runtime.

## Runtime and evidence ownership

The controller and broker run in one bounded systemd service. Systemd owns the
whole cgroup, restart and fencing, including `setsid` descendants. The same real
controller-kill test used for the old path now also exercises this path. Startup,
visit, operation and deadline budgets live in the job, not the provider session.
A tool broker carries an attempt identity; stale attempts cannot write or attest.
Write-ahead edits replay after interruption, and unfinished work remains an
unaccepted Git checkpoint outside the execution sandbox.

Each observation records prediction **before** launch, then source/contract
identity, selected count, exit, timestamps and output digest. The final check
updates the complete multi-example/obligation set for the exact candidate before
review; stale earlier greens do not finish a job. Wrong/zero selection is a
terminal infrastructure block, not a model's invitation to retry arbitrarily.

`memba_runtime.py` prepares a full `git archive` at the approved SHA, copies warm
private dependencies/build caches, and uses already-realized Nix store tools.
There is no Nix evaluation/download, Docker socket, host database socket, or host
network inside candidate execution. Every observation gets:

- fresh PID/network namespaces and a private `/tmp`;
- a fresh PostgreSQL UTF-8 cluster owned by that invocation;
- read-only source, test drivers, features and dependencies;
- writable private `_build` and generated-static directories; Node checks additionally
  get an empty private `node_modules` fixture root with installed dependency children RO;
- synthetic `/etc` identity/hosts data and a private Mix cache/home;
- no host `/home`, `/run`, daemon sockets, secrets or network access.

`MEMBA_POSTGRES_OWNER=dev` tells existing nested helpers that the adapter owns
Postgres. The adapter starts/stops its own cluster; nested browser helpers do not
reset a shared host database. Existing Phoenix/Playwright lifecycle code runs
unchanged. Declared Node checks reuse that existing lifecycle for actual private
Phoenix/RPC/Jason dependencies; only their child receives the real `BASE_URL` and
`ACCEPTANCE_SKIP_APP_START=true`, preventing embedded lifecycles from dropping the
in-use private DB. Full frozen Node selection/exit and owned teardown are retained,
not mocked success. Non-Node checks keep their prior mounts/execution.
Source hashes are also compared after execution. A newly admitted runtime may set
`retain_execution_copies: false` before its fingerprint is approved. After an
observation has finished and its source-integrity receipt is saved, only that
observation's disposable work/home copies are removed; stdout, stderr, receipts,
source templates and controller checkpoints remain. Existing runtimes default to
retention and are not changed. This bounds duplicate-cache accumulation during
long implementation loops.

**Unit development failure is not limited to assertion mismatches.** During a
builder's trusted unit invocation, compiler/missing-interface errors and ordinary
runtime failures (including FunctionClauseError) are actionable feedback. A
compile failure records zero executed tests, never a pass or behavioral acceptance
red. The receipt separately records raw exit, execution count, assertion evidence
and `unit_development` classification/executed count. No path/module/import/alias
matching derives per-file repair permission.

A genuine failed approved unit invocation must be bound to the current candidate
and contract. The approved editable allowlist is the file boundary. Repair only
the current observed responsibility; transitive approved Router/encoder/projector
files need no artificial test aliases. Semantic relevance/minimality remain a
builder discipline and independent-review requirement, not a textual classifier.
Unit/support edit rights still correct test setup. There is no syntax-template
taxonomy, scaffold flag or required nil placeholder.
A missing aggregate clause can be implemented directly after the relevant unit
runtime failure, without manufacturing an assertion mismatch first.

After each implementation repair, rerun unit before another edit or outer check.
Any edit invalidates older diagnostic authority. After unit green, rerun the SAME
outer example. The builder prompt and independent reviewer enforce smallest
change/current obstacle and reject speculative bulk implementation. No extra
model session is required for development tool loops.

Actual runner/connection/setup-callback/access-denial/timeout diagnostics do not
grant implementation. These checks inspect runner error records, exception headers
and setup stack frames—not bare words in test names, code or expected business
values such as `:unauthorized` or `:timeout`. Ecto/Postgrex application query and
constraint exceptions remain development feedback; connection/authentication
exceptions remain environment failures. Successful zero selection, missing acceptance steps, final
proof zero execution, source/contract changes remain fail-closed. Final checks
and review have no development exception. Nonzero failed non-example checks may
stop before tests (formatter/compiler checks or a missing declared test scaffold):
return actual failed/count-zero feedback, not blanket selection cancellation.
It is never proof or inferred unit repair authority; only actual builder unit
compiler/runtime/assertion classification grants relevant implementation rights.
Approved unit-file scaffolding rights remain available. Genuine infrastructure,
zero-test success and invalid acceptance selection still fail closed. Existing
unit/refactor/support discipline and SAME final gates remain binding. Unit failure is not acceptance:
all exact-candidate examples/obligations still must execute and pass before review.
Mixed assertion/setup failures are not assertion red. As elsewhere in this
experimental executor, framework-output recognition is not proof against a
malicious test runner; frozen commands/scopes and independent review remain
necessary boundaries.

### Focused inner checks and acceptance-driver routing

The third 068 attempt's broad unit command did **not load its acceptance driver**.
Seven driver-only edit/check cycles spent 627.63 seconds running 8,253 unrelated
unit-test executions. The old edit guard did not force these checks: the model
chose them, generic guidance failed to distinguish drivers, and unit observation
ignored its `id` argument so no focused command was available.

New contracts can declare optional fixed selections and explicit support roles:

```json
{
  "focused_units": [{
    "id": "person-dispatch",
    "paths": ["web/test/memba/membership/person_rename_dispatch_test.exs"],
    "kind": "domain",
    "script": "cd web; mix test test/memba/membership/person_rename_dispatch_test.exs"
  }],
  "acceptance_support_files": [
    "web/test/features/step_definitions/member_profile_steps.exs"
  ]
}
```

The operator approves the **exact command and its correspondence to the declared
paths** before admission. For the small non-runtime canary, use a fixed `command`
argv instead of `script`. Paths must already be `unit_files`; support paths are a
separate subset, not new edit authority. Selection IDs must be unique and cannot
collide with proof IDs or reserved `unit`. Malformed/ambiguous declarations fail
admission. Absent these optional declarations, existing contracts retain their
broad fallback and unit/support roles; no stopped contract is migrated.

- `observe(kind="unit", id="person-dispatch", prediction=...)` chooses only that
  declared command. `id="unit"` chooses the existing broad gate.
  Unknown IDs and caller-supplied commands/paths are rejected, not interpolated.
- Focused checks are builder-only. Receipts include `unit_selector`/`unit_paths`,
  remain candidate/contract-bound, and never occupy an example/obligation ID.
  The fixed selected command supplies actual failure feedback; stack-frame/import
  matching does not authorize files. Compilation before test loading remains
  zero-execution development feedback; unsupported framework output grants no repair.
- A product repair durably remembers the authorizing unit selector. It must rerun
  **that same selector**, not a cheaper unrelated check. After focused green,
  return to the same active acceptance before further implementation/tests.
  Focused green does not authorize unrelated behavior-preserving refactors; the
  existing broad-green refactor path remains available.
- Declared acceptance-driver/support edits return directly to the same selected
  acceptance. Multiple coherent edits to those support paths are allowed first;
  other edits or unrelated unit/obligation observations must wait for that outer
  observation. This cannot bypass an already-pending product unit check. If no
  outer is active yet, select and observe an approved example first.
- **Every original example and broad regression obligation is still rerun on the
  final candidate at coherent completion, before independent review.** Focused
  green never substitutes for, caches away or weakens these gates. The final
  checking/review loop and the parent-owned exact-state full product gate remain
  unchanged.

The controller polls durable job status during a model visit. If the broker makes
the job terminal, it promptly terminates/reaps only that visit's process group;
systemd remains the outer containment. It does not pay for a fenced tool loop
until the visit timeout, restart the job or refund the visit. Partial stdout and
stderr plus a `.visit.json` receipt are preserved. Error-envelope cost is recorded
when available; without an envelope, `reported_cost_usd` is null (not zero),
`reported_cost_complete` is false, and `known_reported_cost_usd` remains the known
subtotal. Interrupted/unknown visit IDs remain in `unreported_cost_visits`.

The Gherkin selector uses the **real Cucumber pickle compiler**, not regex name
parsing. It accounts for inherited tags and outline rows and records URI, line,
name and feature digest. Missing/duplicate selections and inherited `@todo` are
rejected. Browser rows select by URI/line. Domain rows use the existing ExUnit
scenario-name tag; ambiguous outline names are explicitly rejected rather than
claimed as isolated. Execution counts are checked independently (including
ExUnit exclusions). Acceptance purposes remain at their actual boundaries.

## Exact dispatch: development canary

Discover installed tools first (`claude --version`, `claude --help`, model catalog,
and Bubblewrap location/version); do not install/update or assume access.
The completing canary used discovered `claude-opus-4-6`. The helpers create NEW
jobs and never reset old ones.

```sh
python3 spikes/unattended_delivery/prepare_session_canary.py \
  /ABSOLUTE/NEW/canary ABSOLUTE_BWRAP_PATH claude-opus-4-6
# Inspect the generated contract; the command above prints its canonical digest.
python3 spikes/unattended_delivery/session_candidate.py create \
  /ABSOLUTE/NEW/canary/job /ABSOLUTE/NEW/canary/source \
  /ABSOLUTE/NEW/canary/contract.json APPROVED_CANONICAL_DIGEST
bash spikes/unattended_delivery/dispatch_session.sh /ABSOLUTE/NEW/canary/job
```

Canonical digest: SHA256 of sorted-key JSON with separators `(',', ':')`.
The canary declares six visits (at most three builder/reviewer pairs), 100
operations, ten minutes per complete builder/reviewer visit, 30 seconds per tiny
check, 30 minutes total, two restarts, 1 GiB/128 tasks/16 MiB per file, and a $4
CLI visit cap. A visit now includes the **whole tool loop**, not one file proposal.
The fixture's declared outer-red learning criterion is separate from product
acceptance: missing trace evidence blocks; it never authorizes breaking green
code. The source includes a reserve/release journey and a second invalid-input
example, plus independence and regression/ownership obligations.

## Exact dispatch: Memba baseline/runtime rehearsal

Use a clean checkout with existing dependencies prepared by `bin/dev setup`.
Export **only** the listed non-secret runtime variables from that checkout's
Nix shell to a new JSON file:

```sh
devenv shell -- python3 -c 'import os,json,pathlib; keys=["PATH","PLAYWRIGHT_BROWSERS_PATH","FONTCONFIG_PATH","FONTCONFIG_FILE","MIX_TAILWIND_PATH","MIX_ESBUILD_PATH","SSL_CERT_FILE"]; pathlib.Path("/ABSOLUTE/runtime-env.json").write_text(json.dumps({k:os.environ.get(k) for k in keys}))'

python3 spikes/unattended_delivery/memba_runtime.py prepare \
  /ABSOLUTE/NEW/runtime REPOSITORY APPROVED_FULL_SOURCE_SHA \
  /ABSOLUTE/runtime-env.json ABSOLUTE_BWRAP_PATH
python3 spikes/unattended_delivery/prepare_memba_rehearsal.py \
  /ABSOLUTE/NEW/rehearsal /ABSOLUTE/NEW/runtime
# Inspect contract and approve the printed digest, then:
python3 spikes/unattended_delivery/session_candidate.py create \
  /ABSOLUTE/NEW/rehearsal/job REPOSITORY \
  /ABSOLUTE/NEW/rehearsal/contract.json APPROVED_CANONICAL_DIGEST
bash spikes/unattended_delivery/dispatch_session.sh /ABSOLUTE/NEW/rehearsal/job
```

This helper prepares a **read-only current-main rehearsal**, not an implementation
contract: two member-list domain examples, the real onboarding/browser journey,
and the existing dependency architecture test. Editable paths are empty.
The completing run used source `42982cfb9bacafc6b4f971b0701a1eee6e629335`.

Memba budgets: two model visits, 30 operations, 90 seconds/check (approximately
three times the observed cold browser duration), 600 seconds/visit, 20 minutes
absolute, two restarts, 4 GiB/512 tasks and a 128 MiB file limit. **Do not reuse
16 MiB here:** strace proved OTP's JIT allocates a 64 MiB memfd at VM startup.
The failed old job is untouched; these resources belong to a new admission.

The core supports full-source implementation candidates through `runtime_root`,
approved `editable`/`unit_files`, an approved `unit_script`, and example/obligation
scripts. The supplied Memba helper deliberately grants no implementation rights.
Custom contracts require parent review, actual proving boundaries and explicit
budgets; the helper is not a substitute for adoption of the final 068 contract.

## Bounded read-only inspection

The fifth Sol visit hit its accepted **cumulative response-accounted** 2M-token
threshold after 17 requests, not a provider refusal or context-window overflow.
Repeated cached history was 90.35% of that aggregate. Empty inspection duplicated
the full contract and listed 2,561 repository paths; whole-file reads silently
cut off at 80,000 characters. This correction changes only read presentation,
not scopes, inference policy, old evidence, development gates or proof authority.

`inspect` remains the same read-only capability for builder and reviewer:

- Empty `path`: paged **declared editable/context/unit** path inventory (including
  approved files not yet created), concise status and stable proof/unit IDs.
  IDs/status are **not proof**; they do not assert that old observations certify
  the current candidate. The immutable full contract is not duplicated here.
- `path="@files"`: explicit paged inventory of **all** candidate paths. Existing
  source read permission remains unchanged: any file within the candidate root,
  never host paths or escaping symlinks. Edit permission is still separate.
- `path="@contract"`: exact canonical full approved JSON, SHA256 equal to the
  contract digest, available losslessly through pages. All obligations, scripts,
  scopes and outcome criteria remain available; no summary replaces them.
- `path="@evidence"`: paged index of the job's evidence files, not a multi-log dump.
  `path="@evidence/NAME"`: exact UTF-8 receipt/log content through pages, including
  source/contract IDs and raw results. Evidence traversal/escaping symlinks are
  rejected; no control-plane/host filesystem access is granted.
- An ordinary source/evidence/contract text path accepts zero-based `offset`
  **Unicode characters**, `limit` default 4,000 / maximum 8,000 characters. Index
  offsets count **items**, default 40 / maximum 100. These are character/item
  bounds, not claims of identical encoded-byte or token sizes.
- Optional `query` is a literal string (1–256 characters), not regex or shell.
  It finds the first occurrence at/after `offset`, returns `match_offset` and
  `match_line`, then a bounded range from that occurrence. No match is explicit.
  Omit `query` when continuing that range via `next_offset`.

Every page explicitly reports offset units, totals, truncation and continuation.
`current_candidate` identifies the job's current snapshot, **not** the candidate
that produced a historical evidence file; the exact receipt's own candidate and
contract fields determine its proof identity. Metadata never upgrades old greens.
Text pages additionally report full-content SHA256, character/UTF-8 byte totals
and actual returned character/UTF-8 byte counts. Single long lines and Unicode
are not silently dropped. Follow `next_offset` until null, preserving/checking
SHA256 across pages; changed hashes expose concurrent/different content rather
than certifying an assembled stale file. Non-UTF-8 content remains unsupported
by this text-only capability. Inspect does not execute commands, consume an edit
or check operation, change state, or authorize missing proof. Stale/terminal
attempt, reviewer write, source/contract and all existing repair guards remain.

### Token accounting is not a spend receipt

The adapter keeps `input`, `cacheRead`, `cacheWrite`, `output` and
`totalTokens` separately. For the fifth, SDK response records sum to 190,641
uncached input + 1,809,408 cached input + 2,561 output = 2,002,610. The **sum over
requests** repeatedly counts cached conversation; it is neither unique context
size nor unique generated tokens. Last request input was about 188k tokens,
below the context window. CacheRead is provider-reported reuse, not "free" input.
Rate-derived estimates price these channels differently, but are **not charges**;
subscription/quota/billing implications cannot be inferred from token sums.

Newly reviewed `accounting-only` contracts report every channel/aggregate without
a cumulative token stop; legacy limits, frozen jobs and their overshoots remain
unchanged. Finite request/visit/operation/wall/resource bounds and zero automatic
retry/fallback remain. Large cached contexts can still incur latency, provider
quota/context failures and unknown charges. This is not a spend cap or completion
promise. No further 068 admission, real resume or inference is authorized here.

Start/resume/reviewer prompts contain only brief protocol/safety, exact identities,
limits and retrieval pointers. The same `inspect` pages expose the full contract,
plan, status and exact evidence; per-visit `.context.json` stores controller feedback
instead of embedding it. No receipt/history/inventory dump or new retrieval layer
is added. Persistent native session history remains intact. Independent review must
read the complete truth, not certify from these pointers or concise status.

## Inspect, recover, test

The dispatch command prints a stable systemd service name. Job status is in
`state.json`, checkpoints in `checkpoints/.git`, observations/prompts/provider
results in `evidence/`, and service output in `service.log`. A successful service
exit is **not** acceptance: a durable block also exits 0. Duplicate dispatch is
rejected by the stable service identity; jobs are not recreated to refund spend.
Stop only the printed service to halt a job. Systemd automatically recovers an
unexpected controller death within the original budgets; no chat turn is needed.

```sh
RUN_SYSTEMD_CANDIDATE_TEST=1 python3 -m unittest discover \
  -s spikes/unattended_delivery -p 'test_*.py' -v
```

This includes both real supervisor crash tests and actual sandbox/AST probes.
Without the opt-in, privileged crash tests are explicitly skipped. The new
systemd crash test uses a model double: it proves fencing, durable identity and
budget accounting, **not live provider resume quality**.

## Limits that still matter

- No 068 implementation before the parent adopts its exact final contract. The
  baseline rehearsal does not grant that authority.
- No production packaging, main publication, deployment or release receipt.
- Model/tool protocol errors and provider timeouts can safely block. There is
  no automatic credential fallback or mid-job budget extension.
- Transient systemd units do not survive host reboot; checkpoints are local,
  not off-host disaster recovery. Whole-job cgroup limits also bound the
  controller; memory pressure is recovered through systemd, not a separate
  unlimited control-plane service.
- Baseline browser hosts are explicitly mapped (`lvh.me`, `kmc.lvh.me`,
  `npc.lvh.me`, `nelson.lvh.me`); a different contract must provision its test
  hostnames before admission. No external DNS is available.
- The helper rejects future `@todo` scenarios. Controller-owned activation/tag
  policy and any new driver work for an adopted 068 contract still need explicit
  admission, not silent feature edits or weakened selection.
- Root `__init__.*` files are not supported: they could shadow a trusted Python
  helper beside the frozen candidate directory. Admission rejects them and Git
  metadata edit capabilities rather than executing candidate code on the host.
- Warm dependency copies and Nix paths are prerequisites, not a fresh network
  bootstrap. Reprepare and reapprove if source/dependency/runtime identities
  change. Review source/cached artifacts before sharing externally.
- Textual framework receipts and independent model review are not proof against
  malicious test-runner spoofing or every possible semantic defect. Do not
  generalize one completing synthetic canary into production reliability.
