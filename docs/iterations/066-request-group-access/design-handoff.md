# Iteration 066 — design coverage

Matt explicitly authorised a local mock-up using the checked-in design-system patterns. He reviewed the Admin email → targeted Add → result flow and Eve's request/sent/welcome states, and removed helper/contact copy from Eve's placeholder as noise. The resulting [mock-up](mockup.html) is the approved implementation handoff for this slice; it is not application code.

## Checked-in sources

- `design-system/templates/club-group-non-member.html` — private-group placeholder, sending and sent states. Its alternative Admin email line is superseded for this placeholder by Matt's decision.
- `design-system/templates/club-group-access-request.html` — ordinary Admin conversation and generic management link; the new targeted button is in the approved mock-up.
- `design-system/templates/club-group-members.html` — existing member picker and addition/success patterns; targeted add and already-member states are in the approved mock-up.
- `design-system/emails/group-welcome.html` — existing welcome-email shape.

## New states and constraints

The ordinary request email contains a club-hosted `/groups/:group_id/members/add/:person_id` URL, styled as a button in HTML and shown as a URL in text. GET opens the signed-in, authorised target page without changing membership. The targeted page shows the person and the existing explicit Add action. Already-added shows status without another welcome email. The request placeholder keeps concise sending/sent feedback, no composer and no alternative email contact line.

Reuse generic sign-in, denied, loading and error states. Sign-in should return to the targeted page. On narrow screens, keep email and person/action readable. Keyboard focus lands on the targeted panel, returns to ordinary Add member after Cancel/Escape, and moves to the new member row with status announcement after successful addition. The URL carries identity, not authority; email scanners may follow it safely.

## Verification and limits

The local mock-up was rendered and inspected at 1100px and 390px in headless Chromium without horizontal overflow. Its email link navigates only to the read-only page scene. One bounded read-only OpenAI UX review found the narrow journey coherent and flagged focus recovery, now captured above. No multi-family consensus is claimed. Live `claude.ai/design` was unavailable in this Pi session; no cloud inspection or sync is claimed. Matt accepted the local design coverage for this planning handoff. Cloud synchronization may be done later without blocking this agreed slice.
