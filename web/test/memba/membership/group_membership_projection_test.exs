defmodule Memba.Membership.GroupMembershipProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Projections.FirstClassGroupMembership
  alias Memba.Membership.Projections.GroupMembership, as: LegacyGroupMembership
  alias Memba.Membership.Projectors.FirstClassGroupMembershipV1
  alias Memba.Membership.Projectors.GroupMembership, as: LegacyGroupMembershipProjector

  test "first-class projector has a new origin subscription and strong consistency" do
    assert %{start: {FirstClassGroupMembershipV1, :start_link, [opts]}} =
             FirstClassGroupMembershipV1.child_spec([])

    assert Keyword.fetch!(opts, :name) ==
             "Memba.Membership.Projectors.FirstClassGroupMembershipV1"

    assert Keyword.fetch!(opts, :start_from) == :origin
    assert Keyword.fetch!(opts, :consistency) == :strong
  end

  test "first-class lifecycle projection is idempotent" do
    ids = ids()
    handler_name = "first-class-idempotency-#{Ecto.UUID.generate()}"
    started = started_event(ids, ids.first_group_membership_id)

    assert :ok = project(started, handler_name, 1)
    assert :ok = project(started, handler_name, 1)

    assert %FirstClassGroupMembership{
             group_membership_id: group_membership_id,
             club_membership_id: club_membership_id,
             active: true
           } = Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert group_membership_id == ids.first_group_membership_id
    assert club_membership_id == ids.club_membership_id
    assert 1 == Repo.aggregate(FirstClassGroupMembership, :count)

    assert [[stored_membership_id]] =
             Repo.query!(
               """
               SELECT membership_id
               FROM membership_first_class_group_memberships
               WHERE group_membership_id = $1
               """,
               [ids.first_group_membership_id]
             ).rows

    assert stored_membership_id == ids.club_membership_id

    ended = ended_event(ids, ids.first_group_membership_id, "end-1")
    assert :ok = project(ended, handler_name, 2)
    assert :ok = project(ended, handler_name, 2)

    assert %FirstClassGroupMembership{
             active: false,
             end_idempotency_key: "end-1",
             end_reason: "removed_by_group_member"
           } = Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert is_nil(Membership.get_current_group_membership(ids.group_id, ids.club_membership_id))
  end

  test "end and re-add retain history and expose only the new exact identity" do
    ids = ids()
    handler_name = "first-class-readd-#{Ecto.UUID.generate()}"

    assert :ok = project(started_event(ids, ids.first_group_membership_id), handler_name, 1)

    assert :ok =
             project(
               ended_event(ids, ids.first_group_membership_id, "end-first"),
               handler_name,
               2
             )

    assert :ok = project(started_event(ids, ids.second_group_membership_id), handler_name, 3)

    assert %{
             group_membership_id: group_membership_id,
             club_membership_id: club_membership_id,
             club_id: club_id,
             group_id: group_id,
             person_id: person_id
           } = Membership.get_current_group_membership(ids.group_id, ids.club_membership_id)

    assert group_membership_id == ids.second_group_membership_id
    assert club_membership_id == ids.club_membership_id
    assert club_id == ids.club_id
    assert group_id == ids.group_id
    assert person_id == ids.person_id

    memberships_by_id = Map.new(lifecycle_rows(ids), &{&1.group_membership_id, &1})

    assert %FirstClassGroupMembership{active: false} =
             memberships_by_id[ids.first_group_membership_id]

    assert %FirstClassGroupMembership{active: true} =
             memberships_by_id[ids.second_group_membership_id]
  end

  test "out-of-order lifecycle facts preserve tombstones and the newer current identity" do
    ids = ids()
    handler_name = "first-class-out-of-order-#{Ecto.UUID.generate()}"

    assert :ok =
             project(
               ended_event(ids, ids.first_group_membership_id, "end-before-start"),
               handler_name,
               1
             )

    assert :ok = project(started_event(ids, ids.first_group_membership_id), handler_name, 2)

    assert %FirstClassGroupMembership{active: false} =
             Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert is_nil(Membership.get_current_group_membership(ids.group_id, ids.club_membership_id))

    assert :ok = project(started_event(ids, ids.second_group_membership_id), handler_name, 3)

    assert :ok =
             project(
               ended_event(ids, ids.first_group_membership_id, "delayed-old-end"),
               handler_name,
               4
             )

    assert %{group_membership_id: current_id} =
             Membership.get_current_group_membership(ids.group_id, ids.club_membership_id)

    assert current_id == ids.second_group_membership_id
  end

  test "historical catch-up cannot change legacy current-state visibility" do
    ids = ids()
    handler_name = "first-class-catch-up-isolation-#{Ecto.UUID.generate()}"

    assert :ok =
             legacy_project(
               %GroupMemberRemoved{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 membership_id: ids.club_membership_id,
                 person_id: ids.person_id
               },
               "legacy-current-state-#{Ecto.UUID.generate()}",
               1
             )

    assert %LegacyGroupMembership{active: false} = legacy_membership(ids)

    assert :ok = project(started_event(ids, ids.first_group_membership_id), handler_name, 1)

    assert %FirstClassGroupMembership{active: true} =
             Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert %LegacyGroupMembership{active: false} = legacy_membership(ids)

    assert :ok =
             project(
               ended_event(ids, ids.first_group_membership_id, "historic-end"),
               handler_name,
               2
             )

    assert %FirstClassGroupMembership{active: false} =
             Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert %LegacyGroupMembership{active: false} = legacy_membership(ids)
  end

  test "legacy add and remove events retain their current-state projection compatibility" do
    ids = ids()
    handler_name = "legacy-compatibility-#{Ecto.UUID.generate()}"

    added = %GroupMemberAdded{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.club_membership_id,
      person_id: ids.person_id
    }

    removed = %GroupMemberRemoved{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.club_membership_id,
      person_id: ids.person_id
    }

    assert :ok = legacy_project(added, handler_name, 1)
    assert %LegacyGroupMembership{active: true} = legacy_membership(ids)
    assert 0 == Repo.aggregate(FirstClassGroupMembership, :count)

    assert :ok = legacy_project(removed, handler_name, 2)
    assert %LegacyGroupMembership{active: false} = legacy_membership(ids)
    assert 0 == Repo.aggregate(FirstClassGroupMembership, :count)
  end

  test "first-class lifecycle and current read rebuild identically from event history" do
    ids = ids()

    events = [
      started_event(ids, ids.first_group_membership_id),
      ended_event(ids, ids.first_group_membership_id, "end-before-readd"),
      started_event(ids, ids.second_group_membership_id)
    ]

    assert :ok =
             Commanded.EventStore.append_to_stream(
               App,
               ids.club_id,
               0,
               Enum.map(events, &Mapper.map_to_event_data/1)
             )

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!([FirstClassGroupMembershipV1], checkpoint: checkpoint)

    before_replay = projection_snapshot(ids)
    positions = event_sourced_projection_positions([FirstClassGroupMembershipV1])

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(positions)

    assert ^before_replay = projection_snapshot(ids)
  end

  test "a new projector subscription fills events acknowledged by the pre-upgrade projector" do
    ids = ids()
    child_id = stop_projector!(FirstClassGroupMembershipV1)

    assert :ok =
             Commanded.EventStore.delete_subscription(
               App,
               :all,
               inspect(FirstClassGroupMembershipV1)
             )

    events = [
      started_event(ids, ids.first_group_membership_id),
      ended_event(ids, ids.first_group_membership_id, "pre-upgrade-end")
    ]

    assert :ok =
             Commanded.EventStore.append_to_stream(
               App,
               ids.club_id,
               0,
               Enum.map(events, &Mapper.map_to_event_data/1)
             )

    assert :ok =
             Commanded.Subscriptions.wait_for(
               App,
               ids.club_id,
               2,
               consistency: [LegacyGroupMembershipProjector]
             )

    assert 0 == Repo.aggregate(FirstClassGroupMembership, :count)

    restart_projector!(child_id)
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!([FirstClassGroupMembershipV1], checkpoint: checkpoint)

    assert %FirstClassGroupMembership{
             group_membership_id: group_membership_id,
             active: false,
             end_idempotency_key: "pre-upgrade-end"
           } = Repo.get!(FirstClassGroupMembership, ids.first_group_membership_id)

    assert group_membership_id == ids.first_group_membership_id

    assert is_nil(
             Repo.get_by(LegacyGroupMembership,
               group_id: ids.group_id,
               membership_id: ids.club_membership_id
             )
           )
  end

  test "current read rejects invalid identifiers" do
    ids = ids()

    assert is_nil(Membership.get_current_group_membership("not-a-group", ids.club_membership_id))
    assert is_nil(Membership.get_current_group_membership(ids.group_id, "not-a-membership"))
    assert is_nil(Membership.get_current_group_membership(nil, nil))
  end

  defp project(event, handler_name, event_number) do
    FirstClassGroupMembershipV1.handle(event, %{
      handler_name: handler_name,
      event_number: event_number
    })
  end

  defp legacy_project(event, handler_name, event_number) do
    LegacyGroupMembershipProjector.handle(event, %{
      handler_name: handler_name,
      event_number: event_number
    })
  end

  defp started_event(ids, group_membership_id) do
    %GroupMembershipStarted{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: group_membership_id,
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id
    }
  end

  defp ended_event(ids, group_membership_id, idempotency_key) do
    %GroupMembershipEnded{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: group_membership_id,
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id,
      idempotency_key: idempotency_key,
      reason: "removed_by_group_member"
    }
  end

  defp lifecycle_rows(ids) do
    FirstClassGroupMembership
    |> where([membership], membership.group_id == ^ids.group_id)
    |> where([membership], membership.club_membership_id == ^ids.club_membership_id)
    |> order_by([membership], asc: membership.group_membership_id)
    |> Repo.all()
  end

  defp legacy_membership(ids) do
    Repo.get_by!(LegacyGroupMembership,
      group_id: ids.group_id,
      membership_id: ids.club_membership_id
    )
  end

  defp projection_snapshot(ids) do
    %{
      rows:
        ids
        |> lifecycle_rows()
        |> Enum.map(&Map.take(&1, FirstClassGroupMembership.__schema__(:fields))),
      current: Membership.get_current_group_membership(ids.group_id, ids.club_membership_id)
    }
  end

  defp stop_projector!(projector) do
    {child_id, pid, :worker, [^projector]} =
      Enum.find(Supervisor.which_children(Memba.Supervisor), fn
        {_child_id, _pid, :worker, [module]} -> module == projector
        _other_child -> false
      end)

    :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    on_exit(fn -> restart_projector!(child_id) end)
    assert is_pid(pid)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end

  defp ids do
    %{
      club_id: ID.generate(:club),
      group_id: ID.generate(:group),
      club_membership_id: ID.generate(:membership),
      person_id: ID.generate(:person),
      first_group_membership_id: ID.generate(:group_membership),
      second_group_membership_id: ID.generate(:group_membership)
    }
  end
end
