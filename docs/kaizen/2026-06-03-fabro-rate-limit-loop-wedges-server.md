# Problem: Fabro implementation loop wedged the remote server after rate limits

Date: 2026-06-03

## Context

We were keeping single-piece-flow between iterations 019 and 020:

- Iteration 019: `docs/iterations/019-inbound-club-messages-by-email/plan.md`
- Iteration 020: `docs/iterations/020-migrate-production-email-to-postmark/plan.md`

Iteration 019 had re-validated successfully in Fabro run `01KT5KV6B8K0Y3MH4PJ3XBFH4E`, then another agent started implementation run `01KT5M274P6VNG3WJK24N2SZQ9`. We were watching for 019 to become `merged` before starting iteration 020.

Commands from the local Memba checkout began timing out:

```text
fabro inspect plan-validation --json
fabro inspect iteration-implementation --json
fabro events 01KT5M274P6VNG3WJK24N2SZQ9 --tail 40 -p
```

Matt asked another agent in `~/git/mattwynne/hub.local/` to inspect the Fabro host.

## Expected standard

`bin/dev fabro deliver` and the Fabro implementation workflow should either:

- make steady progress through implementation, validation, review, and status transitions;
- stop clearly when a provider/model/API failure blocks progress; or
- remain observable and recoverable through `fabro inspect`, `fabro events`, and server health endpoints.

An LLM provider rate limit should not be able to drive an unbounded workflow loop, exhaust server memory/swap, leave an iteration indefinitely `implementing`, and make the Fabro API itself unresponsive.

## What happened

The hub.local diagnostic found:

- The CLI was targeting remote Fabro at `https://fabro.home.wynne.family/api/v1`.
- Remote health checks connected but received no HTTP response before timeout:
  - `curl https://fabro.home.wynne.family/health`
  - `curl http://192.168.1.201:32276/health`
- TCP port `32276` was open, but the HTTP server was not servicing requests.
- The local laptop Fabro server was healthy but irrelevant; it had zero runs and did not know about run `01KT5M274P6VNG3WJK24N2SZQ9`.
- The Fabro LXC/container on hub was memory constrained:
  - about 2.0GB used of 2.0GB memory;
  - about 1.0GB used of 1.0GB swap;
  - `pct exec 115 ...` hung.
- Worker process `469609` was still running for run `01KT5M274P6VNG3WJK24N2SZQ9` after about 3.5 hours.
- The parent Fabro server process was also still alive.
- Recent run logs showed a tight loop through implementation workflow stages such as:
  - `validate_task`
  - `task_gate`
  - `sync_task_list`
  - `all_tasks_done`
  - `implement_next_task`
- The repeated underlying error was:

```text
LLM error: Rate limited by openai: Rate limit exceeded
```

Despite those failures, the workflow kept selecting edges and looping back instead of terminating, blocking, backing off safely, or surfacing a clear recoverable failure.

A later recovery attempt found:

- Graceful `pct reboot 115` wedged on `lxc-stop`.
- After clearing the stale task/lock, `pct stop 115` plus `pct start 115` restarted the container.
- `fabro.service` came back up and recreated the `fabro` Docker container.
- `https://fabro.home.wynne.family/health` returned `HTTP/2 200` with `{"status":"ok"}` after restart.
- Container resources dropped to about 442MiB RAM used, 0 swap used, and `/storage` 17% used.
- Run `01KT5M274P6VNG3WJK24N2SZQ9` became inspectable and reported `failed`, reason `terminated`.
- The stopped Docker run container `fabro-run-01KT5M274P6VNG3WJK24N2SZQ9` remained, exited `255`, size about 1.06GB.
- `fabro doctor` also reported a low Anthropic credit balance, so switching providers may not be enough without checking provider quota/credit first.

## Impact

- Iteration 019 remained stuck in `implementing`.
- Iteration 020 could not start because ordered single-piece-flow correctly waited for 019 to merge.
- Fabro's remote API became unresponsive, so normal diagnosis through `inspect` and `events` was unavailable.
- Recovery required manual host-level investigation from `hub.local`, a non-graceful container restart, and later cleanup decisions for the failed run and stopped run container.
- The failure mode risks wasting model spend, exhausting server resources, and hiding the true cause behind generic CLI timeouts.

## What allowed it to happen

The implementation workflow and/or Fabro runtime appears to lack a hard failure guard for repeated model-provider rate-limit errors. A failed LLM stage could be treated as a transitionable workflow outcome, causing the graph to loop through task-selection and validation stages repeatedly.

The server also lacked enough resource isolation or load-shedding to keep the API health endpoint responsive while a worker was spinning and memory/swap were exhausted.

