# Problem: Fabro marked iteration 016 merged while tasks were still incomplete

Date: 2026-06-01

## Context

We were asking Fabro to finish the current iteration and then start the next one with a review/fix loop.

Relevant iteration plans:

- `docs/iterations/016-person-email-addresses/plan.md`
- `docs/iterations/017-remove-open-tracking/plan.md`
- `docs/iterations/README.md`

Relevant Fabro runs and branches:

- Iteration 016 implementation run: `01KT329V7X61YAG1PJ00TCBH59`
  - Web UI: `https://fabro.home.wynne.family/runs/01KT329V7X61YAG1PJ00TCBH59`
  - Branch: `origin/fabro/run/01KT329V7X61YAG1PJ00TCBH59`
- Iteration 016 review run: `01KT39G3BCGWESB6GNEQDTCAW7`
  - Web UI: `https://fabro.home.wynne.family/runs/01KT39G3BCGWESB6GNEQDTCAW7`
  - Branch: `origin/fabro/run/01KT39G3BCGWESB6GNEQDTCAW7`
- Iteration 017 implementation run that was started too early: `01KT3A6RKDN4AWT9A4B57VEAM0`
  - Web UI: `https://fabro.home.wynne.family/runs/01KT3A6RKDN4AWT9A4B57VEAM0`
  - Branch: `origin/fabro/run/01KT3A6RKDN4AWT9A4B57VEAM0`

## Expected standard

The iteration workflow should preserve one implementation WIP slot and should only mark an iteration `merged` after the implementation is complete, reviewed, and safely published to `main`.

Expected safeguards:

- `docs/iterations/README.md` and each plan's `Status:` should reflect the real lifecycle state.
- `todo.md` generated from the implementation plan should not have unchecked work when the iteration is marked `merged`.
- A review workflow should review the final implementation artifact, not an intermediate snapshot.
- Starting iteration 017 should be blocked while iteration 016 is incomplete or active.
- If a local Fabro command times out while the remote run continues, the operator should get an obvious durable signal and a safe recovery path.

## What happened

Iteration 016 was marked `merged` even though its implementation task list was still incomplete, and the original implementation run continued pushing commits afterwards.

Key commit evidence:

- `0a676c5c92be3d414840b0190fc50d13f56a9e04`
  - `iteration 016: mark implementing`
  - Author/committer: `Fabro <fabro@users.noreply.github.com>`
  - Date: `2026-06-01T19:23:45-07:00`
- `3d296a543d5b086e3f8c8d61ed168b40a1975155`
  - `fabro(01KT39G3BCGWESB6GNEQDTCAW7): publish_polish_to_main (succeeded)`
  - Author: `Fabro <noreply@fabro.sh>`
  - Date: `2026-06-02T04:40:33Z`
- `954371db5bf6c972011aa4daabab3cb310d5cd6a`
  - `iteration 016: mark merged`
  - Author/committer: `Fabro <fabro@users.noreply.github.com>`
  - Date: `2026-06-02T04:40:37Z`
  - Changed only `docs/iterations/016-person-email-addresses/plan.md` and `docs/iterations/README.md`, setting iteration 016 from `implementing` to `merged`.
- `eb540414ab3a0cd7c47128082bc8eb0abb9e0000`
  - `iteration 017: mark implementing`
  - Parent: `954371db5bf6c972011aa4daabab3cb310d5cd6a`
  - This started iteration 017 from the false premise that 016 was merged.
- `cb4f41be43bc4a5f752ecb0f06acef5dc018157a`
  - `iteration 017: restore validated after failed implementation`
  - The local `bin/dev fabro deliver docs/iterations/017-remove-open-tracking/plan.md` command timed out while the remote run continued.
- `8392732d218ad68f09a4f15bb62f252edb457779`
  - `iteration 016: restore implementing status`
  - Manual correction after we discovered the mismatch.

At the time of investigation, `origin/main` had iteration 016 marked `merged`, but `docs/iterations/016-person-email-addresses/todo.md` on `origin/main` still had these unchecked tasks:

- 012 Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.
- 013 Add dedicated staff routes and LiveViews under the existing `/admin` staff LiveSession.
- 014 Replace the inline person creation form on `MembaWeb.Admin.ClubsLive.Show` with a “New person” link.
- 015 Build staff forms as repeated email rows with one primary radio button.
- 016 Update staff/operator person displays to show primary and alternate addresses distinctly.
- 017 Update seeds, fixtures, browser acceptance support, and tests.
- 018 Add/enable the planned Cucumber scenarios in `acceptance-tests/features/person_email_addresses.feature`.
- 019 Run targeted checks and `dev check`.

The continuing 016 implementation branch later showed progress beyond `main`, including new files not present on `origin/main` at that time:

- `web/lib/memba_web/live/admin/people_live/new.ex`
- `web/lib/memba_web/live/admin/people_live/edit.ex`
- `web/lib/memba_web/live/admin/person_email_address_form.ex`
- `web/test/memba_web/live/admin_people_live_test.exs`

But even the latest inspected 016 run branch still had tasks 016–019 unchecked. `fabro inspect 01KT329V7X61YAG1PJ00TCBH59 --json` reported the run as still `running`, with checkpoint state around `all_tasks_done -> implement_next_task`, while `origin/main` had already been marked merged earlier.

