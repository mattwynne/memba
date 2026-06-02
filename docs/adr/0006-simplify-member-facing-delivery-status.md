# 6. Simplify member-facing delivery status

Date: 2026-05-26

## Status

accepted

## Context

Memba tracks detailed delivery statuses for operational reliability and support. Providers and future delivery channels may report detailed states such as sent, delivered, delayed, bounced, spam complaint, and opened.

Regular club members should not need to understand provider-specific delivery terminology. Many target club members are older or not especially technical, so member-facing language should be simple and approachable.

Operators still need the detailed status and reason so they can diagnose deliverability problems.

## Decision

Map detailed delivery statuses to a small member-facing status vocabulary:

| Domain status | Member-facing status |
| --- | --- |
| `sent` | `sent` |
| `delivered` | `delivered` |
| `delayed` | `delivery problem` |
| `bounced` | `delivery problem` |
| `spam_complaint` | `delivery problem` |
| `opened` | `opened` |

The Memba staff email delivery view keeps the detailed status and provider/channel reason.

## Consequences

Regular members get a simple WhatsApp/SMS-like receipt experience: sent, delivered, delivery problem, or opened.

Operators retain enough detail to investigate problems without exposing provider jargon in the regular member experience.

The mapping may evolve after real Postmark testing, but this vocabulary is the accepted starting point for the first deliverability slice.
