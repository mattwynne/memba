# Problems

## People cannot ask Memba to erase personal data

Observed: 2026-10-13

Status: Unresolved. Person merge deliberately leaves a non-sign-in historical identity shell and
does not claim to satisfy a data-erasure request.

Memba has no recorded retention policy or supported operation that erases or irreversibly
anonymizes a person's personal data across authoritative events, projections, messages, inbound
email, delivery records, onboarding records, authentication records, backups, logs, and email
providers.

Expected:

- Memba can identify every place it stores or sends a person's personal data.
- A documented retention policy distinguishes data that must be erased, anonymized, or retained.
- An authorized erasure workflow revokes access immediately and completes the required erasure or
  anonymization across Memba and its processors.
- Event-sourced history does not retain readable personal data merely because events are immutable.
- The operation produces an identifier-free audit receipt and is safe to retry.

