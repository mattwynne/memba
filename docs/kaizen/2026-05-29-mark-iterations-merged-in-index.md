# Kaizen: mark iterations merged in the index

Date: 2026-05-29
Status: implemented

## Context

Iteration review can merge an implementation branch, but the iteration index in
`docs/iterations/README.md` is separate status metadata. After iteration 002 was
reviewed, the table still said `ready-for-review`, which made it unclear what
should happen next.

## Change

Add a deterministic helper:

```bash
bin/dev iteration-mark-merged docs/iterations/NNN-topic/plan.md <branch> origin/main
```

The helper:

- resolves the implementation branch and `origin/main`;
- refuses to edit anything unless the branch commit is an ancestor of
  `origin/main`;
- updates `docs/iterations/README.md` to `merged` for that iteration;
- updates `Status: merged` in the iteration `plan.md` and `implementation.md`.

The iteration-review skill and workflow README now remind us to run this helper
after the merge is confirmed.

## Why this shape

This keeps status updates out of LLM prompts and avoids marking an iteration
merged before the branch has actually landed. The helper is safe to run manually
or from a future post-merge pipeline step.

## Follow-up

If we finish the direct-to-main workflow change, call this helper from the
post-merge delivery step so the metadata update lands automatically with the
pipeline's normal commit/push path.

## Resolution

Date: 2026-05-31

Root cause: The delivery workflow lacked a deterministic post-merge step to update the iteration index status.

Fix applied:

- `08a8019`: documented the iteration-mark-merged post-merge step.

Validation:

- Historical delivery evidence: the post-merge status step documentation is present on `main`.

Remaining follow-up:

- None for this note.
