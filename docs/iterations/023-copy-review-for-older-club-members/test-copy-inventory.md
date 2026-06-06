# Visible-copy test inventory

Task 002 inventory of tests and acceptance scenarios that assert public or member-facing copy, labels, placeholders, headings, or delivery-status wording.

## Phoenix controller and LiveView tests

### Public homepage, public club page, member dashboard, get-started, terms/privacy

- `web/test/memba_web/controllers/page_controller_test.exs`
  - Homepage copy and CTA/chrome assertions:
    - hero: `Volunteering shouldn’t feel like work.`;
    - sample club name: `Kootenay Mountaineering Club`;
    - footer copy: `Built with`, `in Nelson, BC.`;
    - sign-in label: `Sign in`;
    - route-level CTA selectors for `/get-started` and `/auth`.
  - Signed-in memberships homepage assertions:
    - `Your clubs`;
    - `You’re a member of 2 clubs`;
    - club names rendered as subdomain links.
  - Public club page assertions:
    - `Welcome to <club name>`;
    - `Members can sign in to see club updates`;
    - `Sign in`/`Sign in to continue` link selector through `#public-club-page-sign-in-link`;
    - refutes member-only phrases such as `Send a club message` and `Signed in as`.
  - Member dashboard assertions:
    - greeting: `Hello, <first name>.`;
    - dashboard intro: `What the club's been saying, and who's around right now.`;
    - CTA: `Send club message`;
    - section headings: `Recent club messages`, `Active members`;
    - active-member count copy: `2 active members`;
    - current recipient explanation: `Everyone with a current membership. They'll all receive your messages.`;
    - layout/footer copy: `Signed in as ...`, `Powered by Memba`.
  - Message detail assertions:
    - `From`;
    - sender name;
    - message subject/body from fixtures;
    - delivery group counts and icons via receipt selectors.
  - About/get-started/terms/privacy assertions:
    - about page: `Membership software for clubs that run on trust.`;
    - get-started page: `Memba is invite-only right now.`, `Want to try Memba with your club?`, `Tell us a little about you and your club.`;
    - signed-in requester copy: `You’re signed in, so we’ll use these details for your request.`, `Tell us which club you want to bring onto Memba.`;
    - validation copy: `can&#39;t be blank`, `is invalid`;
    - acknowledgement copy: `Thanks — we’ll review your request.`, `We’ll contact you if Memba is a good fit for your club.`;
    - policy headings: `Terms of Service`, `Privacy Policy`.

- `web/test/memba_web/auth_gates_test.exs`
  - Public club gate copy:
    - `Welcome to Alpine Club`;
    - `Sign in to continue`;
    - `Powered by`;
    - member dashboard copy: `What the club's been saying, and who's around right now.`;
    - selected club name.

- `web/test/memba_web/components/layouts_test.exs`
  - Public and club layout navigation/chrome:
    - public nav labels `Home`;
    - public `/about`, `/auth`, `/get-started` link selectors;
    - club-site header identity `Signed in as ...`;
    - footer `Powered by Memba`;
    - `Sign out` button selector by id rather than text.

### Authentication

- `web/test/memba_web/controllers/auth_controller_test.exs`
  - Sign-in page:
    - heading: `Sign in to your club`;
    - help text: `Enter your email address and we’ll send you a link to sign in.`;
    - refutes technical/staff copy: `magic link`, `signs up anyone with a memba.io email as Memba staff`;
    - email input and submit button selectors.
  - Check-email acknowledgement:
    - `We’ve sent your sign-in link`;
    - neutral notice helper text;
    - `request another sign-in link` link selector.
  - Several auth flow tests assert the same acknowledgement phrase after submitting.

- `web/test/memba/accounts/auth_email_test.exs`
  - Transactional auth email copy:
    - subject and HTML heading: `Sign in to Memba`;
    - text body: `Use this link to sign in to Memba:`;
    - expiry: `This link expires in 15 minutes.`

