defmodule Memba.Membership.PersonEmailVerificationReplacementTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonEmailVerification
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Projections.PersonEmailAddress

  test "replace/2 preserves verified addresses and revokes removed pending verification tokens" do
    person_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-07-13 20:00:00.000000Z]
    parent = self()

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: " Alice+Verified@Example.COM "
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_verify(%{
               person_id: person_id,
               email: "alice+verified@example.com",
               verified_at: verified_at
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: " Alice+Stale@Example.COM "
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    verification_revoker = fn request ->
      send(parent, {:verification_revoked, request})
      :ok
    end

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
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
                      normalized_email: "alice+verified@example.com",
                      is_primary: false,
                      verified_at: ^verified_at
                    }
                  ]
                }
              ]
            }} =
             PersonEmailVerification.replace(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "Alice+Verified@Example.COM", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong,
               verification_revoker: verification_revoker
             )

    assert_received {:verification_revoked,
                     %{
                       person_id: ^person_id,
                       email: "Alice+Stale@Example.COM",
                       normalized_email: "alice+stale@example.com"
                     }}

    assert %PersonEmailAddress{verified_at: ^verified_at} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+verified@example.com"
             )

    refute Repo.get_by(PersonEmailAddress,
             person_id: person_id,
             normalized_email: "alice+stale@example.com"
           )
  end

  test "replace/2 keeps staff-added alternate addresses pending" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "alice@example.com",
                  email_addresses: [
                    %{
                      email: "alice@example.com",
                      normalized_email: "alice@example.com",
                      is_primary: true,
                      verified_at: %DateTime{}
                    },
                    %{
                      email: "alice@work.example",
                      normalized_email: "alice@work.example",
                      is_primary: false,
                      verified_at: nil
                    }
                  ]
                }
              ]
            }} =
             PersonEmailVerification.replace(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com",
               is_primary: true
             )

    assert %PersonEmailAddress{verified_at: nil} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@work.example",
               is_primary: false
             )
  end

  test "replace/2 rejects a newly introduced primary address" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:error, :primary_email_address_not_verified} =
             PersonEmailVerification.replace(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: true}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "replace/2 rejects addresses already attached to another person" do
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: alice_id,
               name: "Alice",
               email: "Alice@Example.COM"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: bob_id,
               name: "Bob",
               email: "bob@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:error, :email_address_taken} =
             PersonEmailVerification.replace(
               %{
                 person_id: bob_id,
                 email_addresses: [
                   %{email: "bob@example.com", is_primary: true},
                   %{email: " alice@example.com ", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %{
               email: "bob@example.com",
               normalized_email: "bob@example.com",
               primary?: true,
               verified_at: %DateTime{}
             }
           ] = PersonQueries.list_person_email_addresses(bob_id)
  end
end
