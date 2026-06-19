# Shipped surface notes

Task 001 capture of the shipped surfaces that the DS previews must mirror.

## Sources inspected

- `web/lib/memba_web/router.ex`
- `web/lib/memba_web/live/auth_live/onboard.ex`
- `web/lib/memba_web/controllers/page_controller.ex`
- `web/lib/memba_web/controllers/page_html/get_started.html.heex`
- `web/lib/memba_web/live/admin/requests_live/index.ex`
- `web/lib/memba/onboarding/new_request_email.ex`
- `web/lib/memba/email_templates.ex`
- `web/lib/memba_web/controllers/page_html/club.html.heex`
- `web/lib/memba_web/controllers/page_html/message.html.heex`
- `web/lib/memba_web/live/member_message_live/new.ex`
- `web/lib/memba_web/live/member_message_live/show.ex`
- `web/lib/memba_web/components/core_components.ex`
- `web/lib/memba_web/components/admin_components.ex`
- Current ADR context: `docs/adr/0015-use-liveview-for-member-application-pages.md`, `docs/adr/0016-use-resend-as-switchable-email-provider.md`
- Prior DS catch-up context: commit `90a6f7e` and iteration 036 `surface-notes.md`

## Routes and shells

- Public request access:
  - `GET /get-started` renders `PageHTML.get_started/1`.
  - `POST /get-started` either requests email verification, requires verification, or creates a request.
  - Successful signed-out verification redirects to `/auth/check-email` or `/auth/check-email/:request_id`.
  - Magic-link callback includes `return_to=/get-started`, returning the verified requester to the request form.
- Staff onboarding:
  - `GET /auth/onboard`, LiveView `MembaWeb.AuthLive.Onboard`, staff-onboarding browser pipeline.
  - Uses app shell (`Layouts.app`).
- Staff request review:
  - `GET /admin/requests`, LiveView `MembaWeb.Admin.RequestsLive.Index`, action `:index`.
  - `GET /admin/requests/:request_id`, same LiveView, action `:convert`.
  - Uses admin shell (`Layouts.admin`) with active section `:requests`.
- Member surfaces:
  - Club home/member dashboard renders in the club-site shell.
  - Member compose and message detail are LiveViews per ADR 0015; detail delegates to `PageHTML.message/1` once message assigns are loaded.

## Staff onboarding (`/auth/onboard`)

- Main section ID: `#staff-onboarding`.
- Copy:
  - Eyebrow: `Welcome`.
  - H1: `Tell us your name`.
  - Body: `We’ll use this to create your staff person record so messages and diagnostics can show who you are.`
- Form:
  - ID: `#staff-onboarding-form`.
  - Field: `#staff-name-input`, label `Your name`, placeholder `Pat Example`, autocomplete `name`, required.
  - Button: `Continue to Memba staff`.
- Behavioural states/copy to reflect if previewing variants:
  - Missing email redirects to `/auth`.
  - Non-staff email redirects home with error `You are not authorized to access that page.`
  - Existing staff person redirects to the saved return path or `/admin/clubs`.
  - Success flash: `Welcome to Memba, {trimmed_name}.`
  - Blank/invalid name: `Please tell us your name.`
  - Duplicate email: `That email address is already in use.`

## Public account-request flow (`/get-started`)

- Main section ID: `#get-started`.
- Header copy:
  - Eyebrow: `Request access`.
  - H1: `Ask us to set up Memba for your group.`
  - Body: `We review each request before creating a group space, so Memba stays safe for members.`
- Acknowledgement state:
  - Rendered when `@request_submitted?` is true.
  - ID: `#get-started-request-acknowledgement`.
  - Eyebrow: `Request received`.
  - H2: `Thanks — we’ll read your request.`
  - Body: `We’ll email you if Memba looks like a good fit for your group. Nothing has been created yet: no group space, membership, or sign-in access.`
- Flow wrapper:
  - ID: `#get-started-flow`.
  - `data-state="signed-out"` before verification and `data-state="signed-in"` after sign-in.
