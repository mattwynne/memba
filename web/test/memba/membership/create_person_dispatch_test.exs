defmodule Memba.Membership.CreatePersonDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Person

  test "Membership app dispatch routes CreatePerson to the Person aggregate" do
    person_id = Ecto.UUID.generate()

    command = %CreatePerson{
      person_id: person_id,
      name: "Alex Member",
      email: "alex@example.test"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 1,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alex Member",
                  email: "alex@example.test"
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                name: "Alex Member",
                email: "alex@example.test"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %Person{person_id: ^person_id, name: "Alex Member", email: "alex@example.test"} =
             App.aggregate_state(Person, person_id)
  end

  test "Membership app rejects a duplicate CreatePerson for the same aggregate identity" do
    command = %CreatePerson{
      person_id: Ecto.UUID.generate(),
      name: "Alex Member",
      email: "alex@example.test"
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_created} = App.dispatch(command)
  end
end
