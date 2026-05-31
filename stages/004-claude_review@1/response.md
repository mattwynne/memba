# Iteration Plan Review: 010-shared-magic-link-auth

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Unknown user authentication path not specified**: The acceptance criteria don't address what happens when someone who is neither staff (@memba.io) nor a member of any club successfully receives and clicks a magic link. AC6 confirms the system sends magic links to any email without revealing recognition status, but the AC don't specify whether such users can complete authentication, create a session, and if so, what they see on the home page. This is a product decision that affects both implementation and validation.

## Non-Blocking Improvements

1. **Return path preservation should be decided**: Currently listed as an open technical decision with a stated preference. Elevating this to a firm decision in AC11 would improve implementation clarity. The preference to preserve paths including `club_id` is reasonable and should be confirmed.

2. **Zero-club member display could be explicit**: AC7 says "lists all clubs for an active member email" which implicitly includes an empty list for members with no clubs, but being explicit would remove ambiguity.

3. **Email content not specified**: While this could be an implementation detail, the email copy is a product artifact that might benefit from specification or at least a sample.

4. **Sign-out validation**: Implementation mentions sign-out but AC11 handles this implicitly through "require authentication" - making this explicit would strengthen validation.

5. **Email delivery failure handling**: Edge case for Swoosh/Postmark failures not covered, though standard error handling may suffice.

## Smallest Viable Iteration

The current scope is already well-justified as the smallest useful iteration. The plan correctly argues that:
- Authentication without authorization (staff vs member) would be incomplete for real usage
- Multi-club support is necessary given the data model where one email can belong to multiple clubs
- Staff access is needed for admin tooling

If scope reduction were absolutely required, the only viable cut would be staff authorization, deferring admin access to a follow-up iteration. However, this would delay admin tooling work and the current scope is reasonable.

## Required Plan Edits

1. **Add AC15**: "When a user who is neither staff nor a member of any club completes magic link authentication, they receive a valid session and see [SPECIFY: empty home page / message stating no clubs / error and sign-out / other expected behavior]."

2. **Decide return path preservation**: Either:
   - Update AC11 to explicitly state: "Unauthenticated access redirects to `/auth` and returns users to their originally requested path (including `club_id` query parameters) after successful authentication," OR
   - Explicitly decide not to preserve paths and update AC11 accordingly

3. **Optional - Make AC7 explicit**: Update to "A signed-in home page lists all clubs for an active member email (or shows an empty state if the member has no clubs)."

## Validation Plan

The existing validation plan is comprehensive but should add:

**Automated test addition:**
- "Unknown email can complete authentication but has appropriate authorization constraints"

**Manual demo addition:**
8. Submit a magic link request for an email address that is neither staff nor member, click the link, and verify expected behavior per AC15.

The existing validation otherwise covers:
- Token security (hashing, expiration, single-use)
- Session creation
- Email privacy (AC6)
- Multi-club display
- Staff vs member authorization
- Protected route access control
- Integration preservation (webhook route)

**Validation would be complete once:**
- All AC 1-15 are objectively met
- Automated test suite passes
- Manual demo confirms all scenarios including the unknown user case
- `bin/dev check` passes with no regressions

---

The plan is well-structured, detailed, and thoughtful. The implementation steps are clear and appropriately specific. The non-goals are comprehensive. The scope is well-justified. The only blocking issue is the missing specification for the unknown user authentication path - a realistic scenario that needs explicit product guidance before implementation begins.

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"Unknown user authentication path not specified in acceptance criteria","claude_review_required_edits":"Add AC for unknown user authentication and UX; Decide return path preservation"}}
```