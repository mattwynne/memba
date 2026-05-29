defmodule Memba.Membership.CreateClubDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Events.ClubCreated

  test "Membership app dispatch routes CreateClub to the Club aggregate" do
    club_id = Ecto.UUID.generate()

    command = %CreateClub{
      club_id: club_id,
      name: "Kootenay Mountaineering Club"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 1,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club"
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                name: "Kootenay Mountaineering Club"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %Club{club_id: ^club_id, name: "Kootenay Mountaineering Club"} =
             App.aggregate_state(Club, club_id)
  end

  test "Membership app rejects a duplicate CreateClub for the same aggregate identity" do
    command = %CreateClub{
      club_id: Ecto.UUID.generate(),
      name: "Kootenay Mountaineering Club"
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_created} = App.dispatch(command)
  end
end
