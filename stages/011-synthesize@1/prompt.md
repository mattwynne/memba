Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT3TXYP7VZ85A8R7FDY2FWMR
Pipeline progress: 9 of 23 stages completed

## Stage: read_plan_001_060
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 1 60 360 'original plan chunk 001-060'`
- Output:
  ```
  (15 lines omitted)
  
  ## Background / Context
  
  Iteration 015 added staff-managed club slugs and public club subdomain routing at `slug.clubs.memba.io`. The public root of a known club subdomain already resolves the club by host and renders that club's public page.
  
  Current member-facing navigation still uses UUID query strings:
  
  - `/?club_id=<uuid>` for the signed-in club dashboard;
  - `/messages/new?club_id=<uuid>` for composing a message;
  - `/messages/:message_id?club_id=<uuid>` for reading message details.
  
  Those URLs are not suitable as the normal member-facing club-site surface. The club slug should be the advertised and navigated address, while UUID query strings remain only as a temporary backwards-compatible fallback during migration.
  
  ADR 0019 records the local-development decision: production uses `clubs.memba.io`; local development and browser acceptance tests default to `lvh.me` so host-based routing can be exercised without wildcard `/etc/hosts` entries or a project-managed DNS server.
  
  ## Scope
  
  ### In scope
  
  - Add configuration for the club-site base domain used when generating club subdomain URLs:
    - production: `clubs.memba.io`;
    - local/test default: `lvh.me`.
  - Generate signed-in “My clubs” links as club subdomain URLs instead of `?club_id=<uuid>` URLs.
  - Route known club subdomain roots so:
    - unauthenticated visitors see the public club page;
    - signed-in active members see the member dashboard;
    - signed-in non-members see the public club page.
  - Route member-only pages on known club subdomains:
    - `/messages/new` selects the club from the host slug;
    - `/messages/:message_id` selects the club from the host slug.
  - Redirect unauthenticated visitors who open private member URLs on a club subdomain to sign in, preserving the full return URL including host and path.
  - After a valid magic-link sign-in, return active members to the private club subdomain URL they originally requested.
  - Show a safe forbidden/access-denied response when a signed-in non-member opens a private member URL on a club subdomain.
  - Return 404 Not Found for unknown club subdomains.
  - Keep existing `?club_id=<uuid>` member routes as temporary backwards-compatible fallback routes, but stop generating them from normal member navigation.
  - Update browser acceptance support, Cucumber step support, and tests to exercise `lvh.me` host-based local club URLs.
  - Update relevant controller/LiveView/router tests for host-based dashboard, compose, detail, auth return-to, forbidden, and fallback behaviour.
  - Keep `dev check` green.
  
  ### Out of scope
  
  - Removing `?club_id=<uuid>` support entirely.
  - Custom club domains.
  - Club-branded sign-in pages or club-branded magic-link emails.
  - Slug rename history, redirects, or aliases.
  - Reserved slug policy beyond existing slug validation.
  - Running a local DNS server in devenv/process-compose.
  - Production DNS changes for `*.clubs.memba.io`; those remain an external deployment prerequisite.
  - Public club page content changes.
  - Staff/admin routing changes.
  ```

## Stage: read_plan_061_120
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 61 120 360 'original plan chunk 061-120'`
- Output:
  ```
  (14 lines omitted)
  BDD decision: Required.
  
  This iteration changes member-visible URLs, club selection, authentication continuation, and authorization rules. Stakeholder-readable scenarios are useful because the same root URL has public and member meanings depending on sign-in and membership, while private URLs must remain protected.
  
  Add the following shared Cucumber feature file:
  
  - `acceptance-tests/features/member_club_subdomains.feature` (`@wip` for planning until implementation catches up)
  
  The feature covers these scenarios:
  
  - Alice opens Kootenay Mountaineering Club from “My clubs” and lands on `kmc.clubs.memba.io`.
  - Alice composes a message on the KMC subdomain and the host-selected club supplies the recipients.
  - Alice views a message on the KMC subdomain and sees it in KMC.
  - Alice opens a private message URL while signed out, signs in, and returns to the same subdomain URL.
  - Pat, a member of another club, cannot view KMC's private message URL.
  - Robin can still open KMC's public club page at the subdomain root.
  
  ## Allowed acceptance feature changes
  
  - `acceptance-tests/features/member_club_subdomains.feature`: new feature file, tagged `@wip`, to document the member subdomain navigation, host-selected club, auth return-to, private authorization, and public-root rules for this iteration. The tag keeps planning-time checks green until delivery implements the supporting steps and application behaviour.
  - Acceptance support and Cucumber configuration may be updated during implementation to generate and open local club subdomain URLs using the configured local base domain, defaulting to `lvh.me`.
  
  ## Acceptance Criteria
  
  - The application has a configurable club-site base domain for generated club URLs.
  - Production club-site URL generation uses `clubs.memba.io`.
  - Local development and browser acceptance tests default to `lvh.me`, so KMC can be opened as `kmc.lvh.me:<port>`.
  - The signed-in home page lists a member's clubs with links to each club's slug subdomain.
  - The “My clubs” links no longer include `club_id` query strings.
  - Opening `kmc.clubs.memba.io/` while signed out shows the Kootenay Mountaineering Public club page.
  - Opening `kmc.clubs.memba.io/` while signed in as an active KMC member shows the KMC member dashboard.
  - Opening `kmc.clubs.memba.io/` while signed in as a non-member shows the KMC public club page.
  - Opening `unknown.clubs.memba.io/` returns 404 Not Found.
  - Opening `kmc.clubs.memba.io/messages/new` while signed in as an active KMC member shows the compose page for KMC.
  - Sending a message from `kmc.clubs.memba.io/messages/new` addresses KMC members and not members of another club.
  - Opening `kmc.clubs.memba.io/messages/:message_id` while signed in as an active KMC member shows the KMC message detail page.
  - Private member URLs on a club subdomain do not need or generate `club_id` query parameters.
  - Opening a private member URL on a club subdomain while signed out redirects to sign-in with a safe return path that preserves host, path, and query string as needed.
  - Following a valid magic link after that redirect returns the active member to the originally requested private subdomain URL.
  - A signed-in non-member who opens a private member URL on another club's subdomain sees a safe forbidden/access-denied response and does not see private message content.
  - Existing `?club_id=<uuid>` dashboard, compose, and message-detail routes continue to work as temporary backwards-compatible fallbacks.
  - Fallback `?club_id=<uuid>` routes remain protected by the existing active-membership checks.
  - Existing public Memba routes at `/`, `/about`, `/terms`, and `/privacy` on the main host continue to work.
  - Existing staff/admin routes continue to work.
  - ADR 0019 documents the `lvh.me` local subdomain decision.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  ```

