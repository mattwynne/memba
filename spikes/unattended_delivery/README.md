# Unattended delivery: non-production walking skeleton

**Status:** experimental Milestone A spike, not an iteration runner or production workflow.

Matt authorized building/testing the skeleton and then trying a real iteration on October 10.
This implements the dangerous-end experiment in the
[replacement proposal](../../docs/notes/2026-10-09-unattended-delivery-workflow.md).
It does not modify Fabro, `bin/dev fabro deliver`, CI, the active healer experiment, or application behaviour.

## Run

Requires Linux with `/proc` and pidfd support, Python 3.10+, and Git in `/usr/bin` or `/bin`.
No third-party Python dependencies or credentials are needed.

```sh
python3 -m unittest discover -s spikes/unattended_delivery -p 'test_*.py' -v

# Choose a NEW directory. Creation refuses an existing job directory.
python3 spikes/unattended_delivery/controller.py create /tmp/delivery-demo-001
python3 spikes/unattended_delivery/controller.py run /tmp/delivery-demo-001
```

Inspect `state.json`, per-operation stdout/stderr, the `candidate` Git repository,
`remote.git`, and `deployment.sqlite` in that directory. Re-running the same completed
job is a no-op. `run` exits 0 for delivery **to this fake target**, 2 for a preserved
block, or 3 if another supervisor owns the job. Never interpret exit 0 as Memba delivery.

The spike creates its own local bare remote; it cannot select a production source,
remote, service or credential. Do not retrofit those inputs into this demo to launch 068.

## Small protocol

```text
work → checkpoint → review → exact-source check → package → publish → deploy → verify
                     ↓ repair
                    work
```

`fixture_actor.py` supplies scripted builder/reviewer/checker/deployer doubles.
The builder changes one text file. Packaging creates a **fake payload**, not a Memba
image. The SQLite deploy target records one release per stable operation identity;
verification observes both source and payload identity.

The controller owns:

- One immutable contract fingerprint and one atomic durable state document.
- Unaccepted Git checkpoints, source-bound review/check receipts and an artifact digest.
- Cumulative attempt/restart/operation budgets and an absolute deadline.
- Review repair routing; genuine decisions and invalid evidence block.
- Expected-base, fast-forward publication using a local atomic Git ref update.
- Reconciliation when publication/deployment happened but acknowledgment was lost.

The outer supervisor owns the job lock and process lifecycle. A controller waits for
its durable ownership record before starting work. Before replacement, the supervisor
fences the old session, verifies process ownership and uses pidfds to avoid signaling
reused PIDs. An empty `/proc` scan alone is **not** proof of termination: the kernel
must report the process group absent. Git locks left in the exclusively owned candidate
are archived after fencing, never removed from a shared remote. A supervisor-only recovery
journal is saved before fencing and cleared after recovery; stable ownership identities
ensure that another supervisor crash cannot skip recovery or reset the spent budget.

A stopped controller cannot outrun the supervisor's deadline. A completed observation
that arrives after the deadline is retained but is not counted as delivery.

## Tests and lessons

The suite currently has **29 test methods**, including seven actual controller-kill
subcases—one after each phase's external effect, before acknowledgment. It also covers:

- Worker death with useful edits and a stale Git index lock.
- Supervisor death, duplicate dispatch, surviving children and a fork-during-scan race.
- A stopped controller and interrupted/timed-out checks.
- Automatic review repair, stale review and reviewer mutation.
- Zero selected tests, missing release input, wrong deployed/verified artifact identity.
- Cumulative retry exhaustion, immutable contracts and elapsed deadlines.
- Main moving before or during publication, and loss of a successful Git response.
- Deployment failure after publication, without rebuilding the accepted candidate.
- Useful work completed without a final model-style prose message.

Development used observed failing tests: the initial behavioural failure was a job
remaining `running`; recovery initially returned exit 75 after worker death. Artifact
identity and no-final-message tests then exposed three further failures. An independent
read-only Codex review found four more gaps: fencing enumeration, crash-left Git locks,
lost Git responses, and deadline enforcement. Follow-up review found two adjacent gaps:
Git children losing their ownership token and supervisor recovery/accounting being lost
after fencing. Each has a failing regression reproduction and a fix. The reviewer could not run filesystem tests in its read-only sandbox; its
findings came from code inspection and controlled probes. Full filesystem/process tests
were run by the parent outside that sandbox.

This is useful evidence **because the first green suite missed important defects**.
It is not proof that every possible crash point is covered.

## Explicit limits before live use

- No real model adapter, acceptance-example selection, outer BDD loop, unit-TDD worker,
  meaningful independent code acceptance, or multi-obligation iteration completion yet.
  Those are Milestone B—not properties of the scripted fixtures.
- Trusted doubles must retain their session and ownership environment. This is crash
  isolation, **not an adversarial agent sandbox**. Real workers/reviewers need OS-enforced
  authority and resource separation; they cannot share writable controller state.
- No actual Memba `dev check` receipt, production image build/start, GitHub publication
  adapter, Fly deployment, or production smoke adapter is wired into this controller.
  Running the repository's `dev check` validates the spike's repository state separately.
- Local Git compare-and-swap proves the protocol; production publication needs its own
  equivalent safety proof. There is no force-push or integration/rebase implementation.
- A changed main blocks safely; it does not yet automatically integrate and revalidate.
- Tests do not exhaustively kill every internal Git/filesystem operation. Arbitrary Git
  object corruption, remote lock recovery, disk-full/fsync failure, machine power loss,
  shared storage and host replacement remain unproved. Local checkpoints are not off-host
  disaster recovery. Never treat a safe block as successful unattended completion.
- Fixture budget numbers are test limits, not approved model-cost or live-iteration budgets.
- The Python suite is invoked explicitly; it is not silently added to Memba's normal gate
  while this remains an isolated spike.

## Real-iteration admission

At the October 10 inspection there were no `ready` or `validated` iterations in the
iteration index. [068](../../docs/iterations/068-member-name-editing/plan.md) explicitly
says its old validated draft is **not ready** after the 067 insertion. Its replan must
cover historical author names, open member/staff pages, stale concurrent saves, and a
smaller acceptance set. 069 is `needs-revision` and follows 068.

Do not silently deliver the old 068 task list or relabel a one-file demo as a real
iteration. Resolve/publish the approved outcome contract and finish the real-agent and
release adapters before admitting a live job. A historical replay is a separate,
non-production learning run and must be labelled as such.
