# Iteration 015 Club Slugs - Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

No ADRs are explicitly cited in the plan. The implementation follows CQRS/ES patterns (Commands, Events, Aggregates, Projections), Phoenix/LiveView conventions, Ecto patterns, and Elixir idioms consistently with the observable codebase architecture. No ADR violations detected from available evidence.

---

## ADR Violations

None found.

---

## Blocking Issues

None found.

The implementation fully delivers all acceptance criteria from the plan:
- ✅ Slugs added to clubs with auto-generation from names
- ✅ Staff can edit slugs with validation and live duplicate feedback
- ✅ Database unique constraint enforced
- ✅ Public routing via `slug.clubs.memba.io` subdomains works
- ✅ Unknown subdomains return 404
- ✅ Existing club_id routes maintained
- ✅ Comprehensive test coverage across domain, persistence, routing, and UI
- ✅ Dev check passes

The data migration strategy (non-null `slug` column without backfill) aligns with the plan's explicit decision: "Old slug-less `ClubCreated` event replay does not need compatibility support because there is no live production data yet." Since dev check passes, this confirms test databases are clean or reset appropriately.

---

## Bounded-Safe Fixes

### 1. Extract Slug Generation to Domain Module

**File**: `web/test/support/membership_fixtures.ex`

**Issue**: Slug generation logic (combining name + UUID suffix) is duplicated in test fixtures rather than living in the domain module.

**Current**:
```elixir
def membership_club_slug(name, club_id) when is_binary(name) and is_binary(club_id) do
  suffix =
    club_id
    |> String.replace("-", "")
    |> String.slice(0, 8)

  max_base_length = Slug.max_length() - String.length(suffix) - 1

  base =
    name
    |> Slug.default_from_name()
    |> String.slice(0, max_base_length)
    |> String.trim("-")

  case base do
    "" -> suffix
    base -> "#{base}-#{suffix}"
  end
end
```

**Suggested**:
```elixir
# In web/lib/memba/membership/slug.ex
def generate(name, club_id) when is_binary(name) and is_binary(club_id) do
  suffix = club_id |> String.replace("-", "") |> String.slice(0, 8)
  max_base_length = @max_length - String.length(suffix) - 1

  base =
    name
    |> default_from_name()
    |> String.slice(0, max_base_length)
    |> String.trim("-")

  case base do
    "" -> suffix
    base -> "#{base}-#{suffix}"
  end
end

# In web/test/support/membership_fixtures.ex
def membership_club_slug(name, club_id) do
  Memba.Membership.Slug.generate(name, club_id)
end
```

**Rationale**: Eliminates duplication, ensures test slugs match production generation logic, reduces drift risk.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

### 1. Data Migration Strategy for Schema Changes

**Files**: `web/priv/repo/migrations/20250217000000_add_slug_to_membership_clubs.exs`

**Smell**: The migration adds a non-null column without handling existing rows:
```elixir
add :slug, :text, null: false
```

**Why judgement-worthy**: 
- The plan explicitly decides "no live production data yet" and skips backward compatibility
- This works for greenfield deployments but creates a sharp edge for environments with existing test data
- Standard database migration practice would backfill existing rows before applying non-null constraints
- Future schema changes might need a more robust pattern (add nullable → backfill → make non-null)

If dev/staging environments always reset databases, current approach is fine. If they preserve data across deploys, this migration will fail with null constraint violations. Human should establish project-wide data migration conventions before additional schema changes.

---

### 2. Event Versioning and Backward Compatibility

**Files**: 
- `web/lib/memba/membership/events/club_created.ex`
- `web/lib/memba/membership/aggregates/club.ex`

**Smell**: The `ClubCreated` event now requires `slug` in its struct:
```elixir
defstruct [:club_id, :name, :slug]
```

Old events without slugs won't deserialize or replay.

**Why judgement-worthy**:
- Event sourcing best practice treats events as immutable, permanent records
- Adding required fields breaks backward compatibility with existing event streams
- The plan explicitly chooses to ignore this: "no live production data yet"
- This works pre-production but won't scale to live systems where events must be replayable forever

Before production launch, the project needs an event versioning strategy:
- Optional fields with defaults
- Event upcasting/migration
- Versioned event schemas (e.g., `ClubCreatedV2`)

Current approach is acceptable for pre-production based on plan's explicit decision, but human should establish event evolution patterns before go-live.

---