- Explainer card:
  - H2: `Want to use Memba with your club or group?`
  - Signed-out body: verify email first, then provide details for staff review.
  - Signed-in body: tell Memba about the group; staff review before anything is created.
  - Signed-out bullets:
    - `Enter the email address you want to use for your request.`
    - `Open the sign-in link we send to verify you control that email address.`
    - `Come back here signed in to finish your request.`
  - Signed-in bullets:
    - `Tell us who should be the first organizer.`
    - `Name the club, society, association, or group you want to bring onto Memba.`
    - `Share what you want Memba to help with.`
- Signed-out verification form:
  - ID: `#get-started-verification-form`.
  - `aria-label="Verify email for Memba access request"`.
  - Info panel heading: `Verify your email first`.
  - Info panel body: `We’ll send a secure sign-in link so staff only review requests from people who control the requester email address.`
  - Field: `#get-started-verification-email`, label `Email address`, type `email`, autocomplete `email`, required.
  - Button: `Email me a sign-in link`.
  - Privacy/scope note: `Verifying your email does not create a group, membership, or sign-in access to a club.`
  - Invalid email flash: `Enter a valid email address.`
- Signed-in request form:
  - ID: `#get-started-request-form`.
  - `aria-label="Request Memba access"`.
  - Verified-identity panel for signed-in non-member requesters:
    - ID/test ID: `#get-started-verified-identity` / `get-started-verified-identity`.
    - Copy: `You’ve verified your email.`
    - Shows email only.
  - Existing requester/person panel:
    - ID/test ID: `#get-started-signed-in-requester` / `get-started-signed-in-requester`.
    - Copy: `You’re signed in, so we’ll use these details for your request.`
    - Shows name and email.
  - Fields:
    - Non-person requester only: `#get-started-requester-name`, label `Your name`, autocomplete `name`, required.
    - `#get-started-club-name`, label `Group or club name`, autocomplete `organization`, required.
    - `#get-started-note`, label `What would you like Memba to help with?`, textarea rows `5`, placeholder `Example: We want one reliable way to email all current members.`, required.
  - Button: `Request access`.
  - Scope note: `We’ll use these details only to review your Memba request.`
  - Posting while signed out flashes `Verify your email before completing your request.`

## Staff request review and convert (`/admin/requests`)

- Main ID: `#admin-requests-index`, `data-admin-page="requests"`.
- Header:
  - Eyebrow/title: `Requests`.
  - Description: `Review account requests from club organisers before creating clubs, memberships, or sign-in access.`
- Summary cards:
  - `Active requests`: count, `Awaiting Memba staff review.`
  - `Approval model`: `Staff approved`, `Public requests do not create clubs or sending access.`
  - `Next action`: `Reject or convert`, `Each active request has triage actions for staff review.`
- Toolbar:
  - ID `#admin-requests-toolbar`.
  - Summary label `Active` with active request count.
- Inbox card:
  - ID `#admin-requests-inbox-card`.
  - Title `Active request inbox`.
  - Description `Oldest active requests first, with the details staff need before rejection or conversion.`
  - Table ID `#admin-requests-table`, `aria-label="Active onboarding requests"`.
  - Empty row copy: `No active requests to review.`
  - Columns: requester, club, note, submitted, actions.
  - Row includes requester avatar/initials, requester email, request ID, requested club name, `Active` status badge, note, UTC submitted timestamp, and `Reject` / `Convert` actions.
- Conversion panel:
  - ID shape: `#convert-request-panel-{request_id}`.
  - `data-testid="convert-request-panel"`.
  - Eyebrow: `Prepare conversion`.
  - Body: `Review the requested club details and confirm the slug before creating a club, first member, and welcome sign-in link.`
  - Shows requester name and email.
  - Form ID shape: `#convert-request-form-{request_id}`.
  - Fields:
    - Club name, ID shape `#convert-request-club-name-{request_id}`.
    - Slug, ID shape `#convert-request-club-slug-{request_id}`, max length from `ClubSlugForm.max_length/0`.
  - Slug help: `Uses the same lowercase letters, numbers, hyphens, and availability checks as staff club creation.`
  - Buttons: `Cancel`, `Convert request`; convert disabled unless slug feedback is valid.
  - Successful conversion flash: `Converted request for {requested_club_name}.`
  - Welcome email failure flash: `Welcome email could not be delivered: {reason}`.
