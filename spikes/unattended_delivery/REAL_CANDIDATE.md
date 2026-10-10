# Real-agent candidate path (non-production only)

This is a **separate adapter**, not a replacement of `fixture_actor.py` with an
unrestricted agent. `candidate.py` can develop one small, approved Python-domain
example with real model judgment. It cannot yet admit Memba iteration 068.
The existing 29-test fixture controller and its fake release path are unchanged.

## Authority and executor

Discovery on October 10 found Claude Code **2.1.270**, Codex **0.154.0**, and Fabro
client/server **0.316.0-nightly.0**. Fabro's model catalog advertised
`claude-sonnet-4-6`; an actual Claude invocation confirmed access. No versions or
credentials were installed or changed. Codex's granular read allowlist failed to
launch `/bin/sh` and `/usr/bin/python3` on this host (ENOENT); we did **not** switch
it to unrestricted access. Its bundled Bubblewrap executable independently
passed the explicit mount/network isolation probe. The user systemd bus was
unavailable; existing noninteractive sudo permits system transient units.

Systemd, not another home-grown `/proc` supervisor, owns restart, memory/PID/file
limits, deadlines and cgroup termination. A real crash test kills the controller
while a model double has a `setsid` descendant. Systemd fences that descendant,
restarts the controller without conversation intervention, and preserves source,
contract, deadline and spent calls. This proves lifecycle, **not model judgment**.

Claude runs fresh tool-disabled sessions with `--safe-mode --restricted --tools
'' --strict-mcp-config --disable-slash-commands --setting-sources ''`. It has no
shell, filesystem, MCP, publication or deployment tool. The authenticated CLI
is trusted; credentials are neither copied into the candidate nor sent in the
prompt. A builder proposes complete text files. The controller validates exact
per-phase path capabilities before applying them. An independent reviewer gets
the complete approved baseline, current source, contract and actual receipts as
a read-only input snapshot, with no edit capability. Builder/reviewer are
separate model sessions, **not different model families**.

All candidate execution uses Bubblewrap: read-only candidate and `/usr`, fresh
PID/network namespaces, private `/tmp`, no host `/home`, `/run`, `.git`, secrets,
controller state or network. The service limits memory to 1 GiB, tasks to 128,
individual files to 16 MiB and disables core dumps. Scope is deliberately small:
stdlib Python, no writable checkout during tests, no external services. Model
responses are untrusted data, never shell commands. Host administrators and the
installed Claude/Bubblewrap/systemd binaries remain trusted.

## Exact dispatch interface

Run from the repository root. First discover and inspect executable paths using
`command -v claude`, `claude --help`, and the installed sandbox tooling. Do not
substitute an arbitrary executable or silently install/update one.

```sh
# Creates a NEW isolated source Git repository and contract, not a Memba checkout.
python3 spikes/unattended_delivery/prepare_canary.py /ABSOLUTE/NEW/REHEARSAL

# Inspect contract.json, approve its printed canonical digest, then substitute
# the discovered absolute paths. create refuses an existing job directory.
python3 spikes/unattended_delivery/candidate.py create \
  /ABSOLUTE/NEW/REHEARSAL/job /ABSOLUTE/NEW/REHEARSAL/source \
  /ABSOLUTE/NEW/REHEARSAL/contract.json APPROVED_CANONICAL_SHA256 \
  ABSOLUTE_BWRAP_PATH ABSOLUTE_CLAUDE_PATH

bash spikes/unattended_delivery/dispatch.sh /ABSOLUTE/NEW/REHEARSAL/job
```

`prepare_canary.py` prints the admission command and digest. Contract digest is
SHA256 of JSON encoded with sorted keys and separators `(',', ':')`, not the
pretty-printed file bytes. The source identity is a full Git SHA; branch names
are not admitted. All input/proof files must be tracked regular text files.
`context_files` are immutable proof; `editable` and `unit_files` constrain model
proposals. The example has one explicit unittest selector and execution-count
marker. Obligations have stable IDs, a proving method and trusted argv arrays.
The canary is a domain example; it makes **no browser/UI claim**.