### 3. Hardcoded Domain Names in Routing Logic

**Files**: `web/lib/memba_web/plugs/resolve_club_from_host.ex`

**Smell**: Domain names are hardcoded:
```elixir
defp parse_club_subdomain(host) do
  case String.split(host, ".") do
    [slug, "clubs", "memba", "io"] -> {:ok, slug}
    [slug, "clubs", "localhost"] -> {:ok, slug}
    _ -> :error
  end
end
```

**Why judgement-worthy**:
- Makes testing with different domain names harder
- Can't easily support multiple environments with different base domains without code changes
- However, for a single-deployment app, this is simple and explicit

If the app will ever need:
- Multiple environments with different domains (e.g., staging.memba.io)
- Testing with custom domains
- Different TLDs for different regions

Then consider making the base domain configurable via `config/*.exs`. For a single-deployment app, current approach is clear and works.

---

### 4. Slug Minimum Length Not Enforced

**Files**: `web/lib/memba/membership/slug.ex`

**Smell**: The validation regex allows single-character slugs:
```elixir
slug =~ ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/
```

The `?` makes the middle and end parts optional, so "a", "b", "9" are all valid.

**Why judgement-worthy**:
- Single-character slugs might be confusing, easy to typo, or collide unexpectedly
- No minimum length is stated in the plan
- However, they're technically valid and address-safe

Human should decide: Should there be a minimum slug length (e.g., 3 characters), or are single-character slugs acceptable? If a minimum is desired:

```elixir
def valid?(slug) when is_binary(slug) do
  byte_size(slug) >= 3 and  # Add minimum
    byte_size(slug) <= @max_length and
    slug =~ ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/
end
```

---

### 5. Reserved Slug Validation Deferred

**Files**: `web/lib/memba/membership/slug.ex`

**Smell**: The plan acknowledges reserved slugs (www, admin, support, etc.) will be needed but defers implementation.

**Why judgement-worthy**:
- Currently, a club could claim `www` or `admin` as their slug
- This could block critical infrastructure subdomains later
- The plan explicitly defers this as future work

Before public launch or wider club onboarding, implement reserved slug validation:

```elixir
@reserved_slugs ~w(www app admin support postmaster abuse no-reply noreply)

def reserved?(slug) when is_binary(slug) do
  slug in @reserved_slugs
end

def valid?(slug) when is_binary(slug) do
  byte_size(slug) > 0 and
    byte_size(slug) <= @max_length and
    slug =~ ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/ and
    not reserved?(slug)
end
```

Human should establish the reserved word list and implement before public slugs are advertised.

---

## Suggested Fixes

If accepting with bounded-safe fixes:

1. Extract slug generation to `Memba.Membership.Slug.generate/2` and use it from test fixtures (eliminates duplication).

No other fixes are strictly required. The judgement-worthy findings are architectural patterns that work for pre-production but may need evolution before production (data migrations, event versioning, reserved slugs).

---

## Validation Notes

✅ **Dev check passed**: All tests green, compilation clean, no warnings.

✅ **Test coverage**: 
- Domain: Slug validation, generation, uniqueness checking
- Persistence: Migration, schema, projection updates
- Routing: Subdomain parsing, club resolution, 404 for unknown hosts
- UI: LiveView slug display/editing, live duplicate feedback
- Integration: Host-based routing, public club pages

✅ **Plan conformance**: All acceptance criteria delivered:
- Slugs added to clubs with auto-generation
- Staff can edit slugs with validation
- Duplicate detection (live + server + DB)
- Public routing via `slug.clubs.memba.io`
- Backward compatibility with club_id routes
- Unknown hosts return 404

✅ **Code quality**: 
- Clean Phoenix/LiveView patterns
- Proper CQRS/ES separation (Commands, Events, Aggregates, Projections)
- Standard Ecto migrations and schemas
- Appropriate use of plugs for request pipeline
- Small, focused modules with clear responsibilities

✅ **Technical decisions align with plan**:
- Max slug length: 32 characters ✅
- Public club subdomains use `slug.clubs.memba.io` ✅
- Staff-entered slugs must be address-safe (validated, not kebab-cased) ✅
- Duplicate slug feedback: live client + server/DB enforcement ✅
- No backward compatibility for old events (explicit plan decision) ✅

The implementation is production-ready for pre-production environments. Before public launch, address the judgement-worthy findings (reserved slugs, event versioning strategy, minimum slug length policy).