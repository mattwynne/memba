# Manual demo script: member dashboard LiveView polish

Use this after iteration 014 implementation.

1. Sign in as Alice, an active member of Kootenay Mountaineering Club.
2. Open Kootenay Mountaineering Club at `/?club_id=<club_id>`.
3. Confirm the club home is a polished dashboard aligned with `dashboard.jsx`:
   - compact club/member greeting;
   - concise lede;
   - “Got something to share?” CTA card.
4. Confirm the CTA opens `/messages/new?club_id=<club_id>`.
5. Confirm there is no inline compose form on the dashboard.
6. Return to the dashboard.
7. Confirm recent message rows show:
   - sender/member identity;
   - subject;
   - link to member message detail;
   - receipt glance/mini bar where receipt data exists.
8. Confirm receipt glance copy uses member-facing vocabulary and does not expose operator diagnostics.
9. Confirm the active-members card shows an avatar stack, active-member count, and explanatory copy.
10. Open or create a brand-new club with no messages and confirm the designed empty message state appears with a send-message action.
11. Confirm signed-in non-members/inactive members still receive the existing forbidden response for member dashboard access.
12. Confirm public/logged-out club marketing behaviour for `/?club_id=<club_id>` still works.
13. Confirm ADR 0015 is followed: member application pages are LiveViews by default, with static marketing/legal pages as exceptions.
