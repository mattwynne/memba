# Fabro 0.389 → 0.408: control provenance

This note supersedes the earlier inference that offline `ignored.*` warnings
established new losses of platform controls. **They do not.** Exact old and target
binaries report identical diagnostics, node counts and edge counts on all nine
current authored workflow entrypoints. Both releases already use Petri.

No control declarations, model selectors, prompts, graphs, backends or approval
policies were changed to silence these warnings. The separate `run.prepare`
migration remains necessary and unchanged.

## Owner choices recorded (2026-11-09)

Matt accepted the existing shared server-global Slack channel for this upgrade;
per-workflow routing is not a prerequisite. Verify the effective shared destination
before reopening submissions, while preserving human approval and authored intent.

Matt also accepted the existing Proxmox container-wide resource limits for this
upgrade. The individual Docker sandbox CPU/memory declarations remain unenforced;
upstream per-sandbox enforcement is not an upgrade prerequisite. Retain the
intent declarations without claiming enforcement or changing backends.

These decisions accept unchanged behavior, not weaker approval or credential
controls. They authorize neither live maintenance nor workflow/model execution.

## Immutable references and check boundary

| Component | Old | Target |
| --- | --- | --- |
| Fabro | `0.389.0-nightly.0`, [`5c90ad2e0c6662207a952afb303422e3388425d2`](https://github.com/fabro-sh/fabro/tree/5c90ad2e0c6662207a952afb303422e3388425d2) | `0.408.0-nightly.0`, [`77df2763f996f480f63156de55da281973fc40fd`](https://github.com/fabro-sh/fabro/tree/77df2763f996f480f63156de55da281973fc40fd) |
| Locked Petri | [`56ec3849ca693974ff778aa5ad4f9f9410d47d29`](https://github.com/lithoscomputer/petri/tree/56ec3849ca693974ff778aa5ad4f9f9410d47d29) | [`f30a12df140fb60f55a7c6cff3d7f45673c7a7c5`](https://github.com/lithoscomputer/petri/tree/f30a12df140fb60f55a7c6cff3d7f45673c7a7c5) |

Both temporary official macOS ARM64 binaries were checked against release asset
and published archive SHA-256 values:

- Old: `8c4ac562d3dc698144f17e2bb1370e347fea9f1621cc0c966ac28bd0f96cd7ea`.
- Target: `b584274b2458b68dec724b8e9f9dc8b54c2aee1d44893003ac0f221a9e56ea92`.

Only `--version` and `--json validate` were invoked. Validation used controlled
source copies without Git metadata, isolated HOME/FABRO_HOME/cache, no credentials
or user settings, telemetry off, network denied, child executable launches denied,
and writes restricted to temporary scratch. Neither executable was installed.
No server, workflow, sandbox, model request or provider request was started.

`lib/apps/fabro-server/src/manifest_validation.rs` is byte-identical across these
Fabro revisions. Its `validate_manifest` deliberately supplies no model client.
The `ignored.workflow_toml.*` messages come from Petri's
`crates/fabro/frontend/src/workflow_toml.rs`, whose `RUN_SECTIONS_IGNORED` describes
what the **standalone** runner does not implement. They must be traced through
Fabro's embedding host before classifying actual platform behavior.

## Findings by control

### Checkpoint exclusions and durability: host-consumed, unchanged

Affected: `code-review`, `iteration-implementation`, `bdd-plan-implementation` and
`bdd-plan-implementation/scenario`.

In both Fabro releases:

1. `lib/apps/fabro-cli/src/commands/run/petri_worker.rs` calls
   `HooksSpec::for_run` with the admitted `settings.run` and installs those hooks.
2. `lib/components/fabro-petri/src/hooks.rs::HooksSpec::for_run` obtains
   `RunGitSettings::from(settings)`.
3. `lib/components/fabro-petri/src/checkpoint.rs` copies
   `settings.checkpoint` and `exclude_globs`. Checkpoint staging uses Git exclude
   pathspecs; recovery cleaning also excludes those paths. This file is
   byte-identical across the two pinned releases.
4. Fabro's hooks await checkpoint commits; checkpoint failure cancels the run and
   is surfaced as a required-finalization failure, rather than accepting work
   without its checkpoint.

Keep every authored exclusion. The standalone diagnostic is not evidence that
Fabro stopped applying exclusions or stopped making durable checkpoints. These
are source-trace conclusions, not a newly executed checkpoint/recovery test.

### Artifact selection: host-consumed, unchanged selection policy

Affected: both BDD entrypoints.

`HooksSpec::for_run` copies `settings.artifacts.include` in both releases. The
worker supplies the platform artifact writer; the hooks match the configured
workspace globs, store bytes before recording collection, and deduplicate by
path/content. Existing selection limits are 100 files, 10 MiB per file and
50 MiB total per selection, in both versions. Target additionally records notices
for oversized omissions; the limits are not new losses.

Keep the authored artifact include globs and checkpoint exclusions: excluded
scratch is intentionally collected as artifacts, not put into checkpoint Git.
The warning's claim that only the whole retained workspace is the result describes
standalone Petri, not the Fabro worker's artifact collector.

### GitHub integration configuration: host-consumed credential policy

Affected: both BDD entrypoints, which explicitly set `permissions = {}`.

In both versions, `lib/foundation/fabro-config/src/layers/run.rs` combines this
optional map by replacement: an explicit empty higher layer clears an inherited
permission request. `RunIntegrationsGithubSettings::is_token_requested` in
`lib/foundation/fabro-types/src/settings/run.rs` returns false for an empty map.
`lib/components/fabro-petri/src/stage_credentials.rs::StageCredentials::for_run`
only creates the API-token source when this predicate is true. Managed checkout
read credentials and publication credentials are separate facilities; empty
integration permissions are not a claim that no Git credentials ever exist.

Keep the explicit empty map. Removing the warning by deleting it could re-enable
an inherited token request. No credentials were inspected, moved or broadened.

### Slack delivery: pre-existing server-global routing, owner choice

Affected: `code-review`, `iteration-implementation`, `iteration-clarification`,
`slack-prose-smoke`, `slack-question-smoke`.

All five retain their authored Slack destination intent and human approval
configuration. However, `run.interviews` does **not** select the Slack destination
in either pinned release. `lib/apps/fabro-server/src/server.rs::post_question`
is byte-identical and reads only `self.default_channel`, populated from
`server.integrations.slack.default_channel`; without one it does not post the
question. The target's `docs/public/integrations/slack.mdx` and
`docs/public/human-tools/interviews.mdx` describe this server-level requirement.

Human gates still use `ControlInterviewer` and the questions/control API in both
versions. `FabroInterviewer` waits for a person under prompt approval; the worker
selects automatic answers only when effective execution approval is `auto`.
Do not add auto-approval or replace a human gate to address delivery warnings.

This is not a newly introduced regression, and a warning alone does not establish
whether the server is already configured correctly. A workflow cannot safely
establish a shared server's destination. The owner choices were shared routing
versus requiring upstream per-workflow routing; Matt selected shared routing as
recorded above. No server configuration or live delivery was inspected here.
Retain declarations as intent and verify the effective shared destination; do
not put Slack credentials in workflow environments or custom hooks as a workaround.

### Docker resource limits: pre-existing wiring gap, owner choice

Affected: the same five workflows declare CPU/memory intent for Docker.

Both `fabro-petri/src/engine.rs` revisions copy resources into runtime options only
when `backend == SandboxBackend::Daytona`. Both pinned Petri Docker spec builders
in `crates/core/executor-sandbox/src/lib.rs` leave sandbox resources unset; the
Fabro frontend creates default container options. The resource warning accurately
states that Docker is unconstrained on this path in both releases.

The driver itself supports CPU/memory limits:
`sandbox-driver-docker/src/create.rs` maps `spec.resources` to Docker `memory` and
`cpu_quota` at driver revisions `4b35158b591337a9ac17295ca53158f9e8ce4029` (old) and
`0fe4af55c9ddb3887cbcbf6e78d24490501df047` (target). The missing link is upstream
Fabro/Petri wiring, not the authored values. The environment documentation's
Docker limit table is not proof of that wiring.

Keep the limits declared and do not claim they are enforced. Matt accepted the
unchanged baseline with Proxmox container-wide limits, as recorded above; upstream
per-sandbox wiring/enforcement is not a prerequisite for this upgrade. This is a
pre-existing intent gap, not a newly introduced regression.
Changing to Daytona, privileged container manipulation or shell `ulimit` would
change backend/security or constrain only some processes, not preserve the
intended whole-container limits. None is an approved equivalent here.

### Goal gates without retry targets: unchanged fail-closed behavior

Affected: `code-review` (`final_summary`), `iteration-implementation`
(`publish_to_main`), `plan-validation` (`publish_ready`).

Petri's `crates/attractor/frontend/src/lower/loops.rs` is byte-identical across the
pins. It inserts a goal check before exit and requires every gate's success-like
record. Without a retry target, an unsatisfied gate ends the run failed. These
workflows intentionally supply no automatic re-entry target. Adding one merely to
remove a diagnostic could repeat publication or bypass the intended recovery
boundary. Keep the gates and terminal failure policy.

### Imported model stylesheet: unchanged, currently equivalent rules

Affected: `bdd-plan-implementation` imports its scenario graph.

Both pinned `crates/attractor/frontend/src/lower/imports.rs` versions warn and
ignore an imported graph's stylesheet; the importing graph governs. The parent's
and scenario's authored rules are identical and uniform. Keeping both preserves
standalone scenario routing and imported routing without any model change.
Regression tests enforce this equality so future drift is not silently accepted.

### Budget diagnostics: unchanged existing bound

Affected: `plan-validation` and both BDD entrypoints.

Both pins lower otherwise-unbounded loop visits to `MAX_FIRINGS = 500` and report
`info.budget.default`. The budget-lowering source is identical. No new cap or
visit-policy change is needed for migration, and no explicit limit was added to
silence a pre-existing default diagnostic.

## Regression checks and remaining boundary

Run `python3 .fabro/workflows/scripts/test_workflow_control_contracts.py` for the
seven authored retention/documentation checks. Add `--upstream-root <directory>`
for six further pinned source and dual-binary validation checks. The expected
archive layout is named explicitly in the script; download/verification of public
artifacts is separate, never automatic. With that option all 13 checks must run;
without it the provenance class is explicitly skipped, not claimed tested.

The setup migration's separate offline contract test remains unchanged. No
workflow-source controls need deletion or renaming based on these diagnostics.
This comparison establishes no new regressions in the investigated controls, not
full runtime compatibility or rollout readiness. The shared Slack destination and
container-wide-only Docker resource baseline are explicitly accepted above, not
silently assumed. Registered bundles, managed checkout, exact client/server
coordination, external hooks and provider readiness still require their separate
review/authorization.