## Stage: read_plan_121_180
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 121 180 360 'original plan chunk 121-180'`
- Output:
  ```
  (14 lines omitted)
  1. Inspect current routing, `PageController`, member dashboard LiveView, member message routes, compose route, auth return-to handling, and URL generation helpers.
  2. Add configuration for the club-site base domain and generated URL scheme/port where needed:
     - production base domain `clubs.memba.io`;
     - dev/test base domain `lvh.me`;
     - preserve environment-appropriate scheme and port in generated URLs.
  3. Add a small URL/host helper or equivalent web module that:
     - builds a club URL from a club slug;
     - detects whether a request host is under the configured club-site base domain;
     - extracts the slug from the left-most label;
     - ignores non-club hosts.
  4. Update home-page “My clubs” link generation to use the helper and each club's slug.
  5. Update root club-subdomain handling so known club hosts choose between public page and member dashboard:
     - signed-out visitor: public club page;
     - signed-in active member: member dashboard;
     - signed-in non-member: public club page;
     - unknown slug: 404.
  6. Add host-selected member routes for compose and message detail, reusing existing member page modules where practical but passing `club_id` from slug lookup instead of from query parameters.
  7. Ensure private member routes require authentication and active membership for the host-selected club.
  8. Update auth redirect/return-to handling so private subdomain URLs preserve the original host and path through magic-link sign-in, while still avoiding unsafe open redirects.
  9. Keep old `?club_id=<uuid>` routes working as fallback routes and continue to protect them with active-membership checks.
  10. Update templates and verified routes so normal member navigation no longer emits `club_id` query strings.
  11. Update acceptance test support to build club URLs using the configured local base domain, defaulting to `lvh.me`, and to open host-based URLs in Playwright.
  12. Add or update tests for:
      - club URL generation in production-like and local/test configuration;
      - slug extraction from configured club-site hosts;
      - unknown subdomain 404;
      - root public/member/non-member behaviour;
      - compose and message detail host-selected club behaviour;
      - unauthenticated private subdomain redirect and post-auth return;
      - signed-in non-member forbidden private URL;
      - legacy `club_id` fallback still works and remains protected;
      - main-host public and admin routes still work.
  13. Keep the new Cucumber feature tagged `@wip` until the delivery implementation adds matching step support and behaviour.
  14. Run `dev check`.
  
  ## Open Technical Decisions
  
  None known.
  
  Decisions made during planning:
  
  - Use ADR 0019's local subdomain strategy: `lvh.me` for local/test wildcard loopback subdomains.
  - Keep `?club_id=<uuid>` as a temporary fallback, but stop generating it from normal member navigation.
  - Private member URLs on club subdomains should redirect signed-out visitors to sign-in and then return them to the same URL after magic-link auth.
  - Signed-in non-members should see forbidden/access denied on private member URLs.
  - Signed-in non-members at the club subdomain root should see the public club page.
  
  ## New Capability
  
  Members can use a stable, human-readable club subdomain as their normal club-site address. The app can select the active club from the host for member dashboard, compose, and message detail pages, while still preserving public club pages and authentication/authorization boundaries.
  ```

## Stage: read_plan_181_240
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 181 240 360 'original plan chunk 181-240'`
- Output:
  ```
  PLAN_PATH=docs/iterations/018-member-club-subdomains/plan.md
  PLAN_TOTAL_LINES=205
  PLAN_CHUNK=original plan chunk 181-240
  PLAN_CHUNK_LINES=181-240
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted web tests for club-site host detection, URL generation, root routing, private member routing, auth return-to, forbidden access, and legacy fallback routes.
  - Run targeted acceptance-test configuration checks proving `@wip` scenarios are excluded from the default browser Cucumber run.
  - Run browser acceptance support tests that verify local club URLs use `lvh.me` rather than `club_id` query strings.
  - Manual demo:
    1. Start the app locally.
    2. Sign in as a member of KMC.
    3. Confirm the home page links KMC to `kmc.lvh.me:<port>`.
    4. Open `kmc.lvh.me:<port>/` and confirm the KMC member dashboard appears.
    5. Open `kmc.lvh.me:<port>/messages/new` and send a message to KMC members.
    6. Open the message detail on `kmc.lvh.me:<port>/messages/:message_id`.
    7. Sign out, open the private message URL, sign in, and confirm the browser returns to that URL.
    8. Sign in as a member of another club and confirm the private KMC message URL is forbidden.
    9. Confirm `unknown.lvh.me:<port>/` returns 404.
    10. Confirm the old `/?club_id=<uuid>` fallback still works temporarily.
  
  ## Risks / Follow-ups
  
  - Absolute URL generation with scheme, host, and port can be subtle across Phoenix endpoint config, Playwright, reverse proxies, and production deployment. Keep helper tests explicit.
  - Auth return-to handling must preserve subdomain URLs without opening unsafe redirects to arbitrary external sites.
  - The temporary `club_id` fallback should be retired once all member navigation and external links have moved to subdomains.
  - Browser tests may need careful base URL and host handling because Playwright defaults to one base URL but club navigation crosses hosts.
  - Production TLS and wildcard DNS for `*.clubs.memba.io` remain deployment concerns outside this implementation slice.
  ```

