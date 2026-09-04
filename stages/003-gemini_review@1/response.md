# Iteration Plan Review

**Decision:** NOT READY
**Confidence:** High

## Blocking gaps

1. **Vague Goal:** The goal lacks a clear business or user outcome and does not specify the intended beneficiary or actor ("Make messaging better for everyone" is insufficient).
2. **Undefined Scope:** The scope is explicitly stated as "TBD" and lists a massive, unbounded array of possibilities without defining any non-goals or boundaries.
3. **Untestable Acceptance Criteria:** The acceptance criteria ("Messaging is better", "Users are happier") are completely subjective, not concrete, and not objectively testable. They do not cover any edge cases, permissions, or error states.
4. **Missing Iteration Classification & BDD Strategy:** The plan does not classify the iteration as behaviour-facing or technical/engineering, and it lacks an `## Acceptance Scenarios / Feature Files` section or an explicit rationale for omitting Gherkin.
5. **Unresolved Business Decisions:** Fundamental product and domain decisions are entirely unresolved, including identifying the users, the specific problem being solved, the desired behavior change, and the definition of success.
6. **Missing Implementation Plan:** The implementation steps ("Start coding and figure it out") are completely absent. No files, modules, migrations, tests, interfaces, or integration points are named.
7. **Unresolved Technical Decisions:** Core technical decisions regarding the domain, infrastructure, storage, and testing strategy are explicitly left open.
8. **Undefined Capability & Validation:** The new expected capability is "Unknown" and the validation plan ("Run some tests if there are any") does not define how to prove success or identify a clear stop condition.

## Non-blocking improvements

1. The plan is fundamentally incomplete and requires a complete rewrite rather than iterative non-blocking tweaks.

## Smallest viable iteration

Identify one single, concrete, and highly specific problem with messaging (for example, "Users cannot see when a message fails to send"). Define the business rules for handling that specific scenario, specify the UI and domain changes required, and implement the fix exclusively for that one problem.

## Required plan edits

- Replace the goal with a specific, concrete user or business outcome and identify the actor.
- Define a strict, narrow scope focused on one coherent outcome, explicitly stating what is out of scope.
- Rewrite the acceptance criteria to be concrete, specific, and objectively testable, ensuring coverage of edge cases and error states.
- Classify the iteration as behaviour-facing or technical.
- Add an `## Acceptance Scenarios / Feature Files` section that names shared Cucumber feature files/scenarios, or provide a rationale for why Gherkin is not applicable.
- Make concrete decisions for all currently listed "Open Business Decisions" before implementation begins.
- Write a detailed step-by-step implementation plan that names specific files, modules, and testing approaches.
- Resolve all "Open Technical Decisions" to establish a clear architectural and testing strategy.
- Clearly state the new capability and define a concrete validation plan with a clear stop condition.

## Validation plan

The iteration can be considered successful when the specific problem identified in the revised, focused scope is demonstrably solved according to the concrete acceptance criteria and feature files, proven by automated tests and manual verification of the defined stop condition.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":8,"gemini_review_blocking_gaps":"Goal lacks clear business outcome and actor; Scope is explicitly TBD and unbounded; Acceptance criteria are subjective and untestable; Missing iteration classification and BDD scenario decisions; Unresolved business decisions regarding users, problem, behavior, and success; Implementation plan is missing; Unresolved technical decisions; Undefined capability and validation plan","gemini_review_required_edits":"Define specific goal and outcome; Define strict scope and non-goals; Rewrite ACs to be testable and concrete; Classify iteration and add Acceptance Scenarios section; Resolve all open business decisions; Detail specific implementation steps; Resolve open technical decisions; Define new capability and explicit validation plan"}}