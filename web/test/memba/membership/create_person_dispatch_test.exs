defmodule Memba.Membership.CreatePersonDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.VerifyPersonEmailAddress
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.Person

  test "Membership app dispatch routes CreatePerson to the Person aggregate" do
    person_id = Memba.ID.generate(:person)

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
      person_id: Memba.ID.generate(:person),
      name: "Alice",
      email: "alice@example.com"
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_created} = App.dispatch(command)
  end

  test "Membership app dispatches CreatePerson with multiple addresses as an atomic event pair" do
    person_id = Memba.ID.generate(:person)

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
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    command = %ReplacePersonEmailAddresses{
      person_id: person_id,
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
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "alice@example.com",
                  email_addresses: [
                    %{
                      normalized_email: "alice@example.com",
                      is_primary: true,
                      verified_at: %DateTime{}
                    },
                    %{
                      normalized_email: "alice@work.example",
                      is_primary: false,
                      verified_at: nil
                    }
                  ]
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                email: "alice@example.com",
                email_addresses: [
                  %{
                    normalized_email: "alice@example.com",
                    is_primary: true,
                    verified_at: %DateTime{}
                  },
                  %{
                    normalized_email: "alice@work.example",
                    is_primary: false,
                    verified_at: nil
                  }
                ]
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)
  end

  test "Membership app dispatches individual person email-address lifecycle commands" do
    person_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-07-13 18:30:00Z]

    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 2,
              events: [
                %PersonEmailAddressAdded{
                  person_id: ^person_id,
                  email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             App.dispatch(
               %AddPersonEmailAddress{
                 person_id: person_id,
                 email: " Alice+New@Example.COM "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 3,
              events: [
                %PersonEmailAddressVerified{
                  person_id: ^person_id,
                  normalized_email: "alice+new@example.com",
                  verified_at: ^verified_at
                }
              ]
            }} =
             App.dispatch(
               %VerifyPersonEmailAddress{
                 person_id: person_id,
                 email: "alice+new@example.com",
                 verified_at: verified_at
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 4,
              events: [
                %PersonPrimaryEmailAddressChanged{
                  person_id: ^person_id,
                  primary_email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             App.dispatch(
               %MakePersonEmailAddressPrimary{
                 person_id: person_id,
                 email: "alice+new@example.com"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              aggregate_version: 5,
              events: [
                %PersonEmailAddressRemoved{
                  person_id: ^person_id,
                  normalized_email: "alice@example.com"
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                email: "Alice+New@Example.COM",
                email_addresses: [
                  %{
                    email: "Alice+New@Example.COM",
                    normalized_email: "alice+new@example.com",
                    is_primary: true,
                    verified_at: ^verified_at
                  }
                ]
              }
            }} =
             App.dispatch(
               %RemovePersonEmailAddress{person_id: person_id, email: "alice@example.com"},
               returning: :execution_result,
               consistency: :strong
             )
  end
end
