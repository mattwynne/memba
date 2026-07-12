# Problems

## Inbound email from an unverified known address may confuse members

Observed: 2026-07-11

Status: Unresolved. Captured while planning member settings for self-service email-address management and verification.

If a member adds a new email address in Settings, that address should remain unverified until they prove control by opening a verification/sign-in magic link. Until verified, Memba should not trust the address for identity-linked behaviour such as inbound club messages.

That creates a potentially confusing user experience: a member may add an address, see it listed in Settings, then send an email to the club from that same address before verifying it. Memba should reject the inbound message for safety, but the member may reasonably wonder why an address shown in their account is not accepted.

Expected:

- Inbound email from an unverified known address is rejected rather than posted as the member.
- The rejection explains that the address is known but not verified yet.
- The rejection gives the member a clear next action, ideally a path back to Settings or a way to request a verification link.
- The Settings page clearly distinguishes verified addresses from pending addresses so members understand which addresses can be used for sign-in, primary delivery, and inbound posting.
- A future UX pass should think harder about the least confusing path for members who hit this state.
