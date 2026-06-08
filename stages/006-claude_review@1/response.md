# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS (with caveat)

**Note**: Actual ADR files were not included in the implementation evidence, but the implementation demonstrates adherence to the architectural decisions stated in the plan:

- ✅ Separate invitation token storage (database-backed, not Phoenix.Token)
- ✅ Email normalization matching person email addresses  
- ✅ No incomplete person records before profile completion
- ✅ Profile completion state in session/journey
- ✅ Token not consumed on first link open for unknown invitees

## ADR Violations

None identified, with the caveat that ADR files themselves were not available for review.

## Blocking Issues

None. The implementation is production-ready after addressing bounded-safe fixes.

## Bounded-Safe Fixes

1. **Remove dead plug**: `MembaWeb.Authentication.AcceptInvitationPlug` is defined but empty. Either remove it from `router.ex` pipeline `:accept_invitation` and delete the file, or add a module doc explaining it's a placeholder for future middleware.

2. **Use route helper instead of hardcoded path**: In `accept_invitation_controller.ex`, replace:
   ```elixir
   defp club_path(club_id) do
     "/clubs/#{club_id}"
   end
   ```
   with a proper route helper like `~p"/clubs/#{club_id}"` or use the club subdomain routing pattern already established.

## Judgement-Worthy Non-Blocking Code-Health Findings

### 1. PersonEmailAddress migration gap (Severity: High if production data exists)

**Files**: `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`, `web/lib/memba/accounts/person.ex`

**Issue**: The Person schema now has `field :email, :string, virtual: true` and delegates email storage to `person_email_addresses` table, but there's no data migration to:
- Move existing `people.email` column data to `person_email_addresses` 
- Add a migration to remove the `email` column from `people` table
- Handle existing Person records created before this iteration

**Impact**: `Accounts.find_person_by_email/1` now only queries `person_email_addresses`:
```elixir
from p in Person,
  join: e in assoc(p, :email_addresses),
  where: e.normalized_email == ^normalized_email
```

If any Person records exist with email only in `people.email`, they won't be found. The sandbox check passed because test fixtures create new people with the association, but production deployment with existing data would break person lookups.

**Why human judgement**: If this is a green-field deployment or there's no production data, this is non-blocking. If production people exist, a data migration is needed before deploy. Matt should confirm whether backward compatibility is needed.

---

### 2. Person.email virtual field pattern (Severity: Medium)

**Files**: `web/lib/memba/accounts/person.ex`

**Issue**: The virtual `email` field is used only as changeset input to build the `email_addresses` association:
```elixir
defp put_assoc_email_address(changeset) do
  case get_change(changeset, :email) do
    nil -> changeset
    email ->
      email_address_changeset = PersonEmailAddress.changeset(%PersonEmailAddress{}, ...)
      put_assoc(changeset, :email_addresses, [email_address_changeset])
  end
end
```

After loading a Person from the database, `person.email` is `nil` because it's virtual. Code must navigate `person.email_addresses |> List.first() |> Map.get(:email)` to access the email.

**Why human judgement**: This pattern works but is unconventional and may confuse maintainers. Consider either:
- Adding a `primary_email/1` helper function to Person
- Documenting the pattern clearly in the module
- Avoiding the virtual field entirely and handling email differently in changesets

---

### 3. Email template HTML escaping (Severity: Low - security hygiene)

**Files**: `web/lib/memba_web/email/club_member_invitation_email.ex`

**Issue**: Club name is interpolated directly into HTML without escaping:
```elixir
|> html_body("""
<h2>You're invited to join #{club.name}!</h2>
...
""")
```

If a club name contains HTML characters or tags, they'd be rendered in the email. Risk is mitigated because:
- Only Memba staff can create clubs
- Email clients typically sanitize HTML
- The recipient (invitee) is the potential victim, not the staff member

**Why human judgement**: Low-risk in practice but violates security best practices. Swoosh doesn't auto-escape. Consider using `Phoenix.HTML.html_escape/1` or a proper email template library with auto-escaping for production hardening.

---

### 4. Synchronous email delivery (Severity: Low - performance)

**Files**: `web/lib/memba/invitations.ex`

**Issue**: Invitation email is sent synchronously during the HTTP request:
```elixir
defp send_invitation_email(%{invitation: invitation, club: club, url_token: url_token}) do
  ...
  case Memba.Mailer.deliver(email) do
    {:ok, _metadata} -> :ok
    {:error, reason} -> {:error, reason}
  end
end
```

If email delivery is slow or fails, it blocks the staff member's UI. Acceptable for MVP with low invitation volume.

**Why human judgement**: For production scale, consider async email delivery via Oban or similar. Current approach is simpler and acceptable for initial deployment.

---

### 5. Invitation token in projection (Severity: Low - architecture)

**Files**: `web/lib/memba/club_members/projections/invitation.ex`

