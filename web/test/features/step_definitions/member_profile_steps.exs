defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "{word} is known as {string}", %{args: [person_name, requested_name]} = context do
    rename_person!(context, person_name, requested_name)
    context
  end

  step "{word} changes their name to {string}",
       %{args: [person_name, requested_name]} = context do
    rename_person!(context, person_name, requested_name)
    context
  end

  defp rename_person!(context, person_name, requested_name) do
    person = fetch_person!(context, person_name)
    expected_name = PersonQueries.get_person(person.person_id).name

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{email: person.email},
               %{name: requested_name, expected_name: expected_name}
             )

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert %{name: projected_name} = PersonQueries.get_person(person.person_id)
    assert projected_name == normalize_name(requested_name)
  end

  defp normalize_name(name) do
    name
    |> String.trim()
    |> String.replace(~r/\s+/u, " ")
  end

  defp fetch_person!(context, person_name) do
    context
    |> Map.get(:people, %{})
    |> Map.fetch(person_name)
    |> case do
      {:ok, person} -> person
      :error -> flunk("Expected #{inspect(person_name)} to be present in :people")
    end
  end
end
