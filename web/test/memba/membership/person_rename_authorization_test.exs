defmodule Memba.Membership.PersonRenameAuthorizationTest do
  use Memba.EventSourcedCase, async: false
  alias Memba.Membership.{PersonCommands, CommandDispatch}

  test "trusted self actor is separate from posted attrs and unauthorized no-op/confirmation never dispatch" do
    actor = create("Alice Smith", "alice.actor@example.test")
    other = create("Bob Builder", "bob.actor@example.test")
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    for {name, expected} <- [
          {"Changed", "Bob Builder"},
          {"Bob Builder", "Bob Builder"},
          {"Changed", "Confirmed newer"}
        ] do
      attrs = %{person_id: other, name: name, expected_name: expected, actor_person_id: other}
      assert {:error, :forbidden} = PersonCommands.prepare_rename(%{person_id: actor}, attrs)

      result =
        with {:ok, command} <- PersonCommands.prepare_rename(%{person_id: actor}, attrs),
             do: CommandDispatch.dispatch(command, consistency: :strong)

      assert {:error, :forbidden} = result
    end

    assert {:error, :forbidden} =
             PersonCommands.prepare_rename(nil, %{
               person_id: actor,
               name: "Changed",
               expected_name: "Alice Smith"
             })

    assert {:error, :forbidden} =
             PersonCommands.prepare_rename(%{person_id: actor}, %{person_id: other})

    assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
    assert Memba.Membership.get_person(other).name == "Bob Builder"

    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: actor}, %{
        "person_id" => actor,
        "name" => "Robin Jones",
        "expected_name" => "Alice Smith",
        "actor_person_id" => other
      })

    assert command.person_id == actor
    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert Memba.Membership.get_person(actor).name == "Robin Jones"
  end

  defp create(name, email) do
    id = Memba.ID.generate(:person)
    {:ok, command} = PersonCommands.prepare_create(%{person_id: id, name: name, email: email})
    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    id
  end
end
