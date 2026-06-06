# Implementation notes

Date: 2026-06-06
Run ID: 01KTF829DW4XEF3A4VXDPCY8HY

## Summary

This iteration applied the `copy-audit.md` recommendations to the public and member-facing surfaces in scope. The implemented copy uses plain Canadian English, gives concrete next steps, broadens Memba from club-only language to small volunteer-run groups, and keeps message-sending consequences clear before a member emails all current members.

No routes, permissions, product rules, onboarding policy, or message recipient rules were changed.

## Copy changes completed

- Homepage copy now positions Memba as a private member website for small non-profit groups, clubs, societies, and associations, while staying honest about current message/member capabilities.
- Primary public CTAs now describe the next action, especially requesting access for a group.
- `/get-started` now explains staff review before setup, asks plainer form questions, and tells requesters that no group space, membership, or sign-in access has been created yet.
- Sign-in and check-email copy now explains email-link sign-in without member-facing "magic link" language, including the email address to use and link expiry.
- Public club pages now tell members to use the email address their club has for them and explain what stays private after sign-in.
- Signed-in membership empty states now give practical next steps if no clubs are found for an email address.
- Member dashboard copy now plainly lists the main jobs: read messages, send a note, and see current members.
- Compose-message copy now warns before submission that the message will be emailed to all current members of the selected club, with concrete subject/body placeholders.
- Compose success and failure states now say what happened and what to do next without metaphorical language.
- Member message detail/delivery copy now uses delivery language and avoids member-visible internal terms such as "receipt", "addressed members", and "projected".
- Terms and privacy policy wording was left substantively unchanged, as required by the plan.

## Tests and acceptance support

Tests and browser support code that asserted changed visible copy were updated while preserving the same behaviour coverage. The updates covered public pages, authentication/check-email, get-started, member dashboard, message compose states, message delivery detail, and canonical host redirect expectations.

No acceptance feature files were changed.

## Manual iPad-width review

A manual browser review was run at an iPad-like viewport of 820 × 1180. The reviewed pages/states were:

- logged-out homepage;
- get-started request form;
- get-started acknowledgement;
- sign-in page;
- check-email page;
- public club page;
- member dashboard;
- compose message form;
- compose success state;
- message detail delivery view;
- compose error state.

The review confirmed that the revised copy remained readable at that viewport, that buttons and labels still made sense, and that forbidden member-facing technical terms were not visible on the reviewed pages. The only horizontal overflow reported was the existing decorative homepage background blur extending off-screen; page content width stayed within the viewport.

Screenshots and the generated review summary were produced under `.fabro/tmp/ipad-review-task008/` during the run.

## Validation

Validation completed during the implementation run:

- Targeted Phoenix tests for changed public/member copy passed after test updates.
- Targeted acceptance checks for the changed visible labels passed after browser support updates.
- Full `PATH="$PWD/bin:$PATH" dev check` passed after fixing one stale canonical-host redirect assertion:
  - ExUnit: `566 tests, 0 failures`;
  - Acceptance: `44 scenarios (44 passed), 291 steps (291 passed)`.
- `git diff --check` passed.

This final note-only task did not change executable code, config, dependency files, migrations, acceptance tests, or app behaviour, so no additional `dev check` was required.

## Unresolved copy decisions and follow-ups

No unresolved copy decisions block this iteration.

Follow-ups intentionally left outside this iteration:

- Real customer interviews or usability testing should validate the older-iPad persona and voice-of-customer assumptions.
- Privacy and terms could use a later legal/privacy review before adding stronger policy language.
- A future accessibility iteration should review font size, contrast, hit targets, and iPad ergonomics beyond copy alone.
- Staff/admin operations copy remains out of scope for this public/member-facing pass.
