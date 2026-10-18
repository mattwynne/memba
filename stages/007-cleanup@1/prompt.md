Goal: Implement one agreed scenario; check and review it, but do not publish
Run ID: 01M57Y8PZS00BPHM6ZWFZDRCAE


You are a fresh refactoring driver. Read `docs/iterations/068-member-name-editing/plan.md`, its relevant links, project guidance and `.fabro/tmp/bdd/change.md`. Preserve behaviour and work on that one cleanup. Do not publish or weaken tests.

Run the assigned ordinary scenario command (not `dev test:wip`), supporting units and affected earlier examples before editing; predict green. If any are red, missing or not selected, return without edits.

Make the cleanup, format it and rerun those tests. Predict before running commands. You may repair regressions caused by your own cleanup within its scope; return to the navigator if the assignment needs changing. Finish when the relevant tests are green again.

Save actual command output and exit status in distinct logs under `.fabro/tmp/bdd/`. Write `.fabro/tmp/bdd/result.md` with what changed, the commands and results, log paths, and any unresolved problem. Incomplete work can always return; no special verdict is needed.