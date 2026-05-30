# Plan Readiness Review

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Goal is not actionable** - "Make messaging better for everyone" does not identify a specific problem, user need, or measurable outcome.

2. **Scope is completely undefined** - The plan explicitly states "TBD" and lists every possible type of change without committing to any specific work.

3. **All acceptance criteria are subjective and untestable** - "Messaging is better," "Users are happier," and "It works correctly" cannot be objectively verified.

4. **Critical business decisions are unresolved** - The plan cannot proceed without deciding who the users are, which messaging problem to solve, what behavior should change, and what success means. These are foundational, not optional.

5. **Implementation plan is absent** - "Start coding and figure it out" is not a plan. No modules, files, migrations, tests, or sequence of changes are identified.

6. **All technical decisions are unresolved** - The plan doesn't specify whether this involves UI, domain logic, infrastructure, provider integration, or reporting work. Storage changes and testing approach are undefined.

7. **New capability is unknown** - The plan explicitly states the new capability is "Unknown," making it impossible to validate success.

8. **No validation approach** - "Run some tests if there are any" is not a validation plan.

## Non-blocking Improvements

None identified - all gaps are blocking.

## Smallest Viable Iteration

Cannot be determined from this plan. The author must first:
- Choose one specific messaging problem (e.g., "Users cannot see when their message was delivered" or "Admins cannot filter messages by date range")
- Define the minimal change that addresses that problem
- Scope to the smallest testable improvement

Example of a viable scope after problem selection: "Add message delivery timestamps visible to message senders in the message list view."

## Required Plan Edits

The author must completely rewrite this plan:

1. **Define a specific messaging problem** - Choose one concrete user or operator pain point related to messaging. Name who experiences it and when.

2. **Write a focused goal** - State what specific outcome the iteration will achieve for whom (e.g., "Enable message senders to see delivery status").

3. **Bound the scope** - List what is in scope and what is explicitly out of scope. Remove "TBD."

4. **Resolve all business decisions** before writing the plan - Do not proceed until user type, specific problem, intended behavior change, and success criteria are decided.

5. **Write testable acceptance criteria** - Define observable behaviors, UI states, data changes, or API responses that can be verified. Cover happy path, error cases, permissions, and edge cases where relevant.

6. **Create a sequenced implementation plan** - List steps with specific modules, files, schemas, migrations, LiveViews, components, contexts, tests, and integration points. Reference project guidelines and naming conventions.

7. **Resolve technical decisions** - Specify whether changes involve UI, context functions, schemas, migrations, background jobs, external APIs, or configuration. Name the approach.

8. **Define new capability** - State exactly what will be possible after this iteration that is not possible now.

9. **Write a concrete validation plan** - Specify which tests, manual steps, or checks will prove the acceptance criteria are met.

## Validation Plan

A validation plan cannot be written until the iteration has a defined goal, scope, and acceptance criteria. Once rewritten, the validation plan should:

- Name specific ExUnit tests to run
- List manual test scenarios if interactive validation is needed
- Define observable success conditions (e.g., "Message list view shows 'Delivered at 2:34 PM' for sent messages")
- Include rollback or safety checks if data or behavior changes

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":8,"claude_review_blocking_gaps":"Goal is not actionable; Scope is completely undefined; All acceptance criteria are subjective and untestable; Critical business decisions are unresolved; Implementation plan is absent; All technical decisions are unresolved; New capability is unknown; No validation approach","claude_review_required_edits":"Define a specific messaging problem; Write a focused goal; Bound the scope and remove TBD; Resolve all business decisions before writing the plan; Write testable acceptance criteria; Create a sequenced implementation plan with specific modules and files; Resolve technical decisions; Define new capability; Write a concrete validation plan"}}