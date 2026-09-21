defmodule Memba.Membership.RemoveCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.RemoveCustomGroupMember
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "remove_custom_group_member/2 emits only GroupMemberRemoved and updates the projection" do
    fixture = custom_group_with_target!()
    club_id = fixture.club_id
    group_id = fixture.group_id
    target_membership_id = fixture.target_membership_id
    target_person_id = fixture.target_person_id
    actor_person_id = fixture.actor_person_id

    assert %RemoveCustomGroupMember{
             club_id: club_id,
             group_id: group_id,
             membership_id: target_membership_id,
             person_id: target_person_id,
             actor_person_id: actor_person_id
           } ==
             struct!(RemoveCustomGroupMember, %{
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
                %GroupMemberRemoved{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id
                }
              ]
            }} =
             remove_custom_group_member(fixture, returning: :execution_result)

    assert %GroupMembershipProjection{
             club_id: ^club_id,
             group_id: ^group_id,
             membership_id: ^target_membership_id,
             person_id: ^target_person_id,
             active: false
           } =
             Repo.get_by(GroupMembershipProjection,
               group_id: group_id,
               membership_id: target_membership_id
             )
  end

  test "an exact retry is event-free while identity mismatches are rejected" do
    fixture = custom_group_with_target!()

    assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
             remove_custom_group_member(fixture, returning: :execution_result)

    assert {:ok, %ExecutionResult{events: []}} =
             remove_custom_group_member(fixture, returning: :execution_result)

    assert {:error, :membership_person_mismatch} =
             fixture
             |> Map.put(:target_person_id, fixture.actor_person_id)
             |> remove_custom_group_member()
  end

  test "a member can remove themselves as the final custom-group member" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, membership_id, person_id)
    create_custom_group!(club_id, group_id, person_id)

    fixture = %{
      club_id: club_id,
      group_id: group_id,
      actor_person_id: person_id,
      target_person_id: person_id,
      target_membership_id: membership_id
    }

    assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
             remove_custom_group_member(fixture, returning: :execution_result)

    refute Membership.active_member_of_group?(group_id, person_id)

    assert Enum.any?(
             Membership.list_active_members_of_club(club_id),
             &(&1.id == person_id)
           )
  end

  test "an Admin outside the group can remove an Admin without removing club role authority" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, target_membership_id, target_person_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_custom_group!(club_id, group_id, target_person_id)
    assign_admin!(club_id, actor_membership_id, actor_person_id)

    refute Membership.active_member_of_group?(group_id, actor_person_id)

    fixture = %{
      club_id: club_id,
      group_id: group_id,
      actor_person_id: actor_person_id,
      target_person_id: target_person_id,
      target_membership_id: target_membership_id
    }

    assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
             remove_custom_group_member(fixture, returning: :execution_result)

    refute Membership.active_member_of_group?(group_id, target_person_id)
    refute Membership.active_member_of_group?(group_id, actor_person_id)

    assert %{roles: roles} =
             Enum.find(
               Membership.list_active_members_of_club(club_id),
               &(&1.id == target_person_id)
             )

    assert Roles.membership_administrator_name() in roles

    assert Membership.person_has_club_permission?(
             club_id,
             target_person_id,
             Permissions.club_manage_members()
           )
  end

  test "ordinary and inactive outsiders cannot remove a custom-group member" do
    fixture = custom_group_with_target!()
    outsider_person_id = Memba.ID.generate(:person)
    outsider_membership_id = Memba.ID.generate(:membership)

    create_member!(fixture.club_id, outsider_membership_id, outsider_person_id)

    assert {:error, :unauthorized} =
             fixture
             |> Map.put(:actor_person_id, outsider_person_id)
             |> remove_custom_group_member()

    assign_admin!(
      fixture.club_id,
      fixture.target_membership_id,
      fixture.target_person_id
    )

    assert :ok =
             Membership.remove_member(
               %{
                 club_id: fixture.club_id,
                 membership_id: fixture.actor_membership_id,
                 person_id: fixture.actor_person_id
               },
               consistency: :strong
             )

    assert {:error, :unauthorized} = remove_custom_group_member(fixture)
    assert Membership.active_member_of_group?(fixture.group_id, fixture.target_person_id)
  end

  test "the public removal path rejects wrong targets and system groups" do
    fixture = custom_group_with_target!()
    other_person_id = Memba.ID.generate(:person)
    other_membership_id = Memba.ID.generate(:membership)

    create_member!(fixture.club_id, other_membership_id, other_person_id)

    assert {:error, :group_member_not_active} =
             fixture
             |> Map.merge(%{
               target_membership_id: other_membership_id,
               target_person_id: other_person_id
             })
             |> remove_custom_group_member()

    for group_id <- [
          SystemGroups.everyone_group_id(fixture.club_id),
          SystemGroups.admin_group_id(fixture.club_id)
        ] do
      assert {:error, :system_group_not_allowed} =
               fixture
               |> Map.put(:group_id, group_id)
               |> remove_custom_group_member()
    end
  end

  test "remove_custom_group_member/2 requires every command identity" do
    attrs = %{
      club_id: Memba.ID.generate(:club),
      group_id: Memba.ID.generate(:group),
      membership_id: Memba.ID.generate(:membership),
      person_id: Memba.ID.generate(:person),
      actor_person_id: Memba.ID.generate(:person)
    }

    for required <- Map.keys(attrs) do
      assert {:error, {:missing_required_attribute, ^required}} =
               attrs
               |> Map.delete(required)
               |> Membership.remove_custom_group_member()
    end
  end

  defp custom_group_with_target! do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)
    create_custom_group!(club_id, group_id, actor_person_id)
    add_group_member!(club_id, group_id, target_membership_id, target_person_id)

    %{
      club_id: club_id,
      group_id: group_id,
      actor_person_id: actor_person_id,
      actor_membership_id: actor_membership_id,
      target_person_id: target_person_id,
      target_membership_id: target_membership_id
    }
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

  defp remove_custom_group_member(fixture, opts \\ []) do
    Membership.remove_custom_group_member(
      %{
        club_id: fixture.club_id,
        group_id: fixture.group_id,
        membership_id: fixture.target_membership_id,
        person_id: fixture.target_person_id,
        actor_person_id: fixture.actor_person_id
      },
      Keyword.put_new(opts, :consistency, :strong)
    )
  end
end
