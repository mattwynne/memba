# 12. Track whether a message delivery was opened

Date: 2026-05-26

## Status

accepted

## Context

Memba needs member-facing receipt status and operator deliverability status for messages. One important status is whether a delivered message was opened.

Email open tracking can produce duplicate events because clients may load images more than once, proxy images, or trigger repeated requests. Future provider integrations may also send repeated open events.

For the first domain slice, the product need is simply to know whether a recipient delivery has been opened at least once.

## Decision

Track `opened` as a boolean-like delivery status: opened at least once.

The valid transition is `delivered -> opened`.

Once a delivery is `opened`, repeated open reports are idempotent. They do not create additional domain events and do not track open count or last-opened time in this slice.

## Consequences

Member-facing and operator-facing views can answer the important question: was this delivery opened?

The model stays simple and avoids overfitting before real provider/tracking-pixel behaviour is observed.

If we later need open counts, last-opened timestamps, or device/client diagnostics, a future ADR can add separate telemetry events or richer read-model fields without changing the basic receipt vocabulary.
