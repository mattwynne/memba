# One scenario, five prompts

An opt-in native Fabro workflow. It does not change `fabro deliver` or publish code.

```text
navigator → fresh driver → navigator       until the scenario passes
refactoring navigator → fresh driver      until no worthwhile cleanup remains
full checks → fresh review                findings return for repair
```

Read [the graph](workflow.fabro) and the five short [prompts](prompts/). There is no Python controller, tool interceptor, custom test parser or handback schema. Navigators choose the next edge using Fabro's normal routing instruction. Drivers simply return, including when their work is incomplete.

## What the roles share

Fabro keeps each navigator's conversation; each driver and review starts fresh. Since continuing conversations do not automatically receive other agents' messages, the roles leave ordinary files in `.fabro/tmp/bdd/`:

- `change.md`: the navigator's current assignment and predictions.
- `result.md`: the driver's observations and links to actual test logs.
- `review.md`: the combined review findings.
- `base`: the initial Git commit, for reviewing the entire change.
- `check.log`: actual output from the workflow's `bin/dev check` command.

These are notes and command output, not a state machine. Nothing parses the Markdown or approves a handback. Test output is the evidence; a prediction is a question to compare with it. Agents must keep logs from earlier tests rather than overwrite them.

## Before a run

Supply `plan` as the path to the existing iteration plan, which links to relevant ADRs, designs and other context. Mark exactly one domain scenario `@wip` and remove its `@todo` tag before launch. No separate brief or test-command input is needed. Use the normal managed checkout and pinned Docker image in [workflow.toml](workflow.toml). Setup runs the existing sandbox check and forced browser/network preflight.

The navigator starts with `dev test:wip`, expecting one failing scenario. Zero or multiple selected scenarios are errors. A passing scenario also makes that command exit nonzero, with an explicit request to remove `@wip`; the actual test output still says it passed. The navigator removes only that tag and records the ordinary focused command for subsequent refactoring and repairs. Undefined Cucumber steps are implementation work, not infrastructure failure.

There are no additional workflow time, cost or operation limits, and no automatic retries. Fabro's own defaults still apply. The agreed eval records elapsed time and available cost so we can learn what limits are useful later; it does not inherit the old overnight allowance. See [the repeatable eval process](eval/README.md).

## What this deliberately does not enforce

Calling the shots, staying in scope, stopping at the predicted acceptance result, and keeping review read-only are instructions to the agents, not Python checks on every tool call. We retain Fabro's normal Docker lifecycle, logs and Git checkpoints. Native conversation persistence across process restarts is not promised.

The previous controller and its regression fixtures are preserved in the earlier throwaway source commit `c380050bc26e479ddbf0910ebc84ce1c8e51e568` and private rehearsal records, not carried into this example. That version got one scenario green but failed before refactoring and review. Its formatter also encountered an unresolved write-permission error. Removing the controller does not establish that the permission problem is fixed.

Source checks are not end-to-end workflow proof. Record each actual rehearsal against the [eval checklist](eval/README.md); keep results locally under the ignored `eval/results/` directory.
