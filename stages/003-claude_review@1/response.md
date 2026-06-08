Now I'll review this plan against the readiness questions.

---

# Iteration Plan Review: 029 - Membership Admin Invitations

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Feature tag consistency**: The plan says scenarios are tagged `@iteration-029` (line 72) but doesn't mention whether the feature-level `@todo-domain @todo-ui` tags remain until *all* iteration 028+029 scenarios pass together, or whether partial tag removal is allowed mid-iteration. The "Allowed acceptance feature changes" section (line 86) clarifies that tags are removed/narrowed "when covered behaviour passes," which is pragmatic and sufficient.

2. **Inviter identity representation**: The open technical decision about "whether the existing Staff invitation command can accept a club-member actor directly" (line 140) is a healthy acknowledgment. Given that iteration 028 is currently implementing, delivery will resolve this naturally by inspecting the actual Staff invitation API surface.

3. **Validation sequencing**: The validation plan emphasizes "after implementation" checks but could be clearer about whether Cucumber scenarios should be drafted/reviewed *before* code changes (line 149 says "before delivery" but could be more explicit about whether that means before any code changes or just before shipping). The current language is workable.

## Smallest Viable Iteration

The plan already defines a focused, minimal slice:

- Membership Admins can invite new ordinary members by email.
- Reuses iteration 028's invitation infrastructure.
- No pending invitation UI, expiry, bulk operations, or role selection.

The only potentially removable piece would be "resending duplicate pending invitations," but that's a natural consequence of reusing the Staff invitation command and prevents confusing behavior if an admin retries. The plan is already at the smallest useful increment.

## Required Plan Edits

None.

## Validation Plan

The plan provides a clear validation approach:

1. **Acceptance scenarios**: New `@iteration-029` scenarios in `club_member_invitations.feature` express the Membership Admin invitation rules, authorization boundaries, and duplicate-handling behavior.

2. **Domain/application tests**: Prove authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff flow preservation.

3. **Web tests**: Prove action visibility for Membership Admins and unavailability for ordinary members.

4. **Integration check**: Run Cucumber scenarios with appropriate todo tags removed and `dev check`.

5. **Stop condition**: `dev check` passes and the new scenarios pass in their runners.

---

## Detailed Assessment by Readiness Question

### 1. Goal Clarity

**Is the goal clearly articulated?**  
Yes. "Let a club Membership Admin invite new ordinary members by email without Memba Staff involvement."

**Does it state the user/business outcome, not just tasks?**  
Yes. The outcome is club self-service: a Membership Admin can grow the club without Staff help.

**Is the intended beneficiary or actor clear?**  
Yes. The actor is a club Membership Admin; the beneficiary is both the admin (self-service) and the club (growth capability).

### 2. Scope Focus

**Is the scope focused on one coherent outcome?**  
Yes. The outcome is Membership Admin email invitations with the same rules as Staff invitations. Everything else (pending invitation UI, expiry, bulk operations, role selection) is explicitly out of scope.

**Could the iteration be any smaller while still useful?**  
Barely. Removing duplicate-pending resend logic would make retries confusing. Removing authorization checks would be unsafe. The iteration is already minimal.

**Are non-goals and boundaries clear?**  
Extremely clear. The "Out of scope" section (lines 44-55) and "Related Problems" section (lines 17-24) explicitly name what is intentionally left unresolved.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions

**Are acceptance criteria concrete, clear, complete, and objectively testable?**  
Yes (lines 89-107). They cover:
- Happy path: Admin invites unknown email → invitation email → invitee enters name → active membership.
- Edge case: Existing complete person accepts without re-entering name.
- Permission: Only Membership Admins see/use the action; ordinary members cannot.
- Error state: Inviting an active member is rejected with a clear message.
- Data change: Duplicate pending invitation resends and preserves single record.
- Existing behavior: Staff invitations and existing sign-in still work.

**Do they cover happy paths, important edge cases, permissions, error states, and data/state changes?**  
Yes. Happy path, duplicate active member, duplicate pending invitation, authorization (Membership Admin vs. ordinary member), and Staff flow preservation are all explicit.

**Does the plan classify the iteration as behaviour-facing or technical/engineering?**  
Yes. "Behaviour-facing" (line 59).

**For behaviour-facing changes, does the plan include an Acceptance Scenarios / Feature Files section?**  
Yes (lines 63-82). It names `club_member_invitations.feature`, lists specific scenarios with commented rule headings, and uses `@iteration-029` tags. The BDD decision rationale is explicit: "authorization, invitation lifecycle, and identity-control rules" need stakeholder-readable examples.

**Are any business, product, policy, copy, workflow, or domain decisions still unresolved?**  
No (line 109). The plan confirms "None known" and lists confirmed decisions.

### 4. Implementation Plan and Technical Decisions

**Are implementation steps clear, ordered, and specific?**  
Yes (lines 120-135). 14 numbered steps from inspecting iteration 028 through `dev check`. Each step is concrete.

**Are likely files, modules, migrations, tests, interfaces, and integration points named?**  
Partially. The plan names:
- Feature file: `club_member_invitations.feature`
- Permission: `club.manage_members`
- Iteration 028 artifacts: invitation model, commands, routes, emails, profile-completion flow

It does not preemptively name Phoenix routes, LiveView modules, or schema files, but that's appropriate because iteration 028 is still implementing and delivery needs to inspect the actual surface.

**Are data model, API, UI, workflow, integration, and background-job changes clear enough?**  
Yes:
- **Data model**: Reuses iteration 028's pending invitation and membership records; no new tables expected.
- **API**: Reuses iteration 028's invitation command with possible actor extension.
- **UI**: Member-facing invitation form (email only) accessible from members list or new minimal admin page.
- **Workflow**: Same one-use link + profile completion as Staff invitations.
- **Integration**: Email sending via iteration 028's infrastructure.

**Are any technical decisions still unresolved?**  
Yes, three minor ones (lines 137-142):
1. Exact route/page names if no members list exists.
2. Whether Staff invitation command accepts club-member actor or needs a wrapper.
3. How to present direct URL rejection for ordinary members.

All three are explicitly acknowledged as open and deferrable to delivery. The plan states "Any choice is acceptable if it is clear and tested" for the rejection approach.

### 5. Expected Capability and Validation

**What should we be able to do after this iteration that we cannot do now?**  
Clear (lines 144-146): A Membership Admin can invite ordinary members by email without Staff involvement, using email-control verification and profile completion.

**How will we prove success?**  
Clear (lines 148-153):
- Cucumber scenarios pass with appropriate tags removed.
- Domain/application tests prove authorization and lifecycle reuse.
- Web tests prove visibility/unavailability.
- `dev check` passes.

**Is there a clear stop condition?**  
Yes. `dev check` passes and the new Cucumber scenarios pass in their runners.

---

## Summary

This plan is implementation-ready. It defines a focused outcome, names acceptance scenarios with clear rule headings, provides concrete acceptance criteria covering happy paths, edge cases, permissions, and error states, acknowledges open technical decisions as delivery-time choices, and specifies a validation approach with a clear stop condition. The scope is minimal while remaining useful, and the relationship to iteration 028 is explicitly managed as a "build-on" dependency rather than duplication.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}