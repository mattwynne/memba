defmodule Memba.Membership do
  @moduledoc """
  Public API for the Membership bounded context.
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

  @default_dispatch_opts [consistency: :strong]

  @doc """
  Dispatch a Membership domain command through the Membership context boundary.

  Callers supply aggregate UUIDs on the commands. `AddMember` commands must
  attach an existing person to an existing club, and a second active membership
  for the same `{club_id, person_id}` pair is rejected before the Membership
  aggregate command is dispatched.
  """
  def dispatch(command, opts \\ @default_dispatch_opts)

  def dispatch(%CreateClub{} = command, opts) do
    App.dispatch(command, opts)
  end

  def dispatch(%CreatePerson{} = command, opts) do
    App.dispatch(command, opts)
  end

  def dispatch(%AddMember{} = command, opts) do
    with :ok <- ensure_club_exists(command.club_id),
         :ok <- ensure_person_exists(command.person_id),
         :ok <- ensure_no_active_membership(command.club_id, command.person_id) do
      App.dispatch(command, opts)
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

  defp ensure_club_exists(club_id) do
    if get_club(club_id) do
      :ok
    else
      {:error, :club_not_found}
    end
  end

  defp ensure_person_exists(person_id) do
    if get_person(person_id) do
      :ok
    else
      {:error, :person_not_found}
    end
  end

  defp ensure_no_active_membership(club_id, person_id) do
    if active_member_of_club?(club_id, person_id) do
      {:error, :already_active_member}
    else
      :ok
    end
  end
end
