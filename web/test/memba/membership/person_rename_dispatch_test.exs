defmodule Memba.Membership.PersonRenameDispatchTest do
  use Memba.EventSourcedCase, async: false
  alias Memba.Membership.{PersonCommands, CommandDispatch}

  test "simultaneous conditional commands have one winner and no event for the identical target" do
    id = Memba.ID.generate(:person)

    {:ok, create} =
      PersonCommands.prepare_create(%{
        person_id: id,
        name: "Alice Smith",
        email: "race@example.test"
      })

    assert :ok = CommandDispatch.dispatch(create, consistency: :strong)
    parent = self()

    tasks =
      for name <- ["Alice Brown", "Alice Green"] do
        {:ok, command} =
          PersonCommands.prepare_rename(%{person_id: id}, %{
            person_id: id,
            name: name,
            expected_name: "Alice Smith"
          })

        Task.async(fn ->
          send(parent, {:ready, self()})

          receive do
            :go -> CommandDispatch.dispatch(command, consistency: :strong)
          end
        end)
      end

    assert_receive {:ready, first}
    assert_receive {:ready, second}
    send(first, :go)
    send(second, :go)
    results = Enum.map(tasks, &Task.await(&1, 10_000))
    assert Enum.count(results, &(&1 == :ok)) == 1
    assert Enum.count(results, &match?({:error, {:name_conflict, _}}, &1)) == 1
    name = Memba.Membership.PersonQueries.get_person(id).name
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: id}, %{
        person_id: id,
        name: name,
        expected_name: "Alice Smith"
      })

    assert {:ok, %Commanded.Commands.ExecutionResult{events: []}} =
             CommandDispatch.dispatch(command, consistency: :strong, returning: :execution_result)

    assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok, %Commanded.Commands.ExecutionResult{events: []}} =
             CommandDispatch.dispatch(command, consistency: :strong, returning: :execution_result)
  end
end
