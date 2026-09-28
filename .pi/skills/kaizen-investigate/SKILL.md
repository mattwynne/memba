---
name: kaizen-investigate
description: Investigate a docs/kaizen observation, establish evidence-backed causes and resolution options, and record the assessment without implementing a fix. Use when asked to investigate, diagnose, or propose options for a kaizen note.
---

# Kaizen Investigate

Turn a `docs/kaizen/` delivery-machinery observation into an evidence-backed assessment. This stage **does not implement countermeasures**: leave workflow, script, skill, and product behaviour unchanged. Record what is known, what remains uncertain, and an actionable recommendation in the original note. An investigation with a pending human decision is a complete investigation, not a completed fix.

Use this for workflow/tooling friction, not ordinary product bugs unless they expose a delivery-system weakness. For end-to-end capture and repair use `kaizen`; for an already investigated note needing implementation use `kaizen-fix`.

## Select a note

- Resolve a supplied path, title, or slug to exactly one top-level `docs/kaizen/*.md` note. If none matches, report it; if several match, ask which one.
- Without a specified note, list top-level Markdown notes newest first, excluding `README.md`. Consult the ledger, but confirm from the note and relevant git history whether it still needs investigation. An options section alone does not mean a fix has been applied. If history proves a candidate already resolved, backfill its resolution and ledger rather than presenting it as unresolved.
- If none needs investigation, say so. Select a sole candidate automatically and name it; for multiple candidates, give a short numbered list with path and title and ask the user to choose **before investigating**. Check targeted `git log --oneline -- <note>` and, when useful, `git log --oneline --grep='<keywords>'` before presenting stale candidates.
- If a note already contains a substantive investigation, use it as a starting point; update it only for new evidence or a requested reassessment. Do not repeat work simply because no fix has been applied.

## Investigate

1. Run `git status --short --branch`. Protect unrelated work; if the investigation would overlap it, ask how to proceed.
2. Read the note fully, including its context, failures, evidence, questions, and relevant commands. Inspect the referenced logs, history, workflows, prompts, scripts, skills, and docs. Reproduce or validate cheaply and safely when possible.
3. Use [A3 problem-solving](a3-problem-solving.md) to frame the current and target conditions and possible countermeasures, scaled to the problem. For failures, surprising behaviour, or unclear causes, load and follow `/systematic-debugging` before proposing a solution. Use [Five Whys](five-whys.md) to trace evidence-supported causes and their escape path. Branch rather than forcing a single cause or exactly five answers. Separate facts from hypotheses; name unknowns and how to test them.
4. Explain the smallest supported causal mechanism and where it lives (code, prompt, workflow, handoff, environment, docs, or procedure). Distinguish immediate correction, detection/containment, and prevention. Offer viable options, trade-offs, a recommendation, and a validation/effectiveness plan. If the cause is external, identify the owner or next action rather than claiming a repository fix is possible.
5. Append or refine `## Investigation` in the original note without rewriting the observation. Include date, evidence, causal mechanism or uncertainty, options and recommendation, expected versus observed condition, validation plan, and any decision needed. If the note already has a resolution section, preserve it; do not call an unimplemented proposal a resolution. When the choice depends on user priorities, explain the system, evidence, options and recommendation in plain language, then ask one focused question at a time. Record the resulting choice or pending decision; **do not apply the fix in this stage**.
6. Maintain the note's row in `docs/kaizen/README.md`: `Open` if assessed and worth addressing, `Closed` only if no further action is intended or a prior outcome is documented. `Experiment` requires explicit approval of an active experiment and agreed review date; all other review dates are `—`. Do not infer status from headings. Verify every top-level note has exactly one valid linked row, no missing targets, and at most one `Experiment`.
7. Review `git status --short` and `git diff --stat`; commit only the investigation, note, and ledger changes with a concise `kaizen: investigate <problem>` message unless asked not to commit. Do not push without an explicit request. For docs-only changes follow project-specific validation rules; run checks appropriate to any executable changes (normally there should be none).

Report the selected note, findings and evidence, recommendation or open decision, changed files, validation, commit (or why none), and what remains for `kaizen-fix`. Do not claim the problem was fixed by investigation.
