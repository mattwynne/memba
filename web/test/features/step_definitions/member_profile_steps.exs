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
                       email: "alice@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    context
    |> Map.put(:alice_person_id, person_id)
    |> Map.put(:alice_edit_baseline, name)
  end

  step "Alice has since changed their name to {string}",
       %{args: [name]} = context do
    assert :ok = rename(context, name, context.alice_edit_baseline)
    context
  end

  step "Alice submits the older change to {string}",
       %{args: [name]} = context do
    Map.put(context, :rename_result, rename(context, name, context.alice_edit_baseline))
  end

  step "the change should be rejected because their name changed elsewhere", context do
    assert {:error, {:name_changed, current_name}} = context.rename_result
    Map.put(context, :conflicting_name, current_name)
  end

  step "Alice should be known as {string}", %{args: [name]} = context do
    assert %{name: ^name} = PersonQueries.get_person(context.alice_person_id)
    context
  end

  step "Alice confirms replacing {string} with {string}",
       %{args: [expected_name, name]} = context do
    assert expected_name == context.conflicting_name
    assert :ok = rename(context, name, expected_name)
    context
  end

  defp rename(context, name, expected_name) do
    with {:ok, command} <-
           PersonCommands.prepare_rename(
             %{person_id: context.alice_person_id},
             context.alice_person_id,
             %{
               name: name,
               expected_name: expected_name
             }
           ) do
      CommandDispatch.dispatch(command, consistency: :strong)
    end
  end
end
