defmodule Memba.Membership.MemberRoleAuthorizationTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.SystemGroups

  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.ClubMember
  alias Memba.Membership.CommandDispatch, as: MembershipCommandDispatch
  alias Memba.Membership.PersonCommands

  alias Memba.Membership.PermissionQueries
  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles

  test "assign_membership_administrator_as_club_member/2 lets a member with club.manage_members make another active member an administrator" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    membership_administrator_role_id = Roles.membership_administrator_role_id(club_id)

    create_club!(club_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)
    create_person!(target_person_id, "Alice", "alice@example.com")
    add_member!(target_membership_id, club_id, target_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %ClubRoleAssignedToMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^membership_administrator_role_id,
                  assigned_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_assign_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    assert PermissionQueries.has_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )
  end

  test "remove_membership_administrator_as_club_member/2 lets an administrator revoke another administrator when one remains" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    membership_administrator_role_id = Roles.membership_administrator_role_id(club_id)

    create_club!(club_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)
    create_person!(target_person_id, "Alice", "alice@example.com")
    add_member!(target_membership_id, club_id, target_person_id)
    assign_membership_administrator!(club_id, target_membership_id, target_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %ClubRoleRemovedFromMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^membership_administrator_role_id,
                  removed_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    refute PermissionQueries.has_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )

    assert PermissionQueries.has_permission?(
             club_id,
             actor_person_id,
             Permissions.club_manage_members()
           )
  end

  test "remove_membership_administrator_as_club_member/2 does not revoke the last administrator" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

    assert {:error, :last_membership_administrator} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: actor_membership_id,
                       person_id: actor_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert PermissionQueries.has_permission?(
             club_id,
             actor_person_id,
             Permissions.club_manage_members()
           )
  end

  test "last-administrator invariant is enforced even when the actor has permission through another role" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    custom_role_id = Memba.ID.generate(:role)

    create_club!(club_id)
    create_person!(target_person_id, "Robin", "robin@example.com")
    add_member!(target_membership_id, club_id, target_person_id)
    create_person!(actor_person_id, "Alice", "alice@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)

    define_role!(club_id, custom_role_id)
    grant_manage_members!(club_id, custom_role_id)
    assign_role_by_system!(club_id, actor_membership_id, actor_person_id, custom_role_id)

    assert PermissionQueries.has_permission?(
             club_id,
             actor_person_id,
             Permissions.club_manage_members()
           )

    assert {:error, :last_membership_administrator} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert PermissionQueries.has_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )
  end

  test "assign_membership_administrator_as_club_member/2 rejects ordinary members without club.manage_members" do
    club_id = Memba.ID.generate(:club)
    administrator_person_id = Memba.ID.generate(:person)
    administrator_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_person!(administrator_person_id, "Robin", "robin@example.com")
    add_member!(administrator_membership_id, club_id, administrator_person_id)

    assign_membership_administrator!(
      club_id,
      administrator_membership_id,
      administrator_person_id
    )

    create_person!(actor_person_id, "Alice", "alice@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    create_person!(target_person_id, "Bob", "bob@example.com")
    add_member!(target_membership_id, club_id, target_person_id)

    refute PermissionQueries.has_permission?(
             club_id,
             actor_person_id,
             Permissions.club_manage_members()
           )

    assert {:error, :unauthorized} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_assign_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    refute PermissionQueries.has_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )
  end

  test "remove_membership_administrator_as_club_member/2 rejects ordinary members without club.manage_members" do
    club_id = Memba.ID.generate(:club)
    administrator_person_id = Memba.ID.generate(:person)
    administrator_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_person!(administrator_person_id, "Robin", "robin@example.com")
    add_member!(administrator_membership_id, club_id, administrator_person_id)

    assign_membership_administrator!(
      club_id,
      administrator_membership_id,
      administrator_person_id
    )

    create_person!(actor_person_id, "Alice", "alice@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    create_person!(target_person_id, "Bob", "bob@example.com")
    add_member!(target_membership_id, club_id, target_person_id)
    assign_membership_administrator!(club_id, target_membership_id, target_person_id)

    refute PermissionQueries.has_permission?(
             club_id,
             actor_person_id,
             Permissions.club_manage_members()
           )

    assert {:error, :unauthorized} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert PermissionQueries.has_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )
  end

  test "assign_member_role_as_club_member/2 requires club.manage_members" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    administrator_person_id = Memba.ID.generate(:person)
    administrator_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_person!(administrator_person_id, "Admin", "admin@example.com")
    add_member!(administrator_membership_id, club_id, administrator_person_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    create_person!(target_person_id, "Alice", "alice@example.com")
    add_member!(target_membership_id, club_id, target_person_id)
    define_role!(club_id, role_id)

    attrs = %{
      club_id: club_id,
      membership_id: target_membership_id,
      person_id: target_person_id,
      role_id: role_id,
      actor_person_id: actor_person_id
    }

    assert {:error, :unauthorized} =
             (with {:ok, command} <- ClubMember.Role.prepare_assign(attrs) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %ClubRoleAssignedToMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  assigned_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <- ClubMember.Role.prepare_assign(attrs) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)
  end

  test "remove_member_role_as_club_member/2 requires club.manage_members" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    administrator_person_id = Memba.ID.generate(:person)
    administrator_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_person!(administrator_person_id, "Admin", "admin@example.com")
    add_member!(administrator_membership_id, club_id, administrator_person_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    create_person!(target_person_id, "Alice", "alice@example.com")
    add_member!(target_membership_id, club_id, target_person_id)
    define_role!(club_id, role_id)
    assign_role_by_system!(club_id, target_membership_id, target_person_id, role_id)

    attrs = %{
      club_id: club_id,
      membership_id: target_membership_id,
      person_id: target_person_id,
      role_id: role_id,
      actor_person_id: actor_person_id
    }

    assert {:error, :unauthorized} =
             (with {:ok, command} <- ClubMember.Role.prepare_remove(attrs) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %ClubRoleRemovedFromMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  removed_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <- ClubMember.Role.prepare_remove(attrs) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)
  end

  test "club-member role assignment requires the target to be an active member" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    missing_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    create_club!(club_id)
    create_person!(actor_person_id, "Robin", "robin@example.com")
    add_member!(actor_membership_id, club_id, actor_person_id)
    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)
    create_person!(target_person_id, "Alice", "alice@example.com")
    define_role!(club_id, role_id)

    assert {:error, :member_not_active} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_assign(%{
                       club_id: club_id,
                       membership_id: missing_membership_id,
                       person_id: target_person_id,
                       role_id: role_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp create_club!(club_id) do
    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp create_person!(person_id, name, email) do
    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: name,
                       email: email
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp add_member!(membership_id, club_id, person_id) do
    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: membership_id,
                       club_id: club_id,
                       person_id: person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp define_role!(club_id, role_id) do
    assert :ok =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: nil,
                 name: "Roster Helper"
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

  defp assign_membership_administrator!(club_id, membership_id, person_id) do
    assign_role_by_system!(
      club_id,
      membership_id,
      person_id,
      Roles.membership_administrator_role_id(club_id)
    )

    assert PermissionQueries.has_permission?(
             club_id,
             person_id,
             Permissions.club_manage_members()
           )
  end

  defp assign_role_by_system!(club_id, membership_id, person_id, role_id) do
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

  test "member and Admin role command dispatch waits for system group membership projection by default" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: actor_person_id,
                       name: "Alice",
                       email: "alice@example.com"
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: target_person_id,
                       name: "Bob",
                       email: "bob@example.com"
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: actor_membership_id,
                       club_id: club_id,
                       person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command)
              end)

    assert %GroupMembershipProjection{
             active: true,
             club_id: ^club_id,
             group_id: ^everyone_group_id,
             membership_id: ^actor_membership_id,
             person_id: ^actor_person_id
           } = group_membership(everyone_group_id, actor_membership_id)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: target_membership_id,
                       club_id: club_id,
                       person_id: target_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command)
              end)

    assert %GroupMembershipProjection{
             active: true,
             club_id: ^club_id,
             group_id: ^everyone_group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id
           } = group_membership(everyone_group_id, target_membership_id)

    assert :ok =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_assign_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command)
              end)

    assert %GroupMembershipProjection{
             active: true,
             club_id: ^club_id,
             group_id: ^admin_group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id
           } = group_membership(admin_group_id, target_membership_id)

    assert :ok =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command)
              end)

    assert %GroupMembershipProjection{
             active: false,
             club_id: ^club_id,
             group_id: ^admin_group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id
           } = group_membership(admin_group_id, target_membership_id)

    assert :ok =
             (with {:ok, command} <-
                     ClubMember.Remove.prepare(%{membership_id: target_membership_id}) do
                MembershipCommandDispatch.dispatch(command)
              end)

    assert %GroupMembershipProjection{
             active: false,
             club_id: ^club_id,
             group_id: ^everyone_group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id
           } = group_membership(everyone_group_id, target_membership_id)
  end

  defp group_membership(group_id, membership_id) do
    Repo.one(
      from(group_membership in GroupMembershipProjection,
        where: group_membership.group_id == ^group_id,
        where: group_membership.membership_id == ^membership_id
      )
    )
  end
end
