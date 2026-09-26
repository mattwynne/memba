# Problem: Unresolved acceptance scenarios remain after an iteration is merged

Date: 2026-09-26

## Context

While reviewing the browser acceptance suite and its Cucumber tags, we compared the shared feature files with the [iteration index](../iterations/README.md). Planning intentionally commits future scenarios to `main` before implementation, with TODO tags keeping unfinished examples out of the relevant runner.

## Expected standard

A TODO tag should make unfinished coverage visible while its iteration is pending. Once that iteration is marked merged, its scenarios should have a clear outcome: executable coverage, an explicit deferral, or removal if the example no longer belongs in the agreed scope.

## What happened

[Iteration 064](../iterations/README.md) is marked **merged**, but ten scenario AST nodes in `acceptance-tests/features/custom_group_lifecycle.feature` and five in `acceptance-tests/features/custom_group_membership.feature` still inherit `@todo-ui`. Two of the lifecycle outlines also inherit `@todo-domain`, so those examples are selected by neither runner. These are scenario counts, not expanded outline example-row counts.

We do not yet know whether these tags reflect undelivered behaviour, deliberate but undocumented deferral, obsolete examples, or forgotten tag cleanup. Iterations **065–067 are validated rather than merged**; their TODO-tagged future scenarios are expected and are not the problem observed here.

## Impact

A merged status and a green test suite can coexist with examples that remain disabled. Without a clear record of why, it is hard to distinguish accepted scope from unfinished work when later reviewing coverage.

## What allowed it to happen

The planning-time TODO convention permits pending scenarios on `main`, but the ownership and eventual disposition of those tags after delivery are not evident from the feature files or iteration index. This is an observation about visibility, not a confirmed cause of the 064 mismatch.

## Open questions

- Which iteration-064 examples are implemented, deferred, or no longer required?
- Where is an agreed deferral recorded, and how would someone reviewing a merged iteration find it?
