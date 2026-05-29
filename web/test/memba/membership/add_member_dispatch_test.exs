defmodule Memba.Membership.AddMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Membership

  test "Membership app dispatch routes AddMember to the Membership aggregate" do
    membership_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    command = %AddMember{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^membership_id,
              aggregate_version: 1,
              events: [
                %MemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                }
              ],
              aggregate_state: %Membership{
                membership_id: ^membership_id,
                club_id: ^club_id,
                person_id: ^person_id,
                active: true
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %Membership{
             membership_id: ^membership_id,
             club_id: ^club_id,
             person_id: ^person_id,
             active: true
           } = App.aggregate_state(Membership, membership_id)
  end

  test "Membership app rejects a duplicate AddMember for the same aggregate identity" do
    command = %AddMember{
      membership_id: Ecto.UUID.generate(),
      club_id: Ecto.UUID.generate(),
      person_id: Ecto.UUID.generate()
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_added} = App.dispatch(command)
  end
end
