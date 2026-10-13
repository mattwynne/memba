defmodule Memba.Cucumber.PersonMergeSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.PersonMerge
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.CommandDispatch

  step "{word} has the primary email {string}",
       %{args: [person_name, email]} = context do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: person_name,
                       email: email,
                       email_addresses: [%{email: email, is_primary: true}]
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    update_context_person(context, person_name, %{person_id: person_id, email: email})
  end

  step "Memba staff merge {word} into {word}",
       %{args: [source_name, target_name]} = context do
    assert {:ok, %{status: :merged}} =
             PersonMerge.merge(person_id!(context, source_name), person_id!(context, target_name))

    context
  end

  step "Memba staff try to merge {word} into {word}",
       %{args: [source_name, target_name]} = context do
    result =
      PersonMerge.merge(person_id!(context, source_name), person_id!(context, target_name))

    Map.put(context, :person_merge_result, result)
  end

  step "{string} should identify {word}", %{args: [email, person_name]} = context do
    expected_person_id = person_id!(context, person_name)
    assert %{person_id: ^expected_person_id} = PersonQueries.get_verified_person_by_email(email)
    context
  end

  step "{word} should no longer be an active person account",
       %{args: [person_name]} = context do
    person_id = person_id!(context, person_name)
    assert %{merged_into_person_id: merged_into_person_id} = PersonQueries.get_person(person_id)
    assert is_binary(merged_into_person_id)
    refute Enum.any?(PersonQueries.list_people(), &(&1.person_id == person_id))
    context
  end

  step "the person merge should be rejected because a membership needs reconciliation",
       context do
    assert {:error, {:memberships_need_reconciliation, [_club_id | _rest]}} =
             Map.fetch!(context, :person_merge_result)

    context
  end

  step "{string} should still identify {word}", %{args: [email, person_name]} = context do
    expected_person_id = person_id!(context, person_name)
    assert %{person_id: ^expected_person_id} = PersonQueries.get_verified_person_by_email(email)
    context
  end

  defp person_id!(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} -> person_id
      person_id when is_binary(person_id) -> person_id
      nil -> flunk("Expected #{person_name} in the scenario context")
    end
  end

  defp update_context_person(context, person_name, person) do
    people = context |> Map.get(:people, %{}) |> Map.put(person_name, person)
    Map.put(context, :people, people)
  end
end
