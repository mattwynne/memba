# Iteration Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

None identified. The implementation evidence is consistent with the accepted architectural direction for the touched area:

- Membership changes remain command-driven rather than mutating projections directly.
- The existing `GroupMemberAdded` event and projection path are reused.
- Authorization is evaluated through the Membership domain boundary rather than in LiveView alone.
- Email delivery is downstream of a confirmed new transition rather than aggregate or projector behavior.
- Web code is explicitly prevented from referencing the trusted internal membership commands directly.

## Blocking issues

None identified.

The successful `dev ci` run, including all 189 browser acceptance scenarios, provides substantial behavioral coverage. No evidence indicates an omitted acceptance criterion, unsafe authorization path, event-sourcing violation, or welcome-email replay issue requiring another implementation pass.

## Bounded-safe fixes

1. **Strengthen the web-to-domain boundary test**
   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`
   - The test searches source text for three fully qualified command module names. It can be bypassed unintentionally through aliases, shortened module references, dynamic module construction, or a newly added internal command omitted from the hard-coded list.
   - This does not show that the current implementation bypasses the boundary, but the guard provides less protection than its name suggests.

## Judgement-worthy non-blocking code-health findings

1. **Architecture enforcement is based on a command denylist**
   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`
   - **Smell:** The test enumerates selected internal commands rather than expressing the broader rule that web delivery must not depend on `Memba.Membership.Commands`.
   - **Why judgement may be needed:** A namespace-wide rule would be more durable, but the team may prefer narrow checks where trusted commands are intentionally used by other delivery mechanisms. This is architectural-test strategy rather than a product correctness problem.

2. **Boundary enforcement uses raw source matching**
   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`
   - **Smell:** Comments, strings, formatting, and alias choices can affect the result without changing actual module dependencies.
   - **Why judgement may be needed:** Moving to AST-based inspection or a project-wide dependency checker adds complexity. The current lightweight check may be considered sufficient when paired with review discipline.

## Suggested fixes

For the bounded-safe test improvement:

1. Replace the three-command denylist with a check for dependencies on the internal `Memba.Membership.Commands` namespace from `lib/memba_web`.
2. Prefer parsed Elixir AST over unrestricted source substring matching, so comments and string literals do not trigger the rule and aliased command references cannot evade it.
3. If AST inspection is considered excessive, retain the lightweight test but:
   - detect `alias Memba.Membership.Commands`;
   - detect the namespace generally rather than individual commands; and
   - document any intentional exceptions explicitly.

This can be handled as follow-up polish and does not need to block the iteration.

## Validation notes

- The sandbox runtime preflight passed.
- `dev ci` completed successfully.
- Browser acceptance suite result: **189 scenarios passed, 1415 steps passed**.
- The reviewed evidence includes tests around the public Membership command boundary and integration/presentation behavior.
- The implementation follows the plan’s key responsibility boundaries: commands and aggregates determine membership transitions, projections represent committed state, and welcome delivery is a post-transition integration concern.
- No file changes were made during this review.