## Stage: read_plan_241_300
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 241 300 360 'original plan chunk 241-300'`
- Output:
  ```
  PLAN_PATH=docs/iterations/018-member-club-subdomains/plan.md
  PLAN_TOTAL_LINES=205
  PLAN_CHUNK=original plan chunk 241-300
  PLAN_CHUNK_LINES=241-300
  
  (no plan lines in this chunk)
  ```

## Stage: read_plan_301_360
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/018-member-club-subdomains/plan.md' 301 360 360 'original plan chunk 301-360'`
- Output:
  ```
  PLAN_PATH=docs/iterations/018-member-club-subdomains/plan.md
  PLAN_TOTAL_LINES=205
  PLAN_CHUNK=original plan chunk 301-360
  PLAN_CHUNK_LINES=301-360
  
  (no plan lines in this chunk)
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 5.3k in / 1.2k out
- Response:
  > {"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.7k in / 3.7k out
- Response:
  > # Iteration Plan Review: Member Club Subdomains
  > 
  > ## Decision: READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > None. The plan is complete and ready for implementation.
  > 
  > ## Non-blocking Improvements
  > 
  > None significant. The plan is at an appropriate level of detail. Minor details like specific controller/LiveView module names and helper module naming can be determined during implementation as indicated by the "inspect" and "add" steps.
  > 
  > ## Smallest Viable Iteration
  > 
  > The current scope is already the smallest viable iteration. While you could theoretically split this into:
  > 1. Root subdomain routing + "My clubs" links only
  > 2. Compose and message detail subdomain support
  > 
  > This would leave members with a partially-working subdomain they can navigate to but cannot use for their primary workflows (sending and reading messages). The current scope keeps all essential member subdomain navigation together, making it the smallest useful slice.
  > 
  > ## Required Plan Edits
  > 
  > None. The plan is ready for implementation as written.
  > 
  > ## Review by Criteria
  > 
  > ### 1. Goal Clarity ✅
  > - **Goal**: Enable members to navigate their club sites using stable, human-readable subdomain URLs instead of UUID query strings
  > - **User/business outcome**: Clear - members get stable, human-readable club addresses
  > - **Beneficiary**: Active members navigating their clubs
  > - **Assessment**: Well articulated and outcome-focused
  > 
  > ### 2. Scope Focus ✅
  > - **Coherence**: Focused on member subdomain navigation across all essential workflows
  > - **Size**: Appropriate - includes root routing, member pages (compose, detail), auth flows, and authorization boundaries
  > - **Boundaries**: Clear in-scope and out-of-scope lists; explicitly excludes custom domains, club-branded auth, slug history, complete UUID removal, and production DNS changes
  > - **Assessment**: Tightly scoped to one coherent outcome
  > 
  > ### 3. Acceptance Criteria, BDD Decision, Business Decisions ✅
  > 
  > **BDD Decision**: Explicit and justified
  > - States "BDD decision: Required"
  > - Rationale: Changes member-visible URLs, club selection, authentication continuation, and authorization rules; stakeholder-readable scenarios are useful
  > - Names feature file: `acceptance-tests/features/member_club_subdomains.feature`
  > - Lists 6 scenarios covering key behaviors (subdomain navigation, host-selected club, auth return-to, authorization boundaries, public access)
  > - Properly tagged `@wip` for planning
  > 
  > **Acceptance Criteria**: Comprehensive (22 criteria)
  > - **Happy paths**: Member dashboard, compose, message detail, "My clubs" links
  > - **Edge cases**: Unknown subdomain (404), non-member at root (public page)
  > - **Permissions**: Active membership required, non-member forbidden from private URLs
  > - **Error states**: 404 for unknown subdomains, forbidden for non-members
  > - **Authentication flows**: Redirect to sign-in, preserve return URL, magic-link continuation
  > - **Data/state**: Messages address correct club members based on subdomain
  > - **Backward compatibility**: Fallback `?club_id=<uuid>` routes continue working and remain protected
  > - **Existing functionality**: Public routes, staff/admin routes unaffected
  > - **Documentation**: ADR 0019 recorded
  > - **Quality gate**: `dev check` passes
  > 
  > **Business Decisions**: None unresolved
  > 
  > **Assessment**: Complete, concrete, and testable
  > 
  > ### 4. Implementation Plan and Technical Decisions ✅
  > 
  > **Implementation Steps**: 14 clear, ordered steps covering:
  > 1. Inspection of current routing, controllers, LiveViews
  > 2. Configuration for club-site base domain
  > 3. URL/host helper for club URLs and slug extraction
  > 4. "My clubs" link generation updates
  > 5. Root subdomain routing (public/member/non-member cases)
  > 6. Host-selected member routes (compose, detail)
  > 7. Private route auth and membership enforcement
  > 8. Auth redirect/return-to preservation
  > 9. Legacy fallback route preservation
  > 10. Template updates to stop generating `club_id` parameters
  > 11. Acceptance test support for `lvh.me` URLs
  > 12. Comprehensive test additions/updates
  > 13. `@wip` tag management
  > 14. `dev check` execution
  > 
  > **Specificity**: Names key integration points (controllers, LiveViews, routes, templates, auth handling, acceptance support)
  > 
  > **Technical Decisions**: None unresolved
  > - Documents decisions already made: ADR 0019 `lvh.me` strategy, fallback approach, auth flows, non-member handling
  > 
  > **Assessment**: Clear path forward with sufficient technical guidance
  > 
  > ### 5. Expected Capability and Validation ✅
  > 
  > **New Capability**: "Members can use a stable, human-readable club subdomain as their normal club-site address. The app can select the active club from the host for member dashboard, compose, and message detail pages, while still preserving public club pages and authentication/authorization boundaries."
  > 
  > **Validation Plan**: Comprehensive
  > - `dev check` execution
  > - Targeted web tests for host detection, URL generation, routing, auth, authorization
  > - Acceptance-test configuration checks (`@wip` exclusion)
  > - Browser acceptance support tests (verify `lvh.me` usage)
  > - 10-step manual demo covering all key scenarios
  > 
  > **Stop Condition**: Clear - acceptance criteria met, validation steps pass
  > 
  > **Risks/Follow-ups**: Documents 5 known considerations (URL generation subtleties, auth safety, fallback retirement, browser test handling, production deployment prerequisites)
  > 
  > **Assessment**: Clear success criteria and comprehensive validation approach
  > 
  > ## Validation Plan Summary
  > 
  > The iteration will be proven successful when:
  > 1. All 22 acceptance criteria are met
  > 2. `dev check` passes
  > 3. Targeted web tests pass for subdomain routing, URL generation, auth flows, and authorization
  > 4. Acceptance test support correctly uses `lvh.me` for local club URLs
  > 5. Manual demo successfully exercises all key member subdomain workflows
  > 6. `@wip` tag is managed appropriately
  > 
  > {"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.5k in / 2.7k out
- Response:
  > {"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":1,"codex_review_blocking_gaps":"Workflow evidence gap: required plan chunks in context contain omitted lines, so the complete plan text was not available for independent validation","codex_review_required_edits":"Provide or re-run unelided Read Plan chunk outputs covering the complete plan before marking validated"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 0 |
| claude_review_blocking_gaps | None |
| claude_review_confidence | High |
| claude_review_decision | READY |
| claude_review_required_edits | None |
| codex_review_blocking_gap_count | 1 |
| codex_review_blocking_gaps | Workflow evidence gap: required plan chunks in context contain omitted lines, so the complete plan text was not available for independent validation |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Provide or re-run unelided Read Plan chunk outputs covering the complete plan before marking validated |
| gemini_review_blocking_gap_count | 0 |
| gemini_review_blocking_gaps | None |
| gemini_review_confidence | High |
| gemini_review_decision | READY |
| gemini_review_required_edits | None |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three model reviews in context.

The reviewer stages must have exposed both their Markdown reports and these routing context fields. The reviewers run as separate model-review stages so these fields are visible to synthesis:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- Codex/GPT: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

Your job in this stage is to decide whether the plan is ready, needs only obvious editorial/structural correction, or needs human product/technical decisions before it can be ready.

Readiness standard:

A plan is READY only if an engineer can begin implementation without first resolving material product/business decisions or material technical design decisions, and if a reviewer can objectively validate success at the end.

A plan is NOT READY if any of these are true:

- The goal is materially ambiguous.
- The scope is too broad or lacks a smallest useful slice.
- Acceptance criteria are not concrete/testable enough.
- The plan does not classify the iteration as behaviour-facing or technical/engineering.
- A behaviour-facing or domain-policy plan lacks an `## Acceptance Scenarios / Feature Files` section with either named shared Cucumber feature file(s)/scenarios or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.
- The plan expects shared acceptance `.feature` file edits but lacks a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