### Member dashboard and message compose/detail

- `web/test/memba_web/live/member_dashboard_live_test.exs`
  - Member dashboard:
    - greeting: `Hello, Alice.`;
    - CTA text: `Send club message`;
    - delivery glance: `1 of 2 delivered`, `2 of 4 delivered`;
    - delivery labels in `data-receipt-label`: `Delivered`, `Sending`, `Delivery problem`;
    - inactive/hidden status refutes: `Opened`, `opened`;
    - inbound email panel: `Prefer email?`, `Send a club-wide message to`;
    - empty message state: `No messages yet`, `Send the first one`;
    - first-member empty state: `You're the first one here`.

- `web/test/memba_web/member_dashboard_presentation_test.exs`
  - Presentation-layer dashboard copy:
    - `receipt_glance_copy == "1 of 2 delivered"`;
    - delivery labels `Delivered`, `Sending`, `Delivery problem`.

- `web/test/memba_web/live/member_message_live/new_test.exs`
  - Compose page:
    - back link: `Club home`;
    - eyebrow: `New message`;
    - recipient summary: `all 2 active members`, `There’s no list to pick`;
    - sender summary: `Sending as yourself`, `aria-label='Sending as Alice Adams'`;
    - subject placeholder: `What's this about?`;
    - body placeholder: `Write your note to the club…`;
    - submit button: `Send to all members`;
    - cancel link: `Cancel`;
    - inbound email panel: `Prefer email?`, `Send a club-wide message to`.

- `web/test/memba_web/live/member_message_live/new_send_test.exs`
  - Compose success state:
    - `Message sent.`;
    - `all 2 active members`;
    - delivery-detail link: `See who got it`;
    - action links: `Send another message`, `Back to home`.
  - Compose send failure state:
    - `That didn’t send.`;
    - `Your message was not sent to anyone.`;
    - `contact support`;
    - retry/back actions: `Try again`, `Back to club home`.

- `web/test/memba_web/live/member_message_live/show_test.exs`
  - Message delivery/detail page:
    - summary heading: `Who got this`;
    - summary descriptions: `delivered to their inbox`, `on its way`, `we couldn't reach them`;
    - labels: `Delivered`, `Sending`, `Delivery problem`;
    - percentage text such as `67%`, `100%`;
    - recipient row text such as `Bob Builder`;
    - refutes internal/unsupported terms and staff-only fields: `Opened`, `not opened`, `Provider reason`, `Email deliveries`, provider IDs/reasons.

- `web/test/memba_web/controllers/member_message_detail_test.exs`
  - Controller-level detail page delivery assertions:
    - delivery labels: `Sending`, `Delivered`, `Delivery problem`;
    - recipient group counts;
    - refutes `Opened`, `not opened`;
    - refutes staff-only delivery details: delivery IDs, provider addresses/channels/reasons, `Email deliveries`, `Provider reason`, admin links.

- `web/test/memba_web/member_message_detail_loader_test.exs`
  - Presentation/loader labels:
    - detail page title is the message subject;
    - delivery groups include status labels such as `Delivered`.

- `web/test/memba_web/member_email_delivery_presentation_test.exs`
  - Member-facing status source of truth:
    - maps internal statuses to labels `Sending`, `Delivered`, `Delivery problem`;
    - summary descriptions `delivered to their inbox`, `on its way`, `we couldn't reach them`;
    - folds historic `opened` into `Delivered`;
    - still uses `present_receipt(s)` naming internally, so later copy edits should avoid leaking that term in templates while preserving internal APIs unless renamed deliberately.

## Acceptance feature files and browser support code

Feature files are locked by the iteration plan unless an existing visible label change requires preserving behaviour coverage. This inventory marks likely browser-step updates if labels change.

- `acceptance-tests/features/homepage.feature`
  - Scenarios assert “the Memba homepage” and screen fit.
  - Step support in `acceptance-tests/features/support/homepage.js` asserts:
    - page title `/Memba/`;
    - heading `Volunteering shouldn’t feel like work.`;
    - links `Get started` and `Sign in`.

