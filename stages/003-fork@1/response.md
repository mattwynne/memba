# Iteration Plan Review: 005-browser-acceptance-harness

## Decision: NOT READY

## Confidence: Medium

The plan has clear goals and good high-level structure, but lacks critical implementation specifics needed for consistent execution. The gaps are addressable but should be resolved before starting work.

## Blocking Gaps

1. **No concrete module/file names specified**: The plan doesn't name the LiveView modules, routes, or file paths (e.g., `lib/memba_web/live/dev_harness_live.ex`?, route `/dev/harness`?).

2. **Vague PhoenixTest coverage requirement**: Acceptance criterion #7 says "cover the new LiveView browser surface and important interactions" but doesn't specify which interactions or what coverage means.

3. **Missing UI/navigation structure**: No description of how a developer navigates between club creation, person creation, membership, message sending, and receipt viewing. One page? Multiple pages? Tabs? Forms on a dashboard?

4. **Domain API integration not specified**: No mention of which existing domain functions/contexts will be called from LiveView (e.g., `Memba.Clubs.create_club/1`, `Memba.Messages.send_club_message/2`?).

5. **Authentication/authorization approach undefined**: Even for a dev tool, should specify whether there's any auth or if it's completely open (which has security implications even in dev).

## Non-Blocking Improvements

1. Acceptance criteria don't cover error states or validation failures in the browser UI (e.g., what happens if club creation fails?).

2. Implementation step #4 doesn't specify which Playwright step definition files will be modified.

3. No explicit confirmation that zero database migrations are needed (or if any are).

4. PhoenixTest file naming/organization not specified (e.g., `test/memba_web/live/dev_harness_live_test.exs`?).

5. Risks section mentions "gaps in existing query APIs" but doesn't identify likely candidates or mitigation approach.

## Smallest Viable Iteration

The current scope is already reasonably focused. If forced to reduce further, could defer `homepage.feature` and implement only the `member_message_deliverability.feature` flow. However, the current plan is a coherent unit of work.

Alternative slice: Could implement just "send message → view receipt" without status simulation, but status simulation is core to the deliverability story, so current scope is justified.

## Required Plan Edits

Add a new **Technical Details** section after "Implementation Plan" with:

```markdown
## Technical Details

### Routes and Modules
- Route: `/dev/harness` (or specify alternative)
- LiveView module: `MembaWeb.DevHarnessLive` (or specify alternative)
- Mount in router under existing browser pipeline: `scope "/dev", MembaWeb do ... live "/harness", DevHarnessLive end`

### UI Structure
- [Describe navigation: single page with tabs/sections? Multiple routes? List the main sections/forms]

### Domain Integration
- Club creation: calls `Memba.Clubs.create_club/1`
- Person creation: calls `Memba.People.create_person/1`
- [List other domain APIs that will be exposed]

### Authentication
- [Specify: no auth in dev mode? Basic check? Config-gated?]

### Test Files
- PhoenixTest: `test/memba_web/live/dev_harness_live_test.exs`
- Step definitions: `acceptance-tests/step_definitions/[specify files]`

### Data Changes
- Confirm: Zero migrations needed (using existing schema)
```

Update acceptance criterion #7 to:

```markdown
- PhoenixTest-based tests cover the new LiveView browser surface, including:
  - Club creation form submission
  - Person creation form submission
  - Message sending and confirmation
  - Receipt viewing for all delivery statuses
  - Status transition simulation
```

Add to acceptance criteria:

```markdown
- LiveView forms display validation errors for invalid inputs
- Failed domain operations show user-friendly error messages in the browser
```

## Validation Plan

To prove the iteration succeeded:

### Automated Validation
1. Run `npm test` from `acceptance-tests/` → all browser-ready scenarios pass
2. Run `mix test acceptance-tests/cucumber.exs` → all domain scenarios pass including `@todo-web`
3. Run PhoenixTest suite → all new LiveView tests pass
4. Run `dev check` → passes completely
5. Verify `npm test` excludes operator scenarios tagged `@todo-web`

### Manual Validation
1. Start Phoenix app with `dev server`
2. Navigate to dev harness route
3. Create a club with valid data → success message shown
4. Create club with invalid data → validation errors shown
5. Create two people → success
6. Add both as members → success
7. Send club message → message created
8. View receipt list → both members appear with initial statuses
9. Simulate each delivery status (pending, sent, delivered, failed, bounced) → receipt updates in real-time
10. Verify no operator email deliverability UI present (deferred)

### Coverage Check
- Confirm every step from `homepage.feature` has a corresponding Playwright step definition
- Confirm every step from `member_message_deliverability.feature` has a corresponding Playwright step definition
- Confirm PhoenixTest tests exercise the same flows at the LiveView level

### Documentation Check
- README or docs mention how to access the dev harness
- Any new npm commands documented

**Stop condition**: All automated validations pass AND manual flow completes successfully AND all acceptance criteria checked off.