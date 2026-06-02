# Problem: Plan validation depends on unsupported Codex model

Date: 2026-06-01

## Context

While validating iteration 016 (`docs/iterations/016-person-email-addresses/plan.md`), the standard command was run from the project wrapper:

```bash
bin/dev fabro validate-plan docs/iterations/016-person-email-addresses/plan.md
```

Fabro runs on the remote server. The first real validation run was:

- Run ID: `01KT2Z129Q0DEZ8YRC72N3Q9MD`
- Web UI: `https://fabro.home.wynne.family/runs/01KT2Z129Q0DEZ8YRC72N3Q9MD`

The workflow definition in `.fabro/workflows/plan-validation/workflow.fabro` explicitly routes these stages to a Codex model:

- `#codex_review { model: gpt-5.3-codex; reasoning_effort: high; }`
- `#codex_update { model: gpt-5.3-codex; reasoning_effort: high; }`

## Expected standard

Plan validation should be launchable through the documented command in `.fabro/workflows/README.md` and should either:

- validate and publish a ready plan as `validated`; or
- fail because the plan has real readiness gaps that need edits or Matt's input.

The model routing used by the workflow should be compatible with the remote Fabro server and account before the workflow reaches an implementation-relevant gate.

## What happened

The run read the plan successfully. Gemini and Claude both judged the plan `READY` with high confidence and no blocking gaps.

The `Codex/GPT Review` stage then failed with this error:

```text
LLM error: Invalid request to openai: The 'gpt-5.3-codex' model is not supported when using Codex with a ChatGPT acco...
```

Because the workflow expects all reviewer findings before synthesis, it failed closed and routed to `Fail: Plan Not Ready`. The plan stayed `ready` rather than being marked `validated`, even though the available reviewer evidence said it was ready.

A CLI-level model override did not help:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml \
  -I plan_path=docs/iterations/016-person-email-addresses/plan.md \
  --auto-approve \
  --model gpt-5.5 \
  --provider openai
```

That second run (`01KT2Z89F0AH6ND69DNG51DP3B`) still used the explicit `gpt-5.3-codex` node model and failed at the same stage.

The successful workaround was to copy the plan-validation workflow to `/tmp`, change only the explicit Codex node model settings to `gpt-5.5`, and run the temporary workflow. That run succeeded and published iteration 016 as validated:

- Run ID: `01KT2ZERQNQNRW1NMR7C8R7F83`
- Web UI: `https://fabro.home.wynne.family/runs/01KT2ZERQNQNRW1NMR7C8R7F83`
- Commit: `ee305d5a Mark iteration plan validated`

## Impact

This blocked normal plan validation and required operator diagnosis plus a temporary workflow patch. It also created avoidable extra Fabro runs and made the readiness signal ambiguous: the plan was substantively ready, but the workflow reported a not-ready path because one configured model was unavailable.

## What allowed it to happen

The workflow has hard-coded model choices for specific nodes, but there was no preflight or compatibility check to prove those models are available to the remote server/account before running the validation. The generic `--model`/`--provider` override did not override the explicit node stylesheet, so the obvious retry path did not repair the failure.

The failure mode also conflated infrastructure/model unavailability with plan readiness. The synthesis step failed closed, which is safe for product quality, but the reported workflow path did not clearly distinguish "review evidence missing because a model is unsupported" from "plan has readiness gaps".

## Observations

- The plan-validation workflow's model stylesheet explicitly names `gpt-5.3-codex` for `codex_review` and `codex_update`.
- The remote server rejected that model for the current account.
- Gemini and Claude both returned `READY`, high confidence, and no blocking gaps before the Codex stage failed.
- Retrying with CLI `--model gpt-5.5 --provider openai` did not change the node-level `gpt-5.3-codex` routing.
- A temporary workflow copy with Codex nodes changed to `gpt-5.5` completed successfully and published the validated status.
- The main repo also had an unrelated untracked file (`.github/workflows/continuous-delivery.yml`), so the workaround needed care not to include unrelated local changes.

## Why this matters

Future validations can fail for infrastructure reasons while appearing to fail as plan readiness problems. That wastes review cycles, encourages ad-hoc workflow copies, and makes it harder to trust the validation status as a clear signal.

## Open questions

- Which models should the remote Fabro server/account be expected to support for plan validation today?
- Should validation require a distinct Codex-family reviewer, or is an available OpenAI model acceptable for that role?
- Should node-level model overrides be configurable from the wrapper command for emergency retry?

## Possible prevention ideas

- Add a Fabro preflight check that verifies every model named in `workflow.fabro` is available before starting the run.
- Make infrastructure/model failures report a distinct outcome from plan `NOT READY`.
- Replace unsupported hard-coded models with supported ones, or route through a project-level model alias that can be updated centrally.
- Document a supported emergency retry path that does not require copying and editing the workflow by hand.

## Resolution

Date: 2026-06-01

Root cause: The plan-validation workflow pinned `codex_review` and `codex_update` to `gpt-5.3-codex`, but the remote Fabro server/account rejects that model. The node-level model stylesheet overrode the CLI `--model` retry option, so the standard validation command could not recover from the unsupported model.

Fix applied:

- `.fabro/workflows/plan-validation/workflow.fabro`: changed `codex_review` and `codex_update` from `gpt-5.3-codex` to `gpt-5.5`, matching the workflow default and the temporary validation run that successfully published iteration 016.

Validation:

- `fabro validate .fabro/workflows/plan-validation/workflow.toml --no-upgrade-check` — passed; workflow graph is valid.
- `dev check` — passed; 262 ExUnit tests, 0 failures.

Remaining follow-up:

- This fix removes the immediate unsupported-model dependency. A broader Fabro preflight or clearer infrastructure-failure outcome would still help prevent similar model-routing failures in other workflows.
