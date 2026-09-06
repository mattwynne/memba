defmodule Memba.ProjectionBarrierTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.ProjectionBarrier

  test "a barrier is satisfied when selected projectors reach the current checkpoint" do
    club_id = Memba.ID.generate(:club)

    :ok =
      Memba.Membership.create_club(
        %{club_id: club_id, name: "Barrier Club", slug: "barrier-club"},
        consistency: :strong
      )

    assert {:ok, result} =
             ProjectionBarrier.await([Memba.Membership.Projectors.Club], timeout: 100)

    assert result.checkpoint >= 1
    assert result.projectors["Memba.Membership.Projectors.Club"] >= result.checkpoint
  end

  test "a barrier advances when a projector acknowledges an irrelevant event" do
    club_id = Memba.ID.generate(:club)
    projector = "Memba.Membership.Projectors.Membership"

    :ok =
      Memba.Membership.create_club(
        %{club_id: club_id, name: "Ignored Event Club", slug: "ignored-event-club"},
        consistency: :strong
      )

    checkpoint = ProjectionBarrier.current_checkpoint()

    assert %{rows: []} =
             Memba.Repo.query!(
               """
               SELECT last_seen_event_number
               FROM projection_versions
               WHERE projection_name = $1
               """,
               [projector]
             )

    assert {:ok, result} = ProjectionBarrier.await([projector], timeout: 100)
    assert result.checkpoint == checkpoint
    assert result.projectors[projector] >= checkpoint
  end

  test "a barrier rejects an unavailable projector module" do
    assert_raise ArgumentError,
                 ~r/projection barrier projector Memba\.Unknown\.Projector is not available/,
                 fn ->
                   ProjectionBarrier.await([Memba.Unknown.Projector])
                 end
  end

  test "a barrier times out with the current projector positions" do
    club_id = Memba.ID.generate(:club)

    :ok =
      Memba.Membership.create_club(
        %{club_id: club_id, name: "Timeout Club", slug: "timeout-club"},
        consistency: :strong
      )

    checkpoint = ProjectionBarrier.current_checkpoint()

    assert {:error, :timeout, result} =
             ProjectionBarrier.await(["Memba.Unknown.Projector"],
               checkpoint: checkpoint,
               timeout: 1,
               poll_interval: 1
             )

    assert result.checkpoint == checkpoint
    assert result.projectors == %{"Memba.Unknown.Projector" => 0}
  end
end
