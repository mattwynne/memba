defmodule Memba.Membership.ClubGroupQueries do
  @moduledoc """
  Projected club and conversation-group reads for the Membership context.

  Queries here do not depend on the Membership application service. Public
  callers continue to use `Memba.Membership` as their stable API.
  """

  import Ecto.Query

  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Slug
  alias Memba.Repo

  def get_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      Repo.get(Club, club_id)
    else
      :error -> nil
    end
  end

  def get_club_by_slug(slug) do
    with {:ok, slug} <- Slug.normalize_for_lookup(slug) do
      Repo.get_by(Club, slug: slug)
    else
      {:error, _reason} -> nil
    end
  end

  def get_group(group_id) do
    with {:ok, group_id} <- ID.cast(:group, group_id) do
      GroupProjection
      |> where([group], group.group_id == ^group_id)
      |> select([group], %{
        club_id: group.club_id,
        group_id: group.group_id,
        email_slug: group.email_slug,
        group_key: group.group_key,
        name: group.name
      })
      |> Repo.one()
    else
      :error -> nil
    end
  end

  def get_group_by_email_slug(club_id, email_slug) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, email_slug} <- Slug.normalize_for_lookup(email_slug) do
      GroupProjection
      |> where([group], group.club_id == ^club_id)
      |> where([group], group.email_slug == ^email_slug)
      |> select([group], %{
        club_id: group.club_id,
        group_id: group.group_id,
        email_slug: group.email_slug,
        group_key: group.group_key,
        name: group.name
      })
      |> Repo.one()
    else
      :error -> nil
      {:error, _reason} -> nil
    end
  end

  def list_clubs() do
    Club
    |> order_by([club], asc: club.name, asc: club.club_id)
    |> Repo.all()
  end

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

  def list_active_members_of_group(group_id, opts \\ []) when is_list(opts) do
    with {:ok, group_id} <- ID.cast(:group, group_id) do
      include_without_primary_email? =
        Keyword.get(opts, :include_without_primary_email, false)

      members =
        GroupMembershipProjection
        |> join(:inner, [group_membership], membership in MembershipProjection,
          on:
            membership.membership_id == group_membership.membership_id and
              membership.club_id == group_membership.club_id and
              membership.person_id == group_membership.person_id
        )
        |> join(:inner, [_group_membership, membership], person in Person,
          on: person.person_id == membership.person_id
        )
        |> join(
          :left,
          [_group_membership, _membership, person],
          primary_email_address in PersonEmailAddress,
          on:
            primary_email_address.person_id == person.person_id and
              primary_email_address.is_primary == true
        )
        |> where(
          [group_membership, _membership, _person, _primary_email_address],
          group_membership.group_id == ^group_id
        )
        |> where(
          [group_membership, membership, _person, _primary_email_address],
          group_membership.active == true and membership.active == true
        )
        |> require_primary_email_unless_included(include_without_primary_email?)
        |> order_by([_group_membership, _membership, person, _primary_email_address],
          asc: person.name,
          asc: person.person_id
        )
        |> select([_group_membership, membership, person, primary_email_address], %{
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

  defp require_primary_email_unless_included(query, true), do: query

  defp require_primary_email_unless_included(query, false) do
    where(
      query,
      [_group_membership, _membership, _person, primary_email_address],
      not is_nil(primary_email_address.id)
    )
  end

  def list_discoverable_groups_for_member(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      GroupProjection
      |> join(:inner, [group], membership in MembershipProjection,
        on: membership.club_id == group.club_id
      )
      |> join(:inner, [_group, membership], person in Person,
        on: person.person_id == membership.person_id
      )
      |> where([group, _membership, _person], group.club_id == ^club_id)
      |> where([_group, membership, _person], membership.person_id == ^person_id)
      |> where([_group, membership, _person], membership.active == true)
      |> distinct(true)
      |> order_by([group, _membership, _person], asc: group.name, asc: group.group_id)
      |> select([group, _membership, _person], %{
        club_id: group.club_id,
        group_id: group.group_id,
        group_key: group.group_key,
        name: group.name
      })
      |> Repo.all()
    else
      :error -> []
    end
  end

  def list_active_groups_for_member(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      active_member_counts =
        GroupMembershipProjection
        |> join(:inner, [group_membership], membership in MembershipProjection,
          on:
            membership.membership_id == group_membership.membership_id and
              membership.club_id == group_membership.club_id and
              membership.person_id == group_membership.person_id
        )
        |> join(:inner, [_group_membership, membership], person in Person,
          on: person.person_id == membership.person_id
        )
        |> where(
          [group_membership, membership, _person],
          group_membership.active == true and membership.active == true
        )
        |> group_by([group_membership, _membership, _person], [
          group_membership.club_id,
          group_membership.group_id
        ])
        |> select([group_membership, _membership, _person], %{
          club_id: group_membership.club_id,
          group_id: group_membership.group_id,
          active_member_count: count(group_membership.membership_id)
        })

      groups =
        GroupProjection
        |> join(:inner, [group], club in Club, on: club.club_id == group.club_id)
        |> join(:inner, [group, _club], group_membership in GroupMembershipProjection,
          on:
            group_membership.group_id == group.group_id and
              group_membership.club_id == group.club_id
        )
        |> join(
          :inner,
          [_group, _club, group_membership],
          membership in MembershipProjection,
          on:
            membership.membership_id == group_membership.membership_id and
              membership.club_id == group_membership.club_id and
              membership.person_id == group_membership.person_id
        )
        |> join(:inner, [_group, _club, _group_membership, membership], person in Person,
          on: person.person_id == membership.person_id
        )
        |> join(
          :inner,
          [group, _club, _group_membership, _membership, _person],
          member_count in subquery(active_member_counts),
          on: member_count.club_id == group.club_id and member_count.group_id == group.group_id
        )
        |> where([group, _club, ...], group.club_id == ^club_id)
        |> where(
          [_group, _club, group_membership, _membership, _person, _member_count],
          group_membership.person_id == ^person_id
        )
        |> where(
          [_group, _club, group_membership, membership, _person, _member_count],
          group_membership.active == true and membership.active == true
        )
        |> distinct(true)
        |> order_by([group, _club, ...], asc: group.name, asc: group.group_id)
        |> select([group, club, _group_membership, _membership, _person, member_count], %{
          club_id: group.club_id,
          club_slug: club.slug,
          group_id: group.group_id,
          email_slug: group.email_slug,
          group_key: group.group_key,
          name: group.name,
          active_member_count: member_count.active_member_count
        })
        |> Repo.all()

      Enum.map(groups, fn group ->
        group
        |> Map.put(
          :email_address,
          ClubInboundEmailAddress.address(group.club_slug, group.email_slug)
        )
        |> Map.delete(:club_slug)
      end)
    else
      :error -> []
    end
  end

  @doc false
  def active_role_names_by_membership([]), do: %{}

  def active_role_names_by_membership(membership_ids) do
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
end
