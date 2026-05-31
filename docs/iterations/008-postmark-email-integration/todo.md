# Implementation TODO

- [x] 001 Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.
- [x] 002 Decide the smallest provider shape: likely `Memba.Messaging.DeliveryProviders.Postmark` implementing `Memba.Messaging.DeliveryProvider` and using `Memba.Mailer`/Swoosh.
- [x] 003 Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.
- [x] 004 Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.
- [x] 005 Build the outbound email from `DeliveryRequest`, including recipient, configured sender/from, configured reply-to, subject, text body, minimal safe HTML body, and Postmark metadata/custom fields for `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.
- [x] 006 Enable universal Postmark open tracking for member-message emails through the supported Swoosh/Postmark mechanism.
- [x] 007 Ensure transport/auth/configuration/API failures from Postmark fail the send command hard and visibly, while preserving webhook-driven delivery outcomes for recipient-specific status changes.
- [x] 008 Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.
- [x] 009 Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.
- [x] 010 Update documentation for enabling Postmark, configuring environment variables, configuring the Postmark webhook URL, and choosing a monitored Memba-controlled sending subdomain.
- [ ] 011 Run the existing browser/domain acceptance suites and `dev check`, fixing regressions without weakening fake-provider determinism.
