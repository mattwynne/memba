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

Supply `brief` as the path to a committed Markdown file. It names the agreed scenario, its exact acceptance command, intended scope and constraints, and any design/review references. Use the normal managed checkout and pinned Docker image in [workflow.toml](workflow.toml). The setup runs the existing sandbox check and forced browser/network preflight.

For a domain example, use the domain ExUnit runner with its exact `scenario_name` filter and `--trace`, not browser Cucumber. Check that one intended scenario actually ran. Missing step definitions are implementation work, not infrastructure failure.

The graph limits visits to twelve per node and sets stage timeouts, with no automatic retries. This is not the old shared 600-operation/deadline counter, nor a new allowance to run. Any new rehearsal needs fresh agreed limits. No scenario run is authorised by this README.

## What this deliberately does not enforce

Calling the shots, staying in scope, stopping at the predicted acceptance result, and keeping review read-only are instructions to the agents, not Python checks on every tool call. We retain Fabro's normal Docker lifecycle, logs and Git checkpoints. Native conversation persistence across process restarts is not promised.

The previous controller and its regression fixtures are preserved in the earlier throwaway source commit `c380050bc26e479ddbf0910ebc84ce1c8e51e568` and private rehearsal records, not carried into this example. That version got one scenario green but failed before refactoring and review. Its formatter also encountered an unresolved write-permission error. Removing the controller does not establish that the permission problem is fixed.

This simplified version has not completed a scenario rehearsal. Source checks are not end-to-end workflow proof.
