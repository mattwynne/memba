defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Person
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "Alice began changing their name when it was {string}",
       %{args: [expected_name]} = context do
    person_id = Memba.ID.generate(:person)
    email = "alice-member-profile@example.test"

    assert {:ok,
            %CreatePerson{
              person_id: ^person_id,
              name: ^expected_name,
              email: ^email
            } = command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: expected_name,
               email: email
             })

    assert {:ok,
            %ExecutionResult{
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: ^expected_name,
                  email: ^email
                }
              ],
              aggregate_state: %Person{
                person_id: ^person_id,
                name: ^expected_name,
                email: ^email
              }
            }} =
             CommandDispatch.dispatch(command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %{person_id: ^person_id, name: ^expected_name, email: ^email} = person =
             PersonQueries.get_person(person_id)

    context
    |> update_context_map(:people, "Alice", person)
    |> Map.put(:name_edit, %{person_id: person_id, expected_name: expected_name})
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end
end
