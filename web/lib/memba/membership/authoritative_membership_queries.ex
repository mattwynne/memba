defmodule Memba.Membership.AuthoritativeMembershipQueries do
  @moduledoc """
  Club aggregate-backed membership and group participation reads.

  Aggregate state decides access and participation; projected person contact and
  role information is used only for display and recipient details.
  """

  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership.App
  alias Memba.Membership.Club, as: ClubAggregate
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.SystemGroups
  alias Memba.Repo

  def active_member_of_club_authoritatively?(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         %ClubAggregate{club_id: ^club_id} = club <-
           App.aggregate_state(ClubAggregate, club_id) do
      active_membership_ids_for_person(club, person_id) != []
    else
      _invalid_missing_or_inactive -> false
    end
  end

  def resolve_custom_group_target_authoritatively(club_id, person_id, group_id) do
    with {:ok, club_id} <- cast_id(:club, club_id, :invalid_club_id),
         {:ok, person_id} <- cast_id(:person, person_id, :invalid_person_id),
         {:ok, group_id} <- cast_id(:group, group_id, :invalid_group_id),
         {:ok, club} <- authoritative_club(club_id),
         {:ok, membership_id} <- authoritative_active_membership_id(club, person_id),
         {:ok, group} <- authoritative_custom_group(club, group_id),
         {:ok, person} <- projected_person_display(person_id) do
      {:ok,
       %{
         club: %{
           club_id: club.club_id,
           name: club.name,
           slug: club.slug
         },
         membership: %{
           membership_id: membership_id,
           person_id: person_id
         },
         person: person,
         group: %{
           club_id: club.club_id,
           group_id: group.group_id,
           group_key: group.group_key,
           email_slug: group.email_slug,
           name: group.name
         },
         active_group_member?:
           authoritative_group_member_for_membership?(
             club,
             group_id,
             membership_id,
             person_id
           )
       }}
    end
  end

  def active_member_of_group_authoritatively?(club_id, group_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, group_id} <- ID.cast(:group, group_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         %ClubAggregate{club_id: ^club_id} = club <-
           App.aggregate_state(ClubAggregate, club_id),
         true <- Map.has_key?(club.groups, group_id) do
      authoritative_group_member?(club, group_id, person_id)
    else
      _invalid_missing_or_inactive -> false
    end
  end

  def list_active_groups_for_member_authoritatively(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         %ClubAggregate{club_id: ^club_id} = club <-
           App.aggregate_state(ClubAggregate, club_id) do
      club.groups
      |> Map.values()
      |> Enum.filter(&authoritative_group_member?(club, &1.group_id, person_id))
      |> Enum.map(fn group ->
        group
        |> Map.put(:club_id, club.club_id)
        |> Map.put(
          :active_member_count,
          club |> authoritative_group_memberships(group.group_id) |> Enum.count()
        )
        |> Map.put(:email_address, authoritative_group_email_address(club, group))
      end)
      |> Enum.sort_by(&{&1.name, &1.group_id})
    else
      _invalid_or_missing -> []
    end
  end

  def list_active_members_of_group_authoritatively(club_id, group_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, group_id} <- ID.cast(:group, group_id),
         %ClubAggregate{club_id: ^club_id} = club <-
           App.aggregate_state(ClubAggregate, club_id),
         true <- Map.has_key?(club.groups, group_id) do
      memberships = authoritative_group_memberships(club, group_id)

      contact_summaries =
        memberships |> Enum.map(&elem(&1, 1)) |> PersonQueries.list_person_contact_summaries()

      role_names_by_membership =
        memberships
        |> Enum.map(&elem(&1, 0))
        |> ClubGroupQueries.active_role_names_by_membership()

      memberships
      |> Enum.flat_map(fn {membership_id, person_id} ->
        case Map.get(contact_summaries, person_id) do
          %{name: name, primary_email: email} when is_binary(email) ->
            [
              %{
                membership_id: membership_id,
                id: person_id,
                name: name,
                email: email,
                roles: Map.get(role_names_by_membership, membership_id, [])
              }
            ]

          _missing_contact ->
            []
        end
      end)
      |> Enum.sort_by(&{&1.name, &1.id})
    else
      _invalid_or_missing -> []
    end
  end

  defp authoritative_club(club_id) do
    case App.aggregate_state(ClubAggregate, club_id) do
      %ClubAggregate{club_id: ^club_id} = club -> {:ok, club}
      _missing_club -> {:error, :not_found}
    end
  end

  defp authoritative_active_membership_id(club, person_id) do
    case active_membership_ids_for_person(club, person_id) do
      [] -> {:error, :member_not_active}
      membership_ids -> {:ok, Enum.min(membership_ids)}
    end
  end

  defp authoritative_custom_group(club, group_id) do
    with {:ok, group} <- Map.fetch(club.groups, group_id),
         true <- SystemGroups.custom_group?(%{club_id: club.club_id, group_id: group_id}) do
      {:ok, group}
    else
      :error -> {:error, :group_not_defined}
      false -> {:error, :system_group_not_allowed}
    end
  end

  defp projected_person_display(person_id) do
    case Repo.get(Person, person_id) do
      %Person{name: name} -> {:ok, %{person_id: person_id, name: name}}
      nil -> {:error, :person_not_found}
    end
  end

  defp authoritative_group_email_address(club, %{email_slug: email_slug})
       when is_binary(email_slug) do
    ClubInboundEmailAddress.address(club.slug, email_slug)
  end

  defp authoritative_group_email_address(_club, _group), do: nil

  defp authoritative_group_memberships(club, group_id) do
    club.active_memberships
    |> Enum.filter(fn {membership_id, person_id} ->
      authoritative_group_member_for_membership?(
        club,
        group_id,
        membership_id,
        person_id
      )
    end)
    |> Enum.sort_by(fn {membership_id, person_id} -> {person_id, membership_id} end)
    |> Enum.uniq_by(&elem(&1, 1))
  end

  defp authoritative_group_member_for_membership?(club, group_id, membership_id, person_id) do
    cond do
      group_id == SystemGroups.everyone_group_id(club.club_id) ->
        true

      group_id == SystemGroups.admin_group_id(club.club_id) ->
        MapSet.member?(club.active_admin_membership_ids, membership_id)

      true ->
        case Map.get(club.group_memberships, {group_id, membership_id}) do
          %{person_id: ^person_id, active: true} -> true
          _inactive_or_different_person -> false
        end
    end
  end

  defp authoritative_group_member?(club, group_id, person_id) do
    active_membership_ids = active_membership_ids_for_person(club, person_id)

    cond do
      group_id == SystemGroups.everyone_group_id(club.club_id) ->
        active_membership_ids != []

      group_id == SystemGroups.admin_group_id(club.club_id) ->
        Enum.any?(
          active_membership_ids,
          &MapSet.member?(club.active_admin_membership_ids, &1)
        )

      true ->
        Enum.any?(active_membership_ids, fn membership_id ->
          case Map.get(club.group_memberships, {group_id, membership_id}) do
            %{person_id: ^person_id, active: true} -> true
            _inactive_or_different_person -> false
          end
        end)
    end
  end

  defp active_membership_ids_for_person(club, person_id) do
    Enum.flat_map(club.active_memberships, fn
      {membership_id, ^person_id} -> [membership_id]
      {_membership_id, _other_person_id} -> []
    end)
  end

  defp cast_id(type, id, error) do
    case ID.cast(type, id) do
      {:ok, cast_id} -> {:ok, cast_id}
      :error -> {:error, error}
    end
  end
end
