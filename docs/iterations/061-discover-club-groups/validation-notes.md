# Planning checks for 061–065

Matt reviewed the rules and HTML prototype during planning. No further stakeholder review is required; Fabro validation remains pending.

- Native Gherkin parser: all 21 feature files parse; all 79 future expanded examples are excluded by the default domain/browser tag expressions.
- Prototype: 14 static renders and 20 walkthrough checks passed in the design worktree. Copied HTML scripts parse and local design-map links resolve. Local sources are sufficient; no cloud sync was completed.
- `./bin/dev check`: exit 0; 1,259 tests and 132 browser scenarios / 941 steps passed. Checked staged tree: `a38d430d354137c59ff428304b4207a9caf08565` on HEAD `a4dbf56e94cee750eee83b841c7571638f75e237`, unchanged before/after. Log: `/tmp/memba-group-planning/dev-check.log`. Subsequent cleanup changed only documentation and the design-map documentation link, not feature expectations or executable code.
- The standalone Node assertion in `acceptance-tests/test/cucumber_config.test.js:82` still assumes exactly eight debt-free 058 scenarios. It is not exercised by `dev check`. Update that bookkeeping during 061 delivery to accommodate later iterations while preserving old tags and regressions; do not preserve obsolete hidden-group behaviour just to satisfy it.

Publish these artifacts, then run `bin/dev fabro validate-plan` for each plan in sequence. Do not launch delivery without Matt's explicit approval.
