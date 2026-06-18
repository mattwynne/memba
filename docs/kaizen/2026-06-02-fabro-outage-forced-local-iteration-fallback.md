# Problem: Fabro outage forced local iteration fallback

Date: 2026-06-02

## Context

We were shepherding the delivery queue after iteration 017 had completed through Fabro. The next plan was `docs/iterations/018-member-club-subdomains/plan.md`.

The normal command was:

```sh
bin/dev fabro deliver docs/iterations/018-member-club-subdomains/plan.md --poll-interval 30
```

Relevant runs and commits observed:

- Iteration 017 implementation run: `01KT3K5Q9KBFXZ2XQGZKPNC67Q`, published `951ca8d8 iteration 017: Remove email open tracking`.
- Iteration 017 review run: `01KT3RSHJ7DQJYFQHXAMQ3Q8MY`, completed and left `origin/main` at `3f93fc40 iteration 017: mark merged`.
- Iteration 018 validation run: `01KT3TXYP7VZ85A8R7FDY2FWMR`, completed and marked the plan validated.
- Iteration 018 implementation run: `01KT3V4FSC1YK21HH9ZZJVYR7Q`.
- Recovery/status commits on `origin/main`:
  - `bd99deda iteration 018: mark implementing`
  - `955908ac iteration 018: restore validated after stalled implementation`
  - `1b8f033d iteration 018: mark implementing`
  - `e117ae14 iteration 018: restore validated after failed implementation`

## Expected standard

The delivery wrapper should be able to use Fabro as the standard implementation and review path:

1. validate the plan if needed;
2. reserve the implementation WIP slot by marking the plan `implementing`;
3. run the Fabro implementation workflow;
4. publish only after all implementation tasks are complete and `dev check` passes;
5. run the Fabro review workflow;
6. leave `origin/main` with accurate iteration status.

If Fabro cannot start, continue, inspect, steer, or remove a run, the failure should be obvious and recoverable without leaving ambiguous run state or forcing product implementation outside the workflow.

## What happened

Iteration 018 started through Fabro but then became abnormal.

The run branch showed a checkpoint commit whose subject said the workflow had reached `all_tasks_done`:

```text
origin/fabro/run/01KT3V4FSC1YK21HH9ZZJVYR7Q 7b0069d6 fabro(01KT3V4FSC1YK21HH9ZZJVYR7Q): all_tasks_done (succeeded)
```

However, the task list on that same run branch showed only task 001 complete and tasks 002-014 still unchecked:

```text
- [x] 001 Inspect current routing, `PageController`, member dashboard LiveView, member message routes, compose route, auth return-to handling, and URL generation helpers.
- [ ] 002 Add configuration for the club-site base domain and generated URL scheme/port where needed:
...
- [ ] 014 Run `dev check`.
```

Attempts to inspect or steer the run then timed out:

```text
fabro inspect 01KT3V4FSC1YK21HH9ZZJVYR7Q --json
× server request timed out after 30s

fabro steer 01KT3V4FSC1YK21HH9ZZJVYR7Q "...continue with the next unchecked task..."
× server request timed out after 30s

fabro rm -f 01KT3V4FSC1YK21HH9ZZJVYR7Q
error: 01KT3V4FSC1YK21HH9ZZJVYR7Q: server request timed out after 30s
```

`fabro doctor` later reported the configured server as unhealthy:

```text
Fabro Doctor

  Local
  [✓] Configuration (~/.fabro/settings.toml)

  Server
  [✗] Fabro server (health check failed)

Found issues in 1 category.

Errors:
  • Fabro server — Check that the server is reachable and responding to /health.
```

The remote health endpoint also timed out:

```sh
curl -m 10 -k -s -o /tmp/fabro_health_now -w '%{http_code}\n' https://fabro.home.wynne.family/api/v1/health
# 000
```

After the failed implementation launch, the wrapper restored iteration 018 to `validated` on `origin/main`:

```text
e117ae14 iteration 018: restore validated after failed implementation
```

Because the delivery path was blocked and the user had asked for the queue to be shepherded, a Pi `implementation-codex` subagent was used as a fallback to implement iteration 018 locally. That left uncommitted product changes in the working tree while the canonical iteration status on `origin/main` remained `validated`.

## Impact

This blocked the standard Fabro delivery path for iteration 018.

It also created confusing split state:

