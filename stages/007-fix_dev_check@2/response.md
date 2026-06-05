Dev check failure resolved without code/config/test changes.

## 1. Dev check failure from preceding stage

| Failure | Cause | Classification |
|---|---|---|
| `npm test` failed with `sh: line 1: cucumber-js: command not found` | `acceptance-tests/node_modules` was absent, so the declared `@cucumber/cucumber` binary was not installed locally | Sandbox/setup dependency issue, not product code |

The shell also has `HOME=/env`, which is not writable for npm cache use in this sandbox. Installing normally can fail unless npm is given a writable HOME/cache.

## 2. Changes made

No tracked code, config, dependency, test, or acceptance feature changes were needed or made.

Environment-only action taken:

```sh
cd acceptance-tests
HOME="$PWD/../.fabro/tmp/npm-home" npm ci --cache "$PWD/../.fabro/tmp/npm-cache"
```

That installed the already-declared acceptance npm dependencies using a writable temporary cache. After that, the unchanged suite passed.

## 3. Files changed

No tracked files changed.

Current status:

```text
?? .fabro/tmp/
```

Notes:

- `.fabro/tmp/` contains temporary run/cache state.
- `acceptance-tests/node_modules` was installed as an ignored local dependency artifact.
- No `*.feature` files were edited.

## 4. Tests run and results

| Command | Result |
|---|---|
| `cd acceptance-tests && HOME="$PWD/../.fabro/tmp/npm-home" npm ci --cache "$PWD/../.fabro/tmp/npm-cache"` | Passed; installed 119 packages |
| `PATH="$PWD/bin:$PATH" dev ci` | Passed |

`dev ci` results:

- ExUnit: `528 tests, 0 failures`
- Acceptance: `38 scenarios passed`, `252 steps passed`

## 5. Remaining failures or questions

No remaining test failures in the current workspace.

One pipeline/setup note remains: a fresh sandbox that runs `dev ci` without first installing `acceptance-tests` npm dependencies will reproduce the original `cucumber-js: command not found` failure. The normal setup should either run the dependency install step first or provide a writable npm HOME/cache.

## Failure-to-fix mapping

| Dev check failure | Fix/action | Files/modules |
|---|---|---|
| `cucumber-js: command not found` | Installed existing acceptance npm dependencies with writable temporary HOME/cache; no repo changes | No tracked files changed |
| Potential npm cache issue from `HOME=/env` | Avoided by using `.fabro/tmp/npm-home` and `.fabro/tmp/npm-cache` for the install | No tracked files changed |