# Task 001 inspection

Selected task:

- `001 Inspect the existing auth LiveView, auth email module, Postmark webhook controller, read-model change publisher, and current delivery-status LiveViews that subscribe to read-model changes.`

## Findings

### Sign-in request and check-email surface

- The public auth routes are in `web/lib/memba_web/router.ex`:
  - `live "/auth", AuthLive.SignIn, :new`
  - `live "/auth/check-email", AuthLive.SignIn, :sent`
  - `get "/auth/sign-in/:token", AuthController, :callback`
- `MembaWeb.AuthLive.SignIn` owns both the sign-in form and the current static check-email acknowledgement.
- On submit, `handle_event("request_sign_in_link", ...)` calls `request_and_deliver_sign_in_link/3` and then `push_patch(socket, to: ~p"/auth/check-email")`.
- The acknowledgement page uses neutral copy and no request/correlation identifier today:
  - section id: `auth-sign-in-sent`
  - notice id: `sign-in-link-sent-notice`
  - current notice: `If that email address can sign in to Memba, the sign-in email is on its way.`
- The sign-in flow already preserves anti-enumeration behaviour by returning the same acknowledgement for known and unknown addresses. `Accounts.request_sign_in_link/2` returns `{:ok, nil}` for unknown, invalid, and ineligible emails.
- Known recipients get an `auth_sign_in_tokens` row and a private callback URL. Unknown recipients do not get a token or email today.
- A separate get-started verification flow in `MembaWeb.PageController` creates a token with `Accounts.create_sign_in_token/2`, sends via `AuthEmail.deliver_sign_in_link/2`, and redirects to `/auth/check-email`. Later route changes should consider whether this flow needs an auth-progress request ID or should intentionally remain on the static fallback.

### Auth email construction

- `Memba.Accounts.AuthEmail` builds and sends sign-in-link emails through `Memba.Mailer`/Swoosh.
- `deliver_sign_in_link/2` and `/3` normalize the recipient email and callback URL, load `Memba.Accounts.AuthEmailConfig`, build text and HTML bodies, and call `Memba.Mailer.deliver/1`.
- Group-led context is supported through the third argument and is used by `AuthLive.SignIn` for known club-host sign-in requests.
- Provider options today:
  - Resend: `tags` with `memba_email_kind=auth_sign_in_link` and `memba_auth_email_stream`.
  - Postmark/default: `message_stream: config.message_stream`.
- There is no auth-email metadata/correlation in the Postmark provider options yet. Adding Postmark metadata for the opaque auth request should extend this module without changing email body content or exposing request details in UI copy.
- Runtime configuration already supports a dedicated auth stream through `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`; tests and prod examples use `outbound-authentication`.

### Auth persistence

- Current auth persistence is only `auth_sign_in_tokens`, represented by `Memba.Accounts.SignInToken`.
- Tokens store normalized email, SHA-256 token hash, expiry, optional consumed timestamp, and timestamps. Plaintext token is never persisted.
- There is no existing auth-email request/progress table, schema, cleanup query, or public request ID type.
- `Memba.ID` currently has typed prefixes for club/member/messaging/onboarding entities but no auth-email request type.

### Postmark webhook handling

- `MembaWeb.PostmarkWebhookController` handles `/webhooks/postmark` for outbound member-message delivery status.
- It maps Postmark `RecordType` values to `:delivered`, `:delayed`, `:bounced`, and `:spam_complaint`; open events are rejected as unsupported.
- It currently extracts `message_id` and `delivery_id` from `Metadata` first, then top-level fallback keys, and dispatches to `Memba.Messaging.report_email_delivery_*`.
- Missing required metadata returns a `422` response via `{:missing_required_attribute, key}` from the Messaging command builders.
- The controller does not inspect `MessageStream`, `Tag`, or auth-specific metadata yet. Auth-stream handling should branch before member-message dispatch when auth correlation metadata is present, while preserving existing member-message metadata and response semantics.
- Member-message idempotency is owned by the `Memba.Messaging.Message` aggregate; repeated same-status reports become no-op event lists, while conflicting transitions return errors.

### Committed-change publishing and subscribers

- ADR 0021 is implemented by `Memba.ReadModelChanges`.
- The shared message shape is:
  - topic: `Memba.ReadModelChanges.topic()` (`"read_model_changes"`)
  - message: `{:read_model_changed, %{projector:, source_event:, metadata:, changes:}}`
- PubSub starts before Commanded apps/projectors in `Memba.Application`, matching ADR 0021's supervision-order requirement.
- Existing Commanded Ecto projectors publish from `after_update/3`, including the messaging delivery projectors.
- Current LiveView subscribers follow the ADR 0021 pattern by subscribing only when connected and reloading from persistence after relevant messages:
  - `MembaWeb.Admin.DeliveriesLive.Index` refreshes the operator deliveries list when `Memba.Messaging.Projectors.MembaStaffEmailDelivery` commits.
  - `MembaWeb.Admin.MessagesLive.Show` refreshes delivery/member-receipt streams for the current message when `EmailDelivery` or `MemberEmailDelivery` projectors commit for that message.
  - `MembaWeb.MemberMessageLive.Show` refreshes the member message detail when `MemberEmailDelivery` commits for the current message.
  - `MembaWeb.MemberDashboardLive` refreshes the selected club dashboard when `MemberEmailDelivery` changes.
- ADR 0022 keeps projection barriers separate from live-update notifications. This iteration's auth progress record is not a Commanded projection, so later work should use a narrow committed-update publisher rather than overloading projection barriers or broadcasting before DB commit.

## Implementation notes for later tasks

- Add auth-email progress as simple Ecto source-of-truth state, not a Commanded aggregate/projection.
- Preserve the existing `/auth/check-email` fallback route for requests without an opaque public request ID.
- Use a separate auth-progress PubSub topic/message shape with only opaque request IDs/status-change hints, never email addresses or account-existence indicators.
- Have the check-email LiveView reload progress from persistence after broadcasts, mirroring current delivery-status LiveViews.
- Keep the existing member-message webhook path intact: auth webhook routing should key off auth stream/correlation metadata and otherwise continue through the current Messaging dispatch path.
- Existing browser/LiveView tests in `web/test/memba_web/controllers/auth_controller_test.exs` cover the current static route, known/unknown parity, and token/email side effects; these are the nearest tests to update when route shape and progress rendering change.
- Existing Postmark tests in `web/test/memba_web/controllers/postmark_webhook_controller_test.exs` prove member-message metadata/webhook behaviour and should remain green while adding auth-stream cases.
