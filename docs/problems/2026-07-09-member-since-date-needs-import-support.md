# Problems

## Member rows have no "member since" date, and the obvious data source isn't trustworthy

Observed: 2026-07-09

Status: Unresolved. Deliberately pulled out of [iteration 050](../iterations/050-club-home-conversation-and-member-row-fidelity/plan.md) rather than shipped with a misleading date.

The club-home Members tab design (`design-system/wireframes/club-home.html`) shows a join date on
every member row ("Member since Jan 2022", "Member since 2015"). The app doesn't show one at all.

The obvious fix — select `membership.inserted_at` (already on `Membership.Projections.Membership`
via `timestamps()`) and format it — was scoped into iteration 050, then pulled out after Matt
confirmed real clubs will bring migrated/imported membership history. For an imported club,
`inserted_at` would just be the day the data was imported, not the member's real historical join
date. Shipping it as "member since" would show a wrong, confidently-stated date for exactly the
clubs where accurate history probably matters most (established clubs migrating off spreadsheets
or another tool).

Why it matters:

- A confidently wrong date is worse than no date — members and staff would have no reason to
  doubt it.
- This blocks not just this one label; any future feature that assumes a projection/event
  timestamp reflects a real-world historical date (anniversaries, tenure-based permissions,
  "long-time member" treatment, etc.) has the same trap.

Expected:

- A dedicated join-date concept (e.g. `joined_at`) that import tooling can set explicitly,
  separate from `membership.inserted_at`.
- Organically-joined members (invited and accepted in-app) can default `joined_at` to the
  membership creation time; imported members get their real historical date from the import.
- The club-home Members tab shows "member since {joined_at}" once this exists.
