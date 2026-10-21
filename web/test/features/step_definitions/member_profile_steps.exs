defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "{word} is known as {string}", %{args: [person_label, requested_name]} = context do
    %{person_id: person_id} =
      context
      |> Map.get(:people, %{})
      |> Map.fetch!(person_label)

    person = PersonQueries.get_person(person_id)

    assert {:ok, command} =
             PersonCommands.prepare_rename(person, %{
               name: requested_name,
               expected_name: person.name
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert %{person_id: ^person_id, name: ^requested_name} = PersonQueries.get_person(person_id)

    context
  end
end
