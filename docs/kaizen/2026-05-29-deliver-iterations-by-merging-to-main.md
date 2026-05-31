# Kaizen: deliver iterations by merging to main, drop PRs

Date: 2026-05-29
Status: implemented

> Supersedes the PR/auto-merge delivery references in the resolution plan of
> `2026-05-28-extract-iteration-review-workflow.md` (Change 1/Change 2 say "PR +
> squash-merge" / "rides the squash-merge"). Those entries are left as-is; where
> they describe *delivery*, read this kaizen instead. The smell-alerting and
> simplification decisions there still stand.

## Context

Today the two workflows have two separate merge/PR points:

- `iteration-implementation` ends by creating a pull request, which it never
  merges.
- `iteration-review` is the node that actually auto-squash-merges the branch to
  `main` (`[run.pull_request] auto_merge = true, merge_strategy = "squash"`).

The implementation PR is effectively vestigial: it sits open until review merges
the branch. PR creation has also been a recurring failure surface — it depended
on an Anthropic-backed LLM call and broke on credit exhaustion
(`2026-05-29-pr-creation-should-not-depend-on-llm.md`).

Meanwhile we have reframed review as a code-polish + smell radar that runs on
*already-conforming* code, and moved plan conformance into the implementation
workflow (`2026-05-29-move-plan-conformance-to-implementation.md`). Once
implementation owns correctness — green `dev check`, plan conformance, ADRs —
there is nothing left for review to *gate*. A PR that no human reviews, merged
automatically by a downstream workflow, is ceremony.

Memba is a solo, trunk-based project. The README already states each iteration
is independently shippable and leaves `main` green. Direct merges to `main` are
the honest model.

## Decision

- **Implementation merges directly to `main`. No PR.**
- **Review runs after the merge, against `main`, and fixes forward. It never
  blocks and never opens a PR.** Bounded fixes are pushed to `main`;
  judgement-worthy findings are logged to `docs/code-health.md` (per the
  simplification resolution plan). A flagged issue is briefly live on `main`
  until the human acts; that is acceptable for this trunk.

## Resulting flow

```
iteration-implementation:  build → green dev check → plan conformance
                           → squash-merge to main           (no PR)

iteration-review (after):  clone main → review the iteration's diff
                           → auto-fix bounded issues → re-run dev check
                           → push polish to main → log judgement findings
                                                    to docs/code-health.md
                           (no PR, no gate, never blocks)
```

## Design rules

1. **Review must never push red.** Review applies fixes, then re-runs `dev
   check`, and pushes to `main` only if green. If a fix regresses and cannot be
   repaired within budget, it discards the fix, leaves `main` untouched, and
   logs a judgement finding ("attempted X, regressed, left as-is"). This is the
   hard invariant that makes fix-forward safe.

2. **Commit shape.** Implementation squashes its per-task commits into one
   `iteration NNN: <title>` commit on `main` (clean trunk history). Review's
   polish lands as a separate follow-up commit (`review polish: iteration NNN`)
   so history shows what was implemented vs. what review changed.

3. **No `[run.pull_request]`.** Both `workflow.toml`s drop the PR/auto-merge
   block and end in a deterministic "commit + push to `main`" step, with a `git
   pull --rebase` guard against a moved `main`. (Verify Fabro can push to the
   base branch without opening a PR; this is an implementation detail, not a
   design unknown.)

4. **Run metadata moves to the commit trailer.** The data the old PR body
   carried — run id, workflow, plan path, base/head SHA, validation outcome —
   goes into the merge commit message as deterministic trailer lines. No LLM on
   the delivery path (closes the concern in
   `2026-05-29-pr-creation-should-not-depend-on-llm.md` by removing the PR
   entirely).

## Acceptance criteria

- Neither `iteration-implementation` nor `iteration-review` creates a pull
  request; neither `workflow.toml` contains a `[run.pull_request]` block.
- A successful implementation run lands exactly one squashed
  `iteration NNN: ...` commit on `main` with deterministic run metadata in the
  commit trailer.
- A review run pushes polish to `main` only when `dev check` is green after its
  fixes; a regressing fix leaves `main` unchanged and is logged to
  `docs/code-health.md`.
- Review never blocks and never opens a PR; judgement-worthy findings appear
  only in `docs/code-health.md`.
- Both workflows validate with `fabro validate`.

## Risks / follow-ups

- **Racing `main`.** Two runs (or a manual edit) advancing `main` concurrently
  could conflict on push. Low risk on a solo trunk; mitigate with `git pull
  --rebase` before push and fail loudly on conflict rather than force-pushing.
- **No automatic rollback.** Fix-forward means a bad iteration is corrected by a
  follow-up commit or manual revert, not by withholding a merge. Acceptable
  given the trust level; revisit if `main` stability suffers.
- **Push credentials in the sandbox.** Both workflows now need push access to
  `main` from the Fabro sandbox. Confirm the sandbox's git credentials and
  branch-protection settings allow direct pushes to `main`.
- **Depends on plan conformance actually moving into implementation**
  (`2026-05-29-move-plan-conformance-to-implementation.md`). If review still had
  to gate correctness, fix-forward would be unsafe.

## Resolution

Date: 2026-05-31

Root cause: Delivering through PR creation added unnecessary model/tooling dependence for the current iteration workflow.

Fix applied:

- `2c685b1`: changed the delivery path to push/merge iterations to `main` directly.

Validation:

- Historical delivery evidence: the direct-to-main delivery workflow commit is present on `main`.

Remaining follow-up:

- None for this note.
