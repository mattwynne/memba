defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries

  step "{word} began changing their name when it was {string}",
       %{args: [person_role, baseline]} = context do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: baseline,
                       email: "member-profile-#{person_id}@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    context
    |> put_person_id(person_role, person_id)
    |> put_edit_baseline(person_role, baseline)
  end

  step "{word} has since changed their name to {string}",
       %{args: [person_role, new_name]} = context do
    assert :ok =
             context
             |> prepare_rename(person_role, new_name, edit_baseline!(context, person_role))
             |> dispatch_prepared()

    context
  end

  step "{word} submits the older change to {string}",
       %{args: [person_role, requested_name]} = context do
    result =
      context
      |> prepare_rename(person_role, requested_name, edit_baseline!(context, person_role))
      |> dispatch_prepared()

    Map.put(context, :last_person_rename_result, result)
  end

  step "the change should be rejected because their name changed elsewhere", context do
    assert {:error, {:name_changed, current_name}} =
             Map.fetch!(context, :last_person_rename_result)

    Map.put(context, :rename_conflict_current_name, current_name)
  end

  step "{word} should be known as {string}",
       %{args: [person_role, expected_name]} = context do
    person_id = person_id!(context, person_role)
    assert %{person_id: ^person_id, name: ^expected_name} = PersonQueries.get_person(person_id)
    context
  end

  step "{word} confirms replacing {string} with {string}",
       %{args: [person_role, shown_name, requested_name]} = context do
    assert Map.fetch!(context, :rename_conflict_current_name) == shown_name

    assert :ok =
             context
             |> prepare_rename(person_role, requested_name, shown_name)
             |> dispatch_prepared()

    context
  end

  defp prepare_rename(context, person_role, requested_name, expected_name) do
    person_id = person_id!(context, person_role)

    PersonCommands.prepare_rename(
      %{person_id: person_id},
      %{name: requested_name, expected_name: expected_name}
    )
  end

  defp dispatch_prepared({:ok, command}) do
    CommandDispatch.dispatch(command, consistency: :strong)
  end

  defp dispatch_prepared({:error, _reason} = error), do: error

  defp person_id!(context, person_role) do
    context
    |> get_in([:people, person_role, :person_id])
    |> case do
      person_id when is_binary(person_id) -> person_id
      nil -> flunk("Expected #{person_role} in the scenario context")
    end
  end

  defp edit_baseline!(context, person_role) do
    context
    |> get_in([:name_edits, person_role, :baseline])
    |> case do
      baseline when is_binary(baseline) -> baseline
      nil -> flunk("Expected a name-edit baseline for #{person_role}")
    end
  end

  defp put_person_id(context, person_role, person_id) do
    people =
      context
      |> Map.get(:people, %{})
      |> Map.put(person_role, %{person_id: person_id})

    Map.put(context, :people, people)
  end

  defp put_edit_baseline(context, person_role, baseline) do
    edits =
      context
      |> Map.get(:name_edits, %{})
      |> Map.put(person_role, %{baseline: baseline})

    Map.put(context, :name_edits, edits)
  end
end