- `origin/main` correctly says iteration 018 is still `validated`, not delivered;
- a Fabro run branch appears to have reached `all_tasks_done` despite an incomplete todo list;
- local product-code changes exist outside Fabro's normal implementation/review/publish evidence trail;
- the user reasonably asked whether the feature should already work in production, because the local fallback made delivery state harder to explain.

The immediate customer-facing risk was controlled because the fallback changes were not committed or deployed. The delivery-system risk is higher: future work could accidentally treat local fallback implementation as delivered without Fabro review or production deployment.

## What allowed it to happen

Suspected system weaknesses:

- The implementation workflow or its evidence gate allowed an `all_tasks_done` checkpoint to be recorded when the checked task list still had many incomplete tasks.
- The operator-facing recovery path depended on the Fabro server being healthy; when the server timed out, `inspect`, `steer`, and `rm` could not recover or clearly classify the run.
- The wrapper could restore the plan status after a failed launch, but it could not resolve or quarantine the ambiguous remote run branch.
- There is no explicit standard for when it is acceptable to switch from Fabro delivery to a local Pi-agent fallback, or how to label that fallback so it cannot be mistaken for a delivered iteration.
- Health checks surfaced only “server health check failed” from the client perspective, without enough local context to distinguish remote service outage, routing/proxy failure, store lockup, or a long-running request bottleneck.
- The Fabro run sandbox could spawn enough repeated test processes to starve the Fabro service itself inside the same LXC, so one runaway run could make the control plane unable to inspect, steer, or stop that same run.

## Observations

- `origin/main:docs/iterations/018-member-club-subdomains/plan.md` was `Status: validated` after recovery.
- `origin/fabro/run/01KT3V4FSC1YK21HH9ZZJVYR7Q` existed and had recent checkpoint commits, but its `todo.md` showed only task 001 complete.
- `fabro doctor` against the configured target failed at server health.
- `curl` to `https://fabro.home.wynne.family/api/v1/health` returned HTTP code `000` after timing out.
- A local Pi subagent could still implement product changes, so the product work itself was not the blocking constraint; the delivery machinery was.
- The working tree contained uncommitted iteration 018 product changes after the fallback implementation.

## Later infrastructure findings

A Pi subagent investigated from `~/git/mattwynne/hub.local/` and found that the public endpoint, LAN endpoint, and reverse proxy evidence pointed to Fabro's LXC being alive but starved:

- `fabro.home.wynne.family` connected through TLS but timed out with no bytes.
- `http://192.168.1.201:32276/api/v1/health` also connected and then timed out.
- `https://proxy.home.wynne.family/` returned `200`, so the proxy itself was healthy.
- Proxmox showed LXC `115` named `fabro` running at `192.168.1.201/24` with `memory 2048`.
- The host load average was about `55`.
- The Fabro cgroup was at its 2 GB memory ceiling:

```text
memory.current 2132377600
memory.max     2147483648
```

- Pressure metrics were severe:

```text
cpu.pressure some avg10=100.00
memory.pressure some avg10=100.00 full avg10=91.14
io.pressure some avg10≈70
```

- The Fabro subtree had about `1088` processes.
- The dominant process pattern was repeated test processes:

```text
517 bash /workspace/memba/bin/mix test test/memba_web/club_site_config_test.exs
517 bash /repos/mattwynne/memba/bin/mix test test/memba_web/club_site_config_test.exs
```

- Those processes were inside Docker scope for the iteration 018 run container:

```text
/sys/fs/cgroup/lxc/115/ns/system.slice/docker-b746df316...scope
/fabro-run-01KT3V4FSC1YK21HH9ZZJVYR7Q
```

- The Fabro server process was still present:

```text
fabro server start --foreground --bind 0.0.0.0:32276
```

- Server logs showed very slow responses before unresponsiveness and a store warning:

```text
HTTP response ... /events status=200 latency_ms=33858
HTTP response ... /events status=200 latency_ms=20207
WARN ... Failed to write run event error=worker lost canonical run store during append run event
```

These findings make the likely immediate cause more specific: a runaway active run container for `01KT3V4FSC1YK21HH9ZZJVYR7Q` spawned roughly a thousand repeated `mix test test/memba_web/club_site_config_test.exs` processes, exhausting the 2 GB Fabro LXC and starving the control plane.

## Why this matters

Fabro is the standard delivery factory for these iterations. If it can stall, report contradictory task completion evidence, and then become unavailable to inspection/recovery, the operator has to choose between stopping delivery entirely or bypassing the factory. Either path creates waste and increases the chance that iteration state, code state, review evidence, and production expectations drift apart.

