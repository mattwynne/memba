defmodule Memba.Membership do
  @moduledoc """
  Public application service and query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Repo

  @doc """
  Create a club through the Membership Commanded application.

  The caller supplies the club aggregate identity as `:club_id` or
  `"club_id"`.
  """
  def create_club(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- create_club_command(attrs) do
      dispatch(command, dispatch_opts)
    end
  end

  @doc """
  Create a person through the Membership Commanded application.

  The caller supplies the person aggregate identity as `:person_id` or
  `"person_id"`.
  """
  def create_person(attrs, dispatch_opts \\ []) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- create_person_command(attrs) do
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
      |> where([membership, _person], membership.club_id == ^club_id)
      |> where([membership, _person], membership.active == true)
      |> order_by([_membership, person], asc: person.name, asc: person.person_id)
      |> select([_membership, person], %{
        id: person.person_id,
        name: person.name,
        email: person.email
      })
      |> Repo.all()
    else
      :error -> []
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

  defp create_club_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, name} <- fetch_required(attrs, :name) do
      {:ok, %CreateClub{club_id: club_id, name: name}}
    end
  end

  defp create_person_command(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, email} <- fetch_required(attrs, :email) do
      {:ok, %CreatePerson{person_id: person_id, name: name, email: email}}
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
end
