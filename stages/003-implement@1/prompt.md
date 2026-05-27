Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KSMA6WJ75CXA1NGNQKWTSSJV
Pipeline progress: 1 of 15 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/001-member-message-deliverability/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Iteration plan not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,320p' "$PLAN_PATH"`
- Output:
  ```
  (126 lines omitted)
  5. Implement caller-generated UUID aggregate identities per ADR 0011.
  6. Implement minimal Membership aggregates, commands, and events:
     - Club: create a club.
     - Person: create a person with name and email; person identity is club-independent.
     - Membership: add a person as an active member of a club. For this iteration, memberships are active from creation and cannot lapse, expire, or be revoked.
  7. Implement Membership projections/read models and a public Membership query API. Messaging must call this query API to resolve active club members; it must not depend directly on Membership Ecto schemas or projection tables.
  8. Implement the Messaging aggregate as one aggregate per message per ADR 0004.
  9. Implement `SendMessage` so the application service resolves recipients via Membership's query API and includes those resolved recipients in the command, per ADR 0005.
  10. Have the Message aggregate emit `MessageSent` plus one recipient delivery event per resolved recipient in the message stream.
  11. Implement the delivery status state machine inside the Message aggregate:
      - statuses: sent, delivered, delayed, bounced, spam complaint, opened;
      - member-facing mapping from ADR 0006;
      - opened semantics from ADR 0012;
      - invalid transitions rejected;
      - duplicate equivalent status reports idempotent.
  12. Define a fake/stub delivery provider port used by the message-sending service/tests. For this iteration, fake provider success means Memba has handed the delivery to the provider.
  13. Implement Messaging projections/read queries for messages, recipient deliveries, member-facing receipts, and operator deliverability details using `commanded_ecto_projections`.
  14. Configure Elixir Cucumber to read shared feature files from `acceptance-tests/features/**/*.feature` and execute domain step definitions from the Phoenix app test suite, per ADR 0010.
  15. Add domain-level Cucumber step definitions for the shared member-message and operator-deliverability scenarios using fake/stub ports.
  16. Keep the existing cucumber-js/Playwright setup available for future whole-app execution of the same scenarios, but do not implement the Phoenix UI layer in this iteration.
  17. Add lower-level ExUnit tests where useful for EventStore setup, aggregate rules, projector behaviour, status-transition idempotency, and fake provider interactions.
  18. Run `devenv shell mix precommit` and fix any issues.
  
  ## Open Technical Decisions
  
  - Exact compatible package versions should be chosen during implementation for `commanded_eventstore_adapter`, `eventstore`, `commanded_ecto_projections`, and the GitHub Cucumber dependency.
  - Exact folder structure for Elixir Cucumber support code should be chosen during implementation, while preserving ADR 0010's shared feature-file paths.
  
  ## New Capability
  
  After this iteration, Memba will have event-sourced Membership and Messaging domain skeletons. It will be able to model a member sending a message to all active members of their club, create per-recipient delivery state, and project both simple member-facing receipt statuses and detailed operator deliverability information using a fake provider.
  
  This creates the product-shaped foundation for the next iteration: live Postmark sending, provider webhooks, tracking pixels, and a real deliverability demo with test inboxes.
  
  ## Validation Plan
  
  - Use the shared Cucumber feature files as the domain model specification for this iteration.
  - Run the shared scenarios against the Elixir domain model with `huddlz-hq/cucumber` and fake/stub ports.
  - Keep scenarios abstract from infrastructure so they can later run through cucumber-js/Playwright against the whole Phoenix app.
  - Add ExUnit tests for lower-level technical details that are not appropriate in Gherkin.
  - Run `devenv shell mix precommit` before considering implementation complete.
  - No live provider/manual inbox demo is required in this iteration; that belongs to the follow-up Postmark deliverability iteration.
  
  ## Risks / Follow-ups
  
  - EventStore setup may reveal package-version or database lifecycle issues; if so, resolve them before adding live delivery-provider integration.
  - The shared-scenario/two-runner approach is new to this project and may need folder/test-runner refinement.
  - The minimal membership model may need to evolve soon to include active/lapsed membership state, households, renewals, privacy preferences, and unsubscribe/compliance rules.
  - Future notification channels may require changing delivery-channel fields and provider abstractions; ADR 0005 says to keep the shape channel-neutral where practical.
  - The next slice should integrate Postmark end to end: real sending, webhooks, tracking pixel, and a manual demo script using Gmail, Outlook/Hotmail, and other test inboxes.
  ```


You are implementing a validated iteration plan for the Memba Phoenix application.

Use the plan text from the preceding Read Iteration Plan stage. The plan path is docs/iterations/001-member-message-deliverability/plan.md.

Follow these rules:

- Implement the full selected iteration in this run. Do not ask whether to implement the whole plan or only part of it; the plan is the approved scope.
- Work from the plan top-to-bottom. Deliver the smallest complete version of each in-scope item before moving on. Do not broaden the iteration beyond the plan.
- Read AGENTS.md and any referenced project guidance before editing relevant files.
- Use test-driven development for behaviour changes: write the failing automated test first, then implement the code to make it pass. Use unit tests for isolated logic, integration/projection tests for data/state changes, and the planned Cucumber step definitions for the shared acceptance scenarios.
- Do not mark behaviour as done in your summary unless a relevant automated test exists and passes or you clearly report why it could not be run.
- Use automated tests as the primary feedback loop while implementing: add or update the automated tests called for by the plan, run relevant targeted tests as you work, and do not present the implementation as complete while known tests/checks are failing.
- The workflow will run `dev check` immediately after this stage and loop dev check failures back for fixes. Your job is to get the implementation to the point where the full automated suite can go green before human/model review.
- Never edit acceptance feature files. Treat all `*.feature` files, including files under `acceptance-tests/`, as locked domain acceptance criteria for this implementation run. If a feature file appears wrong, stale, or insufficient, stop and report the issue instead of changing it.
- Add step definitions only where the plan explicitly requires executable plumbing for the locked shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or :httpc.
- Follow Phoenix 1.8, HEEx, LiveView, Tailwind, Ecto, and Elixir project rules where relevant.
- Do not commit changes. Fabro will checkpoint the working tree.
- If you hit a real blocker, stop and report it clearly instead of guessing. Real blockers include ambiguous requirements, missing secrets, unavailable external services, incompatible package versions, or missing sandbox/toolchain infrastructure.
- Do not patch repository scripts or application code merely to compensate for a missing sandbox toolchain such as devenv, Elixir, Mix, Node, npm, PostgreSQL, or system packages. Report missing infrastructure as a blocker so the workflow environment can be fixed.

When finished, summarize:

1. What changed.
2. Automated tests added, updated, and run.
3. Any deviations from the plan.
4. Any remaining risks or manual checks.