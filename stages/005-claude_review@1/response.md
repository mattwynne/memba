I now have sufficient evidence across the plan, feature file, design template, and referenced code modules to complete the readiness assessment.

## Readiness Review: Iteration 100 — Generic group-scoped club home

**Decision: READY**
**Confidence: High**

### Verification performed

I read the full plan (`docs/iterations/100-generic-group-scoped-club-home/plan.md`, 269 lines, in one pass), and cross-checked its key claims against the actual repo:

- `design-system/templates/club-groups.html` exists and matches the plan's description (group rail, header, scoped tabs).
- `acceptance-tests/features/group_conversations.feature` already exists, is tagged `@iteration-100 @todo-domain @todo-ui`, and its six scenarios (rail membership, scoping, compose, no-disclosure, remembered selection/fallback) match the plan's summary exactly.
- `web/lib/memba_web/member_dashboard_presentation.ex` and `Memba.Membership.list_active_members_of_group/1` (web/lib/memba/membership.ex:912) exist as named, supporting the plan's implementation steps.
- `Memba.Messaging.send_club_message/2` (web/lib/memba/messaging.ex:63) exists, and the cited `docs/code-health.md` item #3 about the club/group mismatch invariant is real and matches the plan's framing precisely.
- `MembaWeb.MemberMessageDetail` exists, supporting step 8's review target.

### 1. Goal clarity — Met
The goal states a concrete user outcome (a member can choose any group they belong to; that group scopes conversations/members/composition) and names the actor (active club member) and the problem being replaced (hard-coded Everyone dashboard). It's not just a task list.

### 2. Scope focus — Met
Scope is one coherent outcome (generic group-scoped presentation for groups the member already belongs to) with an explicit, substantial "Out of scope" list (no group management, no audience picker, no cross-club switching, no read/unread state). The scope could not obviously be smaller while still resolving the stated problem — dropping remembered-selection or the mismatch-invariant fix would leave either a UX regression or a known security-adjacent gap the plan explicitly flags as necessary for this slice.

### 3. Acceptance criteria / BDD / business decisions — Met
- Classified explicitly as behaviour-facing, with a stated rule change.
- `## Acceptance Scenarios / Feature Files` section is present, names the shared feature file, and the file already exists with scenarios matching the plan's description word-for-word.
- Acceptance Criteria section (10 bullets) is concrete and testable: deterministic group list, Everyone/Admin visibility rules, scoped conversation/member lists, compose behaviour, not-found privacy behaviour, URL-vs-remembered-selection precedence, Everyone route regression protection, club/group mismatch rejection, and `dev check` passing.
- "Open Business Decisions: None known," with five confirmed decisions listed and consistent with the acceptance criteria — no contradictions found.

### 4. Implementation plan / technical decisions — Met
Nine ordered, specific steps naming real modules (`MembaWeb.MemberDashboardPresentation`, `MemberDashboardLive`, `PageHTML.club`, Messaging boundary) and real test layers (Membership, Messaging, dashboard-presentation, LiveView/router, browser). Step 7 directly closes a pre-existing, already-documented code-health risk rather than inventing new scope. "Open Technical Decisions: None expected to block implementation," with three settled conventions listed (opaque group IDs, browser-local persistence as non-authoritative, public API boundary discipline) — consistent with the rest of the plan.

### 5. Expected capability and validation — Met
"New Capability" section states the concrete after-state (one club-home pattern usable for any current or future group). "Validation Plan" is specific: acceptance-tag runner checks, targeted unit tests per layer, Cucumber runs once step support lands, and an explicit manual demo script (switch groups, visit a copied private link as a non-member, compose an Admin message, refresh) that directly exercises the privacy-critical path. `dev check` on committed code is the explicit stop condition.

### Blocking gaps
None found.

### Non-blocking improvements

1. The plan states "DesignSync was not available in this Pi session; the checked-in template is sufficient for this slice" — worth a fresh DesignSync check before UI implementation starts, in case the design has since moved, but this doesn't block planning approval since the checked-in template is authoritative and present.
2. Step 8 ("review all member-facing conversation detail, in-app reply, follow/unfollow, receipt/delivery... paths") is somewhat open-ended as an implementation step; it would benefit from an explicit checklist of file paths (e.g., `member_message_detail.ex` and its test) enumerated up front rather than discovered during implementation — the Risks section already flags this as a known hazard, so it's tracked, just not itemized.
3. The plan doesn't say what happens to the runner-debt tags if `dev check` is run with them still in place (i.e., does `dev check` currently skip `@todo-domain`/`@todo-ui`, or must that be verified first?) — the Validation Plan's first bullet does cover this ("verify `@todo-domain` and `@todo-ui` exclude the planning scenarios from default runners"), so it's actually already addressed; noting only as something to double check early during implementation.

### Smallest viable iteration
The plan as scoped is already close to minimal for a genuinely useful slice: it can't easily drop the remembered-selection feature (it's core to the design's UX) or the club/group mismatch fix (the plan correctly argues this is now unsafe to defer once non-Everyone web composition exists). If a smaller slice were wanted, one could ship group-scoped **viewing** (rail + conversations + members) in one iteration and defer group-scoped **composition** (step 6) plus the mismatch-invariant fix to a fast-follow — but the plan's own reasoning for including composition and the invariant fix together is sound (composing to a non-Everyone group is exactly what makes the mismatch risk live), so splitting would likely just relocate, not reduce, real risk. I don't recommend forcing a split.

### Required plan edits
None required for readiness.

### Validation plan (for implementation, restated)
Use the plan's own five-part validation plan as written: (1) confirm `@todo-domain`/`@todo-ui` correctly exclude the new feature from default runners before implementation; (2) unit-test Membership's group-summary/authorization query in isolation; (3) unit-test Messaging's club/group invariant and recipient composition; (4) test LiveView/router behaviour for rail filtering, scoping, not-found privacy, and remembered-selection fallback; (5) run the Cucumber scenarios end-to-end once step support lands and tags are narrowed; (6) manually demo the ordinary-vs-Admin-member privacy boundary; (7) run `dev check` on the final committed diff.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}