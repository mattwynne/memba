defmodule Memba.Membership.AddCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Events.GroupMemberAdded

  test "add_custom_group_member/2 dispatches an actor-bearing command to the Club aggregate" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    create_member!(club_id, target_membership_id, target_person_id)

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
