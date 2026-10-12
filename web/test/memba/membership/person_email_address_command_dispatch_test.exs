defmodule Memba.Membership.PersonEmailAddressCommandDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  test "prepared person email-address lifecycle commands dispatch and update the read model" do
    person_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-07-13 19:00:00.000000Z]

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: " Alice+New@Example.COM "
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressAdded{
                  person_id: ^person_id,
                  email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{
             person_id: ^person_id,
             email: "Alice+New@Example.COM",
             normalized_email: "alice+new@example.com",
             is_primary: false,
             verified_at: nil
           } =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_verify(%{
               person_id: person_id,
               email: "alice+new@example.com",
               verified_at: verified_at
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressVerified{
                  person_id: ^person_id,
                  normalized_email: "alice+new@example.com",
                  verified_at: ^verified_at
                }
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: ^verified_at} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_make_primary(%{
               person_id: person_id,
               email: "alice+new@example.com"
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonPrimaryEmailAddressChanged{
                  person_id: ^person_id,
                  primary_email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{email: "Alice+New@Example.COM"} = PersonQueries.get_person(person_id)

    assert %PersonEmailAddress{is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )

    assert %PersonEmailAddress{is_primary: true} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok, command, []} =
             PersonEmailAddressCommands.prepare_remove(%{
               person_id: person_id,
               email: "alice@example.com"
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressRemoved{
                  person_id: ^person_id,
                  email: "alice@example.com",
                  normalized_email: "alice@example.com"
                }
              ]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert is_nil(
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )
           )
  end

  test "person email-address command preparation and dispatch enforce pending, primary, removal, and duplicate rules" do
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: alice_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: bob_id,
               name: "Bob",
               email: "bob@example.com"
             })

    assert :ok =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: alice_id,
               email: " Alice.Pending@Example.COM "
             })

    assert :ok =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_make_primary(%{
               person_id: alice_id,
               email: "alice.pending@example.com"
             })

    assert {:error, :email_address_not_verified} =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:ok, command, []} =
             PersonEmailAddressCommands.prepare_remove(%{
               person_id: alice_id,
               email: "alice@example.com"
             })

    assert {:error, :primary_email_address_cannot_be_removed} =
             CommandDispatch.dispatch(command,
               consistency: :strong
             )

    assert {:error, :email_address_taken} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: bob_id,
               email: " ALICE.PENDING@example.com "
             })

    assert [
             %{
               normalized_email: "alice@example.com",
               primary?: true,
               verified_at: %DateTime{}
             },
             %{
               normalized_email: "alice.pending@example.com",
               primary?: false,
               verified_at: nil
             }
           ] = PersonQueries.list_person_email_addresses(alice_id)

    assert [
             %{
               normalized_email: "bob@example.com",
               primary?: true,
               verified_at: %DateTime{}
             }
           ] = PersonQueries.list_person_email_addresses(bob_id)
  end
end
