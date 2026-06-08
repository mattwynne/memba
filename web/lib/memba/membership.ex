defmodule Memba.Membership do
  @moduledoc """
  Public application service and query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.App
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Repo

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
    with {:ok, command} <- replace_person_email_addresses_command(attrs),
         {:ok, email_addresses} <- normalize_command_email_addresses(command),
         :ok <- prevent_duplicate_person_email_addresses(command.person_id, email_addresses) do
      dispatch(command, dispatch_opts)
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
  List active members of the given club for recipient resolution.

  Returns plain maps containing the public identity needed outside the
  Membership context: `:id`, `:name`, and `:email`. Members of other clubs,
  inactive memberships, memberships without a projected person, and invalid club
  IDs are excluded.
  """
  def list_active_members_of_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
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

  defp add_member_command(attrs) do
    with {:ok, membership_id} <- fetch_required(attrs, :membership_id),
         {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, person_id} <- fetch_required(attrs, :person_id) do
      {:ok, %AddMember{membership_id: membership_id, club_id: club_id, person_id: person_id}}
    end
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

  defp fetch_optional(attrs, key) when is_atom(key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
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
end
