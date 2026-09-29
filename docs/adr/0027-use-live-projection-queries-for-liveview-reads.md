# 27. Use live queries for club-member LiveView reads

Date: 2026-09-28

## Status

accepted

## Context

[ADR 0021](0021-publish-committed-read-model-changes.md) announces changes after projections commit. Some club-member LiveViews react to those announcements; others keep showing the data loaded when the page opened. Each page currently has to connect its projection reads to separate event filters and refresh handlers. That duplication makes omissions likely, especially when a page combines membership, people and conversations. A projection event is not itself the authorized result the page should show. We want open member pages to stay current without making every LiveView maintain a second description of its read dependencies. The underlying projections need not be redesigned to achieve this.

## Decision

Club-member LiveViews will obtain projection-backed display data through **live queries**. Each view-specific query returns one coherent view model for one assign and describes which collection scopes and records can change its result. The LiveView owns the subscription; a relevant committed change triggers a fresh, authorized read of that query. Club home begins with one dashboard view model, not separately refreshed fields. Put the reusable binding mechanism in a local Mix path-dependency package independent of Memba and Commanded; keep Memba's queries and notification adapter in the app. This avoids duplicated per-page handlers and event-driven field patching. Staff streams are deferred to a separate decision.

## Consequences

**Easier:**

- Relevant member lists, counts and names update without a manual reload; read and invalidation rules live together.
- Replacing only a query's assign leaves form and navigation state alone.
- The local package enforces an extraction boundary without publishing to Hex now.

**Harder:**

- A query must account for every contributing projection, including records newly entering or leaving a list, and recheck access with current inputs.
- Refreshing can add database work; imprecise invalidation may add more.
- The package requires build and test integration.
- PubSub is not durable: a lost notification can leave a connected page stale, including after access changes, until another update or reconciliation. This does not promise immediate durable delivery.
