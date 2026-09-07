# Manual demo — generic group-scoped club home

## Setup

Use one club with:

- Alice: active member of Everyone only.
- Bob and Carol: active members of Everyone and Admin.
- One Everyone conversation: “Trip planning night.”
- One Admin conversation: “Committee meeting.”

If a named non-system group can be seeded without a UI, add Trips committee with
Alice and Carol to prove the presentation has no Admin-specific branch.

## Demo

1. Sign in as Alice and open the club home.
   - Everyone is selected.
   - The rail does not show Admin.
   - Only the Everyone conversation and member list are available.
2. Sign in as Bob and open the same club home.
   - The rail shows Everyone and Admin.
   - Select Admin. Its header, conversation list, and member list show only
     Admin content.
3. In Bob’s Admin Conversations tab, choose New message and send “Committee
   meeting follow-up.”
   - The compose confirmation retains Admin as the audience.
   - Bob and Carol receive/access it; Alice does not.
4. Copy the Admin URL and open it while signed in as Alice.
   - The response is the ordinary not-found page; no Admin name, count, or
     conversation is revealed.
5. Return as Bob, select Admin, then refresh or reopen the generic club-home
   entry route.
   - Admin is restored.
6. Remove Bob’s Admin membership (or use a browser with a stale Admin
   selection), then reopen the generic club-home route.
   - The app safely falls back to Everyone.
