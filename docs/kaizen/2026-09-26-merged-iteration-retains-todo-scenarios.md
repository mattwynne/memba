# Problem: A merged iteration still has disabled acceptance scenarios

Date: 2026-09-26

## Context

While selecting a smaller browser acceptance suite, we inventoried the shared Gherkin tags and checked [iteration statuses](../iterations/README.md). Planning deliberately adds disabled scenarios before implementation; `@todo-domain` and `@todo-ui` currently keep them out of the relevant runner. The [implementation workflow](../../.fabro/workflows/iteration-implementation/workflow.fabro) checks the iteration task list, `dev check`, conformance, and final artifacts before publishing.

## Expected standard

By the end of an *implemented* iteration, its agreed acceptance scenarios should be executable in their intended layer, not left disabled by planning tags. Future validated-but-undelivered iterations may legitimately retain such tags.

## What happened

Iteration **064 is marked merged**, yet `custom_group_lifecycle.feature` contains ten iteration-064 scenario AST nodes under `@todo-ui` (including two also under `@todo-domain`); `custom_group_membership.feature` also has iteration-064 `@todo-ui` rules. The default browser profile excludes all of these lifecycle scenarios. The two `@todo-domain` lifecycle outlines are excluded from the domain runner too. The browser-configuration inventory test had an outdated expectation that all ten ran in both layers; inspecting the inherited tags exposed the mismatch. We have not established whether these scenarios represent undelivered behaviour, obsolete planning examples, or a tag-cleanup oversight.

Iterations **065–067 are validated, not merged**, and their disabled planning scenarios are expected at this stage. A repository-wide ban on `@todo` would therefore block valid planning.

## Impact

A green acceptance run and a merged status can coexist with disabled scenarios from that iteration. The browser inventory can overstate coverage unless it inspects *selected* scenarios rather than merely counting feature-file entries.

## What allowed it to happen

The final implementation/publish checks do not appear to require zero disabled **scenarios belonging to the iteration being delivered**. This is a candidate missing guardrail, not yet a proven root cause of the iteration-064 mismatch.

## Open questions

- Which iteration-064 examples describe delivered behaviour, and which are intentionally deferred or no longer wanted?
- Where should a scoped check run so planning remains green but implementation cannot publish a merged iteration with unresolved scenario debt?
- How should the check handle inherited tags, scenario outlines, and explicitly agreed deferrals?

## Possible prevention idea

At the end of iteration implementation, check the current iteration's acceptance scenarios for unresolved `@todo` tags (including inherited tags); fail with scenario names or require an explicit reviewed deferral. Do not fail merely because future validated iterations have planned scenarios. Align this check with the proposed single `@todo` / `@journey` tag policy.
