defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "{word} began changing their name when it was {string}",
       %{args: [person_name, original_name]} = context do
    person_id = Memba.ID.generate(:person)
    email = scenario_email(context, person_name)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: original_name,
               email: email
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    context
    |> update_context_map(:people, person_name, %{person_id: person_id, email: email})
    |> update_context_map(:started_name_edits, person_name, original_name)
  end

  step "{word} has since changed their name to {string}",
       %{args: [person_name, current_name]} = context do
    person_id = person_id!(context, person_name)
    expected_name = fetch_from_context!(context, :started_name_edits, person_name)

    assert :ok = change_name(person_id, expected_name, current_name)
    context
  end

  step "{word} submits the older change to {string}",
       %{args: [person_name, requested_name]} = context do
    person_id = person_id!(context, person_name)
    expected_name = fetch_from_context!(context, :started_name_edits, person_name)

    Map.put(context, :last_name_change_result, change_name(person_id, expected_name, requested_name))
  end

  step "the change should be rejected because their name changed elsewhere", context do
    assert {:error, :name_changed} = Map.fetch!(context, :last_name_change_result)
    context
  end

  step "{word} should be known as {string}",
       %{args: [person_name, expected_name]} = context do
    person_id = person_id!(context, person_name)

    assert %{name: ^expected_name} = PersonQueries.get_person(person_id)
    context
  end

  step "{word} confirms replacing {string} with {string}",
       %{args: [person_name, expected_name, requested_name]} = context do
    person_id = person_id!(context, person_name)

    assert :ok = change_name(person_id, expected_name, requested_name)
    context
  end

  defp change_name(person_id, expected_name, requested_name) do
    with {:ok, command} <-
           PersonCommands.prepare_change_name(%{
             person_id: person_id,
             actor_person_id: person_id,
             expected_name: expected_name,
             name: requested_name
           }) do
      CommandDispatch.dispatch(command, consistency: :strong)
    end
  end

  defp person_id!(context, person_name) do
    case fetch_from_context!(context, :people, person_name) do
      %{person_id: person_id} -> person_id
      person_id when is_binary(person_id) -> person_id
    end
  end

  defp fetch_from_context!(context, collection_key, item_key) do
    context
    |> Map.get(collection_key, %{})
    |> Map.fetch(item_key)
    |> case do
      {:ok, value} ->
        value

      :error ->
        flunk("Expected #{inspect(item_key)} to be present in #{inspect(collection_key)}")
    end
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp scenario_email(context, person_name) do
    scenario_suffix =
      context
      |> Map.get(:scenario_name, "scenario")
      |> :erlang.phash2(1_000_000)
      |> Integer.to_string(36)
      |> String.downcase()

    "#{String.downcase(person_name)}-#{scenario_suffix}@example.test"
  end
end
