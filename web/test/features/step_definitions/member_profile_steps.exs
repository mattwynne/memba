defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "Alice began changing their name when it was {string}",
       %{args: [name]} = context do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: name,
                       email: "#{person_id}@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    people = context |> Map.get(:people, %{}) |> Map.put("Alice", %{person_id: person_id})

    context
    |> Map.put(:people, people)
    |> Map.put(:older_name_baseline, name)
  end

  step "Alice has since changed their name to {string}",
       %{args: [name]} = context do
    assert :ok =
             rename_alice(
               context,
               name,
               Map.fetch!(context, :older_name_baseline)
             )

    context
  end

  step "Alice submits the older change to {string}",
       %{args: [name]} = context do
    result =
      rename_alice(
        context,
        name,
        Map.fetch!(context, :older_name_baseline)
      )

    Map.put(context, :rename_result, result)
  end

  step "the change should be rejected because their name changed elsewhere", context do
    assert {:error, {:name_conflict, current_name}} =
             Map.fetch!(context, :rename_result)

    Map.put(context, :conflicting_name, current_name)
  end

  step "Alice should be known as {string}", %{args: [name]} = context do
    person_id = alice_person_id!(context)
    assert %{name: ^name} = PersonQueries.get_person(person_id)
    context
  end

  step "Alice confirms replacing {string} with {string}",
       %{args: [displayed_name, replacement_name]} = context do
    assert Map.fetch!(context, :conflicting_name) == displayed_name
    assert :ok = rename_alice(context, replacement_name, displayed_name)
    context
  end

  defp rename_alice(context, name, expected_name) do
    person_id = alice_person_id!(context)

    with {:ok, command} <-
           PersonCommands.prepare_rename(
             %{person_id: person_id},
             %{name: name, expected_name: expected_name}
           ) do
      CommandDispatch.dispatch(command, consistency: :strong)
    end
  end

  defp alice_person_id!(context) do
    context
    |> get_in([:people, "Alice", :person_id])
    |> case do
      person_id when is_binary(person_id) -> person_id
      nil -> flunk("Expected Alice in the scenario context")
    end
  end
end
