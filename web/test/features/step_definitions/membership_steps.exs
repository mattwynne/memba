defmodule Memba.Cucumber.MembershipSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  step "Kootenay Mountaineering Club is a club", context do
    create_club(context, "Kootenay Mountaineering Club")
  end

  step "Nelson Paddling Club is a club", context do
    create_club(context, "Nelson Paddling Club")
  end

  step "Alice, Bob, and Carol are people", context do
    create_people(context, ["Alice", "Bob", "Carol"])
  end

  step "Alice and Bob are people", context do
    create_people(context, ["Alice", "Bob"])
  end

  step "Pat is a person", context do
    create_people(context, ["Pat"])
  end

  step "Alice, Bob, and Carol are members of Kootenay Mountaineering Club", context do
    add_members(context, ["Alice", "Bob", "Carol"], "Kootenay Mountaineering Club")
  end

  step "Alice and Bob are members of Kootenay Mountaineering Club", context do
    add_members(context, ["Alice", "Bob"], "Kootenay Mountaineering Club")
  end

  step "Pat is a member of Nelson Paddling Club", context do
    add_members(context, ["Pat"], "Nelson Paddling Club")
  end

  defp create_club(context, club_name) do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreateClub{club_id: club_id, name: club_name})

    assert %ClubProjection{club_id: ^club_id, name: ^club_name} = Membership.get_club(club_id)

    update_context_map(context, :clubs, club_name, club_id)
  end

  defp create_people(context, names) do
    Enum.reduce(names, context, &create_person(&2, &1))
  end

  defp create_person(context, name) do
    person_id = Ecto.UUID.generate()
    email = email_for(name)

    assert :ok =
             Membership.dispatch(%CreatePerson{
               person_id: person_id,
               name: name,
               email: email
             })

    assert %PersonProjection{person_id: ^person_id, name: ^name, email: ^email} =
             Membership.get_person(person_id)

    update_context_map(context, :people, name, person_id)
  end

  defp add_members(context, person_names, club_name) do
    Enum.reduce(person_names, context, fn person_name, context ->
      add_member(context, person_name, club_name)
    end)
  end

  defp add_member(context, person_name, club_name) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    person_id = fetch_from_context!(context, :people, person_name)

    refute Membership.active_member_of_club?(club_id, person_id)

    membership_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%AddMember{
               membership_id: membership_id,
               club_id: club_id,
               person_id: person_id
             })

    assert Membership.active_member_of_club?(club_id, person_id)

    assert %{id: ^person_id, name: ^person_name, email: _email} =
             Enum.find(Membership.list_active_members_of_club(club_id), &(&1.id == person_id))

    update_context_map(context, :memberships, {club_name, person_name}, membership_id)
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

  defp email_for(name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}@example.test"
  end
end
