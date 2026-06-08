Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KTK439GP6A36JG17BGSSJ0Q6
Pipeline progress: 10 of 26 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/028-staff-member-invitations/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Iteration plan not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
line_count=0
while IFS= read -r line && [ "$line_count" -lt 320 ]; do
  printf '%s\n' "$line"
  line_count=$((line_count + 1))
done < "$PLAN_PATH"`
- Output:
  ```
  (148 lines omitted)
     - complete invited-person profile and accept invitation for unknown/incomplete person.
  5. Ensure duplicate checks use normalized email:
     - active member in club blocks invitation;
     - pending invitation in club resends;
     - existing person not in club can be invited and reused at acceptance.
  6. Add an invitation email module with clear club context and a one-use invitation link.
  7. Add the Staff club-scoped invite route and form. Exact route name is implementation detail, but it should sit under `/admin/clubs/:club_id/...` and not replace the existing person edit route.
  8. Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.
  9. Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.
  10. Generalize the current staff onboarding/profile completion enough that invited unknown members can enter their name before membership activation. For this slice, profile-completion state can live in the invitation/session journey; do not create an incomplete person before the name is submitted, and avoid overbuilding date-of-birth or configurable detail schemas.
  11. Preserve existing staff onboarding: new Memba staff with no person record still enter a name and continue to the Staff area.
  12. Add domain/application tests for pending invitation creation, duplicate active block, duplicate pending resend, existing-person acceptance, unknown-person profile completion, abandoned profile completion, and accepted-link reuse.
  13. Add browser/LiveView/controller tests for the Staff invite page, invitation email link, profile completion page, and final redirect to the club.
  14. Implement or update Cucumber step definitions only as needed to exercise `club_member_invitations.feature`.
  15. Remove or narrow `@todo-domain`/`@todo-ui` from `club_member_invitations.feature` once implemented.
  16. Run targeted tests for affected auth/membership/onboarding surfaces, then run `dev check`.
  
  ## Open Technical Decisions
  
  - Exact invitation aggregate/stream shape and event names.
  - Exact URL and LiveView/controller split for the Staff invite page, invitation callback, and profile completion step.
  
  Resolved technical decisions for this slice:
  
  - Invitation tokens use separate invitation-token storage from ordinary sign-in tokens, because invitation links grant membership.
  - Unknown invited emails are represented as pending invitations only before acceptance/profile completion; do not create incomplete person records in this slice.
  - Profile-completion state for invited unknown people lives in the invitation/session journey until the invitee submits a valid name.
  - The invitation token is not consumed when an unknown invitee first opens the link. It remains usable while the invitation is pending, and is consumed only when profile completion succeeds and membership is created.
  - For existing complete people, following the link accepts the invitation, creates membership, consumes the token, signs them in, and lands them in the club.
  
  ## New Capability
  
  Memba can invite a person to a club by email without trusting Staff-entered identity details. The invitee proves control of the email, supplies their own required name, and only then becomes an active ordinary club member.
  
  ## Validation Plan
  
  - Matt reviews `acceptance-tests/features/club_member_invitations.feature` for domain language before delivery is treated as final.
  - During implementation, add domain/application tests for invitation lifecycle and duplicate rules.
  - Add web tests for Staff invitation UI, email delivery, invitation callback, profile completion, and redirects.
  - Run the new Cucumber scenarios after removing or narrowing `@todo-domain`/`@todo-ui`.
  - Run existing authentication, request-account, person-email-address, and club membership administration tests to protect adjacent flows.
  - Run `dev check`.
  
  ## Risks / Follow-ups
  
  - This does not yet let Membership Admins invite members, so the approved-club-owner problem remains unresolved for real club self-service.
  - Staff may still have global person/email-address management paths that can create unverified identity data. This slice should close the club-member creation bypass, but full email-verification policy remains larger.
  - Invitation links grant membership and currently have no expiry by decision; revisit expiry before broad production use if risk changes.
  - Pending invitation management is deferred: Staff cannot list, cancel, or manually resend from a management screen yet.
  - Future profile fields such as date of birth, emergency contact, or club-specific details need their own modelling and UX slices.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Iteration review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi
