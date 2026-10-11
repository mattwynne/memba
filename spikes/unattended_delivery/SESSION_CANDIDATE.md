# Stateful builder and Memba runtime adapter

**Non-production implementation path; not publication authority.** Supersedes the
per-red fresh-model protocol in [REAL_CANDIDATE.md](REAL_CANDIDATE.md), without
removing its code, commits or failed jobs. [SESSION_REHEARSAL.md](SESSION_REHEARSAL.md)
records every new trial, including failures and the two completing rehearsals.

## The simplification

One Claude builder session owns its development thinking. It directly uses three
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
(`--resume`), not a new planner or task packet. An interrupted review resumes
review, not implementation. `candidate-accepted-non-production` requires a
source/contract-bound structured reviewer acceptance with no unresolved findings.

For an explicitly approved audit-first baseline, `review_before_edits: true`
closes all builder edit capabilities (including refactors) until an independent,
exact-candidate reviewer returns concrete repair findings. The controller then
persists repair authorization and resumes the same builder; ordinary unit-red
and approved-path guards still apply. This is opt-in, not the default development
loop, and does not prescribe a reviewer verdict.

MCP is a narrow tool boundary, not another agent. Native Claude tools are disabled
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
- writable private `_build` and generated-static directories only;
- synthetic `/etc` identity/hosts data and a private Mix cache/home;
- no host `/home`, `/run`, daemon sockets, secrets or network access.

`MEMBA_POSTGRES_OWNER=dev` tells existing nested helpers that the adapter owns
Postgres. The adapter starts/stops its own cluster; nested browser helpers do not
reset a shared host database. Existing Phoenix/Playwright lifecycle code runs
unchanged. Source hashes are also compared after execution. A newly admitted runtime may set
`retain_execution_copies: false` before its fingerprint is approved. After an
observation has finished and its source-integrity receipt is saved, only that
observation's disposable work/home copies are removed; stdout, stderr, receipts,
source templates and controller checkpoints remain. Existing runtimes default to
retention and are not changed. This bounds duplicate-cache accumulation during
long implementation loops.

Unit-red authorization recognizes actual ExUnit assertion failures (raw exit 2),
not merely a nonzero exit. Missing functions, mixed assertion/setup failures and
setup callbacks do not authorize product edits. Unknown failure formats fail
closed. Python unittest requires a FAIL receipt with no ERROR. Raw framework exit
codes remain in evidence; neither setup work nor a green rehearsal is product red.

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