The service name is printed by dispatch. Re-dispatch while active is rejected by
systemd's stable unit identity; terminal jobs cannot be reset. Inspect
`job/state.json`, `job/service.log`, `job/evidence/`, and `job/checkpoints/.git`.
A running controller can only be launched under systemd. After a host service
restart, dispatch the **same job**, never recreate its budgets. To cancel an
owned job, stop only its printed service; stopping is not acceptance and leaves
its durable state resumable (there is not yet a separate cancellation API).

Admission freezes `job/controller.py`, the contract digest, approved baseline
fingerprint, source SHA, runtime and executor binary digests. Local Git
checkpoints live outside the candidate sandbox. Each proposed patch is saved
before application and replayed idempotently after interruption. Each attempt
is charged durably before invocation; interrupted logs remain unaccepted.
Receipts bind command, exit, time, contract, candidate commit and content digest.
A late result cannot beat the original absolute deadline. Provider errors block;
there is no credential fallback or model shopping. Bounded automatic restart is
for process interruption, not billing/auth failures.

The canary caps are 24 calls, $0.75 per CLI call, 120 seconds per operation,
30 minutes absolute deadline, and three restarts. CLI usage/cost estimates are
recorded, not represented as invoices or hard provider billing guarantees.
No budget is extended on resume. Malformed out-of-capability file proposals
consume a call, apply nothing and receive bounded corrective feedback.

## Evidence loop

1. Persist prediction before running the single selected acceptance example.
2. Observe actual assertion failure; zero selection, import/setup error,
   timeout and interrupted execution are not behavioural red.
3. Builder adds a focused unit test; the controller observes red itself.
4. Builder implements only that obstacle; controller observes unit green.
5. Optional behavior-preserving refactor; controller reruns unit checks, then
   the **same whole acceptance example**, with unchanged selector/proof.
6. Repeat on the next actual failure. Run explicit technical obligations.
7. Independent whole-change review accepts, requests repair, or blocks with a
   decision. Repairs return to the bounded inner loop and acceptance rerun.
   Missing characterization proof for already-working code does not require
   deliberately breaking the implementation.

Implementation/refactoring prompts deliberately contain the current unit
obstacle and editable source, not all future acceptance assertions. The full
contract remains immutable and is supplied to the unit-test builder and whole
reviewer. This is a context projection, not another task plan or specification.
No checkpoint is accepted merely because an agent says “done”. Final status is
`candidate-accepted-non-production` or `blocked`, **never delivered**. The JSON
state is authoritative; service exit 0 also means a durable safe block.

## Reproduce policy and recovery checks

```sh
python3 -m unittest discover -s spikes/unattended_delivery -p 'test_*.py' -v
RUN_SYSTEMD_CANDIDATE_TEST=1 python3 -m unittest discover \
  -s spikes/unattended_delivery -p test_systemd_candidate.py -v
```

The second command creates/stops only its own transient test service. It needs
pre-existing sudo authority and preserves a minimal crash receipt at
`/tmp/memba-candidate-crash-receipt.json` (override with
`CANDIDATE_CRASH_RECEIPT`). Normal discovery skips that privileged check. The
sandbox probe skips explicitly if Bubblewrap is unavailable; that skip is not
isolation evidence. The Python suite is separate from Memba's `dev check`.

## Admission limits / 068 blocker

**Do not pass 068 to this adapter.** The parent's review/adoption of the planner's
final contract is still required, and this adapter has no validated Phoenix,
Postgres or browser sandbox resource/runner adapter, Cucumber AST/outline
selection accounting, or Memba exact-state full-gate receipt. In particular,
`/usr`-only isolation cannot run Memba's Nix runtime, and read-only candidate
execution cannot supply its database/browser lifecycle. Widening mounts to the
host checkout/secrets is not a fix. The prior prototype's hard-coded historical
066 selector is not reused as an alleged generic 068 selector.

Other limits: one example per job; no Gherkin `@wip` lifecycle; no production
packaging, integration, publication, deployment or smoke adapter; no durable
wake-up after a host reboot (transient units do not survive it); no off-host
checkpoint disaster recovery. Textual unittest count/assertion parsing is
specific to this small adapter, not a secure universal test protocol. Independent
review remains necessary: candidate Python code can in principle spoof textual
output or monkeypatch Python test machinery. This is not proof against a
malicious model implementation, arbitrary filesystem corruption or power loss.
Do not promote this canary to general unattended delivery on this evidence.
