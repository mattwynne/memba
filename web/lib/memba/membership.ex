defmodule Memba.Membership do
  @moduledoc """
  Public application service and query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership.AddMember
  alias Memba.Membership.App
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.MembershipQueries
  alias Memba.Membership.AuthoritativeMembershipQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.CustomGroup
  alias Memba.Membership.Authorization
  alias Memba.Membership.ClubMember
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.CustomGroupSlug
  alias Memba.Membership.InvitationAcceptance
  alias Memba.Membership.InvitationQueries
  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.GroupName
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.PersonEmailAddressVerificationRevocation
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.SystemGroupBackfillQueries
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.ProjectionBarrier
  alias Memba.Repo

  @person_email_address_verification_token_ttl_seconds 15 * 60
  @group_access_projectors [GroupMembershipProjector, MembershipProjector]

  @doc """
  Create a club through the Membership Commanded application.

  The caller supplies the club aggregate identity as `:club_id` or
  `"club_id"`.
  """
  def create_club(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubCommands.prepare_create(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Create a custom conversation group as an authenticated club member.

  The caller supplies the Club aggregate identity, a caller-generated group
  identity, and the authenticated actor's person identity. The group identity
  is the creation request's retry key: allocate it once and reuse it when the
  outcome of a dispatch is uncertain. This application service only translates
  the use case into an actor-bearing command; the Club aggregate owns the
  authoritative creation decision.
  """
  def create_custom_group(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- CustomGroup.Create.prepare(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Add an existing club membership to a custom group as an authenticated actor.

  The caller supplies the Club and group identities, the target
  membership/person pair, and the authenticated actor's person identity. The
  application service translates that request into an actor-bearing command.
  The Club aggregate authoritatively requires an active target and an active
  actor who either belongs to the custom group or has its club's
  `club.manage_members` permission. System groups are not writable through this
  use case.

  By default, success returns a `CustomGroupAdmission` identifying the actor,
  target, and whether this command applied a new membership transition or was
  an already-applied retry. This lets follow-up work such as welcome delivery
  respond only to a confirmed new transition without consulting a potentially
  stale projection. Callers may explicitly select a Commanded `:returning`
  mode when they need its lower-level dispatch result instead.
  """
  def add_custom_group_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- CustomGroup.Admit.prepare(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove a current participant from a custom group as an authenticated actor.

  The caller supplies a stable UUID `:removal_operation_id` and must reuse it
  when retrying an uncertain dispatch. An exact retry returns the same
  `CustomGroupRemoval` outcome without another event. Reusing the operation ID
  with different actor, target, group, or club data is rejected. A current
  participant may remove any current participant (including themselves), and a
  current club member with `club.manage_members` may do so from outside the
  group. System groups are not writable through this use case.
  """
  def remove_custom_group_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Preview a custom group's normalized name and allocated email address.

  This authenticated read is advisory: it uses the current projections and
  never reserves a name or address. `create_custom_group/2` must still be used
  on submit so the Club aggregate can recheck authority and identity claims at
  the serialized write boundary.
  """
  def preview_custom_group(attrs) when is_map(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, club_id} <- cast_id(:club, club_id, :not_found),
         {:ok, actor_person_id} <- fetch_required(attrs, :actor_person_id),
         {:ok, actor_person_id} <- cast_id(:person, actor_person_id, :unauthorized),
         :ok <- Authorization.authorize_manage_members(club_id, actor_person_id),
         %Club{} = club <- Repo.get(Club, club_id),
         {:ok, submitted_name} <- fetch_required(attrs, :name),
         {:ok, name} <- GroupName.normalize(submitted_name) do
      custom_group_identity_preview(club, name)
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Update a club's staff-managed display name and public slug.

  The caller supplies the club aggregate identity as `:club_id` or
  `"club_id"`. Slugs must already be valid address-safe values and must not be
  used by another projected club.
  """
  def update_club(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubCommands.prepare_update(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Create a person through the Membership Commanded application.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"`.
  """
  def create_person(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- PersonCommands.prepare_create(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
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
    {revoker, dispatch_opts} = PersonEmailAddressVerificationRevocation.revoker(dispatch_opts)

    with {:ok, command, requests} <- PersonEmailAddressCommands.prepare_replace(attrs) do
      command
      |> CommandDispatch.dispatch(dispatch_opts)
      |> PersonEmailAddressVerificationRevocation.after_dispatch(requests, revoker)
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
    with {:ok, command} <- PersonEmailAddressCommands.prepare_add(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
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
    with {:ok, command} <- PersonEmailAddressCommands.prepare_verify(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
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
    with {:ok, command} <- PersonEmailAddressCommands.prepare_make_primary(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove a non-primary person email address.
  """
  def remove_person_email_address(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    {revoker, dispatch_opts} = PersonEmailAddressVerificationRevocation.revoker(dispatch_opts)

    with {:ok, command, requests} <- PersonEmailAddressCommands.prepare_remove(attrs) do
      command
      |> CommandDispatch.dispatch(dispatch_opts)
      |> PersonEmailAddressVerificationRevocation.after_dispatch(requests, revoker)
    end
  end

  @doc """
  Add a person as an active member of a club through the Membership context.

  The caller supplies the membership identity as `:membership_id` or
  `"membership_id"`. The command is routed to the Club aggregate, which decides
  first-member authority, idempotency, and duplicate active membership. The call
  completes only after any earlier custom-group follow cleanup on the Club
  stream, so a rapid re-add cannot restore access before stale follows are
  cleared.
  """
  def add_member(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- AddMember.prepare(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
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
  caller supplies `:person_id` and may supply `:membership_id`; otherwise the
  workflow recovers an active membership or derives a stable invitation identity.
  """
  def accept_club_member_invitation_for_existing_person(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    InvitationAcceptance.accept_existing(attrs, dispatch_opts)
  end

  @doc """
  Complete an invited unknown person's required profile and accept the invitation.

  The invitee's person record is not created until this API receives a valid
  non-blank name. It creates the person using the invited email, creates an
  ordinary active membership for the invited club, and then marks the invitation
  accepted. The caller may supply `:person_id` and `:membership_id`; otherwise
  the workflow recovers existing identities or derives stable invitation identities.
  """
  def complete_invited_club_member_profile(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    InvitationAcceptance.complete_profile(attrs, dispatch_opts)
  end

  @doc """
  Remove a person from active club membership through the Membership context.

  The caller supplies `:membership_id` or `"membership_id"`. It may also supply
  the matching club and person identities; otherwise the application service
  resolves those routing fields from the membership projection before the Club
  aggregate validates them and decides the Admin and member floors. A successful
  decision also ends every active custom-group membership held by that club
  membership. The call completes only after system-group membership and
  custom-group conversation follows have been cleared.
  """
  def remove_member(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubMember.Remove.prepare(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Assign the built-in Admin role to an active member as a club member actor.

  The caller supplies the target `:membership_id`/`:person_id`, the `:club_id`,
  and `:actor_person_id`. The actor must have the projected
  `club.manage_members` permission. The target member must be active in the
  club. The built-in role ID is derived from the club so callers cannot grant an
  arbitrary role through this Admin-specific entry point. The Club aggregate
  validates the target membership.
  """
  def assign_membership_administrator_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubMember.Role.prepare_assign_administrator(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove the built-in Admin role from an active member as a club member actor.

  The caller supplies the target `:membership_id`/`:person_id`, the `:club_id`,
  and `:actor_person_id`. The actor must have the projected
  `club.manage_members` permission. The target member must be active in the
  club. The built-in role ID is derived from the club so callers cannot remove an
  arbitrary role through this Admin-specific entry point. The Club aggregate
  rejects removal when it would leave the club with no active Admins.
  """
  def remove_membership_administrator_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubMember.Role.prepare_remove_administrator(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Assign a club role to an active member as a club member actor.

  Unlike staff/system setup paths, this entry point requires `:actor_person_id`
  (or `"actor_person_id"`) and authorizes the actor through the projected
  `club.manage_members` permission before dispatching the role-assignment
  command. The Club aggregate validates that the target membership is active
  and matches the submitted club/person IDs.
  """
  def assign_member_role_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubMember.Role.prepare_assign(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Remove a club role from an active member as a club member actor.

  Staff/system setup paths remain separate. This entry point requires
  `:actor_person_id` (or `"actor_person_id"`) and authorizes the actor through
  the projected `club.manage_members` permission before dispatching the
  role-removal command. The Club aggregate validates the target membership,
  role assignment, and Admin floor.
  """
  def remove_member_role_as_club_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- ClubMember.Role.prepare_remove(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Fetch a projected club read model by typed club ID.

  Returns `nil` when the ID is absent or is not a valid club ID.
  """
  def get_club(club_id), do: ClubGroupQueries.get_club(club_id)

  @doc """
  Fetch a projected club read model by public slug.

  Lookup input is normalized only where safe for public addressing: surrounding
  whitespace is trimmed and casing is folded before validating the slug. Values
  that are still invalid, missing, or unknown return `nil`.
  """
  def get_club_by_slug(slug), do: ClubGroupQueries.get_club_by_slug(slug)

  @doc """
  Fetch a public conversation-group summary by typed group ID.

  Returns `nil` when the ID is absent, invalid, or unknown. The plain-map result
  keeps callers outside Membership independent of Membership's projection schema.
  """
  def get_group(group_id), do: ClubGroupQueries.get_group(group_id)

  @doc """
  Fetch a public conversation-group summary by club ID and email routing slug.

  The email slug is normalized by trimming surrounding whitespace and folding
  casing before validation. Invalid club IDs, invalid slugs, and unknown groups
  return `nil`. The plain-map result keeps callers outside Membership independent
  of Membership's projection schema.
  """
  def get_group_by_email_slug(club_id, email_slug),
    do: ClubGroupQueries.get_group_by_email_slug(club_id, email_slug)

  @doc """
  Fetch a projected person read model by typed person ID.

  Returns `nil` when the ID is absent or is not a valid person ID.
  """
  def get_person(person_id), do: PersonQueries.get_person(person_id)

  @doc """
  Fetch a projected person read model by email address.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively across primary and alternate projected email addresses.
  Invalid, blank, and unknown addresses return `nil`.
  """
  def get_person_by_email(email), do: PersonQueries.get_person_by_email(email)

  @doc """
  Fetch a projected person read model by a verified email address.

  This mirrors `get_person_by_email/1`, but only treats email addresses whose
  projected `verified_at` is present as identity-bearing. Invalid, blank,
  unknown, and pending/unverified addresses return `nil`.
  """
  def get_verified_person_by_email(email), do: PersonQueries.get_verified_person_by_email(email)

  @doc """
  List projected clubs for the browser-facing membership flows.

  Results are ordered by name and ID for stable browser/test output.
  """
  def list_clubs(), do: ClubGroupQueries.list_clubs()

  @doc """
  List projected people for the browser-facing membership flows.

  Results are ordered by name and ID for stable browser/test output.
  """
  def list_people(), do: PersonQueries.list_people()

  @doc """
  List global person summaries for the Memba staff operations People index.

  Each person appears once with structured email and active membership summaries.
  The query uses batched read-model lookups so one person with memberships in
  multiple clubs does not require per-row follow-up queries.
  """
  def list_operator_people(), do: PersonQueries.list_operator_people()

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
  def list_person_contact_summaries(person_ids),
    do: PersonQueries.list_person_contact_summaries(person_ids)

  @doc """
  Fetch the primary projected email address for a person.

  Returns `nil` when the person ID is absent, invalid, unknown, or has no
  projected primary email-address row.
  """
  def get_person_primary_email(person_id), do: PersonQueries.get_person_primary_email(person_id)

  @doc """
  List non-primary projected email addresses for a person.

  Invalid, missing, or unknown person IDs return an empty list.
  """
  def list_person_alternate_emails(person_id),
    do: PersonQueries.list_person_alternate_emails(person_id)

  @doc """
  List all projected email addresses for a person.

  The primary address is returned first, followed by alternate addresses ordered
  by display email and row ID. Results are plain maps so callers do not depend on
  Membership projection schemas.
  """
  def list_person_email_addresses(person_id),
    do: PersonQueries.list_person_email_addresses(person_id)

  @doc """
  List active club memberships for a Person settings view.

  Invalid, missing, or unknown person IDs return an empty list. Results include
  the projected club display data plus the membership insertion timestamp so the
  member-facing settings page can show global "Member since …" chips without
  joining against Membership projections from the web layer.
  """
  def list_active_club_memberships_for_person(person_id),
    do: MembershipQueries.list_active_club_memberships_for_person(person_id)

  @doc """
  List active members of the given club for recipient resolution and member lists.

  Returns plain maps containing the public identity needed outside the
  Membership context: `:membership_id`, `:id`, `:name`, `:email`, and `:roles`.
  Role names come from active role assignments and are sorted alphabetically for
  each member. Members of other clubs, inactive memberships, memberships without
  a projected person, and invalid club IDs are excluded.
  """
  def list_active_members_of_club(club_id),
    do: ClubGroupQueries.list_active_members_of_club(club_id)

  @doc """
  Find the signed-in person's member row in a scoped active-member list.

  Resolve the email through projected person email addresses (primary or alternate),
  then compare stable person IDs. The member row retains the primary email for
  display and delivery. Unknown addresses and missing members fail closed.
  """
  def find_member_for_email(members, email) when is_list(members) do
    case get_person_by_email(email) do
      %{person_id: person_id} -> Enum.find(members, &(&1.id == person_id))
      _ -> nil
    end
  end

  def find_member_for_email(_members, _email), do: nil

  @doc """
  List active members of the given conversation group.

  Returns plain maps containing the public identity needed outside the
  Membership context: `:membership_id`, `:id`, `:name`, `:email`, and `:roles`.
  Role names come from active club role assignments and are sorted
  alphabetically for each member. Members whose group row or club membership is
  inactive, members of other groups, members without a projected person, and
  invalid group IDs are excluded.

  By default, members without a primary email address are excluded. Pass
  `include_without_primary_email: true` to include every otherwise eligible
  participant, with `:email` set to `nil` when no primary email row exists.
  """
  def list_active_members_of_group(group_id, opts \\ []) when is_list(opts),
    do: ClubGroupQueries.list_active_members_of_group(group_id, opts)

  @doc """
  List the groups an active club member may discover in the given club.

  Discovery is deliberately separate from group participation. The safe
  summaries contain group identity and display metadata only; they do not
  include member counts, email addresses, or any indication that the person
  belongs to a group. Invalid IDs and people without an active membership in
  the selected club return an empty list.
  """
  def list_discoverable_groups_for_member(club_id, person_id),
    do: ClubGroupQueries.list_discoverable_groups_for_member(club_id, person_id)

  @doc """
  List the conversation groups an active member belongs to in a given club.

  Both the group-membership row and its matching underlying club membership
  must be active. Results are ordered by group name and ID and include each
  group's active member count and optional inbound email address. They are plain
  maps so callers do not depend on Membership projection schemas. Invalid or
  unknown club and person IDs return an empty list.
  """
  def list_active_groups_for_member(club_id, person_id),
    do: ClubGroupQueries.list_active_groups_for_member(club_id, person_id)

  @doc """
  Return one keyset page of incomplete system-group definitions for release backfill.

  The page scans projected clubs in ascending `club_id` order and returns plain
  maps for deterministic Everyone/Admin group definitions whose projected row is
  absent or whose email slug is not yet assigned. `cursor` is the last scanned
  `club_id` from a previous page; callers keep it in process only and may safely
  restart from `nil`.
  """
  def list_system_group_definition_backfill_page(cursor \\ nil, limit \\ 1_000),
    do: SystemGroupBackfillQueries.list_system_group_definition_backfill_page(cursor, limit)

  @doc """
  Return one keyset page of active memberships missing active Everyone membership.

  The page scans active projected club memberships in ascending `membership_id`
  order and returns plain maps suitable for an idempotent `AddGroupMember`
  command. `cursor` is the last scanned `membership_id` from a previous page.
  """
  def list_everyone_group_membership_backfill_page(cursor \\ nil, limit \\ 1_000),
    do: SystemGroupBackfillQueries.list_everyone_group_membership_backfill_page(cursor, limit)

  @doc """
  Return one keyset page of active Admin-role memberships missing active Admin-group membership.

  The page scans active projected Admin role assignments for active projected club
  memberships in ascending `membership_id` order and returns plain maps suitable
  for an idempotent `AddGroupMember` command.
  """
  def list_admin_group_membership_backfill_page(cursor \\ nil, limit \\ 1_000),
    do: SystemGroupBackfillQueries.list_admin_group_membership_backfill_page(cursor, limit)

  @doc """
  List active clubs for a member email address.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Results are ordered by name and ID for stable
  browser/test output. Invalid or blank email addresses return an empty list.
  """
  def list_active_clubs_for_member_email(email),
    do: MembershipQueries.list_active_clubs_for_member_email(email)

  @doc """
  Return whether a person currently has an active membership in a club.

  Invalid club or person IDs return `false`.
  """
  def active_member_of_club?(club_id, person_id),
    do: MembershipQueries.active_member_of_club?(club_id, person_id)

  @doc """
  Return whether a person is currently an active member of a conversation group.

  Both the projected group-membership row and the underlying club membership
  must be active. Invalid group or person IDs return `false`.
  """
  def active_member_of_group?(group_id, person_id),
    do: MembershipQueries.active_member_of_group?(group_id, person_id)

  @doc """
  Return whether the Club aggregate currently records a person as an active
  club member.

  This authoritative query is intended for privacy-sensitive action boundaries
  where a just-committed departure may not yet be visible in Membership
  projections. Invalid IDs and missing or inactive memberships return `false`.
  """
  def active_member_of_club_authoritatively?(club_id, person_id),
    do: AuthoritativeMembershipQueries.active_member_of_club_authoritatively?(club_id, person_id)

  @doc """
  Resolve an active club member and custom group from authoritative Club state.

  The Club aggregate establishes current membership identity, same-club group
  ownership, custom-group classification, and current participation before the
  projected person display name is read. The result is a plain public summary;
  callers do not receive the aggregate or projection schemas.

  Invalid typed IDs return the corresponding `:invalid_*_id` error. Missing
  clubs return `:not_found`; missing or inactive club members return
  `:member_not_active`; missing or cross-club groups return
  `:group_not_defined`; and built-in groups return
  `:system_group_not_allowed`.
  """
  def resolve_custom_group_target_authoritatively(club_id, person_id, group_id),
    do:
      AuthoritativeMembershipQueries.resolve_custom_group_target_authoritatively(
        club_id,
        person_id,
        group_id
      )

  @doc """
  Return whether the Club aggregate currently records a person as an active
  member of one of its groups.

  Privacy-sensitive action boundaries use this narrow authoritative query when
  a just-committed departure may not yet be visible in Membership projections.
  System groups are derived from active club membership and Admin authority;
  custom groups require the same active membership identity that holds the
  group membership.
  """
  def active_member_of_group_authoritatively?(club_id, group_id, person_id),
    do:
      AuthoritativeMembershipQueries.active_member_of_group_authoritatively?(
        club_id,
        group_id,
        person_id
      )

  @doc """
  List the Club aggregate's current groups for a participating person.

  Group inclusion and member counts come from event-sourced Club state. Group
  display fields are taken from that same state, so stale group-membership
  projections cannot retain a private dashboard surface after removal.
  """
  def list_active_groups_for_member_authoritatively(club_id, person_id),
    do:
      AuthoritativeMembershipQueries.list_active_groups_for_member_authoritatively(
        club_id,
        person_id
      )

  @doc """
  List the Club aggregate's current participants in a conversation group.

  Participation is decided entirely from the event-sourced Club state, so a
  committed add, rejoin, or removal is visible even while Membership projections
  lag. Person contact details and role names are projected display data only;
  a participant without available contact details is omitted from recipient
  results. Invalid IDs, missing clubs, and missing groups return an empty list.
  """
  def list_active_members_of_group_authoritatively(club_id, group_id),
    do:
      AuthoritativeMembershipQueries.list_active_members_of_group_authoritatively(
        club_id,
        group_id
      )

  @doc """
  Wait until the Membership read models used by `active_member_of_group?/2`
  have processed every event committed before this call.

  Privacy-sensitive consumers can use this before checking group membership so
  an asynchronous projection cannot briefly preserve access after departure.
  """
  def await_group_access_projections(opts \\ []) when is_list(opts) do
    ProjectionBarrier.await(@group_access_projectors, opts)
  end

  @doc """
  Return whether an email address currently has an active membership in a club.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Invalid club IDs and blank email addresses return `false`.
  """
  def active_member_of_club_by_email?(club_id, email),
    do: MembershipQueries.active_member_of_club_by_email?(club_id, email)

  @doc """
  Fetch a projected club member invitation by typed invitation ID.

  Returns `nil` for missing, invalid, or unknown invitation IDs.
  """
  def get_club_member_invitation(invitation_id), do: InvitationQueries.get(invitation_id)

  @doc """
  Fetch the pending invitation for a club/email pair.

  Email lookup is normalized by trimming whitespace and comparing
  case-insensitively. Accepted invitations and invalid inputs return `nil`.
  """
  def get_pending_club_member_invitation_by_email(club_id, email),
    do: InvitationQueries.get_pending_by_email(club_id, email)

  @doc """
  Fetch a projected club member invitation by plaintext invitation token.

  Invitation tokens are stored only as SHA-256 hashes. Both pending invitations
  and accepted invitations can be found so accepted links can be reopened
  idempotently without creating duplicate memberships.
  """
  def get_club_member_invitation_by_token(token), do: InvitationQueries.get_by_token(token)

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

  defp cast_id(type, id, error) do
    case ID.cast(type, id) do
      {:ok, cast_id} -> {:ok, cast_id}
      :error -> {:error, error}
    end
  end

  defp custom_group_identity_preview(%Club{} = club, name) do
    name_uniqueness_key = GroupName.uniqueness_key(name)

    case Repo.get_by(GroupProjection,
           club_id: club.club_id,
           name_uniqueness_key: name_uniqueness_key
         ) do
      nil ->
        available_custom_group_identity_preview(club, name)

      %GroupProjection{name: existing_name} ->
        {:error, {:group_name_already_defined, existing_name}}
    end
  end

  defp available_custom_group_identity_preview(%Club{} = club, name) do
    club_id = club.club_id

    occupied_email_slugs =
      GroupProjection
      |> where([group], group.club_id == ^club_id)
      |> where([group], not is_nil(group.email_slug))
      |> select([group], group.email_slug)
      |> Repo.all()
      |> MapSet.new()

    unsuffixed_email_slug = CustomGroupSlug.allocate(name, MapSet.new())
    email_slug = CustomGroupSlug.allocate(name, occupied_email_slugs)

    collision_group_name =
      if email_slug == unsuffixed_email_slug do
        nil
      else
        GroupProjection
        |> where([group], group.club_id == ^club_id)
        |> where([group], group.email_slug == ^unsuffixed_email_slug)
        |> select([group], group.name)
        |> Repo.one()
      end

    {:ok,
     %{
       name: name,
       email_slug: email_slug,
       email_address: ClubInboundEmailAddress.address(club, email_slug),
       unsuffixed_email_slug: unsuffixed_email_slug,
       collision_group_name: collision_group_name
     }}
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

  defp prevent_inviting_active_club_member(%InviteClubMember{} = command) do
    if active_member_of_club_by_email?(command.club_id, command.email) do
      {:error, :already_active_member}
    else
      :ok
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

  defp hash_person_email_address_verification_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  defp dispatch_invitation_token_command(command, dispatch_opts) do
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

  defp fetch_optional(attrs, key) when is_atom(key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
  end

  defp timestamp(opts) do
    Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
  end

  defp cast_person_id(person_id) do
    case ID.cast(:person, person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
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
end
