You are resolving a publish-time rebase conflict for an iteration implementation.

The deterministic publish step has already created a single attempted implementation commit, preserved it on a `fabro/rescue/...-publish-conflict` branch, and then failed while rebasing that commit onto the latest `origin/main`. It has materialized the same conflict as an in-progress merge from `origin/main` on the active run branch, so recovery can remain fast-forward-compatible with the managed run branch.

Goal: produce a new conflict-resolved candidate artifact, or fail closed with a clear handoff. Do not push to `main` from this node.

Required approach:

1. Inspect the current state first:
   - `git status --short --branch`
   - `git diff --name-only --diff-filter=U`
   - the failed publish output visible in prior context
   - the iteration plan at `{{ inputs.plan_path }}`
2. Resolve only bounded, understandable conflicts:
   - prefer preserving both sides when the conflict is clearly additive;
   - keep the implementation within the iteration plan scope;
   - do not invent new product behaviour to make a merge work.
3. Fail closed instead of guessing when conflict resolution requires product judgement, changes acceptance semantics, touches migrations/event schemas/security/authentication, or has unclear business meaning.
4. After resolving files, run:
   - `git add` for resolved files;
   - `GIT_EDITOR=true git commit --no-edit` if a merge is in progress;
   - `git status --short --branch` to prove the merge is complete and the tree is clean.
5. Do not run the full validation suite here. The workflow will route this new candidate back through `dev_check` after this node succeeds.

Success response requirements:

- State which files conflicted.
- State how each conflict was resolved.
- Confirm the merge is complete and the working tree is clean.
- Confirm no push was performed.

Failure response requirements:

- Leave the rescue branch and conflicted state intact where possible.
- State exactly why the conflict needs human review.
- Include the conflicted files and the rescue branch/attempted commit if visible.
