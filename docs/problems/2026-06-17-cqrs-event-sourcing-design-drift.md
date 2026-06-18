# Problems

## CQRS/event-sourcing design drift is concentrating orchestration, read-model checks, and side effects in application services

Observed: 2026-06-17

Status: Unresolved

A design review against the CQRS, DDD, RDD, and event-sourcing reference guidance found that Memba has a strong event-sourced foundation, but some recent growth is pulling important responsibilities back into large transaction-script-style application services.

The good baseline:

- `Membership` and `Messaging` are separate Commanded applications with explicit routers and aggregates.
- Commands and events mostly use domain language and past-tense event names.
- Query models are separated into Ecto projections rather than read directly from aggregate streams.
- Messaging calls Membership through public query APIs for recipient and sender/member lookups instead of joining Membership projection tables directly.
- Projection barriers and read-model change publication explicitly acknowledge CQRS read-your-writes and live-update concerns.

The main design drift:

- `Memba.Membership` and `Memba.Messaging` have become very large application-service modules (`membership.ex` is over 1,300 lines; `messaging.ex` is nearly 900 lines). They mix public command APIs, public query APIs, command construction, duplicate read-model preflight checks, cross-aggregate orchestration, side-effect sequencing, and presentation compatibility normalization.
- Some domain policies are enforced only by application-service preflight reads against projections, not by aggregate boundaries. Examples include duplicate club slugs, duplicate person email addresses, duplicate active memberships, active-member invitation checks, and “last Membership Admin” protection. That may be acceptable for cross-aggregate rules, but the policy ownership and consistency trade-off are not named clearly and can be raced unless protected by database constraints or a serialized process.
- Multi-aggregate workflows are orchestrated imperatively without an explicit process manager/saga/outbox boundary. Invitation acceptance and onboarding conversion dispatch several Membership commands in sequence and then update an Ecto request/invitation projection. Failures midway can leave earlier events committed while later steps did not happen.
- Messaging command handling is interleaved with external email side effects. `send_club_message/2` dispatches `SendMessage`, commits `MessageSent` and `EmailDeliveryCreated` events/projections, then calls the email provider. If provider delivery fails part-way through recipient delivery, the function returns an error even though the domain event stream and read models already say the message was sent and deliveries were created. That creates a mismatch between command result, event history, projection state, and real-world side effects.
- Inbound email processing chains several decisions and side effects in one service: receive idempotency, destination resolution, sender resolution, membership authorization, attachment/body policy, message sending, acceptance/rejection recording, and rejection email delivery. These are understandable responsibilities, but they are concentrated in one module rather than named as collaborators with explicit contracts.
- Compatibility for the deprecated `opened` delivery status still leaks across commands/events/projectors/query normalization/presentation/tests (captured separately in `2026-06-17-obliterate-opened-email-delivery-status.md`). This is also a symptom of event-versioning policy being implicit: the codebase lacks a visible rule for historic-event compatibility shims vs active domain vocabulary.
- Several projections store free-text statuses without database check constraints, while some ordinary Ecto tables (`onboarding_requests`, `auth_email_requests`, `membership_club_invitations`) do use status constraints. The inconsistency makes replay/projection bugs easier to persist silently.
- Naming drift such as `list_member_email_deliverys/1` and duplicated email/id normalization helpers makes public contracts less polished and raises the cost of future refactors.

Expected:

- Application services should remain thin use-case coordinators; important policies, collaborations, and side-effect boundaries should be named explicitly.
- Cross-aggregate rules should state whether they are protected by aggregate design, database constraints, serialized process managers, projection preflight checks, or compensating/repair behaviour.
- External side effects should not make an already-committed event stream look as though a failed command did not happen. Delivery handoff should have an explicit lifecycle that is replay-safe and observable.
- Event compatibility code should be distinguished from current domain vocabulary so deprecated concepts do not keep re-entering product design.
- Query/read-model APIs should be named and shaped deliberately; projections can be rebuilt safely and constrained consistently.

Most important improvement opportunity:

Separate message-send domain decisions from email-provider side effects. A small technical iteration should make email delivery handoff an explicit, observable, retryable boundary rather than an immediate post-dispatch side effect hidden inside `Memba.Messaging.send_club_message/2`.
