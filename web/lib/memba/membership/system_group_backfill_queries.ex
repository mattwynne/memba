defmodule Memba.Membership.SystemGroupBackfillQueries do
  @moduledoc "Read-only, keyset-paged source projection queries for system-group backfill."

  import Ecto.Query

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Repo

  def list_system_group_definition_backfill_page(cursor \\ nil, limit \\ 1_000) do
    clubs =
      Club
      |> after_backfill_cursor(:club_id, cursor)
      |> order_by([club], asc: club.club_id)
      |> limit(^normalize_backfill_page_size(limit))
      |> select([club], %{club_id: club.club_id})
      |> Repo.all()

    group_definitions = Enum.flat_map(clubs, &system_group_definitions(&1.club_id))

    existing_email_slugs =
      existing_group_email_slugs(Enum.map(group_definitions, & &1.group_id))

    %{
      entries:
        Enum.reject(group_definitions, fn definition ->
          Map.get(existing_email_slugs, definition.group_id) == definition.email_slug
        end),
      next_cursor: backfill_next_cursor(clubs, :club_id),
      source_count: length(clubs)
    }
  end

  @doc """
  Return one keyset page of active memberships missing active Everyone membership.

  The page scans active projected club memberships in ascending `membership_id`
  order and returns plain maps suitable for an idempotent `AddGroupMember`
  command. `cursor` is the last scanned `membership_id` from a previous page.
  """
  def list_everyone_group_membership_backfill_page(cursor \\ nil, limit \\ 1_000) do
    memberships =
      MembershipProjection
      |> where([membership], membership.active == true)
      |> after_backfill_cursor(:membership_id, cursor)
      |> order_by([membership], asc: membership.membership_id)
      |> limit(^normalize_backfill_page_size(limit))
      |> select([membership], %{
        club_id: membership.club_id,
        membership_id: membership.membership_id,
        person_id: membership.person_id
      })
      |> Repo.all()

    entries =
      memberships
      |> Enum.map(fn membership ->
        Map.put(membership, :group_id, SystemGroups.everyone_group_id(membership.club_id))
      end)
      |> reject_active_group_memberships()

    %{
      entries: entries,
      next_cursor: backfill_next_cursor(memberships, :membership_id),
      source_count: length(memberships)
    }
  end

  @doc """
  Return one keyset page of active Admin-role memberships missing active Admin-group membership.

  The page scans active projected Admin role assignments for active projected club
  memberships in ascending `membership_id` order and returns plain maps suitable
  for an idempotent `AddGroupMember` command.
  """
  def list_admin_group_membership_backfill_page(cursor \\ nil, limit \\ 1_000) do
    assignments =
      RoleAssignment
      |> join(:inner, [assignment], role in RoleProjection,
        on: role.club_id == assignment.club_id and role.role_id == assignment.role_id
      )
      |> join(:inner, [assignment, _role], membership in MembershipProjection,
        on:
          membership.club_id == assignment.club_id and
            membership.membership_id == assignment.membership_id and
            membership.person_id == assignment.person_id
      )
      |> where(
        [assignment, _role, membership],
        assignment.active == true and membership.active == true
      )
      |> where(
        [_assignment, role, _membership],
        role.role_key == ^Roles.membership_administrator_key()
      )
      |> after_backfill_cursor(:membership_id, cursor)
      |> order_by([assignment, _role, _membership], asc: assignment.membership_id)
      |> limit(^normalize_backfill_page_size(limit))
      |> select([assignment, _role, _membership], %{
        club_id: assignment.club_id,
        membership_id: assignment.membership_id,
        person_id: assignment.person_id
      })
      |> Repo.all()

    entries =
      assignments
      |> Enum.map(fn assignment ->
        Map.put(assignment, :group_id, SystemGroups.admin_group_id(assignment.club_id))
      end)
      |> reject_active_group_memberships()

    %{
      entries: entries,
      next_cursor: backfill_next_cursor(assignments, :membership_id),
      source_count: length(assignments)
    }
  end

  defp system_group_definitions(club_id) do
    [
      %{
        club_id: club_id,
        group_id: SystemGroups.everyone_group_id(club_id),
        email_slug: SystemGroups.everyone_email_slug(),
        group_key: SystemGroups.everyone_key(),
        name: SystemGroups.everyone_name()
      },
      %{
        club_id: club_id,
        group_id: SystemGroups.admin_group_id(club_id),
        email_slug: SystemGroups.admin_email_slug(),
        group_key: SystemGroups.admin_key(),
        name: SystemGroups.admin_name()
      }
    ]
  end

  defp existing_group_email_slugs([]), do: %{}

  defp existing_group_email_slugs(group_ids) do
    GroupProjection
    |> where([group], group.group_id in ^group_ids)
    |> select([group], {group.group_id, group.email_slug})
    |> Repo.all()
    |> Map.new()
  end

  defp reject_active_group_memberships([]), do: []

  defp reject_active_group_memberships(entries) do
    group_ids = Enum.map(entries, & &1.group_id)
    membership_ids = Enum.map(entries, & &1.membership_id)

    existing_active_memberships =
      GroupMembershipProjection
      |> where([group_membership], group_membership.group_id in ^group_ids)
      |> where([group_membership], group_membership.membership_id in ^membership_ids)
      |> where([group_membership], group_membership.active == true)
      |> select([group_membership], {group_membership.group_id, group_membership.membership_id})
      |> Repo.all()
      |> MapSet.new()

    Enum.reject(entries, fn entry ->
      MapSet.member?(existing_active_memberships, {entry.group_id, entry.membership_id})
    end)
  end

  defp after_backfill_cursor(query, _field, nil), do: query
  defp after_backfill_cursor(query, _field, ""), do: query

  defp after_backfill_cursor(query, field, cursor) when is_binary(cursor) do
    where(query, [row], field(row, ^field) > ^cursor)
  end

  defp normalize_backfill_page_size(limit) when is_integer(limit) and limit > 0, do: limit
  defp normalize_backfill_page_size(_limit), do: 1_000

  defp backfill_next_cursor([], _field), do: nil

  defp backfill_next_cursor(rows, field) do
    rows
    |> List.last()
    |> Map.fetch!(field)
  end
end
