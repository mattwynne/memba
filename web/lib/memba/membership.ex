defmodule Memba.Membership do
  @moduledoc """
  Public application service and query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
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
  Fetch a projected club read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_club(club_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
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
  Fetch a projected person read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_person(person_id) do
    with {:ok, person_id} <- Ecto.UUID.cast(person_id) do
      Repo.get(Person, person_id)
    else
      :error -> nil
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
  Fetch the primary projected email address for a person.

  Returns `nil` when the person ID is absent, invalid, unknown, or has no
  projected primary email-address row.
  """
  def get_person_primary_email(person_id) do
    with {:ok, person_id} <- Ecto.UUID.cast(person_id) do
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
    with {:ok, person_id} <- Ecto.UUID.cast(person_id) do
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
    with {:ok, person_id} <- Ecto.UUID.cast(person_id) do
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
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
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
      |> select([_membership, person, primary_email_address], %{
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
    with {:ok, club_id} <- Ecto.UUID.cast(club_id),
         {:ok, person_id} <- Ecto.UUID.cast(person_id) do
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
    with {:ok, club_id} <- Ecto.UUID.cast(club_id),
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

  defp prevent_duplicate_active_membership(%AddMember{} = command) do
    if active_member_of_club?(command.club_id, command.person_id) do
      {:error, :already_active_member}
    else
      :ok
    end
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
    case Ecto.UUID.cast(club_id) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :invalid_club_id}
    end
  end

  defp cast_person_id(person_id) do
    case Ecto.UUID.cast(person_id) do
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
