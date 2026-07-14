# Architecture decision records

This directory contains Memba's architecture decision records (ADRs).

| ADR | Summary | Status |
| --- | --- | --- |
| [0001. Use Phoenix for the core application](0001-use-phoenix-for-the-core-application.md) | Use Elixir/Phoenix, Phoenix LiveView, and PostgreSQL for the core application. | accepted |
| [0002. Use Commanded and event sourcing by default](0002-use-commanded-for-cqrs-workflows.md) | Use Commanded as the CQRS and event-sourcing foundation for domain models. | accepted |
| [0003. Use Cucumber at domain and application layers](0003-use-cucumber-at-domain-and-application-layers.md) | Run the same Cucumber feature files at both domain and application layers. | accepted |
| [0004. Model message deliverability as a message aggregate](0004-model-message-deliverability-as-a-message-aggregate.md) | Model the first deliverability slice with one message aggregate per message. | accepted |
| [0005. Message send commands include resolved recipients](0005-message-send-commands-include-resolved-recipients.md) | Resolve recipients before dispatch and include them in `SendMessage` commands. | accepted |
| [0006. Simplify member-facing delivery status](0006-simplify-member-facing-delivery-status.md) | Expose a small member-facing status vocabulary instead of detailed provider statuses. | accepted |
| [0007. Use separate Membership and Messaging Commanded contexts](0007-use-separate-membership-and-messaging-commanded-contexts.md) | Keep membership and messaging in separate Commanded contexts from the start. | accepted |
| [0008. Use PostgreSQL EventStore schema with Commanded](0008-use-postgres-eventstore-schema-with-commanded.md) | Store Commanded events with `commanded_eventstore_adapter` and the `eventstore` package. | accepted |
| [0009. Use Commanded Ecto Projections](0009-use-commanded-ecto-projections.md) | Use `commanded_ecto_projections` for Ecto-backed read models. | accepted |
| [0010. Use shared feature files with Elixir Cucumber](0010-use-shared-feature-files-with-elixir-cucumber.md) | Use the Elixir Cucumber package to share feature files across test layers. | accepted |
| [0011. Use caller-generated UUID aggregate identities](0011-use-caller-generated-uuid-aggregate-identities.md) | Generate UUID aggregate identities at the caller before dispatching commands. | accepted |
| [0012. Track whether a message delivery was opened](0012-track-whether-message-delivery-was-opened.md) | Track whether each delivery has been opened at least once. | accepted |
| [0013. Use PhoenixTest for feature-style web tests](0013-use-phoenix-test-for-feature-style-web-tests.md) | Use `phoenix_test` for feature-style Phoenix web tests. | accepted |
| [0014. Use Fly.io for production hosting](0014-use-fly-io-for-production-hosting.md) | Use Fly.io as Memba's initial production hosting platform. | accepted |
| [0015. Use LiveView for member application pages](0015-use-liveview-for-member-application-pages.md) | Use Phoenix LiveView by default for member application pages. | accepted |
| [0016. Use Resend as a switchable email provider](0016-use-resend-as-switchable-email-provider.md) | Support Resend as a first-class switchable email provider alongside Postmark. | accepted |
| [0017. Treat release state as a first-class production artifact](0017-treat-release-state-as-a-first-class-production-artifact.md) | Explicitly verify production release state as part of the release process. | accepted |
| [0018. Let devenv/process-compose own development services](0018-let-devenv-process-compose-own-dev-services.md) | Keep `bin/dev` thin and let devenv/process-compose own service management. | accepted |
| [0019. Use lvh.me for local club subdomains](0019-use-lvh-me-for-local-club-subdomains.md) | Use a configurable club-site base domain, with `lvh.me` for local subdomains. | accepted |
| [0020. Use Fastmail for production email smoke tests](0020-use-fastmail-for-production-email-smoke-tests.md) | Keep production email smoke tests Fastmail-only. | accepted |
| [0021. Publish committed read-model changes](0021-publish-committed-read-model-changes.md) | Publish committed read-model changes on the application PubSub bus. | accepted |
| [0022. Use projection barriers for read-your-writes checks](0022-use-projection-barriers-for-read-your-writes.md) | Use projection barriers for read-your-writes synchronization and negative acceptance assertions. | accepted |
| [0023. Use URL-addressable LiveView state](0023-use-url-addressable-liveview-state.md) | Reflect visible member-page state changes in the URL whenever practical. | accepted |
