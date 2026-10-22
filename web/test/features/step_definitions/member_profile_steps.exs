defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "{word} is known as {string}", %{args: [person_name, requested_name]} = context do
    person = fetch_person!(context, person_name)
    projected_person = PersonQueries.get_person(person.person_id)

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{email: person.email},
               %{name: requested_name, expected_name: projected_person.name}
             )

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert %{name: ^requested_name} = PersonQueries.get_person(person.person_id)

    context
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