Iteration 017 also began and made partial progress before we stopped it:

- `origin/fabro/run/01KT3A6RKDN4AWT9A4B57VEAM0` had `docs/iterations/017-remove-open-tracking/todo.md` with tasks 001–004 checked and tasks 005–010 unchecked.
- We attempted `fabro steer --interrupt` to pause it, but the run completed another task anyway.
- We then used `fabro rm -f 01KT3A6RKDN4AWT9A4B57VEAM0`, after which `fabro inspect` no longer found the run. Its remote branch remained as salvage evidence.

## Impact

This created serious delivery-pipeline confusion and avoidable risk:

- `origin/main` contained a false lifecycle signal saying iteration 016 was merged.
- The predecessor check allowed iteration 017 to start because it trusted the false status.
- Work for iteration 017 overlapped with unfinished 016 work, increasing conflict and salvage risk.
- The implementation and review state became split across `main`, a still-running 016 branch, and a stopped partial 017 branch.
- The operator had to do manual Git/Fabro forensics to discover which artifacts were real and which statuses were stale.
- There is risk of losing useful 017 work or accidentally publishing 017 changes before 016 is genuinely complete.

## What allowed it to happen

Suspected system weaknesses:

- The review/finalization workflow can mark an iteration `merged` without verifying that the implementation `todo.md` has no unchecked items.
- The review workflow appears to have reviewed/published an intermediate artifact from iteration 016 while the original implementation run was still active.
- The iteration status in `docs/iterations/README.md` is treated as authoritative by predecessor/WIP checks, but it can become false relative to the active Fabro run state and task list.
- Local command timeout/error handling allowed the CLI wrapper to continue with recovery logic while the remote Fabro engine kept running.
- `fabro steer --interrupt` was not a reliable pause/stop control for the 017 run; it accepted the request but the agent still completed another task.
- There is no obvious guardrail that says: do not start/restart a later iteration if any earlier Fabro implementation run is still `running`, even if Git says the earlier plan is `merged`.
- The implementation run's task list and the review/finalization status were not reconciled before advancing the iteration lifecycle.

## Observations

- `origin/main` after the bad merge had `docs/iterations/016-person-email-addresses/plan.md` with `Status: merged` while the same branch's `todo.md` had unchecked implementation tasks.
- `git show 954371db -- docs/iterations/016-person-email-addresses/plan.md docs/iterations/README.md` showed that the merge-status commit only changed lifecycle metadata.
- `git merge-base --is-ancestor origin/fabro/run/01KT329V7X61YAG1PJ00TCBH59 origin/main` returned false during investigation: `origin/main` did not contain the latest 016 run branch.
- `git merge-base --is-ancestor origin/main origin/fabro/run/01KT329V7X61YAG1PJ00TCBH59` also returned false: the still-running 016 branch and `main` had diverged.
- The 017 run branch remained available for salvage after forced removal, with tasks 001–004 checked in `docs/iterations/017-remove-open-tracking/todo.md`.
- During 016 validation, Fabro hit a sandbox Postgres/process issue: `Postgres did not become ready at PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432` and repeated `FATAL: lock file "postmaster.pid" already exists`. The agent diagnosed a zombie postgres PID and cleared stale lock/socket files, then reran `dev check` successfully with `343 tests, 0 failures`. This is separate friction but contributed to the complexity of tracking whether the run was progressing.

## Why this matters

A workflow that can falsely mark incomplete work as merged undermines the whole iteration gate. Once the lifecycle metadata lies, downstream automation does the wrong thing confidently: it starts later work, runs reviews against the wrong artifact, and makes humans reconstruct state from branches, run IDs, todo files, and logs.

This is a quality risk as well as a productivity problem. A future occurrence could publish partially implemented behaviour or let conflicting iterations interleave in a way that loses work or hides missing acceptance coverage.

## Open questions

- Why did review run `01KT39G3BCGWESB6GNEQDTCAW7` accept and finalize iteration 016 while the original implementation run `01KT329V7X61YAG1PJ00TCBH59` was still running?
- Did the review run start from an earlier checkpoint or branch that appeared complete to its evidence collection, or did its gates fail to inspect `todo.md` completion?
- Why did the original implementation run continue after the CLI timeout and after iteration status was marked `merged`?
- Should `fabro rm -f` or another command be the supported way to stop a running workflow, and should `fabro steer --interrupt` be documented as not sufficient for pausing a workflow?
- How should we safely salvage the partial 017 branch after 016 genuinely finishes?

## Possible prevention ideas

- Make finalization refuse to mark an iteration `merged` unless `docs/iterations/<iteration>/todo.md` exists and contains no unchecked `- [ ]` tasks.
- Make `bin/dev fabro deliver` and `bin/dev fabro review` check active Fabro run state, not just `docs/iterations/README.md`, before starting later iterations or review.
- Add a final review gate that verifies the reviewed branch is the terminal implementation artifact for the selected iteration and that no same-iteration implementation run is still active.
- Make status restoration after a failed/timed-out implementation launch detect whether the remote run is still running before changing the plan status back.
- Add a `bin/dev fabro pause/stop <run>` or documented safe-stop procedure that is reliable and obvious to operators.
- Include run IDs and branch names in status commits or iteration metadata so Git lifecycle state can be traced back to the responsible Fabro run without archaeology.
