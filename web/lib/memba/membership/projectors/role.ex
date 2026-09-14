defmodule Memba.Membership.Projectors.Role do
  @moduledoc """
  Projects club role, role permission, role assignment, and flattened member permission read models.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Role",
    consistency: :strong

  import Ecto.Query

  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned, as: LegacyMemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved, as: LegacyMemberRoleRemoved
  alias Memba.Membership.Projections.MemberPermission, as: MemberPermissionProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Projections.RolePermission, as: RolePermissionProjection

  project(%ClubRoleDefined{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :membership_role,
      %RoleProjection{
        club_id: event.club_id,
        role_id: event.role_id,
        role_key: event.role_key,
        name: event.name,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          role_key: event.role_key,
          name: event.name,
          updated_at: now
        ]
      ],
      conflict_target: :role_id
    )
  end)

  project(%ClubRolePermissionGranted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.insert(
      :membership_role_permission,
      %RolePermissionProjection{
        club_id: event.club_id,
        role_id: event.role_id,
        permission: event.permission,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing,
      conflict_target: [:role_id, :permission]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_role_permission, fn repo, _changes ->
      membership_ids = active_membership_ids_for_role(repo, event.club_id, event.role_id)

      Enum.each(membership_ids, fn membership_id ->
        reconcile_member_permissions_for_membership(repo, membership_id)
      end)

      {:ok, membership_ids}
    end)
  end)

  project(%ClubRoleAssignedToMember{} = event, fn multi ->
    project_role_assigned_to_member(multi, event)
  end)

  project(%LegacyMemberRoleAssigned{} = event, fn multi ->
    project_role_assigned_to_member(multi, event)
  end)

  project(%ClubRoleRemovedFromMember{} = event, fn multi ->
    project_role_removed_from_member(multi, event)
  end)

  project(%LegacyMemberRoleRemoved{} = event, fn multi ->
    project_role_removed_from_member(multi, event)
  end)

  project(%ClubMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  project(%LegacyMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  defp project_role_assigned_to_member(multi, event) do
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.insert(
      :membership_role_assignment,
      %RoleAssignmentProjection{
        club_id: event.club_id,
        membership_id: event.membership_id,
        person_id: event.person_id,
        role_id: event.role_id,
        active: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          person_id: event.person_id,
          active: true,
          updated_at: now
        ]
      ],
      conflict_target: [:membership_id, :role_id]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_role_assignment, fn repo, _changes ->
      {:ok, reconcile_member_permissions_for_membership(repo, event.membership_id)}
    end)
  end

  defp project_role_removed_from_member(multi, event) do
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      :membership_role_assignment,
      role_assignment_query(event.membership_id, event.role_id),
      set: [active: false, updated_at: now]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_removed_role_assignment, fn repo,
                                                                                      _changes ->
      {:ok, reconcile_member_permissions_for_membership(repo, event.membership_id)}
    end)
  end

  defp project_member_removed(multi, event) do
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      :membership_role_assignments,
      membership_role_assignments_query(event.membership_id),
      set: [active: false, updated_at: now]
    )
    |> Ecto.Multi.delete_all(
      :membership_member_permissions,
      member_permissions_by_membership_query(event.membership_id)
    )
  end

  defp active_membership_ids_for_role(repo, club_id, role_id) do
    repo.all(
      from(assignment in RoleAssignmentProjection,
        where: assignment.club_id == ^club_id,
        where: assignment.role_id == ^role_id,
        where: assignment.active == true,
        distinct: true,
        select: assignment.membership_id
      )
    )
  end

  defp reconcile_member_permissions_for_membership(repo, membership_id) do
    now = DateTime.utc_now(:microsecond)
    existing_inserted_at = existing_member_permission_inserted_at_by_identity(repo, membership_id)

    rows =
      membership_id
      |> member_permission_counts_for_membership_query()
      |> repo.all()
      |> Enum.map(fn row ->
        row
        |> Map.put(:inserted_at, existing_inserted_at_for(row, existing_inserted_at, now))
        |> Map.put(:updated_at, now)
      end)

    repo.delete_all(member_permissions_by_membership_query(membership_id))

    if rows != [] do
      repo.insert_all(
        MemberPermissionProjection,
        rows,
        on_conflict: {:replace, [:grant_count, :updated_at]},
        conflict_target: [:club_id, :person_id, :membership_id, :permission]
      )
    end

    rows
  end

  defp member_permission_counts_for_membership_query(membership_id) do
    from(assignment in RoleAssignmentProjection,
      join: permission in RolePermissionProjection,
      on:
        permission.club_id == assignment.club_id and
          permission.role_id == assignment.role_id,
      where: assignment.membership_id == ^membership_id,
      where: assignment.active == true,
      group_by: [
        assignment.club_id,
        assignment.membership_id,
        assignment.person_id,
        permission.permission
      ],
      order_by: [asc: permission.permission],
      select: %{
        club_id: assignment.club_id,
        membership_id: assignment.membership_id,
        person_id: assignment.person_id,
        permission: permission.permission,
        grant_count: count(assignment.role_id, :distinct)
      }
    )
  end

  defp existing_member_permission_inserted_at_by_identity(repo, membership_id) do
    repo.all(
      from(member_permission in MemberPermissionProjection,
        where: member_permission.membership_id == ^membership_id,
        select: {
          member_permission.club_id,
          member_permission.person_id,
          member_permission.membership_id,
          member_permission.permission,
          member_permission.inserted_at
        }
      )
    )
    |> Map.new(fn {club_id, person_id, membership_id, permission, inserted_at} ->
      {{club_id, person_id, membership_id, permission}, inserted_at}
    end)
  end

  defp existing_inserted_at_for(row, existing_inserted_at, default) do
    Map.get(
      existing_inserted_at,
      {row.club_id, row.person_id, row.membership_id, row.permission},
      default
    )
  end

  defp role_assignment_query(membership_id, role_id) do
    from(assignment in RoleAssignmentProjection,
      where: assignment.membership_id == ^membership_id,
      where: assignment.role_id == ^role_id
    )
  end

  defp membership_role_assignments_query(membership_id) do
    from(assignment in RoleAssignmentProjection,
      where: assignment.membership_id == ^membership_id
    )
  end

  defp member_permissions_by_membership_query(membership_id) do
    from(member_permission in MemberPermissionProjection,
      where: member_permission.membership_id == ^membership_id
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
