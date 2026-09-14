# Task 024: bounded preparation exercise

Date: 2026-09-14

Purpose: test what a small, defined implementation task with externally prepared context could look like. This is not a workflow redesign or implementation attempt.

Parent investigation: [Iteration workflow timeout](../../2026-09-03-iteration-workflow-timeout-masks-test-failure.md).

Worker-facing artifact: [Sample handoff](worker-handoff.md).

## Baseline and scope

Use historical commit `3ec928f3e`, immediately before the failed task-024 attempt. The original task was “Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.” Its feature contains 13 expanded scenarios across four rules. Earlier tasks had implemented the application behavior; this task supplied executable acceptance coverage.

The exercise prepares only the first rule at the domain layer. This is a defensible small semantic unit because it proves one complete actor outcome, including both positive and negative audience boundaries. It is not a proposed universal rule that every scenario/layer must become a separate workflow node. We have not established the ideal size of the remaining tasks.

No live todo, plan, feature, application code or workflow was changed. The snapshot is a counterfactual: do not feed it to a current delivery worker without regenerating it against the intended source.

## Coverage retained outside this worker

| Existing rule | Expanded instances | Domain layer in this exercise | Browser layer |
| --- | ---: | --- | --- |
| Web composition belongs to the selected group | 1 | Included in the sample handoff, not implemented | Still required |
| Active club members can email a group without joining | 5 | Still required | Still required |
| Replies require conversation write access | 5 | Still required | Still required |
| Replies go to eligible followers except their author | 2 | Still required | Still required |

The packet describes one of 26 scenario/layer executions. It neither completes original task 024 nor absorbs task 025's lifecycle coverage or final gate. A future decomposition must retain this coverage ledger; this exercise does not rewrite execution state.

## Preparation work that moved out of the worker

The original worker had to discover both acceptance stacks, their fixture conventions, public APIs, shared step registry and validation commands. For this packet, preparation established the following facts before coding:

| Prepared fact | Baseline evidence | What the worker no longer needs to discover |
| --- | --- | --- |
| Domain execution is sufficient for this slice; browser proof remains owed | Shared feature and ADR 0010 | Which runner/layer to implement now |
| Club/admin setup already exists; the Carol-inclusive ordinary-member phrase needs an adapter | `custom_group_creation_steps.exs:24–39,308–445` | A new person/club/role fixture design |
| This fixture must be structurally custom (`group_key: nil`) | `custom_group_creation_steps.exs:403–445` versus `group_conversation_steps.exs:371–393` | Whether the older generic Board fixture can be copied unchanged—it cannot be assumed equivalent |
| Existing context maps are compatible with the group action's ID readers | Creation fixture helpers; `group_conversation_steps.exs:626–663` | A second parallel world/context representation |
| The public send action and positive/negative access checks already exist | `group_conversation_steps.exs:128–158,416–459` | Messaging architecture or new application behavior |
| Provider handoff evidence is available without a real email provider | `messaging_steps.exs:1230–1280` | Inbound processing, SMTP, provider configuration or browser mailbox plumbing |
| Shared step discovery and rule-level debt tags are already supported | `domain_cucumber_runner.ex`; creation runner test | A new Cucumber runner or duplicate feature file |

The source map is deliberately anchored to symbols/ranges, with the important facts summarized in the packet. It is not a request to reread every referenced file in full.

## What was genuine work, not merely wasted reading

Existing code is not a ready-made public acceptance library. Several useful helpers are private; similar Gherkin wording differs; context fields have established shapes that new steps must respect. Some adaptation, small extraction and regression work is real. Claiming the worker could simply reuse everything without integration would be misleading.

The sample retains those bounded implementation decisions: where a phrase adapter belongs, whether a small helper extraction improves reuse, exact assertion organization, and failure diagnosis within the specified public boundaries. It removes decisions about which rule/layer to tackle, what other behavior may be deferred, and which whole subsystem to investigate.

Conversely, inbound MIME handling, reply correlation, follow cleanup and browser lifecycle are not needed for this slice. The original dual-layer/four-rule task made much of that material relevant. Not every original read was waste; the assignment itself demanded a broad knowledge surface.

## Handoff contents and exclusions

The worker artifact contains the pinned source, one outcome, explicit remaining coverage, fixture/context facts, relevant public API recipes, the tag change boundary, existing test patterns, focused validation and evidence to return.

It excludes setup logs, prior command bodies, repeated task-023 summaries, earlier reviews, broad task history and implementation details for other rules/layers. Normal project instructions and the cited source excerpts are additional context; the packet's byte size is not a claim about total model input or a validated context budget.

This packet is a prepared working hypothesis, not proof that the task will finish without compaction. Only a bounded worker trial could establish its actual questions, context growth and outcome. Such a trial was not requested or run.

## Checks performed

- Inspected the shared scenario and specific existing domain fixture/action/access/delivery/runner code at the pinned source. The preparation did not rely on the failed 1,725-line candidate as a hidden solution.
- Built a temporary tag-only specimen under `/tmp/memba-062-handoff-selection/`; scenario text was mechanically verified unchanged. The installed Cucumber source-selection API, using the domain and browser exclusion expressions, selected zero/zero instances before the proposed tag move and exactly the intended one/zero afterward. This checks shared tag semantics, not successful Elixir step execution. The actual domain runner's inherited-rule-tag handling was also inspected.
- A bounded independent review read the packet and four relevant sources: runner, action, delivery observations and the pinned feature. It found no material missing decision, incorrect API assumption or weakened scope, and judged the packet ready for a bounded trial—not proven runtime success. It highlighted that recipient count plus inclusion is insufficient to prove everyone received one email; the packet now explicitly requires exact recipient-ID-list equality.
- No application tests or `dev check`: repository edits are documentation only. No product code or executable test/config file changed.

## What this exercise establishes

A useful packet can be made concrete without dumping entire files or demanding speculative implementation. But producing it requires semantic preparation: understanding the outcome, checking reusable code, identifying genuine gaps and assigning the remaining coverage elsewhere. The current character-count-based todo generation does not do that work.

It does not yet establish that a new preparation node is the right architecture, that every task should be this small, or that a particular context limit guarantees success. Those are decisions for the next conversation, using this example rather than another broad investigation.
