I'll now analyze this plan against the readiness criteria and provide a comprehensive review.

---

# Iteration 040 Plan Review

## Decision: **READY**

## Confidence: **High**

---

## Blocking Gaps

**None.**

---

## Non-blocking Improvements

1. **Follow data model specificity:** The plan mentions "a per-(member, conversation) follow state" and "Event-sourced, consistent with `Memba.Messaging`" but doesn't specify command/event names or the projection schema. While "Open Technical Decisions" acknowledges storage choices, naming the likely commands/events (e.g., `FollowConversationRequested`, `ConversationFollowed`, `ConversationUnfollowed`) and the projection shape (e.g., `conversation_followers` table with `{conversation_id, member_id, followed_at}`) would improve implementation clarity.

2. **Unsubscribe token approach hint:** While Open Technical Decisions lists "unsubscribe token mechanism," providing a slight preference or constraint (e.g., "prefer reusing existing token helpers for consistency" or "note security constraints") could guide implementation without blocking progress.

3. **Auto-follow timing precision:** The plan says "auto-follow the sender on conversation creation and a replier on reply (from the 039 events)." It could be slightly clearer whether this means reacting to domain events in event handlers or inline within command handlers. However, the phrase "from the 039 events" suggests reactive event handling, which is sufficient.

4. **Email quoted-thread format specifics:** The plan describes "standard quoted thread" format with `blockquote.gmail_quote` + "On <date>, <name> wrote:" attributions. While the design reference is clear, explicitly noting whether this uses Phoenix helpers or requires custom HTML generation would help implementation, though not blocking.

5. **Migration mention:** No explicit mention of migrations for the follow projection/read model, though the event-sourced approach and projection language imply this. A brief mention (e.g., "add migration for follow projection table") would be thorough but isn't blocking given the clear model description.

---

## Smallest Viable Iteration

The plan **already represents the smallest viable iteration.** The scope is tightly focused on a single coherent outcome: changing reply delivery from all-members to followers-only, with the minimal follow model needed to support that change. The follow model, auto-follow behavior, opt-in control, and delivery narrowing are all interdependent and must ship together to be useful.

Splitting further would leave an incomplete capability:
- Auto-follow without delivery narrowing = no benefit
- Delivery narrowing without auto-follow = original sender wouldn't receive replies
- Follow UI without delivery change = control exists but has no effect

The out-of-scope boundaries are clear and appropriate (digest/batching, reply-by-email, mute-but-stay preferences).

---

## Required Plan Edits

**None.** The plan is ready for implementation as written.

---

## Validation Plan

The plan includes a comprehensive validation approach:

