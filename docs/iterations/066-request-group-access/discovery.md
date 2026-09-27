# Iteration 066 — replanning discovery

The previous plan and features are historical proposals until reconciled with this discovery. No implementation or delivery is authorised.

## Agreed with Matt

- A club member can ask to be added to a custom group.
- An ordinary message to Admin is sufficient; no tracked approval workflow is needed.
- Keep this slice focused and small. General replies to senders outside a group are out of scope.
- The request email should offer an “Add Eve to Board” action (using the actual member and group names).
- The action opens the existing member-management page with the requester selected. An authorised admin confirms the addition there.
- Following the email link alone must not change membership, including when an email scanner follows it.
- Requesting is one click with fixed text; the member does not compose a message. Confirmation says “Your request has been sent”; sending does not itself change membership.
- A member may deliberately ask again later: send another ordinary message, without pending-request tracking.
- If the requester already belongs to the group, show that they are already a member; do not add them again or send another welcome email.
- Someone who has left the club cannot request or be added. Someone removed from only the group can ask again.
- Matt agreed the complete behaviour summary in the facilitator conversation. All three collaborators completed discovery catch-up without an unresolved behavioural contradiction. Scenario agreement and modelling remain to complete.
- Matt explicitly authorised a local mock-up based on existing design patterns and approved the Admin email → targeted Add → result flow (“LGTM”). He then requested Eve’s view. After the noise removal below, the facilitator summarised behaviour and UX as agreed, and Matt said “ok” to proceeding with scenarios and modelling.
- Matt removed the explanatory text below Request access and the alternative Admin email contact line as noise. Both the initial and sent previews omit that contact line. This supersedes the old plan’s requirement to retain it; reconcile the earlier contact-affordance acceptance examples during formulation without changing authorisation rules.

## Working example map

```gherkin
Feature: Ask to be added to a custom group

  Rule: A member can ask the club admins to add them to a custom group

    Example: Eve asks to be added to Board in one click without composing a message

    Example: Admin receives the fixed request identifying Eve and Board

    Example: Eve asks again later and Admin receives another ordinary message

  Rule: An authorised admin confirms addition using existing membership management

    Example: Alice follows the request email action and confirms adding Eve to Board

    Example: An email scanner follows the action without adding Eve

    Example: Dan has already added Eve when Alice follows the request action
```

## Formulation and modelling notes

- Fixed request content and requester confirmation are shown in the approved mock-up; no new requester contact-detail display is included.
- Present the targeted requester with the existing Add action as confirmation, not a separate approval screen. Existing management lacks a targeted-requester deep link, so a small presentation change is needed.
- Reuse current membership-management authorisation at confirmation time; the email link grants no authority.
- No special ban after group removal: agreed above.
- Stale actions reuse existing membership rules: already added means no duplicate welcome; no longer in the club means cannot add.
- Requesting grants no additional rights, rather than removing rights the requester already has (for example, an Admin member asking to join Board).
- Email delivery remains normal asynchronous message delivery; message acceptance is not delivery confirmation.
- Matt agreed to drop “Custom group” as problem-domain vocabulary: use “Group” normally and “Built-in group” for Everyone and Admin when the distinction matters. Recorded in `docs/problem-domain-terms.md` and propagated into proposed scenarios without changing behaviour. Existing internal names/file paths are unchanged.
- Matt removed the redundant background assertion that Eve belongs to neither Board nor Admin. The scenario proposal also now uses “KMC” consistently and omits the irrelevant club-email-slug fixture detail; this does not change eligibility or access rules.
- Scenarios are now recorded in `acceptance-tests/features/custom_group_access_requests.feature` and `acceptance-tests/features/journeys/custom_group_access_request.feature`. The canonical term is **Admin Group**; **Club admin** distinguishes club authority from Memba staff.

## Current evidence affecting the old plan

- `web/lib/memba/messaging/group_email_posting_policy.ex` requires current custom-group participation for inbound custom-group root messages. Active club members can still email Admin without belonging to Admin. The old plan's broader custom-group email claim is stale.
- The current conversation presentation exposes sender names, not their email addresses. General outside-sender reply behaviour is explicitly deferred, not a prerequisite for this slice.

## Collaboration

Completed read-only BB discovery/formulation collaboration:

- Product/business: `thr_3wx7xm733a`
- Development: `thr_6cpib9ftuw`
- Testing: `thr_wq8hpyrecc`

All three caught up through facilitator event 895 and reviewed the formulated examples, with no significant unresolved findings. Their findings were read and incorporated; all three children were archived and stopped. This was a live Three Amigos collaboration, not a multi-family ensemble. Matt owns policy, vocabulary and scope decisions. The final agreed features and domain model are in the published plan.
