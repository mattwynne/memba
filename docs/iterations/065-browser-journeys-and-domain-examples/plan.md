# Browser journeys distinct from domain rule examples

Date: 2026-09-27
Status: merged

This is a delivery record for work already staged, not a new specification of the
product. The acceptance feature files are the current behaviour source of truth;
older iteration plans record what was built or intended at the time. Inserting
this delivery as 065 moves the previously validated, undelivered request-access,
member-name, and member-photo plans to 066, 067, and 068 respectively. Their
`@todo` examples remain future work.

## Goal and decisions

Replace browser repetitions of rule permutations with a few coherent user
journeys, while retaining focused domain Cucumber examples and a conditional,
direct-Playwright responsive smoke check. [ADR 0026](../../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md)
records the approved testing split and partially supersedes ADRs 0003 and 0010.

- Browser selection: `@journey and not @todo`. Domain selection:
  `not @journey and not @todo`. Planned `@todo` scenarios may live on main.
  Browser journeys live one per file in
  [`acceptance-tests/features/journeys/`](../../../acceptance-tests/features/journeys/),
  not one per rule feature. Email/webhook-only results use focused tests unless
  someone follows a link or sees a result in the app.
- Five journeys cover Board conversations, custom-group admission, member
  messaging and replies, onboarding and return to a private URL, and staff
  diagnostics. Rule permutations remain in the domain feature files. A
  reachability report and dry-run test prevent selected browser steps from
  silently becoming undefined; browser-only registrations with no selected
  journey use were removed.
- Matt decided that a club root without an explicit group URL opens Everyone;
  an explicit `/groups/:group_id` URL opens that group. This intentionally
  removes the browser-local last-selected-group restoration delivered in 058
  and preserved in 061. Conversations and Members now use ordinary links
  rather than the custom keyboard tab hook previously delivered in 045. The
  previous iteration plans remain historical records, not current rules.
- Responsive presentation checks use Playwright directly and run when relevant
  files change or classification is uncertain. The responsive-testing ADR is
  still proposed, not accepted. No custom product-side browser JavaScript is
  introduced for this work.

## Evidence and delivery status

The pre-cut browser baseline was 186 scenarios in 14m40.560s. On the staged
suite before the latest rail-click fix, `bin/dev check` passed with 1,572
ExUnit tests, 10 responsive viewport/page checks, and five browser scenarios
(83 steps) in 48.387s; the focused domain Cucumber suite passed 176 tests.
After an independent ensemble review, the Board rail step's unconditional
`page.goto` was removed: a unit test now proves a broken click cannot pass, and
the focused custom-group browser journey passes with click-driven URL/state.
The responsive trigger now includes deleted presentation files and changes to
its checker, gallery, app JS, and immediate tooling inputs. `--force` reaches
the Playwright runner; a focused forced check passed all 10 viewport/page checks.
The final quality gate must run on the clean committed state before that
commit is pushed; the preceding staged-state check is not proof for these
post-review repairs. GitHub's continuous-delivery workflow repeats the check
on the pushed commit before deploying to Fly.io.

The checked-in design-system templates still describe older tab semantics;
they are historical design inputs until explicitly reconciled with the
approved native-link navigation. Do not mistake them for implemented tab
behaviour. The feature files, LiveView, and current tests define what ships.

## Provenance and scope boundaries

- Current acceptance contract: [browser tests](../../../acceptance-tests/README.md),
  [journey files](../../../acceptance-tests/features/journeys/), and the domain
  feature files. The files, not this log, define currently executable rules.
- Earlier group and tab decisions: [045](../045-club-home-section-tabs/plan.md),
  [058](../058-generic-group-scoped-club-home/plan.md), and
  [061](../061-discover-club-groups/plan.md); the later Everyone/default choice
  supersedes remembered restoration only, not URL-addressable group access.
- The undelivered [066 request-access](../066-request-group-access/plan.md),
  [068 name-editing](../068-member-name-editing/plan.md), and
  [069 photo](../069-member-profile-photo/plan.md) plans retain their own
  future scenarios and are not implemented by this delivery.
- Application, navigation, and responsive-check edits were staged alongside
  the browser-suite cut. Do not infer their validation from an old gate after
  any subsequent changes; run `dev check` on the final staged or committed
  state before publication.