- Rejection panel exists on the shipped surface even though no rejection-email preview is in scope:
  - ID shape: `#reject-request-panel-{request_id}`.
  - Eyebrow: `Reject request`.
  - Body says requester will not receive an email.
  - Notes field label: `Internal rejection notes`.
  - Help text: `Internal notes are stored for staff audit only and are not sent to the requester.`
  - Buttons: `Cancel`, `Reject request`.
- Inactive conversion state:
  - ID `#inactive-request-panel`.
  - H2: `That request is no longer active.`
  - Body: `It may have already been converted or rejected, or the link may be wrong.`
  - Link: `Back to active requests`.

## New-request notification email

- Module: `Memba.Onboarding.NewRequestEmail`.
- Delivery:
  - From defaults to `{"Memba", "hello@memba.io"}` unless provider/config overrides.
  - To defaults to `hello@memba.io`.
  - Reply-to is the requester name/email.
  - Subject: `New Memba request: {requested_club_name}`.
  - Default Postmark message stream: `outbound-onboarding`.
  - Resend tags include `memba_email_kind=onboarding_new_request` and `memba_onboarding_request_id={request_id}`.
- Plain-text body:
  - `New Memba access request`
  - `Request ID: {request_id}`
  - `Club: {requested_club_name}`
  - requester name and email
  - note text
  - `Open this request:` followed by `{Endpoint.url()}/admin/requests/{request_id}`.
- HTML shell:
  - Shared email shell from `Memba.EmailTemplates`.
  - Canvas `#ece9e0`, paper `#ffffff`, line `#e6e3dc`, ink `#15201c`, forest link/action color `#1f4842`.
  - 560px centered card, conservative table markup, inline styles.
  - Header: Memba sprig + `Memba`, label `Staff notification`.
  - Card heading: `New Memba access request`.
  - Body is the plain text converted to paragraphs with `<br>` inside paragraphs.
  - Preheader: `New Memba access request for Memba staff.`
  - Footer reason: `This staff notification was sent because someone requested access to Memba.`

## Club home / member dashboard

- Template: `PageHTML.club/1` in club-site shell.
- Main ID: `#member-club-home`.
- Data:
  - `data-live-view="member-dashboard"`.
  - `data-club-id={selected_club.club_id}`.
- Layout:
  - Max width 3xl, stacked sections.
  - Hero has a bottom border using `border-base-300`.
  - Uses sage/daisyUI app tokens (`bg-primary`, `text-base-content`, `border-base-300`, `bg-base-100`) rather than legacy `--club-site-*` tokens.
- Hero copy:
  - Eyebrow: selected club name.
  - H1: `Hello, {first_name}.`
  - Body: `Read recent club messages, send a note to all current members, and see who is on the member list.`
- CTA card:
  - ID `#member-dashboard-cta`.
  - Primary-color card.
  - H2: `Send a message to the club?`
  - Body: `Messages go to all current members.`
  - Button: `Send club message`.
  - Optional inbound-email panel:
    - ID `#member-dashboard-inbound-email`.
    - Eyebrow: `Prefer email?`
    - Copy: `You can also send a club-wide message to {inbound_email_address}`.
- Recent messages:
  - Section ID `#club-messages`.
  - Heading: `Recent club messages`.
  - List ID `#member-message-list`.
  - Empty state ID `#member-message-list-empty`:
    - H3: `No club messages yet`.
    - Body: `When a member sends a message, it will appear here.`
    - Button: `Send the first message`.
  - Message row:
    - Article ID shape `#member-message-{message_id}`.
    - `data-testid="club-message-row"`.
    - Uses shared avatar (`avatar avatar-placeholder`), sender name, subject, optional receipt glance bar/copy, sent-at label, and chevron.
- Current members:
  - Section ID `#club-members`.
  - Heading: `Current members`.
  - Optional member-management button: `Invite member`.
  - Card ID `#active-members-card`, `data-active-member-count`, `data-active-members-state`.
  - First-run state (`@active_member_count <= 1`):
    - ID `#active-members-empty-state`.
    - Shows first member avatar or users icon fallback.
    - H3: `You’re the first member listed`.
    - Body: `As members are added, you’ll see them here.`
  - Active-members state:
    - Avatar stack up to six members plus overflow avatar.
    - Count label and body `Memba sends club-wide messages to everyone with a current membership.`

