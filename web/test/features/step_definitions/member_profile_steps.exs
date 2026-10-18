defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands

  step "{word} began changing their name when it was {string}",
       %{args: [person_name, current_name]} = context do
    person_id = Memba.ID.generate(:person)
    email = email_for(context, person_name)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: current_name,
                       email: email
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    context
    |> update_context_map(:people, person_name, %{person_id: person_id, email: email})
    |> update_context_map(:member_profile_name_edits, person_name, %{
      person_id: person_id,
      expected_name: current_name
    })
  end

  step "{word} has since changed their name to {string}",
       %{args: [person_name, newer_name]} = context do
    %{person_id: person_id} =
      context
      |> Map.fetch!(:people)
      |> Map.fetch!(person_name)

    %{expected_name: expected_name} =
      context
      |> Map.fetch!(:member_profile_name_edits)
      |> Map.fetch!(person_name)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_rename(
                       %{person_id: person_id},
                       %{name: newer_name, expected_name: expected_name}
                     ) do
                CommandDispatch.dispatch(command)
              end)

    context
  end

  step "{word} submits the older change to {string}",
       %{args: [person_name, draft_name]} = context do
    %{person_id: person_id} =
      context
      |> Map.fetch!(:people)
      |> Map.fetch!(person_name)

    edit =
      context
      |> Map.fetch!(:member_profile_name_edits)
      |> Map.fetch!(person_name)

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{person_id: person_id},
               %{name: draft_name, expected_name: edit.expected_name}
             )

    dispatch_result = CommandDispatch.dispatch(command)

    authoritative_current_name =
      case dispatch_result do
        {:error, {:name_changed, current_name}} -> current_name
        _other -> nil
      end

    update_context_map(
      context,
      :member_profile_name_edits,
      person_name,
      Map.merge(edit, %{
        draft_name: draft_name,
        authoritative_current_name: authoritative_current_name,
        dispatch_result: dispatch_result
      })
    )
  end

  defp email_for(context, person_name) do
    normalized_name =
      person_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}-#{scenario_suffix(context)}@example.test"
  end

  defp scenario_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
    |> String.downcase()
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end
end
