defmodule Memba.Membership.RemoveCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Commanded.EventStore.EventData
  alias Commanded.EventStore.TypeProvider
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "a current participant removes self or another participant, but an ordinary outsider cannot" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.first_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.second_person_id)

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:error, :unauthorized} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.third_person_id)

    assert Membership.active_member_of_group?(ids.group_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.second_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.second_person_id)
  end

  test "an active Admin outside the group removes a participant without joining or changing club roles" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    assign_admin!(ids, ids.third_membership_id, ids.third_person_id)
    assign_admin!(ids, ids.second_membership_id, ids.second_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.third_person_id)
    members_before = Membership.list_active_members_of_club(ids.club_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.third_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.second_person_id)
    refute Membership.active_member_of_group?(ids.group_id, ids.third_person_id)
    assert Membership.list_active_members_of_club(ids.club_id) == members_before
  end

  test "rejects target mismatch, inactive targets, and both system groups" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:error, :membership_person_mismatch} =
             remove(
               ids,
               ids.second_membership_id,
               ids.third_person_id,
               ids.first_person_id
             )

    assert {:error, :group_member_not_active} =
             remove(ids, ids.third_membership_id, ids.third_person_id, ids.first_person_id)

    for system_group_id <- [
          SystemGroups.everyone_group_id(ids.club_id),
          SystemGroups.admin_group_id(ids.club_id)
        ] do
      assert {:error, :system_group_not_allowed} =
               remove(
                 %{ids | group_id: system_group_id},
                 ids.first_membership_id,
                 ids.first_person_id,
                 ids.first_person_id
               )
    end
  end

  test "allows the last participant to leave while preserving the empty group and club membership" do
    ids = fixture_with_three_members()

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.first_membership_id, ids.first_person_id, ids.first_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.first_person_id)
    assert [] = Membership.list_active_members_of_group(ids.group_id)
    assert Membership.get_group(ids.group_id).name == "Board"

    assert Enum.any?(
             Membership.list_active_members_of_club(ids.club_id),
             &(&1.id == ids.first_person_id)
           )
  end

  test "exact retries are event-free, conflicts fail, and an old retry cannot remove a re-added participant" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    operation_id = Ecto.UUID.generate()

    attrs =
      removal_attrs(ids, ids.second_membership_id, ids.second_person_id, ids.first_person_id)

    attrs = Map.put(attrs, :removal_operation_id, operation_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %GroupMemberRemoved{
                  removal_operation_id: ^operation_id,
                  actor_person_id: actor_person_id
                }
              ]
            }} = Membership.remove_custom_group_member(attrs, returning: :execution_result)

    assert actor_person_id == ids.first_person_id

    assert {:ok, %ExecutionResult{events: []}} =
             Membership.remove_custom_group_member(attrs, returning: :execution_result)

    assert {:error, :removal_operation_conflict} =
             Membership.remove_custom_group_member(
               %{attrs | actor_person_id: ids.third_person_id},
               consistency: :strong
             )

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert Membership.active_member_of_group?(ids.group_id, ids.second_person_id)

    assert %GroupMembershipProjection{active: true} =
             Repo.get_by!(GroupMembershipProjection,
               group_id: ids.group_id,
               membership_id: ids.second_membership_id
             )
  end

  test "persisted operation identity makes exact retry event-free and conflict durable after aggregate restart" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    operation_id = Ecto.UUID.generate()

    attrs =
      ids
      |> removal_attrs(ids.second_membership_id, ids.second_person_id, ids.first_person_id)
      |> Map.put(:removal_operation_id, operation_id)

    assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
             Membership.remove_custom_group_member(attrs, returning: :execution_result)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok, %ExecutionResult{events: []}} =
             Membership.remove_custom_group_member(attrs, returning: :execution_result)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:error, :removal_operation_conflict} =
             Membership.remove_custom_group_member(
               %{attrs | actor_person_id: ids.third_person_id},
               consistency: :strong
             )

    assert count_removal_operation_events(ids.club_id, operation_id) == 1
  end

  test "a delayed persisted retry cannot remove a re-add after aggregate restart" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    operation_id = Ecto.UUID.generate()

    attrs =
      ids
      |> removal_attrs(ids.second_membership_id, ids.second_person_id, ids.first_person_id)
      |> Map.put(:removal_operation_id, operation_id)

    assert {:ok, %CustomGroupRemoval{}} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok, %ExecutionResult{events: []}} =
             Membership.remove_custom_group_member(attrs, returning: :execution_result)

    assert Membership.active_member_of_group?(ids.group_id, ids.second_person_id)
    assert count_removal_operation_events(ids.club_id, operation_id) == 1
  end

  test "EventStore deserializes and replays legacy removal JSON without operation fields" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    legacy_event = %GroupMemberRemoved{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.second_membership_id,
      person_id: ids.second_person_id
    }

    event_data = %EventData{
      event_type: TypeProvider.to_string(legacy_event),
      data: %{
        "club_id" => ids.club_id,
        "group_id" => ids.group_id,
        "membership_id" => ids.second_membership_id,
        "person_id" => ids.second_person_id
      },
      metadata: %{}
    }

    assert :ok =
             EventStore.append_to_stream(
               App,
               ids.club_id,
               latest_stream_version(ids.club_id),
               [event_data]
             )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert %GroupMemberRemoved{
             actor_person_id: nil,
             removal_operation_id: nil
           } =
             ids.club_id
             |> then(&EventStore.stream_forward(App, &1))
             |> Enum.to_list()
             |> List.last()
             |> Map.fetch!(:data)

    group_id = ids.group_id
    membership_id = ids.second_membership_id

    assert %Club{
             group_memberships: %{
               {^group_id, ^membership_id} => %{active: false}
             },
             removal_operations: %{}
           } = App.aggregate_state(Club, ids.club_id)
  end

  test "requires a caller-generated removal operation ID" do
    assert {:error, {:missing_required_attribute, :removal_operation_id}} =
             Membership.remove_custom_group_member(%{
               club_id: Memba.ID.generate(:club),
               group_id: Memba.ID.generate(:group),
               membership_id: Memba.ID.generate(:membership),
               person_id: Memba.ID.generate(:person),
               actor_person_id: Memba.ID.generate(:person)
             })
  end

  defp fixture_with_three_members do
    ids = %{
      club_id: Memba.ID.generate(:club),
      group_id: Memba.ID.generate(:group),
      first_membership_id: Memba.ID.generate(:membership),
      first_person_id: Memba.ID.generate(:person),
      second_membership_id: Memba.ID.generate(:membership),
      second_person_id: Memba.ID.generate(:person),
      third_membership_id: Memba.ID.generate(:membership),
      third_person_id: Memba.ID.generate(:person)
    }

    assert :ok = Membership.create_club(membership_club_attrs(club_id: ids.club_id))
    create_member!(ids.club_id, ids.first_membership_id, ids.first_person_id)
    create_member!(ids.club_id, ids.second_membership_id, ids.second_person_id)
    create_member!(ids.club_id, ids.third_membership_id, ids.third_person_id)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 actor_person_id: ids.first_person_id,
                 name: "Board"
               },
               consistency: :strong
             )

    ids
  end

  defp create_member!(club_id, membership_id, person_id) do
    assert :ok =
             Membership.create_person(%{
               person_id: person_id,
               name: "Test member",
               email: "#{person_id}@example.com"
             })

    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )
  end

  defp add_group_member!(ids, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp assign_admin!(ids, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: ids.club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(ids.club_id)
               },
               consistency: :strong
             )
  end

  defp remove(ids, membership_id, person_id, actor_person_id) do
    ids
    |> removal_attrs(membership_id, person_id, actor_person_id)
    |> Map.put(:removal_operation_id, Ecto.UUID.generate())
    |> Membership.remove_custom_group_member(consistency: :strong)
  end

  defp count_removal_operation_events(club_id, operation_id) do
    club_id
    |> then(&EventStore.stream_forward(App, &1))
    |> Enum.count(fn recorded_event ->
      match?(
        %GroupMemberRemoved{removal_operation_id: ^operation_id},
        recorded_event.data
      )
    end)
  end

  defp latest_stream_version(club_id) do
    club_id
    |> then(&EventStore.stream_forward(App, &1))
    |> Enum.to_list()
    |> List.last()
    |> Map.fetch!(:stream_version)
  end

  defp removal_attrs(ids, membership_id, person_id, actor_person_id) do
    %{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: membership_id,
      person_id: person_id,
      actor_person_id: actor_person_id
    }
  end
end