## Observations

- This was delivery-machinery failure, not a product-code failure.
- The first visible symptom in the local Memba checkout was API timeout, not a clear message that OpenAI rate limits were blocking implementation.
- The run was still represented as alive rather than terminal, so iteration status stayed `implementing` and blocked downstream work.
- `fabro inspect` and `fabro events` were not reliable recovery tools once the remote server stopped servicing requests.
- A separate local Fabro server being healthy could mislead diagnosis unless the CLI target/server URL is checked.
- The hub.local agent could only diagnose by inspecting host/container state and process/log evidence.
- A graceful LXC reboot was not enough once the container was wedged; recovery required clearing a stale Proxmox task/lock and using stop/start.
- After restart, the run transitioned to an inspectable failed/terminated state, which is better than an unresponsive API but still left Memba's iteration status requiring cleanup or retry decisions.

## Why this matters

If provider rate limits can wedge the workflow engine, any long implementation run can turn a transient external-service error into a pipeline outage. That undermines single-piece-flow: the WIP slot remains occupied, later validated work cannot proceed, and the operator must perform manual archaeology instead of using normal Fabro controls.

## Open questions

- Which workflow edge or runtime retry policy allowed the implementation graph to loop after OpenAI rate-limit failures?
- Did the loop create new checkpoints, spend more tokens, or only spin through deterministic nodes?
- What server/container memory limit is appropriate for concurrent Fabro server plus worker processes?
- Should provider rate limits be classified as terminal, retry-with-backoff, or human-intervention failures in implementation workflows?
- What is the safest operator recovery procedure for a stuck active implementation run after a server restart?
- Should stopped per-run Docker containers be pruned automatically after failed/terminated runs, or retained for evidence with a size/age limit?

## Possible prevention ideas

- Add a hard retry budget for LLM provider rate-limit failures inside Fabro workers.
- Route repeated rate-limit failures to a terminal or human-intervention state rather than back to `implement_next_task`.
- Add exponential backoff and clear status reporting for model-provider throttling.
- Keep health endpoints responsive under worker pressure, or expose a separate lightweight supervisor health endpoint.
- Add watchdog detection for runs that repeat the same node cycle without progress.
- Make `fabro inspect/events` report the configured server target prominently when timeouts occur.
- Document a safe recovery runbook for remote Fabro server/container restart, including what to do when graceful LXC reboot hangs on `lxc-stop`.
- Add post-restart cleanup guidance for failed runs, stale iteration statuses, and stopped per-run Docker containers.

## Resolution

Date: 2026-06-03

Root cause: Failed LLM/prompt nodes in the implementation workflow could still flow through normal routing because key edges depended only on context values, not `outcome=succeeded`. When OpenAI rate limits caused prompt failures, stale routing context let the graph continue cycling. The graph also allowed a very high per-node visit count and the Docker run environment had no CPU or memory limit, so a runaway run could consume the Fabro host and starve the control plane. A later inspection of the same pre-fix run found a second amplification mechanism: the run container's PID 1 was `sleep infinity`, so orphaned children from repeated `dev check`/browser acceptance runs were adopted but not reaped, accumulating hundreds of zombie PIDs.

Fix applied:

- `.fabro/workflows/iteration-implementation/workflow.fabro`: lowered the graph visit circuit breaker, added per-node visit budgets to the task-list, implementation, and validation nodes, and made implementation-loop edges fail closed unless the upstream node succeeded.
- `.fabro/workflows/iteration-implementation/workflow.toml`: added Docker CPU and memory limits for the `memba-dev` environment so an implementation run has a resource ceiling inside the Fabro LXC.
- `devenv.nix`: added `tini` to the Fabro dev image and made it the image entrypoint, preserving the previous workaround for the devenv entrypoint exit-137 issue while giving long-lived run containers a PID 1 that reaps orphaned child processes.
- `docs/reference/fabro-devenv.md`: documented the `tini` entrypoint rationale.

Validation:

- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml --no-upgrade-check` — passed with existing goal-gate warnings only.
- `dev check` — passed: 396 ExUnit tests and 31 Cucumber scenarios.
- `devenv container build fabro-dev` — attempted locally, but this Mac cannot build the required `aarch64-linux` container derivation (`Current system: aarch64-darwin`). The image needs to be built/loaded on the Fabro Linux host.
- `dev check` after the `tini` image change — passed: 396 ExUnit tests and 31 Cucumber scenarios.

Remaining follow-up:

- Fabro itself should still classify provider rate limits as terminal/human-intervention or retry-with-backoff failures at the runtime level; this repo fix prevents the Memba implementation workflow from amplifying those failures.
