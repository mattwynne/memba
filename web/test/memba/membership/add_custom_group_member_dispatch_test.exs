defmodule Memba.Membership.AddCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "add_custom_group_member/2 lets an active custom-group member admit an active club member" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    creator_person_id = Memba.ID.generate(:person)
    creator_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, creator_membership_id, creator_person_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: creator_person_id,
                 name: "Board"
               },
               consistency: :strong
             )

    add_group_member!(club_id, group_id, actor_membership_id, actor_person_id)

    assert %AddCustomGroupMember{
             club_id: ^club_id,
             group_id: ^group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id,
             actor_person_id: ^actor_person_id
           } =
             struct!(AddCustomGroupMember, %{
               club_id: club_id,
               group_id: group_id,
               membership_id: target_membership_id,
               person_id: target_person_id,
               actor_person_id: actor_person_id
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %GroupMemberAdded{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id
                }
              ]
            }} =
             Membership.add_custom_group_member(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id,
                 actor_person_id: actor_person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "add_custom_group_member/2 lets an active Admin outside the group admit another member without joining" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    creator_person_id = Memba.ID.generate(:person)
    creator_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, creator_membership_id, creator_person_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)
    create_custom_group!(club_id, group_id, creator_person_id)
    assign_admin!(club_id, actor_membership_id, actor_person_id)

    refute Membership.active_member_of_group?(group_id, actor_person_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %GroupMemberAdded{
                  group_id: ^group_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id
                }
              ]
            }} =
             add_custom_group_member(
               club_id,
               group_id,
               target_membership_id,
               target_person_id,
               actor_person_id,
               returning: :execution_result
             )

    refute Membership.active_member_of_group?(group_id, actor_person_id)
    assert Membership.active_member_of_group?(group_id, target_person_id)
  end

  test "add_custom_group_member/2 rejects forged and unauthorized actor identities" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    creator_person_id = Memba.ID.generate(:person)
    creator_membership_id = Memba.ID.generate(:membership)
    outsider_person_id = Memba.ID.generate(:person)
    outsider_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, creator_membership_id, creator_person_id)
    create_member!(club_id, outsider_membership_id, outsider_person_id)
    create_member!(club_id, target_membership_id, target_person_id)
    create_custom_group!(club_id, group_id, creator_person_id)

    for unauthorized_actor_person_id <- [
          Memba.ID.generate(:person),
          outsider_person_id
        ] do
      assert {:error, :unauthorized} =
               add_custom_group_member(
                 club_id,
                 group_id,
                 target_membership_id,
                 target_person_id,
                 unauthorized_actor_person_id
               )
    end

    add_group_member!(club_id, group_id, outsider_membership_id, outsider_person_id)

    assert :ok =
             Membership.remove_member(
               %{
                 club_id: club_id,
                 membership_id: outsider_membership_id,
                 person_id: outsider_person_id
               },
               consistency: :strong
             )

    assert {:error, :unauthorized} =
             add_custom_group_member(
               club_id,
               group_id,
               target_membership_id,
               target_person_id,
               outsider_person_id
             )

    refute Membership.active_member_of_group?(group_id, target_person_id)
  end

  test "add_custom_group_member/2 requires the exact active target membership in the same club" do
    club_id = Memba.ID.generate(:club)
    foreign_club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    foreign_person_id = Memba.ID.generate(:person)
    foreign_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)
    create_custom_group!(club_id, group_id, actor_person_id)
    create_club!(foreign_club_id)
    create_member!(foreign_club_id, foreign_membership_id, foreign_person_id)

    assert {:error, :member_not_active} =
             add_custom_group_member(
               club_id,
               group_id,
               Memba.ID.generate(:membership),
               Memba.ID.generate(:person),
               actor_person_id
             )

    assert {:error, :membership_person_mismatch} =
             add_custom_group_member(
               club_id,
               group_id,
               target_membership_id,
               foreign_person_id,
               actor_person_id
             )

    assert {:error, :member_not_active} =
             add_custom_group_member(
               club_id,
               group_id,
               foreign_membership_id,
               foreign_person_id,
               actor_person_id
             )

    refute Membership.active_member_of_group?(group_id, target_person_id)
    refute Membership.active_member_of_group?(group_id, foreign_person_id)
  end

  test "the public custom-group use case rejects system groups while trusted commands remain available" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)

    for system_group_id <- [everyone_group_id, admin_group_id] do
      assert {:error, :system_group_not_allowed} =
               add_custom_group_member(
                 club_id,
                 system_group_id,
                 target_membership_id,
                 target_person_id,
                 actor_person_id
               )
    end

    assert {:ok,
            %ExecutionResult{
              events: [
                %GroupMemberAdded{
                  group_id: ^admin_group_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id
                }
              ]
            }} =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: admin_group_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id
               },
               returning: :execution_result
             )
  end

  test "add_custom_group_member/2 requires the authenticated actor identity" do
    assert {:error, {:missing_required_attribute, :actor_person_id}} =
             Membership.add_custom_group_member(%{
               club_id: Memba.ID.generate(:club),
               group_id: Memba.ID.generate(:group),
               membership_id: Memba.ID.generate(:membership),
               person_id: Memba.ID.generate(:person)
             })
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id),
               consistency: :strong
             )
  end

  defp create_custom_group!(club_id, group_id, actor_person_id) do
    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: actor_person_id,
                 name: "Board"
               },
               consistency: :strong
             )
  end

  defp assign_admin!(club_id, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )
  end

  defp add_group_member!(club_id, group_id, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp add_custom_group_member(
         club_id,
         group_id,
         membership_id,
         person_id,
         actor_person_id,
         opts \\ []
       ) do
    Membership.add_custom_group_member(
      %{
        club_id: club_id,
        group_id: group_id,
        membership_id: membership_id,
        person_id: person_id,
        actor_person_id: actor_person_id
      },
      Keyword.put_new(opts, :consistency, :strong)
    )
  end

  defp create_member!(club_id, membership_id, person_id) do
    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Test member",
                 email: "#{person_id}@example.com"
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )
  end
end
