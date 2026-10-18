defmodule Memba.Membership.PersonCommandDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.Commands.RenamePerson
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

  test "routes a prepared rename and projects its normalized event" do
    person_id = create_person!("Alice Smith")

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{person_id: person_id},
               %{name: " Alice   Jones ", expected_name: "Alice Smith"}
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [%PersonRenamed{person_id: ^person_id, name: "Alice Jones"}]
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{name: "Alice Jones"} = PersonQueries.get_person(person_id)
  end

  test "an identical target dispatches without an event" do
    person_id = create_person!("Alice Smith")

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{person_id: person_id},
               %{name: " Alice   Smith ", expected_name: "stale baseline"}
             )

    assert {:ok, %ExecutionResult{events: []}} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{name: "Alice Smith"} = PersonQueries.get_person(person_id)
  end

  test "protects a newer name and conditionally confirms its replacement" do
    person_id = create_person!("Alice Smith")

    assert :ok = rename_person(person_id, "Alice Jones", "Alice Smith")

    assert {:error, {:name_conflict, "Alice Jones"}} =
             rename_person(person_id, "Alice Brown", "Alice Smith")

    assert %PersonProjection{name: "Alice Jones"} = PersonQueries.get_person(person_id)

    assert :ok = rename_person(person_id, "Alice Brown", "Alice Jones")
    assert %PersonProjection{name: "Alice Brown"} = PersonQueries.get_person(person_id)
  end

  test "serializes simultaneous renames from the same baseline" do
    person_id = create_person!("Alice Smith")

    assert {:ok,
            %RenamePerson{
              name: "Alice Jones",
              expected_name: "Alice Smith"
            } = jones_command} =
             PersonCommands.prepare_rename(
               %{person_id: person_id},
               %{name: "Alice Jones", expected_name: "Alice Smith"}
             )

    assert {:ok,
            %RenamePerson{
              name: "Alice Brown",
              expected_name: "Alice Smith"
            } = brown_command} =
             PersonCommands.prepare_rename(
               %{person_id: person_id},
               %{name: "Alice Brown", expected_name: "Alice Smith"}
             )

    task_supervisor = start_supervised!({Task.Supervisor, []})
    test_pid = self()

    jones_task =
      dispatch_when_released(task_supervisor, test_pid, "Alice Jones", jones_command)

    brown_task =
      dispatch_when_released(task_supervisor, test_pid, "Alice Brown", brown_command)

    assert_receive {:rename_dispatch_ready, jones_pid, "Alice Jones"}
    assert_receive {:rename_dispatch_ready, brown_pid, "Alice Brown"}
    assert jones_pid == jones_task.pid
    assert brown_pid == brown_task.pid

    send(jones_task.pid, :dispatch)
    send(brown_task.pid, :dispatch)

    results = [Task.await(jones_task), Task.await(brown_task)]

    assert [{winning_name, :ok}] =
             Enum.filter(results, fn {_requested_name, result} -> result == :ok end)

    assert [{_losing_name, {:error, {:name_conflict, ^winning_name}}}] =
             Enum.reject(results, fn {_requested_name, result} -> result == :ok end)

    assert %PersonProjection{name: ^winning_name} = PersonQueries.get_person(person_id)
  end

  defp create_person!(name) do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: name,
               email: "#{person_id}@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    person_id
  end

  defp rename_person(person_id, name, expected_name) do
    with {:ok, command} <-
           PersonCommands.prepare_rename(
             %{person_id: person_id},
             %{name: name, expected_name: expected_name}
           ) do
      CommandDispatch.dispatch(command, consistency: :strong)
    end
  end

  defp dispatch_when_released(task_supervisor, test_pid, requested_name, command) do
    Task.Supervisor.async_nolink(task_supervisor, fn ->
      send(test_pid, {:rename_dispatch_ready, self(), requested_name})

      receive do
        :dispatch ->
          {requested_name, CommandDispatch.dispatch(command, consistency: :strong)}
      end
    end)
  end
end
