## Repair summary

No code/config/test changes were needed.

### 1. Review issue from the gate

#### `broaden-opened-projector-noops`
**Title:** Broaden `EmailDeliveryOpened` replay-only projector no-op clauses.

**Result:** Already satisfied by the current implementation.

Both projector shims already match only the event struct and do **not** constrain metadata shape:

- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
  - `project(%EmailDeliveryOpened{}, fn multi -> multi end)`

- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
  - `project(%EmailDeliveryOpened{}, fn multi -> multi end)`

There is no `%{email_delivery_id: _}` or other metadata-specific pattern in either projector no-op clause. This is already the broad defensive shape requested by the synthesized review.

### 2. Concrete changes made

None.

Justification: applying a patch would either be a no-op or introduce unnecessary churn. The selected bounded issue was to loosen over-constrained projector no-op clauses, but the clauses are already maximally broad for the `Commanded.Projections.Ecto.project/2` style used here.

### 3. Files changed

None.

### 4. Validation performed

Ran source verification:

```sh
git status --short
grep -RInE 'project\(%EmailDeliveryOpened\{|%\{email_delivery_id:' web/lib/memba/messaging/projectors
```

Result:

```text
?? .fabro/tmp/
web/lib/memba/messaging/projectors/member_email_delivery.ex:51:  project(%EmailDeliveryOpened{}, fn multi ->
web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex:61:  project(%EmailDeliveryOpened{}, fn multi ->
```

This confirms:
- no repair diff was introduced;
- the only untracked path is `.fabro/tmp/`;
- both projector no-op clauses are already broad;
- no projector metadata pattern like `%{email_delivery_id: _}` exists.

I did not rerun `dev check` because no code/config/test/app-behaviour change was made in this repair pass. The earlier pipeline `dev_check` had already passed on this same code state before repair.

### 5. Remaining gaps or human questions

None.

## Issue-to-fix mapping

| Review issue | Status | Files/modules/tests |
|---|---:|---|
| `broaden-opened-projector-noops` | No change needed; already satisfied | `Memba.Messaging.Projectors.MemberEmailDelivery`, `Memba.Messaging.Projectors.MembaStaffEmailDelivery` |