Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT1AMRKX17WYJ6MX9H9P9HDK
Pipeline progress: 1 of 13 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/013-member-compose-liveview-flow/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,260p' "$PLAN_PATH"`
- Output:
  ```
  (165 lines omitted)
     - subject/body inputs using Phoenix form components;
     - “Send to all members” primary action and cancel/back action.
  7. Render success state based on `ComposeSuccess`, adding the required “Send another message” action.
  8. Render failure state based on `ComposeError`, adjusted to say nothing was sent and contact support; include Try again and Back to club home actions.
  9. Add or update LiveView/Phoenix tests for:
     - auth and selected-club requirements;
     - no sender dropdown;
     - sender derived from current member;
     - successful submit and success action links;
     - send failure state and support copy;
     - club home CTA replacing inline compose.
  10. Update acceptance step support only as needed for the new send-failure scenario and for existing normal-send steps to use the new compose flow without changing scenario wording.
      - Simulate send unavailability through test support rather than Gherkin wording. Prefer a test-only configuration seam around the existing message sending/delivery boundary (for example an application-env flag or fake-provider failure mode set by step support) so the feature can say only that sending is unavailable.
  11. Remove `@wip` from the new failure scenario once implemented and passing.
  12. Remove the legacy `POST /?club_id=<club_id>` send route and controller action in this slice once the LiveView submit path is covered. Do not keep a parallel member send endpoint unless a test reveals an existing non-UI caller that must be preserved.
  13. Run the targeted browser Cucumber feature and `dev check`.
  
  ## Technical Decisions
  
  - LiveView module: `MembaWeb.MemberMessageLive.New`.
  - Compose path: `GET /messages/new?club_id=<club_id>`; use Phoenix verified routes (`~p`) in implementation/tests.
  - Send-unavailability simulation: add/use a test-support seam around the sending boundary or fake provider configuration, configured by step support, without exposing infrastructure details in Gherkin.
  - Legacy inline send endpoint: remove the old `POST /?club_id=<club_id>` route/controller action once the LiveView submit path replaces it.
  
  ## New Capability
  
  Members have a focused, calmer compose experience with clear post-send choices. Messages are sent as the logged-in member, and failure is treated as an incident with support guidance rather than a confusing form validation problem.
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted LiveView/Phoenix tests for the compose LiveView and club-home CTA.
  - Run `acceptance-tests/features/member_message_deliverability.feature` through the browser runner.
  - Manual demo:
    - sign in as Alice;
    - open Kootenay Mountaineering Club;
    - click “Send club message”;
    - confirm compose screen has no sender dropdown and shows Alice as sender;
    - send “Trip planning night”;
    - confirm success state shows “See who got it”, “Send another message”, and “Back to home”;
    - follow “See who got it” to the message detail page;
    - return and use “Send another message” to start a fresh compose;
    - simulate send failure and confirm the message was not sent, support guidance appears, and Try again/Home actions are available.
  
  ## Risks / Follow-ups
  
  - Existing browser helpers may assume the inline form exists; update helpers while keeping feature language business-focused.
  - Error simulation needs a clean test seam so the new Gherkin does not become infrastructure-specific.
  - Removing the sender dropdown changes a product affordance that existed accidentally; tests should make the new rule explicit.
  - Dashboard polish remains a future iteration.
  ```


You are independently reviewing an iteration plan before implementation.

Use the plan text from the preceding `Read Iteration Plan` stage. Do not assume any missing details. Be strict, practical, and specific.

Review the plan against these readiness questions:

1. Goal clarity
   - Is the goal clearly articulated?
   - Does it state the user/business outcome, not just tasks?
   - Is the intended beneficiary or actor clear?

2. Scope focus
   - Is the scope focused on one coherent outcome?
   - Could the iteration be any smaller while still useful?
   - Are non-goals and boundaries clear?

3. Acceptance criteria, BDD scenario decision, and business decisions
   - Are acceptance criteria concrete, clear, complete, and objectively testable?
   - Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?
   - Does the plan classify the iteration as behaviour-facing or technical/engineering?
   - For behaviour-facing or domain-policy changes, does the plan include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenarios that will express the rules, or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples?
   - Are any business, product, policy, copy, workflow, or domain decisions still unresolved?

4. Implementation plan and technical decisions
   - Are implementation steps clear, ordered, and specific?
   - Are likely files, modules, migrations, tests, interfaces, and integration points named where useful?
   - Are data model, API, UI, workflow, integration, and background-job changes clear enough?
   - Are any technical decisions still unresolved?

5. Expected capability and validation
   - What should we be able to do after this iteration that we cannot do now?
   - How will we prove success?
   - Is there a clear stop condition?

Return a Markdown report with:

- Decision: READY or NOT READY
- Confidence: High, Medium, or Low
- Blocking gaps: numbered list
- Non-blocking improvements: numbered list
- Smallest viable iteration: your recommended smallest useful slice
- Required plan edits: concrete edits the author should make
- Validation plan: how to prove the iteration succeeded

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response and must not be wrapped in a Markdown code fence.

Use these keys exactly so the synthesis stage can fail closed if reviewer findings are not visible in context:

- `gemini_review_decision`: `READY` or `NOT READY`
- `gemini_review_confidence`: `High`, `Medium`, or `Low`
- `gemini_review_blocking_gap_count`: integer count of blocking gaps
- `gemini_review_blocking_gaps`: concise semicolon-separated blocking gaps, or `None`
- `gemini_review_required_edits`: concise semicolon-separated required edits, or `None`

Examples:

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":2,"gemini_review_blocking_gaps":"Ordering is not decided; Acceptance criteria omit visible table columns","gemini_review_required_edits":"State ordering; Define table columns and row identity"}}
