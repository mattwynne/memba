defmodule Memba.Membership.RoleProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projectors.Role
  alias Memba.Membership.Projections.MemberPermission, as: MemberPermissionProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Projections.RolePermission, as: RolePermissionProjection
  alias Memba.Membership.Roles

  test "CreateClub projects the default Admin role and permission grant" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    assert %RoleProjection{
             role_id: ^role_id,
             club_id: ^club_id,
             role_key: "admin",
             name: "Admin"
           } = Repo.get(RoleProjection, role_id)

    assert %RolePermissionProjection{
             club_id: ^club_id,
             role_id: ^role_id,
             permission: "club.manage_members"
           } = role_permission(role_id, Permissions.club_manage_members())

    assert [] = Repo.all(MemberPermissionProjection)
  end

  test "role assignment projects active assignments and flattened member permissions" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(membership_id, club_id, person_id)

    assert %RoleAssignmentProjection{
             club_id: ^club_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             role_id: ^role_id,
             active: true
           } = role_assignment(membership_id, role_id)

    assert %MemberPermissionProjection{
             club_id: ^club_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             permission: "club.manage_members",
             grant_count: 1
           } =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
  end

  test "granting a permission projects flattened member permissions for active assignments" do
    club_id = Memba.ID.generate(:club)
    role_id = Memba.ID.generate(:role)
    bootstrap_membership_id = Memba.ID.generate(:membership)
    bootstrap_person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(bootstrap_membership_id, club_id, bootstrap_person_id)
    add_member!(membership_id, club_id, person_id)
    define_role!(club_id, role_id)
    assign_role!(club_id, membership_id, person_id, role_id)

    refute member_permission(
             club_id,
             person_id,
             membership_id,
             Permissions.club_manage_members()
           )

    grant_manage_members!(club_id, role_id)

    assert %MemberPermissionProjection{
             club_id: ^club_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             permission: "club.manage_members",
             grant_count: 1
           } =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
  end

  test "equivalent Admin permission and assignment events do not inflate a repaired flattened grant" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    insert_role_projection!(club_id, role_id, role_key: "admin", name: "Admin")
    insert_role_permission_projection!(club_id, role_id, Permissions.club_manage_members())
    insert_role_assignment_projection!(club_id, membership_id, person_id, role_id)

    seeded_member_permission =
      insert_member_permission_projection!(
        club_id,
        membership_id,
        person_id,
        Permissions.club_manage_members(),
        1
      )

    seeded_inserted_at = seeded_member_permission.inserted_at

    append_role_events!(club_id, [
      %ClubCreated{
        club_id: club_id,
        name: "Kootenay Mountaineering Club",
        slug: "kmc"
      },
      %ClubMemberAdded{
        membership_id: membership_id,
        club_id: club_id,
        person_id: person_id
      },
      %ClubRoleDefined{
        club_id: club_id,
        role_id: role_id,
        role_key: "admin",
        name: "Admin"
      },
      %ClubRolePermissionGranted{
        club_id: club_id,
        role_id: role_id,
        permission: Permissions.club_manage_members()
      },
      %ClubRoleAssignedToMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: role_id
      }
    ])

    assert %MemberPermissionProjection{grant_count: 1, inserted_at: ^seeded_inserted_at} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
  end

  test "equivalent assignment events remove stale flattened rows when person identity is corrected" do
    club_id = Memba.ID.generate(:club)
    role_id = Memba.ID.generate(:role)
    membership_id = Memba.ID.generate(:membership)
    old_person_id = Memba.ID.generate(:person)
    corrected_person_id = Memba.ID.generate(:person)

    insert_role_projection!(club_id, role_id,
      role_key: "custom_membership_manager",
      name: "Custom Membership Manager"
    )

    insert_role_permission_projection!(club_id, role_id, Permissions.club_manage_members())
    insert_role_assignment_projection!(club_id, membership_id, old_person_id, role_id)

    insert_member_permission_projection!(
      club_id,
      membership_id,
      old_person_id,
      Permissions.club_manage_members(),
      1
    )

    append_role_events!("#{club_id}-corrected-role-assignment", [
      %ClubRoleAssignedToMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: corrected_person_id,
        role_id: role_id
      }
    ])

    assert is_nil(
             member_permission(
               club_id,
               old_person_id,
               membership_id,
               Permissions.club_manage_members()
             )
           )

    assert %RoleAssignmentProjection{
             club_id: ^club_id,
             person_id: ^corrected_person_id,
             active: true
           } = role_assignment(membership_id, role_id)

    assert [
             %MemberPermissionProjection{
               club_id: ^club_id,
               person_id: ^corrected_person_id,
               permission: "club.manage_members",
               grant_count: 1
             }
           ] = member_permissions_for_membership(membership_id)
  end

  test "mismatched assignment and permission club identities do not flatten a grant" do
    permission_club_id = Memba.ID.generate(:club)
    assignment_club_id = Memba.ID.generate(:club)
    role_id = Memba.ID.generate(:role)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    insert_role_projection!(permission_club_id, role_id,
      role_key: "custom_membership_manager",
      name: "Custom Membership Manager"
    )

    insert_role_permission_projection!(permission_club_id, role_id, Permissions.club_manage_members())
    insert_role_assignment_projection!(assignment_club_id, membership_id, person_id, role_id)

    append_role_events!("#{assignment_club_id}-mismatched-role-assignment-club", [
      %ClubRoleAssignedToMember{
        club_id: assignment_club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: role_id
      }
    ])

    assert %RoleAssignmentProjection{
             club_id: ^assignment_club_id,
             person_id: ^person_id,
             active: true
           } = role_assignment(membership_id, role_id)

    assert [] = member_permissions_for_membership(membership_id)
  end

  test "flattened member permissions reconcile exact counts through replay and removals" do
    club_id = Memba.ID.generate(:club)
    admin_role_id = Roles.membership_administrator_role_id(club_id)
    custom_role_id = Memba.ID.generate(:role)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(membership_id, club_id, person_id)
    define_role!(club_id, custom_role_id)
    grant_manage_members!(club_id, custom_role_id)
    assign_role!(club_id, membership_id, person_id, custom_role_id)

    assert %MemberPermissionProjection{grant_count: 2} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )

    append_role_events!("#{club_id}-equivalent-custom-role-events", [
      %ClubRolePermissionGranted{
        club_id: club_id,
        role_id: custom_role_id,
        permission: Permissions.club_manage_members()
      },
      %ClubRoleAssignedToMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: custom_role_id
      }
    ])

    assert %MemberPermissionProjection{grant_count: 2} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )

    append_role_events!("#{club_id}-remove-custom-role", [
      %ClubRoleRemovedFromMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: custom_role_id
      }
    ])

    assert %RoleAssignmentProjection{active: false} =
             role_assignment(membership_id, custom_role_id)

    assert %MemberPermissionProjection{grant_count: 1} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )

    append_role_events!("#{club_id}-remove-admin-role", [
      %ClubRoleRemovedFromMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: admin_role_id
      }
    ])

    assert %RoleAssignmentProjection{active: false} =
             role_assignment(membership_id, admin_role_id)

    assert is_nil(
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
           )
  end

  test "removing a role assignment deactivates it and removes its flattened permission" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    replacement_membership_id = Memba.ID.generate(:membership)
    replacement_person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(membership_id, club_id, person_id)
    add_member!(replacement_membership_id, club_id, replacement_person_id)
    assign_role!(club_id, replacement_membership_id, replacement_person_id, role_id)

    assert :ok =
             App.dispatch(
               %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    assert %RoleAssignmentProjection{active: false} = role_assignment(membership_id, role_id)

    assert is_nil(
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
           )
  end

  test "flattened member permissions keep a grant count across multiple assigned roles" do
    club_id = Memba.ID.generate(:club)
    custom_role_id = Memba.ID.generate(:role)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(membership_id, club_id, person_id)
    define_role!(club_id, custom_role_id)
    grant_manage_members!(club_id, custom_role_id)

    assign_role!(club_id, membership_id, person_id, custom_role_id)

    assert %MemberPermissionProjection{grant_count: 2} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )

    assert :ok =
             App.dispatch(
               %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: custom_role_id
               },
               consistency: :strong
             )

    assert %RoleAssignmentProjection{active: false} =
             role_assignment(membership_id, custom_role_id)

    assert %MemberPermissionProjection{grant_count: 1} =
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
  end

  test "removing a member deactivates role assignments and removes flattened permissions" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    replacement_membership_id = Memba.ID.generate(:membership)
    replacement_person_id = Memba.ID.generate(:person)

    create_club!(club_id)
    add_member!(membership_id, club_id, person_id)
    add_member!(replacement_membership_id, club_id, replacement_person_id)
    assign_role!(club_id, replacement_membership_id, replacement_person_id, role_id)

    assert :ok =
             App.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %RoleAssignmentProjection{active: false} = role_assignment(membership_id, role_id)

    assert is_nil(
             member_permission(
               club_id,
               person_id,
               membership_id,
               Permissions.club_manage_members()
             )
           )
  end

  defp append_role_events!(stream_id, events) do
    event_data = Enum.map(events, &Mapper.map_to_event_data/1)

    assert :ok = Commanded.EventStore.append_to_stream(App, stream_id, 0, event_data)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!([Role], checkpoint: checkpoint)
  end

  defp insert_role_projection!(club_id, role_id, attrs) do
    Repo.insert!(%RoleProjection{
      club_id: club_id,
      role_id: role_id,
      role_key: Keyword.get(attrs, :role_key),
      name: Keyword.fetch!(attrs, :name)
    })
  end

  defp insert_role_permission_projection!(club_id, role_id, permission) do
    Repo.insert!(%RolePermissionProjection{
      club_id: club_id,
      role_id: role_id,
      permission: permission
    })
  end

  defp insert_role_assignment_projection!(club_id, membership_id, person_id, role_id) do
    Repo.insert!(%RoleAssignmentProjection{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: role_id,
      active: true
    })
  end

  defp insert_member_permission_projection!(
         club_id,
         membership_id,
         person_id,
         permission,
         grant_count
       ) do
    Repo.insert!(%MemberPermissionProjection{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      permission: permission,
      grant_count: grant_count
    })
  end

  defp create_club!(club_id) do
    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )
  end

  defp add_member!(membership_id, club_id, person_id) do
    assert :ok =
             App.dispatch(
               %AddClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp define_role!(club_id, role_id) do
    assert :ok =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: "custom_membership_manager",
                 name: "Custom Membership Manager"
               },
               consistency: :strong
             )
  end

  defp grant_manage_members!(club_id, role_id) do
    assert :ok =
             App.dispatch(
               %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: role_id,
                 permission: Permissions.club_manage_members()
               },
               consistency: :strong
             )
  end

  defp assign_role!(club_id, membership_id, person_id, role_id) do
    case App.dispatch(
           %AssignClubRoleToMember{
             club_id: club_id,
             membership_id: membership_id,
             person_id: person_id,
             role_id: role_id
           },
           consistency: :strong
         ) do
      :ok -> :ok
      {:error, :role_already_assigned} -> :ok
      other -> flunk("expected role assignment to succeed, got #{inspect(other)}")
    end
  end

  defp role_permission(role_id, permission) do
    Repo.one(
      from(role_permission in RolePermissionProjection,
        where: role_permission.role_id == ^role_id,
        where: role_permission.permission == ^permission
      )
    )
  end

  defp role_assignment(membership_id, role_id) do
    Repo.one(
      from(assignment in RoleAssignmentProjection,
        where: assignment.membership_id == ^membership_id,
        where: assignment.role_id == ^role_id
      )
    )
  end

  defp member_permission(club_id, person_id, membership_id, permission) do
    Repo.one(
      from(member_permission in MemberPermissionProjection,
        where: member_permission.club_id == ^club_id,
        where: member_permission.person_id == ^person_id,
        where: member_permission.membership_id == ^membership_id,
        where: member_permission.permission == ^permission
      )
    )
  end

  defp member_permissions_for_membership(membership_id) do
    Repo.all(
      from(member_permission in MemberPermissionProjection,
        where: member_permission.membership_id == ^membership_id,
        order_by: [asc: member_permission.permission]
      )
    )
  end
end