## Member message detail / read view

- Template: `PageHTML.message/1`, loaded by `MemberMessageLive.Show`.
- Main ID: `#member-message-detail`.
- Data:
  - `data-live-view="member-message-detail"`.
  - `data-club-id`.
  - `data-message-id`.
- Back link: `Club home`.
- Header:
  - Eyebrow: `Club message`.
  - H1: message subject.
  - Meta ID `#member-message-meta`: `From {sender_name} · sent to {count} member(s)`.
  - Body ID `#member-message-body`, whitespace-preserving.
- Delivery summary:
  - Section ID `#member-receipt-summary`.
  - Card with heading `Message delivery`.
  - Count pill ID `#member-receipts-summary`.
  - Summary bar ID `#member-receipt-summary-bar` with status-colored segments.
  - Legend ID `#member-receipt-summary-legend` with status labels, descriptions, counts, and percentages.
- Members by status:
  - Section ID `#member-receipts-section`.
  - H2: `Members by delivery status`.
  - Body: `Delivered messages are shown first. Messages still sending or not delivered are grouped below.`
  - Empty state ID `#member-receipts-empty`: `Memba has not prepared the delivery list for this message yet. Check again in a moment.`
  - Group ID shape `#member-receipt-group-{status_slug}`.
  - Group toggle IDs shape `#member-receipt-group-toggle-{status_slug}` with expanded/collapsed chevron.
  - Expanded receipt rows show recipient initial, name, icon, and shared `status_badge`.

## Member compose states from `MemberMessageLive.New`

- Main ID: `#member-message-compose`.
- Data includes `data-live-view="member-message-compose"`, club/current-member/count fields, `data-compose-state`, and `data-sent-message-id`.
- Composing card:
  - Back link: `Club home`.
  - Eyebrow: `New message`.
  - H1: `Send a message to all current members`.
  - Club label: selected club name.
  - Recipient summary: `Before you send: this message will be emailed to {all N current members} of {club}. There is no list to pick.`
  - Optional inbound-email hint: `Prefer email? You can also send a club-wide message to {inbound_email_address}`.
  - From summary shows avatar, `{current_member.name} (you)`, and `Sending as yourself`.
  - Form ID `#member-message-compose-form`.
  - Fields: `#member-message-subject-input` (`Subject`) and `#member-message-body-input` (`Message`).
  - Body validation message: `Message body can’t be blank.`
  - Buttons: `Send to all current members`, `Cancel`.
- Success state:
  - ID `#member-compose-success-state`.
  - Eyebrow: `Club message`.
  - H1: `Your message is being sent.`
  - Summary: `Memba is sending your message to {all N current members}. You can check delivery on the message page.`
  - Buttons: `Check delivery`, `Send another message`, `Back to club home`.
- Error state:
  - ID `#member-compose-error-state`.
  - Eyebrow: `Club message`.
  - H1: `Your message was not sent.`
  - Summary: `No one received this message. Please try again. If it still fails, ask a group organizer to contact Memba.`
  - Buttons: `Try again`, `Back to club home`.

## Shared component cues for static previews

- App/member buttons are `btn` plus variant classes:
  - Primary: `btn btn-primary`.
  - Secondary: `btn btn-soft`.
  - Ghost: `btn btn-ghost`.
  - Danger: `btn btn-error`.
- Shared avatars render as `avatar avatar-placeholder`; inner circle uses rounded full, sage text, and a sage background from a deterministic cycle.
- Shared status badges render as `badge badge-soft` plus optional `badge-success`, `badge-info`, `badge-warning`, or `badge-error`, with a tiny current-color dot.
- Admin components use explicit hex palette:
  - Ink `#15201c`, secondary `#4b5a55`, muted `#7d877f`.
  - Forest/action `#1f4842`.
  - Lines `#d6d2c8`, `#e0ddd4`, `#e6e3dc`.
  - Warm canvas/backgrounds `#efede8`, `#fbfaf8`, `#f8f5ee`.
