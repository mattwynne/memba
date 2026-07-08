defmodule Memba.Cucumber.MembershipSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Slug
  alias Memba.Repo

  step "Kootenay Mountaineering Club is a club", context do
    create_club(context, "Kootenay Mountaineering Club")
  end

  step "Nelson Paddling Club is a club", context do
    create_club(context, "Nelson Paddling Club")
  end

  step "Alice, Bob, and Carol are people", context do
    create_people(context, ["Alice", "Bob", "Carol"])
  end

  step "Alice, Bob, Carol, and Dana are people", context do
    create_people(context, ["Alice", "Bob", "Carol", "Dana"])
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

  step "Alice, Bob, and Carol are active members of Kootenay Mountaineering Club", context do
    context
    |> create_club("Kootenay Mountaineering Club")
    |> create_people(["Alice", "Bob", "Carol"])
    |> add_members(["Alice", "Bob", "Carol"], "Kootenay Mountaineering Club")
  end

  step "Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club", context do
    add_members(context, ["Alice", "Bob", "Carol", "Dana"], "Kootenay Mountaineering Club")
  end

  step "Alice and Bob are members of Kootenay Mountaineering Club", context do
    add_members(context, ["Alice", "Bob"], "Kootenay Mountaineering Club")
  end

  step "Pat is a member of Nelson Paddling Club", context do
    add_members(context, ["Pat"], "Nelson Paddling Club")
  end

  step ~r/^(\w+) has the roles (.+) and (.+) in (.+)$/,
       %{args: [person_name, first_role_name, second_role_name, club_name]} = context do
    assign_roles(context, person_name, [first_role_name, second_role_name], club_name)
  end

  step ~r/^(\w+) has the role (.+) in (.+)$/,
       %{args: [person_name, role_name, club_name]} = context do
    assign_roles(context, person_name, [role_name], club_name)
  end

  step ~r/^(\w+) is removed from (.+)$/, %{args: [person_name, club_name]} = context do
    membership_id = active_membership_id!(context, person_name, club_name)

    assert :ok =
             Membership.remove_member(
               %{membership_id: membership_id},
               consistency: :strong
             )

    update_context_map(context, :memberships, {club_name, person_name}, nil)
  end

  step ~r/^(\w+) views the member list for (.+)$/,
       %{args: [viewer_name, club_name]} = context do
    club_id = fetch_from_context!(context, :clubs, club_name)
    viewer_id = person_id_from_context!(context, viewer_name)

    assert Membership.active_member_of_club?(club_id, viewer_id)

    context
    |> Map.put(:current_member_list_club, club_name)
    |> Map.put(:current_member_list, Membership.list_active_members_of_club(club_id))
  end

  step ~r/^(\w+)'s member row should show the roles (.+) and (.+)$/,
       %{args: [person_name, first_role_name, second_role_name]} = context do
    assert_member_roles(context, person_name, [first_role_name, second_role_name])
  end

  step ~r/^(\w+)'s member row should show the role (.+)$/,
       %{args: [person_name, role_name]} = context do
    assert_member_roles(context, person_name, [role_name])
  end

  step ~r/^(\w+)'s member row should show no roles$/, %{args: [person_name]} = context do
    assert_member_roles(context, person_name, [])
  end

  step ~r/^(\w+) should not appear in the member list$/, %{args: [person_name]} = context do
    refute find_member_row(context, person_name)
    context
  end

  step ~r/^(.+) should appear in the member list$/, %{args: [person_names_text]} = context do
    person_names_text
    |> parse_person_list()
    |> Enum.each(fn person_name ->
      assert find_member_row(context, person_name),
             "Expected #{person_name} to appear in the member list"
    end)

    context
  end

  step "Memba staff review people", context do
    Map.put(context, :current_read_model, :people)
  end

  step "Memba should list Alice as one person", context do
    assert Map.get(context, :current_read_model) == :people
    person_id = person_id_from_context!(context, "Alice")

    count =
      PersonProjection
      |> where([person], person.name == "Alice")
      |> Repo.aggregate(:count)

    assert count == 1
    assert %PersonProjection{name: "Alice"} = Membership.get_person(person_id)

    context
  end

  step "Memba should show Alice's Kootenay Mountaineering Club membership", context do
    assert_person_membership(context, "Alice", "Kootenay Mountaineering Club")
  end

  step "Memba should show Alice's Nelson Paddling Club membership", context do
    assert_person_membership(context, "Alice", "Nelson Paddling Club")
  end

  step "Kootenay Mountaineering Club has the slug {string}", %{args: [slug]} = context do
    create_club(context, "Kootenay Mountaineering Club", slug)
  end

  step "Pat starts creating the club {string}", %{args: [club_name]} = context do
    Map.put(context, :pending_club, %{name: club_name, slug: Slug.default_from_name(club_name)})
  end

  step "Memba should suggest the slug {string}", %{args: [expected_slug]} = context do
    assert %{slug: ^expected_slug} = Map.fetch!(context, :pending_club)
    context
  end

  step "Pat saves the club", context do
    %{name: club_name, slug: slug} = Map.fetch!(context, :pending_club)
    create_club(context, club_name, slug)
  end

  step "Kootenay Mountaineering Club should have the slug {string}", %{args: [slug]} = context do
    assert_club_slug(context, "Kootenay Mountaineering Club", slug)
  end

  step "Pat tries to change Kootenay Mountaineering Club's slug to {string}",
       %{args: [slug]} = context do
    try_change_club_slug(context, "Kootenay Mountaineering Club", slug)
  end

  step "Pat tries to change Nelson Paddling Club's slug to {string}", %{args: [slug]} = context do
    try_change_club_slug(context, "Nelson Paddling Club", slug)
  end

  step "Memba should reject the club slug as invalid", context do
    assert {:error, :invalid_format} = Map.fetch!(context, :club_slug_change_result)
    context
  end

  step "Memba should reject the club slug as already taken", context do
    assert {:error, :slug_taken} = Map.fetch!(context, :club_slug_change_result)
    context
  end

  step "Kootenay Mountaineering Club should keep its previous slug", context do
    assert_club_kept_previous_slug(context, "Kootenay Mountaineering Club")
  end

  step "Nelson Paddling Club should keep its previous slug", context do
    assert_club_kept_previous_slug(context, "Nelson Paddling Club")
  end

  defp create_club(context, club_name) do
    create_club(context, club_name, scenario_slug(context, club_name))
  end

  defp create_club(context, club_name, slug) do
    case get_in(context, [:clubs, club_name]) do
      nil ->
        club_id = Memba.ID.generate(:club)

        assert :ok =
                 App.dispatch(
                   %CreateClub{
                     club_id: club_id,
                     name: club_name,
                     slug: slug
                   },
                   consistency: :strong
                 )

        assert %ClubProjection{club_id: ^club_id, name: ^club_name, slug: ^slug} =
                 Membership.get_club(club_id)

        update_context_map(context, :clubs, club_name, club_id)

      club_id ->
        assert :ok =
                 Membership.update_club(
                   %{club_id: club_id, name: club_name, slug: slug},
                   consistency: :strong
                 )

        assert %ClubProjection{club_id: ^club_id, name: ^club_name, slug: ^slug} =
                 Membership.get_club(club_id)

        context
    end
  end

  defp create_people(context, names) do
    Enum.reduce(names, context, &create_person(&2, &1))
  end

  defp scenario_slug(_context, "Kootenay Mountaineering Club"), do: "kmc"

  defp scenario_slug(context, club_name) do
    suffix = scenario_slug_suffix(context)

    slug_base =
      club_name
      |> Slug.default_from_name()
      |> String.slice(0, Slug.max_length() - String.length("-" <> suffix))
      |> String.trim("-")

    case slug_base do
      "" -> suffix
      slug_base -> "#{slug_base}-#{suffix}"
    end
  end

  defp scenario_slug_suffix(context) do
    context
    |> Map.get(:scenario)
    |> case do
      %{id: id} when is_binary(id) -> id
      _scenario -> Ecto.UUID.generate()
    end
    |> String.replace(~r/[^a-z0-9]+/u, "")
    |> String.slice(0, 8)
  end

  defp create_person(context, name) do
    if get_in(context, [:people, name]) do
      context
    else
      person_id = Memba.ID.generate(:person)
      email = email_for(context, name)

      assert :ok =
               App.dispatch(
                 %CreatePerson{
                   person_id: person_id,
                   name: name,
                   email: email,
                   email_addresses: [%{email: email, is_primary: true}]
                 },
                 consistency: :strong
               )

      assert %PersonProjection{person_id: ^person_id, name: ^name, email: ^email} =
               Membership.get_person(person_id)

      assert [
               %{email: ^email, normalized_email: ^email, primary?: true}
             ] = Membership.list_person_email_addresses(person_id)

      update_context_map(context, :people, name, person_id)
    end
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

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             App.dispatch(
               %AddMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert Membership.active_member_of_club?(club_id, person_id)

    assert %{id: ^person_id, name: ^person_name, email: _email} =
             Enum.find(Membership.list_active_members_of_club(club_id), &(&1.id == person_id))

    update_context_map(context, :memberships, {club_name, person_name}, membership_id)
  end

  defp assign_roles(context, person_name, role_names, club_name) do
    Enum.reduce(role_names, context, fn role_name, context ->
      assign_role(context, person_name, role_name, club_name)
    end)
  end

  defp assign_role(context, person_name, role_name, club_name) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    person_id = person_id_from_context!(context, person_name)
    membership_id = active_membership_id!(context, person_name, club_name)
    role_id = ensure_role(context, club_id, role_name)

    unless active_role_assignment?(club_id, membership_id, person_id, role_id) do
      assert :ok =
               App.dispatch(
                 %AssignMemberRole{
                   club_id: club_id,
                   membership_id: membership_id,
                   person_id: person_id,
                   role_id: role_id
                 },
                 consistency: :strong
               )
    end

    context
  end

  defp ensure_role(_context, club_id, role_name) do
    role_key = role_key(role_name)

    case Repo.get_by(RoleProjection, club_id: club_id, role_key: role_key) do
      %RoleProjection{role_id: role_id} ->
        role_id

      nil ->
        role_id = Memba.ID.deterministic(:role, ["acceptance-list-members", club_id, role_key])

        assert :ok =
                 App.dispatch(
                   %DefineClubRole{
                     club_id: club_id,
                     role_id: role_id,
                     role_key: role_key,
                     name: role_name
                   },
                   consistency: :strong
                 )

        assert %RoleProjection{role_id: ^role_id, name: ^role_name} =
                 Repo.get(RoleProjection, role_id)

        role_id
    end
  end

  defp try_change_club_slug(context, club_name, slug) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    previous_slug = Membership.get_club(club_id).slug

    result =
      Membership.update_club(
        %{club_id: club_id, name: club_name, slug: slug},
        consistency: :strong
      )

    context
    |> Map.put(:club_slug_change_result, result)
    |> update_context_map(:previous_club_slugs, club_name, previous_slug)
  end

  defp assert_club_slug(context, club_name, expected_slug) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    assert %{slug: ^expected_slug} = Membership.get_club(club_id)
    context
  end

  defp assert_club_kept_previous_slug(context, club_name) do
    previous_slug = fetch_from_context!(context, :previous_club_slugs, club_name)
    assert_club_slug(context, club_name, previous_slug)
  end

  defp person_id_from_context!(context, person_name) do
    case fetch_from_context!(context, :people, person_name) do
      %{person_id: person_id} -> person_id
      person_id when is_binary(person_id) -> person_id
    end
  end

  defp assert_person_membership(context, person_name, club_name) do
    assert Map.get(context, :current_read_model) == :people

    person_id = person_id_from_context!(context, person_name)
    club_id = fetch_from_context!(context, :clubs, club_name)

    assert Membership.active_member_of_club?(club_id, person_id)

    assert Enum.any?(Membership.list_active_members_of_club(club_id), fn member ->
             member.id == person_id and member.name == person_name
           end)

    context
  end

  defp assert_member_roles(context, person_name, expected_role_names) do
    assert %{roles: ^expected_role_names} = find_member_row!(context, person_name)
    context
  end

  defp find_member_row!(context, person_name) do
    find_member_row(context, person_name) ||
      flunk("Expected #{person_name} to appear in the member list")
  end

  defp find_member_row(context, person_name) do
    person_id = person_id_from_context!(context, person_name)

    context
    |> Map.fetch!(:current_member_list)
    |> Enum.find(&(&1.id == person_id and &1.name == person_name))
  end

  defp active_membership_id!(context, person_name, club_name) do
    case fetch_from_context!(context, :memberships, {club_name, person_name}) do
      membership_id when is_binary(membership_id) ->
        membership_id

      _missing ->
        club_id = fetch_from_context!(context, :clubs, club_name)
        person_id = person_id_from_context!(context, person_name)

        MembershipProjection
        |> where([membership], membership.club_id == ^club_id)
        |> where([membership], membership.person_id == ^person_id)
        |> where([membership], membership.active == true)
        |> select([membership], membership.membership_id)
        |> limit(1)
        |> Repo.one() ||
          flunk("Expected active membership for #{person_name} in #{club_name}")
    end
  end

  defp active_role_assignment?(club_id, membership_id, person_id, role_id) do
    RoleAssignmentProjection
    |> where([assignment], assignment.club_id == ^club_id)
    |> where([assignment], assignment.membership_id == ^membership_id)
    |> where([assignment], assignment.person_id == ^person_id)
    |> where([assignment], assignment.role_id == ^role_id)
    |> where([assignment], assignment.active == true)
    |> Repo.exists?()
  end

  defp parse_person_list(text) do
    text
    |> String.replace(~r/,?\s+and\s+/u, ", ")
    |> String.split(~r/\s*,\s*/u, trim: true)
  end

  defp role_key(role_name) do
    role_name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
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

  defp email_for(context, name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}-#{scenario_email_suffix(context)}@example.test"
  end

  defp scenario_email_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
