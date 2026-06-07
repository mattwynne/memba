# Problems

## Clubs need to connect their own web address to their Memba site

Observed: 2026-06-06

Status: Unresolved. [Iteration 018](../iterations/018-member-club-subdomains/plan.md) delivered Memba-hosted club subdomains, but club-owned custom hostnames, DNS verification, HTTPS provisioning, and custom-host session behaviour remain future work.

Kootenay Mountaineering Club would like members to use a club-owned address such as `members.kootenaymountaineeringclub.ca` for its Memba site, rather than only a Memba-hosted address such as `kmc.clubs.memba.io`.

This should be explored as a product capability, with KMC as the first real user, not as a KMC-specific customization.

Expected:

- A club owner can request a custom web address for their club site.
- Memba gives the club clear DNS instructions, for example a `CNAME` from `members.kootenaymountaineeringclub.ca` to the club's Memba-hosted address.
- Memba verifies that the club controls the address before activating it.
- The address is served over HTTPS before members are directed to use it.
- The custom address routes to the same club site as the Memba-hosted address.
- Sign-in links preserve the custom address when the sign-in was requested from that address.
- Memba staff can see and debug the custom address status.

## Discovery notes

Possible product flow:

1. Club owner opens club settings for web address/domain.
2. Club owner enters a hostname such as `members.kootenaymountaineeringclub.ca`.
3. Memba validates that the hostname is well formed, not reserved, and not already claimed by another club.
4. Memba shows DNS setup instructions.
5. Memba periodically checks whether DNS points at the expected Memba target.
6. Once DNS is verified, Memba provisions HTTPS for the hostname.
7. Once the certificate is ready, Memba marks the custom address active.
8. Requests to the custom hostname resolve to the club's public/member site.

Possible statuses:

- `pending_dns`
- `dns_verified`
- `certificate_pending`
- `active`
- `failed`
- `removed`

Possible domain events:

- `CustomWebAddressRequested`
- `CustomWebAddressDnsVerified`
- `CustomWebAddressCertificateRequested`
- `CustomWebAddressActivated`
- `CustomWebAddressFailed`
- `CustomWebAddressRemoved`

Implementation shape to consider:

- Keep projectors limited to Memba-owned state/read models.
- Do not have a projector write Fly configuration or call external APIs.
- Use a worker, process manager, or outbox job for side effects such as DNS checks and Fly certificate provisioning.
- Fly certificate management can likely be automated through Fly's API, with `flyctl certs add` / `flyctl certs show` as useful manual equivalents during discovery.
- The app needs host-to-club lookup for arbitrary custom hostnames, not only slug extraction from `*.clubs.memba.io`.
- The current production session cookie domain is `.memba.io`; arbitrary club domains cannot use that cookie, so custom-domain sign-in likely needs host-scoped sessions or an explicit handoff design.
- LiveView/origin checks must allow active custom hosts without accepting unsafe arbitrary origins.
- Decide whether the Memba-hosted address remains available, redirects to the custom address, or becomes a fallback.

Open questions:

- Is this available on all plans or only higher/premium plans?
- Is the first slice club-owner self-serve, staff-assisted, or staff-only with product-visible status?
- Does v1 allow one custom address per club or multiple?
- Are apex domains supported, or only subdomains via `CNAME`?
- What exact DNS target should Memba ask clubs to use?
- What happens if DNS later stops pointing at Memba?
- Who may add, remove, or change the custom address?
- Should custom web addresses affect email sender domains, or is that a separate premium email-deliverability feature?
