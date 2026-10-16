defmodule Memba.Membership.PersonCommandDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonNameChanged
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  test "dispatches prepared CreatePerson with normalized name and email" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: " Alice ",
               email: " Alice@Example.COM "
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "alice@example.com"
                }
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{person_id: ^person_id, name: "Alice", email: "alice@example.com"} =
             PersonQueries.get_person(person_id)

    assert %PersonEmailAddress{
             person_id: ^person_id,
             normalized_email: "alice@example.com",
             is_primary: true,
             verified_at: %DateTime{}
           } = Repo.get_by(PersonEmailAddress, person_id: person_id)
  end

  test "accepts an email-address set for new staff create flows" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: " Alice ",
               email_addresses: [
                 %{email: " Alice@Example.COM ", is_primary: true},
                 %{email: "alice@work.example", is_primary: false}
               ]
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "Alice@Example.COM"
                },
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "Alice@Example.COM",
                  email_addresses: [
                    %{
                      email: "Alice@Example.COM",
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
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@work.example"
             )
  end

  test "rejects globally duplicate normalized email addresses before dispatch" do
    existing_person_id = Memba.ID.generate(:person)
    duplicate_person_id = Memba.ID.generate(:person)
    duplicate_alternate_person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: existing_person_id,
               name: "Alice",
               email: "Alice@Example.COM"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:error, :email_address_taken} =
             PersonCommands.prepare_create(%{
               person_id: duplicate_person_id,
               name: "Duplicate Alice",
               email: " alice@example.com "
             })

    assert {:error, :email_address_taken} =
             PersonCommands.prepare_create(%{
               person_id: duplicate_alternate_person_id,
               name: "Duplicate Alternate Alice",
               email_addresses: [
                 %{email: "duplicate@example.com", is_primary: true},
                 %{email: " ALICE@EXAMPLE.COM ", is_primary: false}
               ]
             })

    assert is_nil(PersonQueries.get_person(duplicate_person_id))
    assert is_nil(PersonQueries.get_person(duplicate_alternate_person_id))
  end

  test "changes a person's own name only when the expected name is still current" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, create} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice Smith",
               email: "alice-name-change@example.com"
             })

    assert :ok = CommandDispatch.dispatch(create, consistency: :strong)

    assert {:error, :self_authorization_required} =
             PersonCommands.prepare_change_name(%{
               person_id: person_id,
               actor_person_id: Memba.ID.generate(:person),
               expected_name: "Alice Smith",
               name: "Alice Jones"
             })

    assert {:ok, first_change} =
             PersonCommands.prepare_change_name(%{
               person_id: person_id,
               actor_person_id: person_id,
               expected_name: "Alice Smith",
               name: "Alice Jones"
             })

    assert :ok = CommandDispatch.dispatch(first_change, consistency: :strong)

    assert {:ok, stale_change} =
             PersonCommands.prepare_change_name(%{
               person_id: person_id,
               actor_person_id: person_id,
               expected_name: "Alice Smith",
               name: "Alice Brown"
             })

    assert {:error, :name_changed} =
             CommandDispatch.dispatch(stale_change, consistency: :strong)

    assert %PersonProjection{name: "Alice Jones"} = PersonQueries.get_person(person_id)

    assert {:ok, confirmed_change} =
             PersonCommands.prepare_change_name(%{
               person_id: person_id,
               actor_person_id: person_id,
               expected_name: "Alice Jones",
               name: " Alice   Brown "
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [%PersonNameChanged{person_id: ^person_id, name: "Alice Brown"}]
            }} =
             CommandDispatch.dispatch(confirmed_change,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{name: "Alice Brown"} = PersonQueries.get_person(person_id)
  end
end