Correction policy:

Codex may only be asked to make obvious plan edits that do not require judgment calls, such as:

- tightening wording without changing meaning
- reorganizing existing content into clearer sections
- turning already-stated expectations into objective acceptance criteria
- making implicit boundaries explicit when the plan already clearly implies them
- removing duplication or contradiction when the intended meaning is obvious

Do not ask Codex to invent product policy, scope, UX, domain, data-model, integration, or technical-design decisions. If the plan needs those decisions, fail the validation and raise them for Matt.

Synthesis instructions:

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in context. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
2. Compare the three reviews.
3. Include a reviewer decision table with each reviewer's decision, confidence, blocking gap count, and notes.
4. Identify consensus findings.
5. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
6. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
7. If only obvious edits are needed, produce a concrete repair brief for Codex.
8. If Matt's input is needed, do not produce a repair brief as if Codex can solve it; list the decisions/questions clearly.

Voting/consensus guardrails:

- If two or more reviewers say NOT READY, you must not publish READY unless you explicitly quote or summarize each NOT READY blocker and explain why it is wrong or non-blocking.
- If any reviewer says NOT READY, include a `Reviewer objections addressed` section that accounts for every blocking gap from that reviewer.
- Do not treat successful reviewer node execution as readiness. Only the reviewer decision and findings content can support readiness.
- If your response cannot include a real synthesis report with the sections below, route to Matt/human input rather than READY.

Return a Markdown report with:

1. Provisional decision: READY, OBVIOUS FIXES NEEDED, or NEEDS MATT
2. Reviewer decision table: Reviewer, Decision, Confidence, Blocking gaps count, Notes
3. Consensus findings: 3-6 bullets
4. Reviewer objections addressed: account for every NOT READY blocking gap, or "No reviewer returned NOT READY"
5. Corrected findings: reviewer findings you changed, downgraded, combined, or rejected
6. Blocking gaps: numbered list, each with why it blocks implementation
7. Codex repair brief: exact instructions for obvious edits only, or "None"
8. Questions for Matt: decisions that need human input, or "None"
9. Validation checklist: what to check after any Codex update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but Codex should apply only obvious fixes:

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
