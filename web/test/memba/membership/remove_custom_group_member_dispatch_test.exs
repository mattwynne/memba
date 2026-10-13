defmodule Memba.Membership.RemoveCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.CommandDispatch, as: MembershipCommandDispatch
  alias Memba.Membership.CustomGroup
  alias Memba.Membership.PersonCommands

  alias Memba.Membership.MembershipQueries
  alias Memba.Membership.ClubGroupQueries
  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Commanded.EventStore.EventData
  alias Commanded.EventStore.TypeProvider
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "a current participant removes self or another participant, but an ordinary outsider cannot" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.first_person_id)

    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:error, :unauthorized} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.third_person_id)

    assert MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.second_person_id)

    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)
  end

  test "an active Admin outside the group removes a participant without joining or changing club roles" do
    ids = fixture_with_three_members()
    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    assign_admin!(ids, ids.third_membership_id, ids.third_person_id)
    assign_admin!(ids, ids.second_membership_id, ids.second_person_id)

    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.third_person_id)
    members_before = ClubGroupQueries.list_active_members_of_club(ids.club_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.second_membership_id, ids.second_person_id, ids.third_person_id)

    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)
    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.third_person_id)
    assert ClubGroupQueries.list_active_members_of_club(ids.club_id) == members_before
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

    refute MembershipQueries.active_member_of_group?(ids.group_id, ids.first_person_id)
    assert [] = ClubGroupQueries.list_active_members_of_group(ids.group_id)
    assert ClubGroupQueries.get_group(ids.group_id).name == "Board"

    assert Enum.any?(
             ClubGroupQueries.list_active_members_of_club(ids.club_id),
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
            }} =
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, returning: :execution_result)
              end)

    assert actor_person_id == ids.first_person_id

    assert {:ok, %ExecutionResult{events: []}} =
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, returning: :execution_result)
              end)

    assert {:error, :removal_operation_conflict} =
             (with {:ok, command} <-
                     CustomGroup.Remove.prepare(%{attrs | actor_person_id: ids.third_person_id}) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)

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
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, returning: :execution_result)
              end)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok, %ExecutionResult{events: []}} =
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, returning: :execution_result)
              end)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:error, :removal_operation_conflict} =
             (with {:ok, command} <-
                     CustomGroup.Remove.prepare(%{attrs | actor_person_id: ids.third_person_id}) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

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
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    add_group_member!(ids, ids.second_membership_id, ids.second_person_id)
    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok, %ExecutionResult{events: []}} =
             (with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command, returning: :execution_result)
              end)

    assert MembershipQueries.active_member_of_group?(ids.group_id, ids.second_person_id)
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

    legacy_checkpoint = Memba.ProjectionBarrier.current_checkpoint()
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

    # Raw EventStore appends have no dispatch consistency boundary; join the
    # legacy event's follow-cleanup handler before releasing the sandbox owner.
    assert %{checkpoint: ^legacy_checkpoint} =
             Memba.ProjectionBarrier.await!([ClearRemovedGroupMemberFollows],
               checkpoint: legacy_checkpoint,
               timeout: 5_000
             )
  end

  test "requires a caller-generated removal operation ID" do
    assert {:error, {:missing_required_attribute, :removal_operation_id}} =
             (with {:ok, command} <-
                     CustomGroup.Remove.prepare(%{
                       club_id: Memba.ID.generate(:club),
                       group_id: Memba.ID.generate(:group),
                       membership_id: Memba.ID.generate(:membership),
                       person_id: Memba.ID.generate(:person),
                       actor_person_id: Memba.ID.generate(:person)
                     }) do
                MembershipCommandDispatch.dispatch(command, [])
              end)
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

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(membership_club_attrs(club_id: ids.club_id)) do
                MembershipCommandDispatch.dispatch(command, [])
              end)

    create_member!(ids.club_id, ids.first_membership_id, ids.first_person_id)
    create_member!(ids.club_id, ids.second_membership_id, ids.second_person_id)
    create_member!(ids.club_id, ids.third_membership_id, ids.third_person_id)

    assert :ok =
             (with {:ok, command} <-
                     CustomGroup.Create.prepare(%{
                       club_id: ids.club_id,
                       group_id: ids.group_id,
                       actor_person_id: ids.first_person_id,
                       name: "Board"
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    ids
  end

  defp create_member!(club_id, membership_id, person_id) do
    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Test member",
                       email: "#{person_id}@example.com"
                     }) do
                MembershipCommandDispatch.dispatch(command, [])
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       club_id: club_id,
                       membership_id: membership_id,
                       person_id: person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
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
    attrs =
      ids
      |> removal_attrs(membership_id, person_id, actor_person_id)
      |> Map.put(:removal_operation_id, Ecto.UUID.generate())

    with {:ok, command} <- CustomGroup.Remove.prepare(attrs) do
      MembershipCommandDispatch.dispatch(command, consistency: :strong)
    end
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