1. **Domain/integration layer:**
   - Auto-follow rules (sender at creation, replier at reply)
   - Opt-in default (non-engaged members don't follow)
   - Follow/unfollow command execution
   - Reply delivery to followers only
   - Replier excluded from their own notification
   - Unfollow stops future delivery

2. **Email delivery layer:**
   - Only followers receive emails
   - Stop-following link functionality
   - Footer content ("you're following · stop following")
   - Sender remains `<club> via Memba`
   - Conversation context preserved (quoted thread format)

3. **Acceptance scenarios:**
   - `@iteration-040` scenarios in `club_message_replies.feature` pass
   - Existing 039 conversation/reply/membership scenarios remain green
   - Replace "reply emailed to every member" with "reply emailed to followers"

4. **Full validation:**
   - `dev check` passes

**How to prove success:**
- Before: A reply emails all current members (noisy reply-all from 039)
- After: A reply emails only followers; sender and repliers auto-follow; others must opt in; unfollowing stops emails
- Evidence: BDD scenarios demonstrate the new rules; manual verification shows non-followers receive no emails

The validation plan is complete, concrete, and testable.

---

## Detailed Assessment

### 1. Goal Clarity ✅

**Is the goal clearly articulated?**
Yes. The goal is explicit: "Stop emailing every reply to the whole club. Introduce following a conversation so that a reply reaches only the people who follow it."

**Does it state the user/business outcome?**
Yes. The outcome is behavioural: members can opt in to receive replies, avoiding the noisy reply-all while ensuring engaged participants (sender and repliers) still hear the conversation. The "After this iteration" section clearly articulates the four observable capabilities.

**Is the intended beneficiary clear?**
Yes. Club members are the beneficiaries: they receive fewer unwanted emails (non-followers are not spammed) while having clear opt-in control when they want to follow a conversation.

### 2. Scope Focus ✅

**Is the scope focused on one coherent outcome?**
Yes. The iteration has a single, coherent outcome: changing reply delivery from "all members" to "followers only" and providing the minimal follow model to support that change.

**Could it be any smaller while still useful?**
No. The follow model (auto-follow + opt-in control + unfollow) and the delivery narrowing are interdependent and must ship together. Removing any piece would leave an incomplete or broken capability.

**Are non-goals and boundaries clear?**
Yes. Out of scope explicitly lists:
- Reply-by-email (iteration 041)
- Digest/batching
- Changes to who can reply
- Advanced notification preferences (mute-but-stay)

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Are acceptance criteria concrete, clear, complete, and testable?**
Yes. The six acceptance criteria are specific and objectively verifiable:
1. Auto-follow rules (sender, repliers, non-engaged defaults)
2. Follow/unfollow functionality (in-app and email)
3. Reply delivery to followers only
4. Unfollow stops future emails
5. Email infrastructure preserved (tracking, layout, sender)
6. BDD scenarios pass, `dev check` passes

They cover happy paths (follow, reply delivery), edge cases (replier excluded from their own email), permissions (only current members), state changes (follow/unfollow), and error conditions implicitly (unfollow stops delivery = validates halting).

**BDD scenario classification?**
Yes. The plan explicitly classifies this as "Behaviour-facing" and includes an `## Acceptance Scenarios / Feature Files` section stating "BDD decision: **Required.**"

**Are feature files specified?**
Yes. The plan names `acceptance-tests/features/club_message_replies.feature` and describes exactly what changes: replace the 039 "every member" rule with "followers only," add scenarios for auto-follow, opt-in default, follow/unfollow, and unfollow-stops-email. The "Allowed acceptance feature changes" section provides precise instructions.

**Are business decisions resolved?**
Yes. The "Open Business Decisions" section states "None outstanding on audience" and explicitly documents the Reply-To decision (no-reply guidance in this iteration, conversation address in 041). The confirmed decisions (only followers, auto-follow, default off) are clear.

### 4. Implementation Plan and Technical Decisions ✅

**Are implementation steps clear, ordered, and specific?**
Yes. The six-step plan is logical and sequential:
1. Add follow model (commands/events/projection, auto-follow)
2. Rewire delivery (all members → followers)
3. Add UI control
4. Add email unsubscribe link
5. Revise BDD scenarios
6. Run `dev check`

**Are likely files, modules, and integration points named?**
Reasonably. The plan names:
- `club_message_replies.feature` (BDD)
- `Memba.Messaging` (consistency guideline)
- Design assets: `emails/reply-notification.html`, `wireframes/member-conversation.html`
- Integration point: "iteration 038's email-handoff boundary if landed"

The lack of specific module names (e.g., `Memba.Messaging.FollowConversation` command) is noted as a non-blocking improvement but doesn't prevent implementation.

**Are data model, API, UI, workflow changes clear?**
Yes:
- **Data model:** Per-(member, conversation) follow state, event-sourced
- **API/domain:** Follow/unfollow commands, auto-follow on creation/reply
- **UI:** Follow toggle on message-detail screen
- **Workflow:** Reply delivery filtered to followers, unsubscribe link in email
- **Email:** Quoted thread format, footer with follow state

**Are technical decisions resolved or appropriately deferred?**
Yes. The "Open Technical Decisions" section lists three implementation details (follow storage approach, token mechanism, delivery path factoring) and correctly notes "these are implementation details and should not need product decisions." These are appropriate for implementation-time resolution.

### 5. Expected Capability and Validation ✅

**What can we do after that we cannot do now?**
Clearly stated:
- Before: Replies email all members (noisy, from 039)
- After: Replies email only followers; members can opt in/out; sender and repliers auto-follow
- Net new: Model C opt-in reply delivery, eliminating reply-all noise

**How will we prove success?**
Comprehensive validation plan covering domain tests, email tests, BDD scenarios, and `dev check`.

**Is there a clear stop condition?**
Yes. The acceptance criteria and BDD scenarios provide objective pass/fail conditions. The iteration is complete when replies email followers (not all members), auto-follow works, follow/unfollow controls work, and scenarios pass.

---

## Summary

This is a **well-structured, implementation-ready plan**. The goal is clear and user-focused. The scope is minimal and coherent. Acceptance criteria are concrete and testable. BDD scenarios are properly specified with clear feature file changes. Business decisions are resolved. The implementation plan is logical and specific. Technical decisions are appropriately identified as implementation-time choices. The validation approach is thorough.

The plan demonstrates excellent scope discipline: it changes exactly what's needed to move from interim reply-all to opt-in followers, no more and no less. The design references and email format specifications provide clear implementation targets. The relationship to iterations 039 (builds on) and 041 (sets up for) is explicit.

The non-blocking improvements identified above would enhance clarity but do not prevent successful implementation. An experienced team can proceed confidently with this plan as written.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```