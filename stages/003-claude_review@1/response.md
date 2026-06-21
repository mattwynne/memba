Now I'll review this plan against the five readiness criteria.

## Iteration Plan Review: 042 - Club Email Subdomains

### Decision: READY

### Confidence: High

### Blocking gaps

None.

### Non-blocking improvements

1. **Implementation step timing**: Step 2 of the implementation plan says "where the production/default inbound namespace remains `clubs.memba.io`" — this could clarify that the production namespace is already `clubs.memba.io` and will now accept wildcards under it, rather than implying the namespace itself is staying the same while moving from flat to subdomain addresses.

2. **Validation plan specificity**: The validation plan could name specific test files or modules, similar to how the feature files are explicitly named in the Acceptance Scenarios section, but this is not blocking since the validation activities themselves are clear.

3. **Cutover documentation**: While risks mention seed data and docs, the implementation plan could explicitly list a step for reviewing/updating any seed scripts or example data, though this is covered adequately in the risks section.

### Smallest viable iteration

The plan already represents a minimal, coherent slice:
- Exactly one route (`everyone`)
- Hard cutover (no alias support)
- Integration with iteration 041's existing reply mechanism without changing it
- Only the essential UI surfaces (dashboard, compose, reply emails)

Could not be smaller while remaining useful. Any reduction would leave the feature incomplete or require a follow-up to make it usable.

### Required plan edits

None.

### Detailed Review Against Criteria

#### 1. Goal clarity ✅

**Pass.** The goal clearly states the user/business outcome: members can email club-wide messages to `everyone@<club-slug>.clubs.memba.io` instead of `<club-slug>@clubs.memba.io`. The beneficiary (members) and the replaced behavior are explicit. The goal includes a concrete example (Kootenay Mountaineering Club) and explains the relationship to reply-by-email from iteration 041.

#### 2. Scope focus ✅

**Pass.** The iteration is focused on a single coherent outcome: changing the inbound email address convention from flat to subdomain-based. The scope boundaries are exceptionally clear:
- In scope: exactly the `everyone` route, rejection of unsupported routes/subdomains, UI address display updates, integration with 041's reply mechanism
- Out of scope: channels/groups, aliases, custom domains, old address compatibility, staff UI for rejections, changing reply matching logic

The iteration cannot be smaller while remaining useful—it's already the minimal slice that delivers the new address convention in a working state.

#### 3. Acceptance criteria, BDD decision, and business decisions ✅

**Pass.**

**Acceptance criteria** are concrete, specific, and testable:
- UI display locations (dashboard, compose page)
- Club resolution by slug
- Inbound message creation from primary and alternate addresses
- Preservation of existing semantics (authorization, body handling, attachments, idempotency, delivery, visibility)
- Rejection rules (unsupported local parts, unknown subdomains, old flat address)
- Reply destination generation
- Reply routing preservation
- Safe rejection behavior
- Documentation updates
- Smoke test updates
- `dev check` passing

Criteria cover happy paths (inbound creation, alternate addresses), edge cases (unsupported routes, unknown subdomains), error states (rejections), state changes (message creation), and preservation of existing behavior.

**BDD decision** is explicit: "Required" with clear justification. The plan names three specific feature files and describes what scenarios were updated during planning:
- `member_message_deliverability.feature`
- `club_message_replies.feature`
- `email_branding.feature`

The plan explains the `@todo-domain` / `@todo-ui` tag strategy for preserving green mainline until implementation.

**Business decisions** section explicitly states "None known" and lists all confirmed decisions (namespace choice, hard cutover, `everyone`-only, deferred features, external setup responsibility). No unresolved product/policy/workflow questions.

#### 4. Implementation plan and technical decisions ✅

**Pass.** The 14-step implementation plan is ordered, specific, and actionable:
- Named activities: inspect current code, update helpers, update destination resolver, update acceptance, add rejection logic, update UI surfaces, update docs, update smoke tests
- Named integration points: iteration 041 reply generation, Postmark/Resend parsers, acceptance step support
- Named artifacts: member dashboard, member compose, reply notification email, smoke-test config, Postmark docs
- Clear data model impact: no schema changes, just address generation and parsing logic
- Clear UI changes: dashboard and compose copy/mailto links
- Clear external dependencies: Matt performs Postmark/DNS prerequisite setup

**Technical decisions** section explicitly states no decisions block implementation and lists implementation constraints (environment-configurable namespace, rejection reason flexibility, case-insensitive normalization, 041 integration compatibility). These are appropriate guidance without over-constraining the implementer.

#### 5. Expected capability and validation ✅

**Pass.**

**Expected capability** is clear: "each club owns a subdomain under `clubs.memba.io`, and the first route on that subdomain is `everyone`." The benefit is explicit: "a better foundation for future addresses such as channels or special-purpose routes while avoiding root `memba.io` subdomain reservation problems."

**Validation plan** is comprehensive and specific:
- Unit/domain tests for address generation and destination resolution with named test scenarios
- Existing acceptance tests rerun under new address shape with named coverage areas
- Reply-by-email tests from 041 rerun with new destination
- Member UI tests for displayed address
- Documentation review
- Production smoke tests
- Full `dev check`

**Stop condition** is implicit but clear: all acceptance criteria met, `dev check` passes, production smoke test passes after Matt's prerequisite setup.

### Risks section

The Risks / Follow-ups section explicitly addresses:
- External prerequisite dependency (Postmark/DNS)
- Integration dependency on iteration 041
- Hard cutover implications
- Future work boundaries (channels)
- Known unresolved problem (rejected email visibility)

All risks are acknowledged with mitigation or acceptance statements.

### Validation Plan

To prove iteration 042 succeeded:

1. **Run `dev check`** and confirm all unit tests, domain tests, and acceptance tests pass
2. **Verify acceptance scenario execution**: Confirm all `@todo-domain` / `@todo-ui` tags were removed or narrowed and the following scenarios are executable and passing:
   - `member_message_deliverability.feature`: inbound to `everyone@kmc.clubs.memba.io`, unsupported local parts rejected, unknown subdomains rejected, old flat address rejected
   - `club_message_replies.feature`: reply destination is `everyone@<club>.clubs.memba.io`, header-based routing still works
   - `email_branding.feature`: rejection branding example uses new address
3. **Inspect member UI**:
   - Load KMC member dashboard and confirm "everyone@kmc.clubs.memba.io" appears
   - Load KMC member compose page and confirm "everyone@kmc.clubs.memba.io" appears
4. **Verify smoke test updates**: Confirm `smoke-tests/lib/config.js` and `smoke-tests/README.md` default to `everyone@test.clubs.memba.io`
5. **Run production smoke test** (after Matt's Postmark/DNS prerequisite) and confirm it passes against `everyone@test.clubs.memba.io`
6. **Verify documentation**: Confirm `docs/postmark-email.md` and runbooks describe wildcard `*.clubs.memba.io` setup

All six validation activities must succeed to consider the iteration complete.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}