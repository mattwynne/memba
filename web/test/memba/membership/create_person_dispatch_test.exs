defmodule Memba.Membership.CreatePersonDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
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

  test "Membership app dispatches CreatePerson with multiple addresses as an atomic event pair" do
    person_id = Ecto.UUID.generate()

    command = %CreatePerson{
      person_id: person_id,
      name: "Alice",
      email_addresses: [
        %{email: "alice@example.com", is_primary: true},
        %{email: "alice@work.example", is_primary: false}
      ]
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 2,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "alice@example.com"
                },
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "alice@example.com",
                  email_addresses: [
                    %{
                      email: "alice@example.com",
                      normalized_email: "alice@example.com",
                      is_primary: true
                    },
                    %{
                      email: "alice@work.example",
                      normalized_email: "alice@work.example",
                      is_primary: false
                    }
                  ]
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                name: "Alice",
                email: "alice@example.com",
                email_addresses: [
                  %{
                    email: "alice@example.com",
                    normalized_email: "alice@example.com",
                    is_primary: true
                  },
                  %{
                    email: "alice@work.example",
                    normalized_email: "alice@work.example",
                    is_primary: false
                  }
                ]
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)
  end

  test "Membership app dispatches ReplacePersonEmailAddresses to the Person aggregate" do
    person_id = Ecto.UUID.generate()

    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    command = %ReplacePersonEmailAddresses{
      person_id: person_id,
      email_addresses: [
        %{email: "alice@example.com", is_primary: false},
        %{email: "alice@work.example", is_primary: true}
      ]
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 2,
              events: [
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "alice@work.example"
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                email: "alice@work.example"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)
  end
end
