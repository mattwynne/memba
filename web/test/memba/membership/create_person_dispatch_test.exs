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
      name: "Alice",
      email: "alice@example.com"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 1,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "alice@example.com"
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                name: "Alice",
                email: "alice@example.com"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %Person{person_id: ^person_id, name: "Alice", email: "alice@example.com"} =
             App.aggregate_state(Person, person_id)
  end

  test "Membership app rejects a duplicate CreatePerson for the same aggregate identity" do
    command = %CreatePerson{
      person_id: Ecto.UUID.generate(),
      name: "Alice",
      email: "alice@example.com"
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_created} = App.dispatch(command)
  end
end
