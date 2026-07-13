defmodule Memba.Membership do
  @moduledoc """
  Public application service and query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.App
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Commands.VerifyPersonEmailAddress
  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Repo

  @person_email_address_verification_token_ttl_seconds 15 * 60

  @doc """
  Create a club through the Membership Commanded application.

  The caller supplies the club aggregate identity as `:club_id` or
  `"club_id"`.
  """
  def create_club(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- create_club_command(attrs),
         :ok <- prevent_duplicate_club_slug(command) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Update a club's staff-managed display name and public slug.

  The caller supplies the club aggregate identity as `:club_id` or
  `"club_id"`. Slugs must already be valid address-safe values and must not be
  used by another projected club.
  """
  def update_club(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- update_club_command(attrs),
         :ok <- prevent_duplicate_club_slug(command) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Create a person through the Membership Commanded application.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"`.
  """
  def create_person(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- create_person_command(attrs),
         {:ok, email_addresses} <- normalize_command_email_addresses(command),
         :ok <- prevent_duplicate_person_email_addresses(command.person_id, email_addresses) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Atomically replace a person's primary and alternate email addresses.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"`. The submitted `:email_addresses` or `"email_addresses"` value
  must be a non-empty list with exactly one primary address.
  """
  def replace_person_email_addresses(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    {verification_revoker, dispatch_opts} =
      person_email_address_verification_revoker(dispatch_opts)

    with {:ok, command} <- replace_person_email_addresses_command(attrs),
         {:ok, email_addresses} <- normalize_command_email_addresses(command),
         :ok <- prevent_duplicate_person_email_addresses(command.person_id, email_addresses),
         {:ok, removed_verification_requests} <-
           pending_removed_person_email_address_verification_requests(
             command.person_id,
             email_addresses
           ) do
      command
      |> dispatch(dispatch_opts)
      |> revoke_removed_person_email_address_verifications(
        removed_verification_requests,
        verification_revoker
      )
    end
  end

  @doc """
  Add a new pending email address to a person.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"`. The submitted email address is rejected before dispatch when it
  is already attached to another person.
  """
  def add_person_email_address(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- add_person_email_address_command(attrs),
         {:ok, email_addresses} <- normalize_command_email_addresses(command),
         :ok <- prevent_duplicate_person_email_addresses(command.person_id, email_addresses) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Resend verification for an already-pending person email address.

  This is an application-service side effect, not a Membership domain-state
  transition: it validates that the projected email address still belongs to the
  person and is still pending, then asks the configured issuer to create/deliver
  a fresh verification link. No Membership command is dispatched unless a future
  state-changing verification step succeeds.
  """
  def resend_person_email_address_verification(attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, person_id} <- cast_person_id(person_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email),
         {:ok, email_address} <-
           pending_person_email_address_for_verification(person_id, normalized_email) do
      email_address
      |> person_email_address_verification_request()
      |> issue_person_email_address_verification(opts)
    end
  end

  @doc """
  Consume an email-address verification token exactly once.

  A token is accepted only when it is known, unexpired, unconsumed, unrevoked,
  and still scoped to a pending email address attached to the same Person.
  """
  def consume_person_email_address_verification_token(token, opts \\ [])

  def consume_person_email_address_verification_token(token, opts)
      when is_binary(token) and is_list(opts) do
    token_hash = hash_person_email_address_verification_token(token)
    now = timestamp(opts)

    EmailAddressVerificationToken.consume(token_hash, now, fn verification_token ->
      with {:ok, email_address} <-
             pending_person_email_address_for_verification(
               verification_token.person_id,
               verification_token.normalized_email
             ) do
        {:ok, person_email_address_verification_request(email_address)}
      end
    end)
  end

  def consume_person_email_address_verification_token(_token, _opts), do: {:error, :not_found}

  @doc """
  Mark a pending person email address as verified.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"` and the email address as `:email` or `"email"`. The optional
  `:verified_at`/`"verified_at"` value defaults to the current UTC time.
  """
  def verify_person_email_address(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- verify_person_email_address_command(attrs) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Mark an email address as verified when a successful sign-in link proves mailbox control.

  This is intentionally a safe no-op for invalid, unknown, and already-verified
  addresses so sign-in callback handling does not reveal account state or change
  the existing session semantics. When the normalized email belongs to a pending
  Person email address, the ordinary Membership verification command is
  dispatched.
  """
  def verify_pending_person_email_address_for_sign_in(email, dispatch_opts \\ [])
      when is_list(dispatch_opts) do
    case pending_person_email_address_for_sign_in(email) do
      {:ok, %PersonEmailAddress{} = email_address} ->
        email_address
        |> person_email_address_verification_request()
        |> verify_person_email_address(dispatch_opts)
        |> normalize_sign_in_verification_result()

      :not_pending ->
        :ok
    end
  end

  @doc """
  Make a verified person email address primary.
  """
  def make_person_email_address_primary(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- make_person_email_address_primary_command(attrs) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove a non-primary person email address.
  """
  def remove_person_email_address(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    {verification_revoker, dispatch_opts} =
      person_email_address_verification_revoker(dispatch_opts)

    with {:ok, command} <- remove_person_email_address_command(attrs) do
      removed_verification_requests =
        pending_removed_person_email_address_verification_requests(
          command.person_id,
          command.email
        )

      command
      |> dispatch(dispatch_opts)
      |> revoke_removed_person_email_address_verifications(
        removed_verification_requests,
        verification_revoker
      )
    end
  end

  @doc """
  Add a person as an active member of a club through the Membership context.

  The caller supplies the membership aggregate identity as `:membership_id` or
  `"membership_id"`. A second active membership for the same club/person pair is
  rejected before dispatch.
  """
  def add_member(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- add_member_command(attrs),
         :ok <- prevent_duplicate_active_membership(command) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Create a pending club member invitation for an email address.

  Invitation creation is intentionally actor-neutral. Callers that represent
  club Membership Admins must authorize the actor before calling this shared
  lifecycle, while Staff/system callers can use the same service without being
  represented as club members.

  The public API generates the plaintext one-use invitation token before
  dispatch and stores only its hash in Membership. The caller may supply
  `:invitation_id`/`"invitation_id"`; otherwise this application service
  generates the caller-side aggregate identity before dispatching the command.

  Returns `{:ok, %{invitation_id: ..., invitation_token: ...}}` on successful
  dispatch so the caller can hand the plaintext token to the email delivery
  layer without persisting it.
  """
  def invite_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command, invitation_token} <- invite_club_member_command(attrs),
         :ok <- prevent_inviting_active_club_member(command) do
      case get_pending_club_member_invitation_by_email(command.club_id, command.email) do
        %ClubInvitation{} = invitation ->
          resend_pending_club_member_invitation(invitation, dispatch_opts)

        nil ->
          with {:ok, dispatch_result} <-
                 dispatch_invitation_token_command(command, dispatch_opts) do
            {:ok,
             invitation_token_result(
               command.invitation_id,
               invitation_token,
               :execution_result,
               dispatch_result
             )}
          end
      end
    end
  end

  @doc """
  Resend an existing pending club member invitation.

  The pending invitation can be addressed either by `:invitation_id` or by the
  same `:club_id`/`:email` pair that was invited. Resending rotates the stored
  invitation token hash and returns a fresh plaintext token for email delivery.
  """
  def resend_club_member_invitation(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, invitation} <- pending_invitation_for_resend(attrs),
         {:ok, command, invitation_token} <- resend_club_member_invitation_command(invitation),
         {:ok, dispatch_result} <- dispatch_invitation_token_command(command, dispatch_opts) do
      {:ok,
       invitation_token_result(
         command.invitation_id,
         invitation_token,
         :execution_result,
         dispatch_result
       )}
    end
  end

  @doc """
  Accept a pending invitation for an existing complete person.

  This orchestration creates an ordinary active membership for the invited club
  and then marks the invitation accepted with the person and membership IDs. The
  caller supplies `:person_id` and may supply `:membership_id`; otherwise this
  application service generates the membership aggregate identity before
  dispatch.
  """
  def accept_club_member_invitation_for_existing_person(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, invitation} <- pending_invitation_for_acceptance(attrs),
         {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, person_id} <- cast_person_id(person_id),
         {:ok, _person} <- fetch_existing_person(person_id),
         :ok <- ensure_person_has_invitation_email(person_id, invitation),
         {:ok, membership_id} <- invitation_membership_id(attrs),
         {:ok, membership_id} <- cast_membership_id(membership_id),
         {:ok, add_member_command} <-
           invitation_add_member_command(invitation, person_id, membership_id),
         :ok <- prevent_duplicate_active_membership(add_member_command),
         {:ok, add_member_result} <-
           dispatch_acceptance_command(add_member_command, dispatch_opts),
         {:ok, accept_command} <-
           accept_club_member_invitation_command(invitation, person_id, membership_id),
         {:ok, accept_result} <- dispatch_acceptance_command(accept_command, dispatch_opts) do
      {:ok,
       acceptance_result(invitation, person_id, membership_id, add_member_result, accept_result)}
    end
  end

  @doc """
  Complete an invited unknown person's required profile and accept the invitation.

  The invitee's person record is not created until this API receives a valid
  non-blank name. It creates the person using the invited email, creates an
  ordinary active membership for the invited club, and then marks the invitation
  accepted. The caller may supply `:person_id` and `:membership_id`; otherwise
  this application service generates both aggregate identities before dispatch.
  """
  def complete_invited_club_member_profile(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, invitation} <- pending_invitation_for_acceptance(attrs),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, person_id} <- invitation_person_id(attrs),
         {:ok, person_id} <- cast_person_id(person_id),
         {:ok, membership_id} <- invitation_membership_id(attrs),
         {:ok, membership_id} <- cast_membership_id(membership_id),
         :ok <-
           prevent_duplicate_person_email_addresses(person_id, [
             %{normalized_email: invitation.normalized_email}
           ]),
         {:ok, create_person_command} <-
           invitation_create_person_command(invitation, person_id, name),
         {:ok, add_member_command} <-
           invitation_add_member_command(invitation, person_id, membership_id),
         {:ok, create_person_result} <-
           dispatch_acceptance_command(create_person_command, dispatch_opts),
         {:ok, add_member_result} <-
           dispatch_acceptance_command(add_member_command, dispatch_opts),
         {:ok, accept_command} <-
           accept_club_member_invitation_command(invitation, person_id, membership_id),
         {:ok, accept_result} <- dispatch_acceptance_command(accept_command, dispatch_opts) do
      {:ok,
       invitation
       |> acceptance_result(person_id, membership_id, add_member_result, accept_result)
       |> Map.put(:person_execution_result, create_person_result)}
    end
  end

  @doc """
  Remove a person from active club membership through the Membership context.

  The caller supplies the membership aggregate identity as `:membership_id` or
  `"membership_id"`.
  """
  def remove_member(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- remove_member_command(attrs) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Assign the built-in Admin role to an active member as a club member actor.

  The caller supplies the target `:membership_id`/`:person_id`, the `:club_id`,
  and `:actor_person_id`. The actor must have the projected
  `club.manage_members` permission. The target member must be active in the
  club. The built-in role ID is derived from the club so callers cannot grant an
  arbitrary role through this Admin-specific entry point.
  """
  def assign_membership_administrator_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, attrs} <- put_membership_administrator_role_id(attrs) do
      assign_member_role_as_club_member(attrs, dispatch_opts)
    end
  end

  @doc """
  Remove the built-in Admin role from an active member as a club member actor.

  The caller supplies the target `:membership_id`/`:person_id`, the `:club_id`,
  and `:actor_person_id`. The actor must have the projected
  `club.manage_members` permission. The target member must be active in the
  club. The built-in role ID is derived from the club so callers cannot remove an
  arbitrary role through this Admin-specific entry point. The removal is rejected
  when it would leave the club with no active Admins.
  """
  def remove_membership_administrator_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, attrs} <- put_membership_administrator_role_id(attrs) do
      remove_member_role_as_club_member(attrs, dispatch_opts)
    end
  end

  @doc """
  Assign a club role to an active member as a club member actor.

  Unlike staff/system setup paths, this entry point requires `:actor_person_id`
  (or `"actor_person_id"`) and authorizes the actor through the projected
  `club.manage_members` permission before dispatching the role-assignment
  command. The target membership must be active and must match the submitted
  club/person IDs.
  """
  def assign_member_role_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- assign_member_role_command(attrs),
         :ok <-
           Authorization.authorize_manage_members(
             command.club_id,
             command.assigned_by_person_id
           ),
         :ok <-
           ensure_active_membership(
             command.club_id,
             command.person_id,
             command.membership_id
           ) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove a club role from an active member as a club member actor.

  Staff/system setup paths remain separate. This entry point requires
  `:actor_person_id` (or `"actor_person_id"`) and authorizes the actor through
  the projected `club.manage_members` permission before dispatching the
  role-removal command. The target membership must be active and must match the
  submitted club/person IDs.
  """
  def remove_member_role_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- remove_member_role_command(attrs),
         :ok <-
           Authorization.authorize_manage_members(
             command.club_id,
             command.removed_by_person_id
           ),
         :ok <-
           ensure_active_membership(
             command.club_id,
             command.person_id,
             command.membership_id
           ),
         :ok <- ensure_membership_administrator_removal_keeps_an_administrator(command) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Fetch a projected club read model by typed club ID.

  Returns `nil` when the ID is absent or is not a valid club ID.
  """
  def get_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      Repo.get(Club, club_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch a projected club read model by public slug.

  Lookup input is normalized only where safe for public addressing: surrounding
  whitespace is trimmed and casing is folded before validating the slug. Values
  that are still invalid, missing, or unknown return `nil`.
  """
  def get_club_by_slug(slug) do
    with {:ok, slug} <- Slug.normalize_for_lookup(slug) do
      Repo.get_by(Club, slug: slug)
    else
      {:error, _reason} -> nil
    end
  end

  @doc """
  Fetch a projected person read model by typed person ID.

  Returns `nil` when the ID is absent or is not a valid person ID.
  """
  def get_person(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      Repo.get(Person, person_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch a projected person read model by email address.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively across primary and alternate projected email addresses.
  Invalid, blank, and unknown addresses return `nil`.
  """
  def get_person_by_email(email) do
    case normalize_email(email) do
      nil ->
        nil

      normalized_email ->
        Person
        |> join(:inner, [person], email_address in PersonEmailAddress,
          on: email_address.person_id == person.person_id
        )
        |> where([_person, email_address], email_address.normalized_email == ^normalized_email)
        |> limit(1)
        |> Repo.one()
    end
  end

  @doc """
  Fetch a projected person read model by a verified email address.

  This mirrors `get_person_by_email/1`, but only treats email addresses whose
  projected `verified_at` is present as identity-bearing. Invalid, blank,
  unknown, and pending/unverified addresses return `nil`.
  """
  def get_verified_person_by_email(email) do
    case normalize_email(email) do
      nil ->
        nil

      normalized_email ->
        Person
        |> join(:inner, [person], email_address in PersonEmailAddress,
          on: email_address.person_id == person.person_id
        )
        |> where([_person, email_address], email_address.normalized_email == ^normalized_email)
        |> where([_person, email_address], not is_nil(email_address.verified_at))
        |> limit(1)
        |> Repo.one()
    end
  end

  @doc """
  List projected clubs for the browser-facing membership flows.

  Results are ordered by name and ID for stable browser/test output.
  """
  def list_clubs() do
    Club
    |> order_by([club], asc: club.name, asc: club.club_id)
    |> Repo.all()
  end

  @doc """
  List projected people for the browser-facing membership flows.

  Results are ordered by name and ID for stable browser/test output.
  """
  def list_people() do
    Person
    |> order_by([person], asc: person.name, asc: person.person_id)
    |> Repo.all()
  end

  @doc """
  List global person summaries for the Memba staff operations People index.

  Each person appears once with structured email and active membership summaries.
  The query uses batched read-model lookups so one person with memberships in
  multiple clubs does not require per-row follow-up queries.
  """
  def list_operator_people() do
    people =
      Person
      |> order_by([person], asc: person.name, asc: person.person_id)
      |> Repo.all()

    person_ids = Enum.map(people, & &1.person_id)
    email_summaries = person_email_summaries(person_ids)
    membership_summaries = person_membership_summaries(person_ids)

    Enum.map(people, fn person ->
      emails = Map.get(email_summaries, person.person_id, %{alternate_emails: []})

      %{
        person_id: person.person_id,
        name: person.name,
        primary_email: Map.get(emails, :primary_email) || person.email,
        alternate_emails: Map.get(emails, :alternate_emails, []),
        memberships: Map.get(membership_summaries, person.person_id, [])
      }
    end)
  end

  @doc """
  Return projected club summaries keyed by club ID.

  Invalid IDs are ignored. Results are plain maps so other contexts can enrich
  their read models through Membership's public query API rather than joining
  directly against Membership projection tables.
  """
  def list_club_summaries(club_ids) do
    if is_list(club_ids) do
      club_ids = cast_ids(:club, club_ids)

      if club_ids == [] do
        %{}
      else
        Club
        |> where([club], club.club_id in ^club_ids)
        |> select([club], %{
          club_id: club.club_id,
          name: club.name,
          slug: club.slug
        })
        |> Repo.all()
        |> Map.new(&{&1.club_id, &1})
      end
    else
      %{}
    end
  end

  @doc """
  Return projected person contact summaries keyed by person ID.

  Invalid IDs are ignored. Primary email addresses are read from the dedicated
  email-address projection, falling back to the historical person email field
  when a primary email row is not available.
  """
  def list_person_contact_summaries(person_ids) do
    if is_list(person_ids) do
      person_ids = cast_ids(:person, person_ids)

      if person_ids == [] do
        %{}
      else
        email_summaries = person_email_summaries(person_ids)

        Person
        |> where([person], person.person_id in ^person_ids)
        |> select([person], %{
          person_id: person.person_id,
          name: person.name,
          email: person.email
        })
        |> Repo.all()
        |> Map.new(fn person ->
          emails = Map.get(email_summaries, person.person_id, %{})

          {person.person_id,
           %{
             person_id: person.person_id,
             name: person.name,
             primary_email: Map.get(emails, :primary_email) || person.email
           }}
        end)
      end
    else
      %{}
    end
  end

  @doc """
  Fetch the primary projected email address for a person.

  Returns `nil` when the person ID is absent, invalid, unknown, or has no
  projected primary email-address row.
  """
  def get_person_primary_email(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.is_primary == true)
      |> select([email_address], email_address.email)
      |> Repo.one()
    else
      :error -> nil
    end
  end

  @doc """
  List non-primary projected email addresses for a person.

  Invalid, missing, or unknown person IDs return an empty list.
  """
  def list_person_alternate_emails(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.is_primary == false)
      |> order_by([email_address], asc: email_address.email, asc: email_address.id)
      |> select([email_address], email_address.email)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  List all projected email addresses for a person.

  The primary address is returned first, followed by alternate addresses ordered
  by display email and row ID. Results are plain maps so callers do not depend on
  Membership projection schemas.
  """
  def list_person_email_addresses(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> order_by([email_address],
        desc: email_address.is_primary,
        asc: email_address.email,
        asc: email_address.id
      )
      |> select([email_address], %{
        email: email_address.email,
        normalized_email: email_address.normalized_email,
        primary?: email_address.is_primary
      })
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  List active members of the given club for recipient resolution and member lists.

  Returns plain maps containing the public identity needed outside the
  Membership context: `:membership_id`, `:id`, `:name`, `:email`, and `:roles`.
  Role names come from active role assignments and are sorted alphabetically for
  each member. Members of other clubs, inactive memberships, memberships without
  a projected person, and invalid club IDs are excluded.
  """
  def list_active_members_of_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      members =
        MembershipProjection
        |> join(:inner, [membership], person in Person,
          on: person.person_id == membership.person_id
        )
        |> join(:inner, [membership, person], primary_email_address in PersonEmailAddress,
          on:
            primary_email_address.person_id == person.person_id and
              primary_email_address.is_primary == true
        )
        |> where([membership, _person, _primary_email_address], membership.club_id == ^club_id)
        |> where([membership, _person, _primary_email_address], membership.active == true)
        |> order_by([_membership, person, _primary_email_address],
          asc: person.name,
          asc: person.person_id
        )
        |> select([membership, person, primary_email_address], %{
          membership_id: membership.membership_id,
          id: person.person_id,
          name: person.name,
          email: primary_email_address.email
        })
        |> Repo.all()

      role_names_by_membership =
        members
        |> Enum.map(& &1.membership_id)
        |> active_role_names_by_membership()

      Enum.map(members, fn member ->
        Map.put(member, :roles, Map.get(role_names_by_membership, member.membership_id, []))
      end)
    else
      :error -> []
    end
  end

  @doc """
  List active clubs for a member email address.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Results are ordered by name and ID for stable
  browser/test output. Invalid or blank email addresses return an empty list.
  """
  def list_active_clubs_for_member_email(email) do
    case normalize_email(email) do
      nil ->
        []

      normalized_email ->
        MembershipProjection
        |> join(:inner, [membership], email_address in PersonEmailAddress,
          on: email_address.person_id == membership.person_id
        )
        |> join(:inner, [membership, _email_address], club in Club,
          on: club.club_id == membership.club_id
        )
        |> where([membership, _email_address, _club], membership.active == true)
        |> where(
          [_membership, email_address, _club],
          email_address.normalized_email == ^normalized_email
        )
        |> distinct(true)
        |> order_by([_membership, _email_address, club], asc: club.name, asc: club.club_id)
        |> select([_membership, _email_address, club], club)
        |> Repo.all()
    end
  end

  @doc """
  Return whether a person currently has an active membership in a club.

  Invalid club or person IDs return `false`.
  """
  def active_member_of_club?(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      MembershipProjection
      |> where([membership], membership.club_id == ^club_id)
      |> where([membership], membership.person_id == ^person_id)
      |> where([membership], membership.active == true)
      |> Repo.exists?()
    else
      :error -> false
    end
  end

  @doc """
  Return whether an email address currently has an active membership in a club.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Invalid club IDs and blank email addresses return `false`.
  """
  def active_member_of_club_by_email?(club_id, email) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         normalized_email when is_binary(normalized_email) <- normalize_email(email) do
      MembershipProjection
      |> join(:inner, [membership], email_address in PersonEmailAddress,
        on: email_address.person_id == membership.person_id
      )
      |> where([membership, _email_address], membership.club_id == ^club_id)
      |> where([membership, _email_address], membership.active == true)
      |> where(
        [_membership, email_address],
        email_address.normalized_email == ^normalized_email
      )
      |> Repo.exists?()
    else
      _invalid -> false
    end
  end

  @doc """
  Fetch a projected club member invitation by typed invitation ID.

  Returns `nil` for missing, invalid, or unknown invitation IDs.
  """
  def get_club_member_invitation(invitation_id) do
    with {:ok, invitation_id} <- ID.cast(:club_invitation, invitation_id) do
      Repo.get(ClubInvitation, invitation_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch the pending invitation for a club/email pair.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Accepted invitations and invalid inputs return `nil`.
  """
  def get_pending_club_member_invitation_by_email(club_id, email) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, email} <- EmailAddresses.normalize_email(email) do
      ClubInvitation
      |> where([invitation], invitation.club_id == ^club_id)
      |> where([invitation], invitation.normalized_email == ^email.normalized_email)
      |> where([invitation], invitation.status == "pending")
      |> limit(1)
      |> Repo.one()
    else
      _invalid -> nil
    end
  end

  @doc """
  Fetch a projected club member invitation by plaintext invitation token.

  Invitation tokens are stored only as SHA-256 hashes. Both pending invitations
  and accepted invitations can be found so accepted links can be reopened
  idempotently without creating duplicate memberships.
  """
  def get_club_member_invitation_by_token(token) when is_binary(token) do
    token
    |> InvitationToken.hash_token()
    |> then(&Repo.get_by(ClubInvitation, token_hash: &1))
  end

  def get_club_member_invitation_by_token(_token), do: nil

  @doc """
  Return whether a person currently has an app-defined club-scoped permission.

  Permission checks are answered from Membership's projected permission state so
  callers do not need to know which role granted the permission. Invalid club
  IDs, person IDs, unsupported permission identifiers, and missing projected
  grants return `false`.
  """
  def person_has_club_permission?(club_id, person_id, permission) do
    Authorization.has_permission?(club_id, person_id, permission)
  end

  defp cast_ids(type, ids) do
    ids
    |> Enum.reduce([], fn id, valid_ids ->
      case ID.cast(type, id) do
        {:ok, id} -> [id | valid_ids]
        :error -> valid_ids
      end
    end)
    |> Enum.uniq()
    |> Enum.reverse()
  end

  defp person_email_summaries([]), do: %{}

  defp person_email_summaries(person_ids) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id in ^person_ids)
    |> order_by([email_address],
      desc: email_address.is_primary,
      asc: email_address.email,
      asc: email_address.id
    )
    |> select([email_address], %{
      person_id: email_address.person_id,
      email: email_address.email,
      primary?: email_address.is_primary
    })
    |> Repo.all()
    |> Enum.group_by(& &1.person_id)
    |> Map.new(fn {person_id, email_addresses} ->
      primary_email =
        email_addresses
        |> Enum.find(& &1.primary?)
        |> case do
          nil -> nil
          email_address -> email_address.email
        end

      alternate_emails =
        for %{primary?: false, email: email} <- email_addresses do
          email
        end

      {person_id, %{primary_email: primary_email, alternate_emails: alternate_emails}}
    end)
  end

  defp person_membership_summaries([]), do: %{}

  defp person_membership_summaries(person_ids) do
    MembershipProjection
    |> join(:left, [membership], club in Club, on: club.club_id == membership.club_id)
    |> where([membership, _club], membership.person_id in ^person_ids)
    |> where([membership, _club], membership.active == true)
    |> order_by([membership, club],
      asc: club.name,
      asc: club.club_id,
      asc: membership.membership_id
    )
    |> select([membership, club], %{
      person_id: membership.person_id,
      membership_id: membership.membership_id,
      club_id: membership.club_id,
      club_name: club.name,
      club_slug: club.slug
    })
    |> Repo.all()
    |> Enum.group_by(& &1.person_id)
  end

  defp active_role_names_by_membership([]), do: %{}

  defp active_role_names_by_membership(membership_ids) do
    RoleAssignment
    |> join(:inner, [assignment], role in RoleProjection,
      on: role.role_id == assignment.role_id and role.club_id == assignment.club_id
    )
    |> where([assignment, _role], assignment.membership_id in ^membership_ids)
    |> where([assignment, _role], assignment.active == true)
    |> order_by([assignment, role],
      asc: assignment.membership_id,
      asc: role.name,
      asc: role.role_id
    )
    |> select([assignment, role], %{
      membership_id: assignment.membership_id,
      role_name: role.name
    })
    |> Repo.all()
    |> Enum.group_by(& &1.membership_id, & &1.role_name)
  end

  defp create_club_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, slug} <- club_slug(attrs, name) do
      {:ok, %CreateClub{club_id: club_id, name: name, slug: slug}}
    end
  end

  defp update_club_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, club_id} <- cast_club_id(club_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, slug} <- fetch_required(attrs, :slug),
         {:ok, slug} <- Slug.validate(slug) do
      {:ok, %UpdateClub{club_id: club_id, name: name, slug: slug}}
    end
  end

  defp create_person_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, email_attrs} <- create_person_email_attrs(attrs) do
      {:ok, struct!(CreatePerson, Map.merge(%{person_id: person_id, name: name}, email_attrs))}
    end
  end

  defp replace_person_email_addresses_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email_addresses} <- fetch_required(attrs, :email_addresses) do
      {:ok, %ReplacePersonEmailAddresses{person_id: person_id, email_addresses: email_addresses}}
    end
  end

  defp add_person_email_address_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email) do
      {:ok, %AddPersonEmailAddress{person_id: person_id, email: email}}
    end
  end

  defp verify_person_email_address_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, verified_at} <- verified_at(attrs) do
      {:ok,
       %VerifyPersonEmailAddress{person_id: person_id, email: email, verified_at: verified_at}}
    end
  end

  defp make_person_email_address_primary_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email) do
      {:ok, %MakePersonEmailAddressPrimary{person_id: person_id, email: email}}
    end
  end

  defp remove_person_email_address_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email) do
      {:ok, %RemovePersonEmailAddress{person_id: person_id, email: email}}
    end
  end

  defp add_member_command(attrs) do
    with {:ok, membership_id} <- fetch_required(attrs, :membership_id),
         {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, person_id} <- fetch_required(attrs, :person_id) do
      {:ok, %AddMember{membership_id: membership_id, club_id: club_id, person_id: person_id}}
    end
  end

  defp invite_club_member_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, invitation_id} <- invitation_id(attrs) do
      invitation_token = InvitationToken.generate_token()

      {:ok,
       %InviteClubMember{
         invitation_id: invitation_id,
         club_id: club_id,
         email: email,
         token_hash: InvitationToken.hash_token(invitation_token)
       }, invitation_token}
    end
  end

  defp resend_club_member_invitation_command(%ClubInvitation{} = invitation) do
    invitation_token = InvitationToken.generate_token()

    {:ok,
     %ResendClubMemberInvitation{
       invitation_id: invitation.invitation_id,
       token_hash: InvitationToken.hash_token(invitation_token)
     }, invitation_token}
  end

  defp invitation_create_person_command(%ClubInvitation{} = invitation, person_id, name) do
    {:ok,
     %CreatePerson{
       person_id: person_id,
       name: name,
       email_addresses: [%{email: invitation.email, is_primary: true}]
     }}
  end

  defp invitation_add_member_command(%ClubInvitation{} = invitation, person_id, membership_id) do
    {:ok,
     %AddMember{
       membership_id: membership_id,
       club_id: invitation.club_id,
       person_id: person_id
     }}
  end

  defp accept_club_member_invitation_command(
         %ClubInvitation{} = invitation,
         person_id,
         membership_id
       ) do
    {:ok,
     %AcceptClubMemberInvitation{
       invitation_id: invitation.invitation_id,
       person_id: person_id,
       membership_id: membership_id
     }}
  end

  defp remove_member_command(attrs) do
    with {:ok, membership_id} <- fetch_required(attrs, :membership_id) do
      {:ok, %RemoveMember{membership_id: membership_id}}
    end
  end

  defp assign_member_role_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, membership_id} <- fetch_required(attrs, :membership_id),
         {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, role_id} <- fetch_required(attrs, :role_id),
         {:ok, actor_person_id} <- fetch_required(attrs, :actor_person_id) do
      {:ok,
       %AssignMemberRole{
         club_id: club_id,
         membership_id: membership_id,
         person_id: person_id,
         role_id: role_id,
         assigned_by_person_id: actor_person_id
       }}
    end
  end

  defp remove_member_role_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, membership_id} <- fetch_required(attrs, :membership_id),
         {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, role_id} <- fetch_required(attrs, :role_id),
         {:ok, actor_person_id} <- fetch_required(attrs, :actor_person_id) do
      {:ok,
       %RemoveMemberRole{
         club_id: club_id,
         membership_id: membership_id,
         person_id: person_id,
         role_id: role_id,
         removed_by_person_id: actor_person_id
       }}
    end
  end

  defp put_membership_administrator_role_id(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, club_id} <- cast_club_id(club_id) do
      {:ok, Map.put(attrs, :role_id, Roles.membership_administrator_role_id(club_id))}
    end
  end

  defp prevent_duplicate_active_membership(%AddMember{} = command) do
    if active_member_of_club?(command.club_id, command.person_id) do
      {:error, :already_active_member}
    else
      :ok
    end
  end

  defp prevent_inviting_active_club_member(%InviteClubMember{} = command) do
    if active_member_of_club_by_email?(command.club_id, command.email) do
      {:error, :already_active_member}
    else
      :ok
    end
  end

  defp ensure_active_membership(club_id, person_id, membership_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, membership_id} <- ID.cast(:membership, membership_id) do
      active? =
        MembershipProjection
        |> where([membership], membership.membership_id == ^membership_id)
        |> where([membership], membership.club_id == ^club_id)
        |> where([membership], membership.person_id == ^person_id)
        |> where([membership], membership.active == true)
        |> Repo.exists?()

      if active? do
        :ok
      else
        {:error, :member_not_active}
      end
    else
      :error -> {:error, :member_not_active}
    end
  end

  defp pending_invitation_for_resend(attrs) do
    case fetch_optional(attrs, :invitation_id) do
      {:ok, invitation_id} ->
        invitation_id
        |> get_club_member_invitation()
        |> ensure_pending_invitation()

      :error ->
        with {:ok, club_id} <- fetch_required(attrs, :club_id),
             {:ok, email} <- fetch_required(attrs, :email) do
          club_id
          |> get_pending_club_member_invitation_by_email(email)
          |> ensure_pending_invitation()
        end
    end
  end

  defp pending_invitation_for_acceptance(attrs) do
    with {:ok, invitation_id} <- fetch_required(attrs, :invitation_id) do
      invitation_id
      |> get_club_member_invitation()
      |> ensure_pending_invitation()
    end
  end

  defp ensure_pending_invitation(nil), do: {:error, :pending_invitation_not_found}

  defp ensure_pending_invitation(%ClubInvitation{status: "pending"} = invitation),
    do: {:ok, invitation}

  defp ensure_pending_invitation(%ClubInvitation{status: "accepted"}),
    do: {:error, :already_accepted}

  defp resend_pending_club_member_invitation(%ClubInvitation{} = invitation, dispatch_opts) do
    with {:ok, command, invitation_token} <- resend_club_member_invitation_command(invitation),
         {:ok, dispatch_result} <- dispatch_invitation_token_command(command, dispatch_opts) do
      {:ok,
       invitation_token_result(
         command.invitation_id,
         invitation_token,
         :execution_result,
         dispatch_result
       )}
    end
  end

  defp fetch_existing_person(person_id) do
    case get_person(person_id) do
      %Person{} = person -> {:ok, person}
      nil -> {:error, :person_not_found}
    end
  end

  defp ensure_person_has_invitation_email(person_id, %ClubInvitation{} = invitation) do
    has_invited_email? =
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.normalized_email == ^invitation.normalized_email)
      |> Repo.exists?()

    if has_invited_email? do
      :ok
    else
      {:error, :invitation_email_mismatch}
    end
  end

  defp pending_person_email_address_for_verification(person_id, normalized_email) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id == ^person_id)
    |> where([email_address], email_address.normalized_email == ^normalized_email)
    |> limit(1)
    |> Repo.one()
    |> ensure_pending_person_email_address()
  end

  defp pending_person_email_address_for_sign_in(email) do
    case normalize_email(email) do
      nil ->
        :not_pending

      normalized_email ->
        PersonEmailAddress
        |> where([email_address], email_address.normalized_email == ^normalized_email)
        |> where([email_address], is_nil(email_address.verified_at))
        |> limit(1)
        |> Repo.one()
        |> case do
          %PersonEmailAddress{} = email_address -> {:ok, email_address}
          nil -> :not_pending
        end
    end
  end

  defp normalize_sign_in_verification_result(:ok), do: :ok
  defp normalize_sign_in_verification_result({:ok, _result}), do: :ok
  defp normalize_sign_in_verification_result({:error, _reason} = error), do: error

  defp ensure_pending_person_email_address(nil), do: {:error, :pending_email_address_not_found}

  defp ensure_pending_person_email_address(%PersonEmailAddress{verified_at: nil} = email_address) do
    {:ok, email_address}
  end

  defp ensure_pending_person_email_address(%PersonEmailAddress{verified_at: %DateTime{}}) do
    {:error, :email_address_already_verified}
  end

  defp pending_removed_person_email_address_verification_requests(
         person_id,
         replacement_email_addresses
       )
       when is_list(replacement_email_addresses) do
    with {:ok, person_id} <- cast_person_id(person_id) do
      retained_normalized_emails =
        Enum.map(replacement_email_addresses, & &1.normalized_email)

      requests =
        PersonEmailAddress
        |> where([email_address], email_address.person_id == ^person_id)
        |> where([email_address], is_nil(email_address.verified_at))
        |> where(
          [email_address],
          email_address.normalized_email not in ^retained_normalized_emails
        )
        |> order_by([email_address], asc: email_address.normalized_email)
        |> Repo.all()
        |> Enum.map(&person_email_address_verification_request/1)

      {:ok, requests}
    end
  end

  defp pending_removed_person_email_address_verification_requests(person_id, email) do
    with {:ok, person_id} <- cast_person_id(person_id),
         {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.normalized_email == ^normalized_email)
      |> where([email_address], is_nil(email_address.verified_at))
      |> Repo.one()
      |> case do
        nil ->
          []

        %PersonEmailAddress{} = email_address ->
          [person_email_address_verification_request(email_address)]
      end
    else
      _invalid -> []
    end
  end

  defp ensure_membership_administrator_removal_keeps_an_administrator(
         %RemoveMemberRole{} = command
       ) do
    with {:ok, club_id} <- ID.cast(:club, command.club_id),
         true <- command.role_id == Roles.membership_administrator_role_id(club_id),
         true <-
           active_role_assignment?(
             club_id,
             command.membership_id,
             command.person_id,
             command.role_id
           ) do
      if active_role_assignment_count(club_id, command.role_id) > 1 do
        :ok
      else
        {:error, :last_membership_administrator}
      end
    else
      _not_membership_administrator_removal -> :ok
    end
  end

  defp active_role_assignment?(club_id, membership_id, person_id, role_id) do
    active_role_assignments_query(club_id, role_id)
    |> where([assignment], assignment.membership_id == ^membership_id)
    |> where([assignment], assignment.person_id == ^person_id)
    |> Repo.exists?()
  end

  defp active_role_assignment_count(club_id, role_id) do
    club_id
    |> active_role_assignments_query(role_id)
    |> Repo.aggregate(:count, :membership_id)
  end

  defp active_role_assignments_query(club_id, role_id) do
    RoleAssignment
    |> where([assignment], assignment.club_id == ^club_id)
    |> where([assignment], assignment.role_id == ^role_id)
    |> where([assignment], assignment.active == true)
  end

  defp prevent_duplicate_club_slug(%CreateClub{} = command) do
    case Repo.get_by(Club, slug: command.slug) do
      nil -> :ok
      %Club{} -> {:error, :slug_taken}
    end
  end

  defp prevent_duplicate_club_slug(%UpdateClub{} = command) do
    case Repo.get_by(Club, slug: command.slug) do
      nil -> :ok
      %Club{club_id: club_id} when club_id == command.club_id -> :ok
      %Club{} -> {:error, :slug_taken}
    end
  end

  defp normalize_command_email_addresses(%CreatePerson{email_addresses: nil, email: email}) do
    with {:ok, normalized_email} <- EmailAddresses.normalize_primary_email(email) do
      {:ok, [%{normalized_email: normalized_email}]}
    end
  end

  defp normalize_command_email_addresses(%CreatePerson{email_addresses: email_addresses}) do
    EmailAddresses.validate_set(email_addresses)
  end

  defp normalize_command_email_addresses(%ReplacePersonEmailAddresses{
         email_addresses: email_addresses
       }) do
    EmailAddresses.validate_set(email_addresses)
  end

  defp normalize_command_email_addresses(%AddPersonEmailAddress{email: email}) do
    with {:ok, normalized_email_address} <- EmailAddresses.normalize_email(email) do
      {:ok, [normalized_email_address]}
    end
  end

  defp person_email_address_verification_request(%PersonEmailAddress{} = email_address) do
    %{
      person_id: email_address.person_id,
      email: email_address.email,
      normalized_email: email_address.normalized_email
    }
  end

  defp issue_person_email_address_verification(request, opts) do
    issuer =
      case Keyword.fetch(opts, :verification_issuer) do
        {:ok, issuer} ->
          issuer

        :error ->
          fn request -> default_person_email_address_verification_issuer(request, opts) end
      end

    case issue_person_email_address_verification_with(issuer, request) do
      :ok -> {:ok, request}
      {:ok, issuer_result} -> {:ok, Map.put(request, :issuer_result, issuer_result)}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected_email_address_verification_issuer_result, other}}
    end
  end

  defp issue_person_email_address_verification_with(issuer, request)
       when is_function(issuer, 1) do
    issuer.(request)
  end

  defp issue_person_email_address_verification_with(_issuer, _request) do
    {:error, :invalid_email_address_verification_issuer}
  end

  defp default_person_email_address_verification_issuer(request, opts) do
    token = InvitationToken.generate_token()
    now = timestamp(opts)
    expires_at = DateTime.add(now, @person_email_address_verification_token_ttl_seconds, :second)

    attrs = %{
      person_id: request.person_id,
      normalized_email: request.normalized_email,
      token_hash: hash_person_email_address_verification_token(token),
      expires_at: expires_at
    }

    case EmailAddressVerificationToken.insert(attrs) do
      {:ok, %EmailAddressVerificationToken{} = verification_token} ->
        {:ok, %{token: token, expires_at: verification_token.expires_at}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp person_email_address_verification_revoker(opts) do
    case Keyword.pop(opts, :verification_revoker) do
      {nil, opts} ->
        {fn request -> default_person_email_address_verification_revoker(request, opts) end, opts}

      {revoker, opts} ->
        {revoker, opts}
    end
  end

  defp revoke_removed_person_email_address_verifications(
         {:error, _reason} = error,
         _requests,
         _revoker
       ) do
    error
  end

  defp revoke_removed_person_email_address_verifications(result, [], _revoker), do: result

  defp revoke_removed_person_email_address_verifications(result, requests, revoker) do
    with :ok <- revoke_person_email_address_verifications(requests, revoker) do
      result
    end
  end

  defp revoke_person_email_address_verifications(requests, revoker)
       when is_list(requests) and is_function(revoker, 1) do
    Enum.reduce_while(requests, :ok, fn request, :ok ->
      case revoke_person_email_address_verification_with(revoker, request) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp revoke_person_email_address_verifications(_requests, _revoker) do
    {:error, :invalid_email_address_verification_revoker}
  end

  defp revoke_person_email_address_verification_with(revoker, request) do
    case revoker.(request) do
      :ok -> :ok
      {:ok, _revoked} -> :ok
      {:error, _reason} = error -> error
      other -> {:error, {:unexpected_email_address_verification_revoker_result, other}}
    end
  end

  defp default_person_email_address_verification_revoker(request, opts) do
    now = timestamp(opts)

    with {:ok, person_id} <- cast_person_id(request.person_id),
         {:ok, %{normalized_email: normalized_email}} <-
           EmailAddresses.normalize_email(request.normalized_email) do
      EmailAddressVerificationToken.revoke_pending(person_id, normalized_email, now)
    else
      _invalid -> {:error, :invalid_email_address_verification_request}
    end
  end

  defp hash_person_email_address_verification_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  defp prevent_duplicate_person_email_addresses(person_id, email_addresses) do
    with {:ok, person_id} <- cast_person_id(person_id) do
      normalized_emails = Enum.map(email_addresses, & &1.normalized_email)

      PersonEmailAddress
      |> where([email_address], email_address.normalized_email in ^normalized_emails)
      |> where([email_address], email_address.person_id != ^person_id)
      |> select([email_address], email_address.normalized_email)
      |> limit(1)
      |> Repo.one()
      |> case do
        nil -> :ok
        _normalized_email -> {:error, :email_address_taken}
      end
    end
  end

  defp dispatch_invitation_token_command(command, dispatch_opts) do
    case dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> ok
      {:error, _reason} = error -> error
    end
  end

  defp dispatch_acceptance_command(command, dispatch_opts) do
    case dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> ok
      {:error, _reason} = error -> error
    end
  end

  defp dispatch(command, dispatch_opts) do
    case App.dispatch(command, dispatch_opts) do
      :ok -> :ok
      {:ok, _result} = ok -> ok
      {:error, _reason} = error -> error
    end
  end

  defp fetch_required(attrs, key) when is_atom(key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp invitation_id(attrs) do
    case fetch_optional(attrs, :invitation_id) do
      {:ok, invitation_id} -> {:ok, invitation_id}
      :error -> {:ok, ID.generate(:club_invitation)}
    end
  end

  defp invitation_person_id(attrs) do
    case fetch_optional(attrs, :person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:ok, ID.generate(:person)}
    end
  end

  defp invitation_membership_id(attrs) do
    case fetch_optional(attrs, :membership_id) do
      {:ok, membership_id} -> {:ok, membership_id}
      :error -> {:ok, ID.generate(:membership)}
    end
  end

  defp fetch_optional(attrs, key) when is_atom(key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
  end

  defp verified_at(attrs) do
    case fetch_optional(attrs, :verified_at) do
      {:ok, %DateTime{} = verified_at} -> {:ok, verified_at}
      {:ok, _verified_at} -> {:error, :invalid_verified_at}
      :error -> {:ok, DateTime.utc_now(:microsecond)}
    end
  end

  defp timestamp(opts) do
    Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
  end

  defp create_person_email_attrs(attrs) do
    case fetch_optional(attrs, :email_addresses) do
      {:ok, email_addresses} ->
        email_attrs =
          case fetch_optional(attrs, :email) do
            {:ok, email} -> %{email: email, email_addresses: email_addresses}
            :error -> %{email_addresses: email_addresses}
          end

        {:ok, email_attrs}

      :error ->
        with {:ok, email} <- fetch_required(attrs, :email) do
          {:ok, %{email: email}}
        end
    end
  end

  defp cast_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :invalid_club_id}
    end
  end

  defp cast_person_id(person_id) do
    case ID.cast(:person, person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end

  defp cast_membership_id(membership_id) do
    case ID.cast(:membership, membership_id) do
      {:ok, membership_id} -> {:ok, membership_id}
      :error -> {:error, :invalid_membership_id}
    end
  end

  defp club_slug(attrs, name) do
    case fetch_optional(attrs, :slug) do
      {:ok, ""} -> Slug.default_from_name(name) |> Slug.validate()
      {:ok, slug} -> Slug.validate(slug)
      :error -> Slug.default_from_name(name) |> Slug.validate()
    end
  end

  defp normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized_email -> normalized_email
    end
  end

  defp normalize_email(_email), do: nil

  defp invitation_token_result(invitation_id, invitation_token, :execution_result, :ok) do
    %{invitation_id: invitation_id, invitation_token: invitation_token}
  end

  defp invitation_token_result(
         invitation_id,
         invitation_token,
         :execution_result,
         execution_result
       ) do
    %{
      invitation_id: invitation_id,
      invitation_token: invitation_token,
      execution_result: execution_result
    }
  end

  defp acceptance_result(
         %ClubInvitation{} = invitation,
         person_id,
         membership_id,
         add_member_result,
         accept_result
       ) do
    %{
      invitation_id: invitation.invitation_id,
      club_id: invitation.club_id,
      person_id: person_id,
      membership_id: membership_id,
      membership_execution_result: add_member_result,
      invitation_execution_result: accept_result
    }
  end
end
