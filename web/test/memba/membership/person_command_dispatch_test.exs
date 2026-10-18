defmodule Memba.Membership.PersonCommandDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonRenamed
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

  test "a stale rename preserves the newer projection until conditionally confirmed" do
    person_id = Memba.ID.generate(:person)
    actor = %{person_id: person_id}

    assert {:ok, create} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice Smith",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(create, consistency: :strong)
    assert :ok = Phoenix.PubSub.subscribe(Memba.PubSub, Memba.ReadModelChanges.topic())

    assert {:ok, rename_to_jones} =
             PersonCommands.prepare_rename(
               actor,
               person_id,
               "Alice Smith",
               %{name: "Alice Jones"}
             )

    assert {:ok,
            %ExecutionResult{
              events: [%PersonRenamed{name: "Alice Jones"} = renamed_event]
            }} =
             CommandDispatch.dispatch(rename_to_jones,
               returning: :execution_result,
               consistency: :strong
             )

    assert_receive {:read_model_changed,
                    %{
                      projector: Memba.Membership.Projectors.Person,
                      source_event: ^renamed_event
                    }}

    assert {:ok, stale_rename} =
             PersonCommands.prepare_rename(
               actor,
               person_id,
               "Alice Smith",
               %{name: "Alice Brown"}
             )

    assert {:error, {:name_changed, "Alice Jones"}} =
             CommandDispatch.dispatch(stale_rename, consistency: :strong)

    assert %PersonProjection{name: "Alice Jones"} = PersonQueries.get_person(person_id)

    assert {:ok, confirmed_rename} =
             PersonCommands.prepare_rename(
               actor,
               person_id,
               "Alice Jones",
               %{name: "Alice Brown"}
             )

    assert :ok = CommandDispatch.dispatch(confirmed_rename, consistency: :strong)
    assert %PersonProjection{name: "Alice Brown"} = PersonQueries.get_person(person_id)

    projection_positions =
      event_sourced_projection_positions([Memba.Membership.Projectors.Person])

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()
    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(projection_positions)

    assert %PersonProjection{name: "Alice Brown"} = PersonQueries.get_person(person_id)
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
end
