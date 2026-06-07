defmodule Memba.Membership.MemberRoleAuthorizationTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles

  test "assign_member_role_as_club_member/2 requires club.manage_members" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    create_club!(club_id)
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
             Membership.assign_member_role_as_club_member(attrs, consistency: :strong)

    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %MemberRoleAssigned{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  assigned_by_person_id: ^actor_person_id
                }
              ]
            }} =
             Membership.assign_member_role_as_club_member(
               attrs,
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "remove_member_role_as_club_member/2 requires club.manage_members" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    create_club!(club_id)
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
             Membership.remove_member_role_as_club_member(attrs, consistency: :strong)

    assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %MemberRoleRemoved{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  removed_by_person_id: ^actor_person_id
                }
              ]
            }} =
             Membership.remove_member_role_as_club_member(
               attrs,
               returning: :execution_result,
               consistency: :strong
             )
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
             Membership.assign_member_role_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: missing_membership_id,
                 person_id: target_person_id,
                 role_id: role_id,
                 actor_person_id: actor_person_id
               },
               consistency: :strong
             )
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
               consistency: :strong
             )
  end

  defp create_person!(person_id, name, email) do
    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )
  end

  defp add_member!(membership_id, club_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )
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

  defp assign_membership_administrator!(club_id, membership_id, person_id) do
    assign_role_by_system!(
      club_id,
      membership_id,
      person_id,
      Roles.membership_administrator_role_id(club_id)
    )

    assert Membership.person_has_club_permission?(
             club_id,
             person_id,
             Permissions.club_manage_members()
           )
  end

  defp assign_role_by_system!(club_id, membership_id, person_id, role_id) do
    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )
  end
end