- `acceptance-tests/features/authentication.feature`
  - Scenarios use behavioural wording, but support code asserts visible member/public copy:
    - `acceptance-tests/features/support/authentication.js` uses label `Email address`, button `Email me a sign-in link`, acknowledgement `Thanks. You should have an email in your inbox with a sign-in link.`;
    - public club page heading `Welcome to <club name>` and link `Sign in to continue`;
    - invalid link copy `That sign-in link is invalid or has expired.`;
    - signed-in identity `Signed in as ...`;
    - signed-out homepage link `Sign in`;
    - staff onboarding support uses `Your name` and `Continue to Memba staff` (staff/admin copy is out of scope but may be touched if shared auth copy changes).

- `acceptance-tests/features/request_account.feature`
  - Scenarios are behavioural, but browser support in `acceptance-tests/features/support/request_account.js` asserts public request labels and acknowledgement:
    - form labels `Your name`, `Email address`, `Club name`, `Short note`;
    - submit button `Request access`;
    - acknowledgement contains `we’ll review your request` and `does not create a club, membership, or sign-in access`;
    - signed-in requester panel contains known name/email.
  - The same support file also includes staff/admin labels (`Club slug`, `Convert request`, `Reject request`, etc.) that are out of scope unless a shared label changes.

- `acceptance-tests/features/member_club_subdomains.feature`
  - Scenarios use behavioural wording.
  - Step definitions in `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js` assert:
    - dashboard selector and hero contains `Kootenay Mountaineering Club`;
    - compose selected-club text equals the club name;
    - recipient summary contains `of Kootenay Mountaineering Club`;
    - public/smoke-test pages still use `Welcome to <club name>` refutes.

- `acceptance-tests/features/member_message_deliverability.feature`
  - Member-visible status phrases in scenario text:
    - `Sending`, `Delivered`, `Delivery problem`;
    - “message was not sent” and “contact support” steps.
  - Step definitions and member harness support assert:
    - delivery status text via member detail selectors;
    - failed send state copy through `assertMemberWasToldMessageWasNotSent` and `assertMemberWasToldToContactSupport`;
    - inbound rejection email phrases for WIP scenarios (`Your email was not posted`, `attachments are not supported yet`, `plain text message body is required`) are email/inbound scope, not the public/member web copy pass unless touched incidentally.

- `acceptance-tests/features/staff_club_slugs.feature`, `memba_staff_operations.feature`, `person_email_addresses.feature`, and `memba_staff_email_deliverability.feature`
  - Mostly staff/admin or operational coverage and therefore out of this iteration’s public/member copy scope.
  - They do include shared public club page steps (`Welcome to <club name>`, `Powered by Memba`) and member-message delivery terms (`delivery`) that should be checked if shared support code changes.

## Practical update targets for later tasks

- Highest-risk brittle Phoenix tests for copy edits:
  - `page_controller_test.exs`;
  - `auth_controller_test.exs`;
  - `member_dashboard_live_test.exs`;
  - `member_message_live/new_test.exs`;
  - `member_message_live/new_send_test.exs`;
  - `member_message_live/show_test.exs`;
  - `member_email_delivery_presentation_test.exs`.
- Highest-risk acceptance support files for copy edits:
  - `acceptance-tests/features/support/homepage.js`;
  - `acceptance-tests/features/support/authentication.js`;
  - `acceptance-tests/features/support/request_account.js`;
  - `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js`;
  - `acceptance-tests/features/step_definitions/member_message_steps.js`;
  - `acceptance-tests/features/support/member_message.js`.
- Prefer selector/data-attribute assertions where behaviour is already covered. Keep direct text assertions only where the wording is the behaviour being protected (for example delivery status labels, consequence-setting copy, and labels used by Playwright `getByLabel`/`getByRole`).
