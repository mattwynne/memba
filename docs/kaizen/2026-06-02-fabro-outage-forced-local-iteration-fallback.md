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

## Observations

- `origin/main:docs/iterations/018-member-club-subdomains/plan.md` was `Status: validated` after recovery.
- `origin/fabro/run/01KT3V4FSC1YK21HH9ZZJVYR7Q` existed and had recent checkpoint commits, but its `todo.md` showed only task 001 complete.
- `fabro doctor` against the configured target failed at server health.
- `curl` to `https://fabro.home.wynne.family/api/v1/health` returned HTTP code `000` after timing out.
- A local Pi subagent could still implement product changes, so the product work itself was not the blocking constraint; the delivery machinery was.
- The working tree contained uncommitted iteration 018 product changes after the fallback implementation.

## Why this matters

Fabro is the standard delivery factory for these iterations. If it can stall, report contradictory task completion evidence, and then become unavailable to inspection/recovery, the operator has to choose between stopping delivery entirely or bypassing the factory. Either path creates waste and increases the chance that iteration state, code state, review evidence, and production expectations drift apart.

## Open questions

- Why did run `01KT3V4FSC1YK21HH9ZZJVYR7Q` reach an `all_tasks_done` checkpoint while `todo.md` still had unchecked tasks?
- Was the timeout caused by the remote Fabro service, a home-network/proxy path, a server-side store/lock issue, or something else?
- Does Fabro have enough run-local evidence to reconstruct what happened without the API being healthy?
- Should local fallback implementation be explicitly forbidden, allowed only with a named salvage branch, or wrapped in a documented recovery workflow?

## Possible prevention ideas

- Add a final task-list consistency gate that refuses `all_tasks_done` unless every item in the iteration `todo.md` is checked.
- Add a delivery-wrapper preflight that checks Fabro health before marking an iteration `implementing`.
- Add an offline or degraded-mode run inspection command that can read enough local/remote run evidence to classify stalled runs when the API is unhealthy.
- Add a documented “Fabro unavailable” recovery standard that says whether to pause, create a salvage branch, or use a local agent fallback, and how to keep the iteration status unambiguous.
- Improve health-check diagnostics so operators can tell remote outage, proxy timeout, local server issue, and store warmup/lockup apart quickly.