## Open questions

- Why did run `01KT3V4FSC1YK21HH9ZZJVYR7Q` reach an `all_tasks_done` checkpoint while `todo.md` still had unchecked tasks?
- What caused the run container to spawn hundreds of duplicate `mix test test/memba_web/club_site_config_test.exs` processes?
- Why were sandbox resource limits or process supervision unable to stop the runaway test loop before it starved the Fabro control plane?
- Does Fabro have enough run-local evidence to reconstruct what happened without the API being healthy?
- Should local fallback implementation be explicitly forbidden, allowed only with a named salvage branch, or wrapped in a documented recovery workflow?

## Possible prevention ideas

- Add a final task-list consistency gate that refuses `all_tasks_done` unless every item in the iteration `todo.md` is checked.
- Add a delivery-wrapper preflight that checks Fabro health before marking an iteration `implementing`.
- Add an offline or degraded-mode run inspection command that can read enough local/remote run evidence to classify stalled runs when the API is unhealthy.
- Add a documented “Fabro unavailable” recovery standard that says whether to pause, create a salvage branch, or use a local agent fallback, and how to keep the iteration status unambiguous.
- Isolate Fabro's control plane from run-container resource exhaustion, or give run containers strict process, CPU, memory, and timeout limits.
- Add a watchdog for runaway repeated commands inside a run container, especially when the same focused test command appears hundreds of times.
- Improve health-check diagnostics so operators can tell remote outage, proxy timeout, local server issue, store warmup/lockup, and sandbox resource starvation apart quickly.

## Resolution

Date: 2026-06-18

Root cause: The 2026-06-18 recurrence had the same control-plane starvation shape as this note, but a different immediate trigger. A review run (`01KVD4QS7YWV8WXTKT4VTY0AZW`) and an implementation run (`01KVD4QTPF926TR7PRT7H792VA`) started in parallel and both remained in setup for about 4.5 hours, each running `prepare_mix.sh` / `devenv shell ... mix deps.get`. The Fabro LXC was still limited to 2 GB RAM and 1 GB swap, so the two setup containers plus the Fabro server filled memory and swap. TCP connections to Fabro still opened, but `/health`, `/api/v1/health`, `fabro inspect`, and `fabro logs` stopped returning before client timeouts. Previous workflow fixes reduced runaway loops, but they did not address the control-plane capacity problem when multiple Docker sandboxes run concurrently on the same small LXC.

Fix applied:

- Host recovery: terminated the obsolete stuck Fabro workers and setup commands for runs `01KVD4QS7YWV8WXTKT4VTY0AZW` and `01KVD4QTPF926TR7PRT7H792VA`; both runs then became inspectable as `failed`, reason `terminated`.
- Host cleanup: stopped the two corresponding Docker run containers (`fabro-run-01KVD4QS7YWV8WXTKT4VTY0AZW` and `fabro-run-01KVD4QTPF926TR7PRT7H792VA`).
- Host capacity: increased Proxmox LXC 115 (`fabro`) from 2 GB RAM / 1 GB swap / 1 core to 4 GB RAM / 2 GB swap / 2 cores with `pct set 115 -memory 4096 -swap 2048 -cores 2`.
- `.fabro/workflows/iteration-review/workflow.toml`: added Docker resource limits (`cpu = 1`, `memory = "1024MB"`) so review sandboxes cannot individually consume the whole Fabro LXC while running alongside implementation sandboxes.

Validation:

- `curl -k -m 5 https://fabro.home.wynne.family/api/v1/health` — returned HTTP 200 after worker termination and after the capacity change.
- `fabro inspect 01KVD4QTPF926TR7PRT7H792VA` — returned `failed`, reason `terminated` instead of timing out.
- `fabro doctor` — server location and credentials passed; remaining warnings were version parity, missing Daytona sandbox, and missing Brave web search, not server health.
- `git show origin/main:docs/iterations/README.md | grep -n "034\|035\|036\|037"` — confirmed iteration state was not left ambiguous: 034 and 035 merged; 036 and 037 validated.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check` — passed with the expected existing goal-gate retry warnings.

Remaining follow-up:

- Add a repository-level or Fabro-level concurrency guard before deliberately running review and implementation in parallel again, or prove the new host/resource-limit configuration with two concurrent sandbox setup runs.
- Consider a lightweight host/runbook check that reports LXC memory, swap, and pressure metrics when Fabro health times out, so operators can distinguish proxy/network failure from control-plane starvation quickly.