rm -rf .fabro/tmp
mkdir -p .fabro/tmp
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
echo "Review start SHA: $(cat .fabro/tmp/review-start-sha.txt)"
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (266 lines omitted)
  ==> commanded
  Compiling 69 files (.ex)
  Generated commanded app
  ==> commanded_eventstore_adapter
  Compiling 2 files (.ex)
  Generated commanded_eventstore_adapter app
  ==> commanded_ecto_projections
  Compiling 1 file (.ex)
  Generated commanded_ecto_projections app
  ==> tailwind
  Compiling 3 files (.ex)
  Generated tailwind app
  ==> elixir_make
  Compiling 8 files (.ex)
  Generated elixir_make app
  ==> cc_precompiler
  Compiling 3 files (.ex)
  Generated cc_precompiler app
  ==> lazy_html
  Downloading precompiled NIF to /tmp/cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.11.tar.gz
  Compiling 3 files (.ex)
  Generated lazy_html app
  ==> websock
  Compiling 1 file (.ex)
  Generated websock app
  ==> bandit
  Compiling 54 files (.ex)
  Generated bandit app
  ==> swoosh
  Compiling 59 files (.ex)
  Generated swoosh app
  ==> websock_adapter
  Compiling 4 files (.ex)
  Generated websock_adapter app
  ==> phoenix
  Compiling 74 files (.ex)
  Generated phoenix app
  ==> phoenix_live_view
  Compiling 49 files (.ex)
  Generated phoenix_live_view app
  ==> phoenix_live_dashboard
  Compiling 36 files (.ex)
  Generated phoenix_live_dashboard app
  ==> phoenix_test
  Compiling 31 files (.ex)
  Generated phoenix_test app
  ==> phoenix_ecto
  Compiling 7 files (.ex)
  Generated phoenix_ecto app
  Sandbox runtime check passed.
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (1104 lines omitted)
      When Pat starts creating the club "Kootenay Mountaineering Club"
      Then Memba should suggest the slug "kootenay-mountaineering-club"
      When Pat saves the club
      Then Kootenay Mountaineering Club should have the slug "kootenay-mountaineering-club"
  [acceptance 2026-06-08T08:11:43.206Z] scenario teardown start: Staff create a club with the suggested slug status=PASSED
  [acceptance 2026-06-08T08:11:43.215Z] scenario finish: Staff create a club with the suggested slug status=PASSED duration=2398ms
  
    Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-08T08:11:43.216Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-08T08:11:43.266Z] scenario reset app state: Staff enter an invalid slug
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-08T08:11:44.432Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1126ms
      Given Kootenay Mountaineering Club is a club
      When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
      Then Memba should reject the club slug as invalid
      And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-08T08:11:45.776Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-08T08:11:45.786Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2570ms
  
    Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-08T08:11:45.787Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-08T08:11:45.839Z] scenario reset app state: Staff enter a slug that another club already uses
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-08T08:11:47.018Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1140ms
      Given Kootenay Mountaineering Club has the slug "kmc"
      And Nelson Paddling Club is a club
      When Pat tries to change Nelson Paddling Club's slug to "kmc"
      Then Memba should reject the club slug as already taken
      And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-08T08:11:48.748Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-08T08:11:48.758Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=2971ms
  
    @not-domain
    Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-08T08:11:48.760Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-08T08:11:48.807Z] scenario reset app state: Robin opens an unknown club subdomain
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-08T08:11:49.981Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1132ms
      When Robin opens "unknown.clubs.memba.io"
      Then Robin should see a not found page
  [acceptance 2026-06-08T08:11:50.052Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-08T08:11:50.061Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1301ms
  
  [acceptance 2026-06-08T08:11:50.061Z] AfterAll: closing shared browser
  [acceptance 2026-06-08T08:11:50.097Z] AfterAll: closed shared browser
  [acceptance 2026-06-08T08:11:50.097Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-08T08:11:50.100Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  69 scenarios (69 passed)
  466 steps (466 passed)
  3m17.996s (executing steps: 3m06.256s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='4e7532d0e9c366bd627ea71ffbb6a0080e895976'
echo '=== Implementation Evidence Debug ==='
echo "PWD: $PWD"
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Base sha input: ${base_sha:-<empty>}"
echo ''
if [ -z "$base_sha" ]; then
  echo 'Missing required input: base_sha' >&2
  echo 'Run via: bin/dev fabro review <branch> <plan_path> [base_ref_or_base_sha]' >&2
  exit 1
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Base sha is not present locally: $base_sha" >&2
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  echo "Base sha still does not resolve after fallback: $base_sha" >&2
  echo '--- available refs ---' >&2
  git show-ref >&2 || true
  echo '--- recent commits ---' >&2
  git log --oneline --decorate --max-count=40 --all >&2 || true
  exit 1
fi
echo '=== Implementation Evidence ==='
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD)"
echo "Base sha: $base_sha"
echo ''
echo '--- git status --short ---'
git status --short
echo ''
echo '--- git diff --stat ---'
if ! git diff --stat "$base_sha"..HEAD; then
  echo "Could not compute diff stat from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- git diff --name-status ---'
if ! git diff --name-status "$base_sha"..HEAD; then
  echo "Could not compute diff name-status from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- changed source/config/test file excerpts ---'
if ! changed_files=$(git diff --name-only "$base_sha"..HEAD); then
  echo "Could not compute changed files from $base_sha to HEAD." >&2
  exit 1
fi
if [ -z "$changed_files" ]; then
  echo 'No files differ between base sha and HEAD.'
else
  excerpt_files=$(printf '%s
' "$changed_files" | grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/|docs/adr/)' || true)
  if [ -z "$excerpt_files" ]; then
    echo 'No changed files matched the excerpt filter.'
  else
    printf '%s
' "$excerpt_files" | while IFS= read -r file; do
      if [ -f "$file" ]; then
        echo "=== $file ==="
        sed -n '1,220p' "$file"
        echo ''
      fi
    done
  fi
fi`
- Output:
  ```
  (6337 lines omitted)
        :password,
        :port,
        :socket_dir,
        :ssl,
        :ssl_opts,
        :timeout,
        :types,
        :username
      ]
  
      Memba.Repo.config()
      |> Keyword.take(allowed_keys)
      |> Keyword.reject(fn {_key, value} -> is_nil(value) end)
    end
  
    defp event_store_schema do
      Memba.EventStore.config()
      |> Keyword.fetch!(:schema)
      |> to_string()
    end
  
    defp projection_tables do
      :memba
      |> Application.get_env(:event_sourced_projection_tables, [])
      |> List.wrap()
      |> Enum.uniq()
      |> then(fn tables -> Enum.uniq([@projection_versions_table | tables]) end)
    end
  
    defp qualified_projection_table_name(table) do
      prefix = Application.get_env(:commanded_ecto_projections, :schema_prefix) || "public"
  
      [prefix, table]
      |> Enum.map(&quote_identifier/1)
      |> Enum.join(".")
    end
  
    defp quote_identifier(identifier) do
      escaped =
        identifier
        |> to_string()
        |> String.replace(~s("), ~s(""))
  
      ~s("#{escaped}")
    end
  
    defp query!(conn, statement) do
      Postgrex.query!(conn, statement, [])
    end
  end
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 6.1k in / 20.2k out
- Response:
  > # Iteration Review Report
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: High
  > 
  > ## ADR Conformance: PASS (with caveat)
  > 
  > **Note**: Actual ADR files were not included in the implementation evidence, but the implementation demonstrates adherence to the architectural decisions stated in the plan:
  > 
  > - ✅ Separate invitation token storage (database-backed, not Phoenix.Token)
  > - ✅ Email normalization matching person email addresses  
  > - ✅ No incomplete person records before profile completion
  > - ✅ Profile completion state in session/journey
  > - ✅ Token not consumed on first link open for unknown invitees
  > 
  > ## ADR Violations
  > 
  > None identified, with the caveat that ADR files themselves were not available for review.
  > 
  > ## Blocking Issues
  > 
  > None. The implementation is production-ready after addressing bounded-safe fixes.
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **Remove dead plug**: `MembaWeb.Authentication.AcceptInvitationPlug` is defined but empty. Either remove it from `router.ex` pipeline `:accept_invitation` and delete the file, or add a module doc explaining it's a placeholder for future middleware.
  > 
  > 2. **Use route helper instead of hardcoded path**: In `accept_invitation_controller.ex`, replace:
  >    ```elixir
  >    defp club_path(club_id) do
  >      "/clubs/#{club_id}"
  >    end
  >    ```
  >    with a proper route helper like `~p"/clubs/#{club_id}"` or use the club subdomain routing pattern already established.
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > ### 1. PersonEmailAddress migration gap (Severity: High if production data exists)
  > 
  > **Files**: `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`, `web/lib/memba/accounts/person.ex`
  > 
  > **Issue**: The Person schema now has `field :email, :string, virtual: true` and delegates email storage to `person_email_addresses` table, but there's no data migration to:
  > - Move existing `people.email` column data to `person_email_addresses` 
  > - Add a migration to remove the `email` column from `people` table
  > - Handle existing Person records created before this iteration
  > 
  > **Impact**: `Accounts.find_person_by_email/1` now only queries `person_email_addresses`:
  > ```elixir
  > from p in Person,
  >   join: e in assoc(p, :email_addresses),
  >   where: e.normalized_email == ^normalized_email
  > ```
  > 
  > If any Person records exist with email only in `people.email`, they won't be found. The sandbox check passed because test fixtures create new people with the association, but production deployment with existing data would break person lookups.
  > 
  > **Why human judgement**: If this is a green-field deployment or there's no production data, this is non-blocking. If production people exist, a data migration is needed before deploy. Matt should confirm whether backward compatibility is needed.
  > 
  > ---
  > 
  > ### 2. Person.email virtual field pattern (Severity: Medium)
  > 
  > **Files**: `web/lib/memba/accounts/person.ex`
  > 
  > **Issue**: The virtual `email` field is used only as changeset input to build the `email_addresses` association:
  > ```elixir
  > defp put_assoc_email_address(changeset) do
  >   case get_change(changeset, :email) do
  >     nil -> changeset
  >     email ->
  >       email_address_changeset = PersonEmailAddress.changeset(%PersonEmailAddress{}, ...)
  >       put_assoc(changeset, :email_addresses, [email_address_changeset])
  >   end
  > end
  > ```
  > 
  > After loading a Person from the database, `person.email` is `nil` because it's virtual. Code must navigate `person.email_addresses |> List.first() |> Map.get(:email)` to access the email.
  > 
  > **Why human judgement**: This pattern works but is unconventional and may confuse maintainers. Consider either:
  > - Adding a `primary_email/1` helper function to Person
  > - Documenting the pattern clearly in the module
  > - Avoiding the virtual field entirely and handling email differently in changesets
  > 
  > ---
  > 
  > ### 3. Email template HTML escaping (Severity: Low - security hygiene)
  > 
  > **Files**: `web/lib/memba_web/email/club_member_invitation_email.ex`
  > 
  > **Issue**: Club name is interpolated directly into HTML without escaping:
  > ```elixir
  > |> html_body("""
  > <h2>You're invited to join #{club.name}!</h2>
  > ...
  > """)
  > ```
  > 
  > If a club name contains HTML characters or tags, they'd be rendered in the email. Risk is mitigated because:
  > - Only Memba staff can create clubs
  > - Email clients typically sanitize HTML
  > - The recipient (invitee) is the potential victim, not the staff member
  > 
  > **Why human judgement**: Low-risk in practice but violates security best practices. Swoosh doesn't auto-escape. Consider using `Phoenix.HTML.html_escape/1` or a proper email template library with auto-escaping for production hardening.
  > 
  > ---
  > 
  > ### 4. Synchronous email delivery (Severity: Low - performance)
  > 
  > **Files**: `web/lib/memba/invitations.ex`
  > 
  > **Issue**: Invitation email is sent synchronously during the HTTP request:
  > ```elixir
  > defp send_invitation_email(%{invitation: invitation, club: club, url_token: url_token}) do
  >   ...
  >   case Memba.Mailer.deliver(email) do
  >     {:ok, _metadata} -> :ok
  >     {:error, reason} -> {:error, reason}
  >   end
  > end
  > ```
  > 
  > If email delivery is slow or fails, it blocks the staff member's UI. Acceptable for MVP with low invitation volume.
  > 
  > **Why human judgement**: For production scale, consider async email delivery via Oban or similar. Current approach is simpler and acceptable for initial deployment.
  > 
  > ---
  > 
  > ### 5. Invitation token in projection (Severity: Low - architecture)
  > 
  > **Files**: `web/lib/memba/club_members/projections/invitation.ex`
  > 
  > **Issue**: The invitation token is generated in the projection handler, not in the command/event:
  > ```elixir
  > def handle(%InvitationCreated{} = event, _metadata) do
  >   {url_token, hashed_token} = InvitationToken.build_hashed_token()
  >   projection = %Invitation{} |> changeset(%{..., hashed_token: hashed_token}) |> Repo.insert!()
  >   {:ok, url_token}
  > end
  > ```
  > 
  > This means:
  > - Token is not part of the event stream (only in read model)
  > - Rebuilding projections would regenerate different tokens
  > - All existing invitation links would be invalidated on projection rebuild
  > 
  > This is unconventional for event sourcing but may be an intentional trade-off for simplicity. Tokens are one-use anyway.
  > 
  > **Why human judgement**: If projection rebuilds are expected to be rare and invalidating pending invitations is acceptable, this is fine. Otherwise, consider generating tokens deterministically or including them in events.
  > 
  > ---
  > 
  > ### 6. Duplicate invitation race condition (Severity: Low)
  > 
  > **Files**: `web/lib/memba/invitations.ex`, migration for invitations table
  > 
  > **Issue**: Duplicate detection happens in the context layer, not enforced by database constraints:
  > ```elixir
  > cond do
  >   pending_invitation = find_pending_invitation(club_id, normalized_email) -> resend_invitation(...)
  >   true -> create_new_invitation(...)
  > end
  > ```
  > 
  > No unique constraint exists on `(club_id, normalized_email)` for `status = 'pending'`. If two staff members invite the same email simultaneously, both might create separate invitation aggregates (different UUIDs).
  > 
  > **Impact**: Worst case is duplicate invitation emails sent. When the invitee accepts, only one invitation is consumed; the other remains pending but harmless.
  > 
  > **Why human judgement**: The impact is minimal (duplicate emails, not duplicate memberships). Adding a unique constraint would prevent the race but add complexity. Current approach is acceptable if duplicate emails are tolerable.
  > 
  > ---
  > 
  > ### 7. Basic email template styling (Severity: Low - UX)
  > 
  > **Files**: `web/lib/memba_web/email/club_member_invitation_email.ex`
  > 
  > **Issue**: Email template is minimal HTML with no:
  > - CSS styling or branding
  > - Header/footer with company info
  > - Unsubscribe link (if required for transactional emails)
  > - Responsive design for mobile
  > 
  > Functional for MVP but looks unpolished.
  > 
  > **Why human judgement**: Determine when to invest in professional email templates. Current version is acceptable for internal testing and early clubs but should be improved before broader rollout.
  > 
  > ---
  > 
  > ### 8. Person email accessor API (Severity: Low - DX)
  > 
  > **Files**: `web/lib/memba/accounts/person.ex`
  > 
  > **Issue**: No clear helper for accessing a person's email after loading from the database. Code must navigate:
  > ```elixir
  > person.email_addresses |> List.first() |> Map.get(:email)
  > ```
  > 
  > Combined with issue #2 (virtual email field), this creates friction for developers.
  > 
  > **Why human judgement**: Consider adding a `Person.primary_email/1` helper or preloading with a custom select to make email access cleaner. Document the current approach if keeping it.
  > 
  > ---
  > 
  > ## Suggested Fixes
  > 
  > ### For Bounded-Safe Issues:
  > 
  > **1. Remove empty plug** (or document it):
  > ```elixir
  > # In router.ex, remove from pipeline:
  >   pipeline :accept_invitation do
  >     # ... other plugs ...
  >     # plug MembaWeb.Authentication.AcceptInvitationPlug  # Remove this line
  >   end
  > 
  > # Delete web/lib/memba_web/authentication/accept_invitation_plug.ex
  > ```
  > 
  > **2. Use route helper**:
  > ```elixir
  > # In accept_invitation_controller.ex
  > defp club_path(club_id) do
  >   ~p"/clubs/#{club_id}"
  >   # Or use the proper club subdomain routing if that's the pattern
  > end
  > ```
  > 
  > ---
  > 
  > ## Validation Notes
  > 
  > ### Test Coverage:
  > - ✅ Domain tests cover invitation creation, resend, duplicate detection, and acceptance
  > - ✅ Controller tests cover both existing-person and unknown-person flows
  > - ✅ Controller tests cover profile completion edge cases (invalid name, reopening, expiry)
  > - ✅ LiveView tests cover staff invitation UI
  > - ✅ Email delivery tests verify template and recipients
  > - ✅ Acceptance tests (Cucumber) exercise end-to-end flows
  > 
  > ### Dev Check Results:
  > - ✅ All compilation warnings resolved
  > - ✅ All tests passing (69 scenarios, 466 steps)
  > - ✅ Sandbox runtime check passed
  > - ✅ No formatter issues
  > 
  > ### Plan Conformance:
  > - ✅ Invitation aggregate with pending/accepted/expired states
  > - ✅ Email normalization via PersonEmailAddress
  > - ✅ Separate invitation token storage
  > - ✅ Duplicate checks (active member block, pending resend)
  > - ✅ Invitation email with club context and one-use link
  > - ✅ Staff invite route under `/admin/clubs/:club_id/invite`
  > - ✅ Invitation callback validates tokens and routes appropriately
  > - ✅ Profile completion for unknown invitees
  > - ✅ Existing staff onboarding preserved
  > - ✅ Acceptance feature scenarios implemented
  > 
  > ### Architecture Observations:
  > - Clean separation: Invitations context handles workflow, ClubMembers handles domain
  > - Proper event sourcing with aggregate, commands, events, and projections
  > - Good error handling with specific error atoms
  > - Session-based email binding during profile completion is secure (1-hour Phoenix.Token)
  > - Token not consumed until acceptance completes (as required)
  > 
  > ---
  > 
  > **Overall Assessment**: This is a well-executed implementation that conforms to the plan and passes all automated checks. The bounded-safe fixes are trivial. The judgement-worthy findings are legitimate design questions but don't block merge—they're candidates for follow-up kaizen or pre-production hardening based on deployment context and risk tolerance.

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 8.3k in / 4.3k out
- Response:
  > # Iteration Review Report
  > 
  > ## Decision: REJECT
  > 
  > ## Confidence: Medium
  > 
  > The implementation appears broadly plan-conforming and `dev ci` passed, but there is one deployment-safety gap around the `PersonEmailAddress` storage change that needs either a small implementation pass or an explicit human decision before merge/deploy.
  > 
  > ## ADR conformance: PASS
  > 
  > No clear ADR violation is evident from the provided implementation evidence.
  > 
  > The implementation appears to respect the plan’s architecture-relevant decisions:
  > 
  > - Invitation tokens use separate storage from ordinary sign-in tokens.
  > - Unknown invited emails remain pending invitations; incomplete `Person` records are not created before profile completion.
  > - Invitation acceptance consumes tokens only after successful acceptance/profile completion.
  > - Existing complete people can accept and become club members directly.
  > - The Staff invite route is additive and does not replace the existing person edit route.
  > 
  > ## ADR violations
  > 
  > None identified from the available evidence.
  > 
  > ## Blocking issues
  > 
  > 1. **Potentially unsafe migration from `people.email` to `person_email_addresses` without backfill or explicit no-data decision**
  > 
  >    **Files:**
  > 
  >    - `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`
  >    - `web/lib/memba/accounts/person.ex`
  >    - `web/lib/memba/accounts.ex`
  > 
  >    **Issue:**
  > 
  >    The implementation appears to move email lookup behavior from `people.email` to the new `person_email_addresses` association. `Person.email` is now virtual, and `Accounts.find_person_by_email/1` appears to query `person_email_addresses.normalized_email`.
  > 
  >    The evidence does not show a migration that backfills existing `people.email` values into `person_email_addresses`.
  > 
  >    **Why this blocks:**
  > 
  >    If any existing environment contains persisted `people.email` data, those people may no longer be discoverable by email after deployment. That can affect:
  > 
  >    - duplicate active-member checks;
  >    - existing-person invitation acceptance;
  >    - sign-in/onboarding flows that rely on finding a person by email;
  >    - adjacent Staff/person administration behavior.
  > 
  >    This is not merely polish if real data exists. It needs one of:
  > 
  >    - a data backfill migration;
  >    - an explicit human/product decision that no deployed database contains relevant `people.email` data and backfill is unnecessary;
  >    - or a compatibility path that reads both old and new storage until migration is complete.
  > 
  > ## Bounded-safe fixes
  > 
  > 1. **Remove or document the empty invitation plug**
  > 
  >    **Files:**
  > 
  >    - `web/lib/memba_web/authentication/accept_invitation_plug.ex`
  >    - `web/lib/memba_web/router.ex`
  > 
  >    `MembaWeb.Authentication.AcceptInvitationPlug` appears to be an empty/pass-through plug. If it has no behavior today, it adds routing/authentication indirection without value.
  > 
  > 2. **Replace hardcoded club path construction with verified routes**
  > 
  >    **File:**
  > 
  >    - `web/lib/memba_web/controllers/accept_invitation_controller.ex`
  > 
  >    The helper:
  > 
  >    ```elixir
  >    defp club_path(club_id) do
  >      "/clubs/#{club_id}"
  >    end
  >    ```
  > 
  >    should use Phoenix verified routes, e.g. `~p"/clubs/#{club_id}"`, or the project’s established club-routing helper if club access is subdomain-aware.
  > 
  > 3. **Escape interpolated values in invitation email HTML**
  > 
  >    **File:**
  > 
  >    - `web/lib/memba_web/email/club_member_invitation_email.ex`
  > 
  >    The email HTML appears to interpolate `club.name` directly into an HTML string. Even if club names are Staff-controlled, escaping is the safer default for generated HTML.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **Invitation token generation in projection/read-model layer**
  > 
  >    **Files:**
  > 
  >    - `web/lib/memba/club_members/projections/invitation.ex`
  >    - `web/lib/memba/invitations.ex`
  > 
  >    **Smell:**
  > 
  >    The invitation URL token appears to be generated while handling the invitation projection rather than being produced as part of the command/event workflow.
  > 
  >    **Why this may need human judgement:**
  > 
  >    In an event-sourced system, projection rebuilds should usually be deterministic. If rebuilding projections regenerates different invitation token hashes, outstanding invitation links may become invalid. That may be acceptable for this slice, but it is an architectural trade-off worth making explicit.
  > 
  > 2. **Synchronous email delivery during Staff invite request**
  > 
  >    **File:**
  > 
  >    - `web/lib/memba/invitations.ex`
  > 
  >    **Smell:**
  > 
  >    Invitation email delivery appears to happen synchronously during the invite workflow.
  > 
  >    **Why this may need human judgement:**
  > 
  >    This is simple and acceptable for low-volume MVP usage, but it couples Staff UI latency and error behavior to the mail provider. If invitation volume or deliverability reliability becomes important, this should move behind a durable async job.
  > 
  > 3. **Duplicate pending-invitation race not enforced by database constraint**
  > 
  >    **Files:**
  > 
  >    - `web/lib/memba/invitations.ex`
  >    - invitation projection/table migration
  > 
  >    **Smell:**
  > 
  >    Duplicate detection appears to be performed in application code by looking for a pending invitation before creating/resending. There does not appear to be a partial unique database constraint for pending invitations by `{club_id, normalized_email}`.
  > 
  >    **Why this may need human judgement:**
  > 
  >    Concurrent invites for the same email and club could create duplicate pending invitations and send duplicate emails. The behavioral impact is probably low, but database constraints are usually better for enforcing uniqueness when the invariant matters.
  > 
  > 4. **Virtual `Person.email` field may confuse future maintainers**
  > 
  >    **Files:**
  > 
  >    - `web/lib/memba/accounts/person.ex`
  >    - callers that need a person’s email address
  > 
  >    **Smell:**
  > 
  >    `Person.email` appears to be retained as a virtual changeset input while persisted email addresses live in `person_email_addresses`.
  > 
  >    **Why this may need human judgement:**
  > 
  >    After loading a `Person`, `person.email` will be `nil` unless manually populated. Future code may accidentally use the virtual field and miss the associated email addresses. A clear accessor such as `Person.primary_email/1` or `Accounts.primary_email_for_person/1` would reduce ambiguity.
  > 
  > 5. **Invitation email template is intentionally minimal**
  > 
  >    **File:**
  > 
  >    - `web/lib/memba_web/email/club_member_invitation_email.ex`
  > 
  >    **Smell:**
  > 
  >    The email appears functional but basic: minimal branding, no reusable template, and no styling system.
  > 
  >    **Why this may need human judgement:**
  > 
  >    This is acceptable for an implementation slice, but before broader production use, invitation emails may need product/design review.
  > 
  > ## Suggested fixes
  > 
  > Because the decision is `REJECT`, address the blocking migration/data compatibility issue first.
  > 
  > Recommended implementation options:
  > 
  > 1. **Preferred: add a backfill migration**
  > 
  >    Add a migration that copies existing `people.email` rows into `person_email_addresses` with normalized email values, preserving existing people for duplicate checks and invitation acceptance.
  > 
  >    The migration should:
  > 
  >    - skip blank/null emails;
  >    - normalize using the same semantics as the application where practical;
  >    - avoid duplicate rows;
  >    - preserve timestamps;
  >    - be safe to run once in deployed environments.
  > 
  > 2. **Alternative: explicit human decision**
  > 
  >    If Matt confirms there is no deployed/persistent data requiring migration, record that decision in the iteration notes or an appropriate technical note, then the blocker can be waived.
  > 
  > 3. **Then apply bounded-safe cleanup**
  > 
  >    - Remove the empty `AcceptInvitationPlug` or give it a real documented responsibility.
  >    - Replace hardcoded `"/clubs/#{club_id}"` with verified routes.
  >    - Escape interpolated email HTML values.
  > 
  > ## Validation notes
  > 
  > - `dev ci` succeeded.
  > - Acceptance suite succeeded: `69 scenarios`, `466 steps`.
  > - Sandbox runtime check passed.
  > - The implementation appears to cover the main planned flows:
  >   - Staff invite form;
  >   - invitation email link;
  >   - existing-person acceptance;
  >   - unknown-person profile completion;
  >   - duplicate active-member block;
  >   - duplicate pending invitation resend;
  >   - accepted-link reuse behavior.
  > - The remaining blocker is not exposed by the green test suite because it concerns migration behavior for pre-existing persisted `people.email` data.

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 3.7k in / 3.2k out
- Response:
  > # Iteration Review Report
  > 
  > ## Decision: REJECT
  > 
  > ## Confidence: High
  > 
  > ## ADR Conformance: PASS
  > 
  > ## ADR Violations
  > None identified. The implementation adheres to the architectural decisions stated in the plan (e.g., using separate invitation token storage, preserving incomplete person creation for profile completion, etc.).
  > 
  > ## Blocking Issues
  > 1. **Missing Data Migration for `people.email` to `person_email_addresses`**
  >    The implementation introduces a new `person_email_addresses` table and modifies the `Person` schema to make `email` a virtual field. `Accounts.find_person_by_email/1` has been updated to query the new `person_email_addresses` table instead of the `people` table. However, there is no backfill migration to move existing `people.email` data into `person_email_addresses`.
  >    
  >    If any existing environment (such as production) contains persisted `people.email` data, those users will no longer be discoverable by email. This breaks duplicate active-member checks, existing-person invitation acceptance, and staff administration for those users. This requires either a data backfill migration or an explicit product decision that existing data can be safely discarded.
  > 
  > ## Bounded-Safe Fixes
  > 1. **Remove or document unused `AcceptInvitationPlug`**
  >    `MembaWeb.Authentication.AcceptInvitationPlug` is defined but empty. Either remove it from the `router.ex` pipeline and delete the file, or add a module doc explaining it is a placeholder for future middleware.
  > 2. **Replace hardcoded club path construction with verified routes**
  >    In `accept_invitation_controller.ex`, the helper `defp club_path(club_id), do: "/clubs/#{club_id}"` should use Phoenix verified routes (e.g., `~p"/clubs/#{club_id}"`) or the project's established subdomain-aware routing pattern.
  > 3. **Escape interpolated values in invitation email HTML**
  >    In `club_member_invitation_email.ex`, `club.name` is interpolated directly into an HTML string (`<h2>You're invited to join #{club.name}!</h2>`). Even if club names are Staff-controlled, it is a safer default to use `Phoenix.HTML.html_escape/1` for generated HTML.
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 1. **Synchronous Email Delivery (Performance)**
  >    **File(s)**: `web/lib/memba/invitations.ex`
  >    **Smell**: Invitation email delivery happens synchronously during the HTTP request.
  >    **Why it may need human judgement**: This ties the Staff UI latency and error behavior to the email provider's response time. It is perfectly acceptable for a low-volume MVP, but may need to be moved behind a durable async job (e.g., Oban) as the application scales.
  > 2. **Virtual `Person.email` field may cause confusion (Maintainability)**
  >    **File(s)**: `web/lib/memba/accounts/person.ex`
  >    **Smell**: `Person.email` is retained as a virtual field strictly for changeset inputs. After loading a `Person` from the database, `person.email` will be `nil`.
  >    **Why it may need human judgement**: Future maintainers may accidentally use the virtual field expecting a value. Adding an explicit accessor like `Person.primary_email/1` or `Accounts.primary_email_for_person/1` would reduce ambiguity.
  > 3. **Duplicate pending-invitation race not enforced by database constraint (Data Integrity)**
  >    **File(s)**: `web/lib/memba/invitations.ex`, invitations table migration
  >    **Smell**: Duplicate detection is performed in the context layer by checking for an existing pending invitation before creating or resending. There is no partial unique database constraint for pending invitations on `{club_id, normalized_email}`.
  >    **Why it may need human judgement**: Concurrent invites could theoretically create duplicate pending invitations and send duplicate emails. Adding a unique constraint would provide stronger structural guarantees.
  > 4. **Invitation token generation in projection/read-model layer (Architecture)**
  >    **File(s)**: `web/lib/memba/club_members/projections/invitation.ex`
  >    **Smell**: The invitation URL token appears to be generated while handling the invitation projection, rather than being produced as part of the command/event workflow.
  >    **Why it may need human judgement**: In an event-sourced system, projection rebuilds should usually be deterministic. If rebuilding the projection regenerates different invitation token hashes, outstanding invitation links could be invalidated. This architectural trade-off is worth noting for the future.
  > 
  > ## Suggested Fixes
  > 1. **Add a backfill migration**: Create an Ecto migration that copies existing `people.email` rows into `person_email_addresses` with normalized email values, skipping nulls and preserving timestamps.
  > 2. **Clean up Plug**: Delete `web/lib/memba_web/authentication/accept_invitation_plug.ex` and remove it from `router.ex`.
  > 3. **Use verified routes**: Update `club_path/1` in `accept_invitation_controller.ex` to use `~p"/clubs/#{club_id}"`.
  > 4. **Escape HTML**: Wrap `club.name` in `Phoenix.HTML.html_escape/1` in `club_member_invitation_email.ex`.
  > 
  > ## Validation Notes
  > - **Dev Check**: Passed successfully.
  > - **Automated Coverage**: 69 scenarios and 466 steps passed. Domain, controller, LiveView, and email delivery tests cover the planned invitation lifecycle correctly.
  > - **Migration Safety**: The blocking issue regarding data migration safety was not exposed by the green test suite because test fixtures create fresh data using the new association flow, but it poses a strict risk to deployed environments holding existing records.

## Stage: synthesize_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 11.9k in / 1.8k out
- Response:
  > {
  >   "context_updates": {
  >     "implementation_accepted": false,
  >     "review_fixes_available": true,
  >     "review_blockers": [
  >       {
  >         "id": "backfill-person-email-addresses",
  >         "title": "Backfill existing people.email values into person_email_addresses",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "cleanup-empty-accept-invitation-plug",
  >         "title": "Remove or document empty AcceptInvitationPlug",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "use-verified-club-route",
  >         "title": "Replace hardcoded club path with verified route",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "escape-invitation-email-html",
  >         "title": "Escape interpolated invitation email HTML values",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       }
  >     ]
  >   }
  > }

## Stage: review_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: review_gate

## Stage: snapshot_before_review_repair
- Status: succeeded
- Handler: command
- Script: `set -eu
mkdir -p .fabro/tmp
kind='review'
git diff --binary > ".fabro/tmp/${kind}-repair-before.patch"
git diff --name-only > ".fabro/tmp/${kind}-repair-before-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-before-stat.txt" || true
printf 'Repair baseline (%s) captured.\n' "$kind"`
- Output:
  ```
  Repair baseline (review) captured.
  ```

## Current context
| Key | Value |
|-----|-------|
| implementation_accepted | false |
| review_blockers | [{"id":"backfill-person-email-addresses","title":"Backfill existing people.email values into person_email_addresses","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"cleanup-empty-accept-invitation-plug","title":"Remove or document empty AcceptInvitationPlug","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"use-verified-club-route","title":"Replace hardcoded club path with verified route","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"escape-invitation-email-html","title":"Escape interpolated invitation email HTML values","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}] |
| review_fixes_available | true |


Apply the automatic repair brief from the preceding Synthesize Review stage for docs/iterations/028-staff-member-invitations/plan.md.

Rules:

- Fix only the concrete bounded issues selected by the review synthesis.
- Treat this as a post-green refactoring/maintainability pass. Do not add new product behaviour here.
- Stay within the iteration plan and do not introduce new product decisions.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). If a requested fix requires changing one, leave it unchanged and report it as a code-health/manual follow-up.
- Add or update automated tests only when needed to preserve or clarify existing behaviour while refactoring.
- Do not skip or weaken existing validation.
- Do not commit changes.
- Review must never push red. If a fix proves unsafe, too large, judgement-heavy, or likely to regress behaviour, discard that fix, leave the code unchanged for that issue, and report it as a code-health/manual follow-up instead of forcing a change.
- **Sandbox/runtime boundary**: If the requested fix or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- **If no changes were needed**: If after reviewing the issues you determine that no code/config/test changes are required, state that explicitly and provide clear justification for why the review issues do not require changes.

When finished, summarize:

1. Each review issue from the gate.
2. The concrete code/config/test changes made for each issue (or an explicit statement that no changes were needed with justification).
3. Files changed (grouped by issue addressed).
4. Tests run and their results.
5. Any remaining gaps or human questions.

Include an issue-to-fix mapping showing which files/modules/tests address each review issue.