# Problems

## Memba has no pricing page or defined pricing

Observed: 2026-06-19

Status: Unresolved. The shared visitor header (aligned to the marketing design system) includes a "Pricing" link, but there is no pricing page, no pricing section, and no defined pricing model. As a placeholder the "Pricing" link points at `/get-started` (the request-access flow) so the navigation matches the design system without leading to a dead end.

The design system's marketing nav lists Features · Pricing · About, which implies visitors can find out what Memba costs. In reality Memba has no published pricing: no price points, no plans, no pricing page, and onboarding happens through a staff-reviewed access request rather than a self-serve purchase. The "Pricing" link is therefore advertising a destination that does not exist, and currently redirects to the request-access form.

Expected:

- Visitors who want to understand cost should reach a real answer — either a pricing page with plans/price points, or honest interim copy explaining how pricing works while Memba is invite-only.
- The nav "Pricing" link should resolve to that destination rather than silently redirecting to `/get-started`.
- A pricing decision needs to be made: what Memba costs, whether there are tiers (e.g. by club/member count), and how that fits the current staff-approved onboarding model.