**Issue**: The invitation token is generated in the projection handler, not in the command/event:
```elixir
def handle(%InvitationCreated{} = event, _metadata) do
  {url_token, hashed_token} = InvitationToken.build_hashed_token()
  projection = %Invitation{} |> changeset(%{..., hashed_token: hashed_token}) |> Repo.insert!()
  {:ok, url_token}
end
```

This means:
- Token is not part of the event stream (only in read model)
- Rebuilding projections would regenerate different tokens
- All existing invitation links would be invalidated on projection rebuild

This is unconventional for event sourcing but may be an intentional trade-off for simplicity. Tokens are one-use anyway.

**Why human judgement**: If projection rebuilds are expected to be rare and invalidating pending invitations is acceptable, this is fine. Otherwise, consider generating tokens deterministically or including them in events.

---

### 6. Duplicate invitation race condition (Severity: Low)

**Files**: `web/lib/memba/invitations.ex`, migration for invitations table

**Issue**: Duplicate detection happens in the context layer, not enforced by database constraints:
```elixir
cond do
  pending_invitation = find_pending_invitation(club_id, normalized_email) -> resend_invitation(...)
  true -> create_new_invitation(...)
end
```

No unique constraint exists on `(club_id, normalized_email)` for `status = 'pending'`. If two staff members invite the same email simultaneously, both might create separate invitation aggregates (different UUIDs).

**Impact**: Worst case is duplicate invitation emails sent. When the invitee accepts, only one invitation is consumed; the other remains pending but harmless.

**Why human judgement**: The impact is minimal (duplicate emails, not duplicate memberships). Adding a unique constraint would prevent the race but add complexity. Current approach is acceptable if duplicate emails are tolerable.

---

### 7. Basic email template styling (Severity: Low - UX)

**Files**: `web/lib/memba_web/email/club_member_invitation_email.ex`

**Issue**: Email template is minimal HTML with no:
- CSS styling or branding
- Header/footer with company info
- Unsubscribe link (if required for transactional emails)
- Responsive design for mobile

Functional for MVP but looks unpolished.

**Why human judgement**: Determine when to invest in professional email templates. Current version is acceptable for internal testing and early clubs but should be improved before broader rollout.

---

### 8. Person email accessor API (Severity: Low - DX)

**Files**: `web/lib/memba/accounts/person.ex`

**Issue**: No clear helper for accessing a person's email after loading from the database. Code must navigate:
```elixir
person.email_addresses |> List.first() |> Map.get(:email)
```

Combined with issue #2 (virtual email field), this creates friction for developers.

**Why human judgement**: Consider adding a `Person.primary_email/1` helper or preloading with a custom select to make email access cleaner. Document the current approach if keeping it.

---

## Suggested Fixes

### For Bounded-Safe Issues:

**1. Remove empty plug** (or document it):
```elixir
# In router.ex, remove from pipeline:
  pipeline :accept_invitation do
    # ... other plugs ...
    # plug MembaWeb.Authentication.AcceptInvitationPlug  # Remove this line
  end

# Delete web/lib/memba_web/authentication/accept_invitation_plug.ex
```

**2. Use route helper**:
```elixir
# In accept_invitation_controller.ex
defp club_path(club_id) do
  ~p"/clubs/#{club_id}"
  # Or use the proper club subdomain routing if that's the pattern
end
```

---

## Validation Notes

### Test Coverage:
- ✅ Domain tests cover invitation creation, resend, duplicate detection, and acceptance
- ✅ Controller tests cover both existing-person and unknown-person flows
- ✅ Controller tests cover profile completion edge cases (invalid name, reopening, expiry)
- ✅ LiveView tests cover staff invitation UI
- ✅ Email delivery tests verify template and recipients
- ✅ Acceptance tests (Cucumber) exercise end-to-end flows

### Dev Check Results:
- ✅ All compilation warnings resolved
- ✅ All tests passing (69 scenarios, 466 steps)
- ✅ Sandbox runtime check passed
- ✅ No formatter issues

### Plan Conformance:
- ✅ Invitation aggregate with pending/accepted/expired states
- ✅ Email normalization via PersonEmailAddress
- ✅ Separate invitation token storage
- ✅ Duplicate checks (active member block, pending resend)
- ✅ Invitation email with club context and one-use link
- ✅ Staff invite route under `/admin/clubs/:club_id/invite`
- ✅ Invitation callback validates tokens and routes appropriately
- ✅ Profile completion for unknown invitees
- ✅ Existing staff onboarding preserved
- ✅ Acceptance feature scenarios implemented

### Architecture Observations:
- Clean separation: Invitations context handles workflow, ClubMembers handles domain
- Proper event sourcing with aggregate, commands, events, and projections
- Good error handling with specific error atoms
- Session-based email binding during profile completion is secure (1-hour Phoenix.Token)
- Token not consumed until acceptance completes (as required)

---

**Overall Assessment**: This is a well-executed implementation that conforms to the plan and passes all automated checks. The bounded-safe fixes are trivial. The judgement-worthy findings are legitimate design questions but don't block merge—they're candidates for follow-up kaizen or pre-production hardening based on deployment context and risk tolerance.