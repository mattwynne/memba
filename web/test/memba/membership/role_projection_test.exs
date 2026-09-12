defmodule Memba.Membership.RoleProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Permissions
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
end
