defmodule Memba.Cucumber.MembershipAdministrationSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Membership.SystemGroups
  alias Memba.Repo

  step ~r/^(.+) are members of the (.+) Admin group$/,
       %{args: [person_names_text, club_name]} = context do
    context =
      person_names_text
      |> parse_person_list()
      |> Enum.reduce(context, fn person_name, context ->
        ensure_membership_administrator(context, person_name, club_name)
      end)

    club_id = fetch_club_id!(context, club_name)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    person_names_text
    |> parse_person_list()
    |> Enum.each(fn person_name ->
      person = fetch_person!(context, person_name)
      assert Membership.active_member_of_group?(admin_group_id, person.person_id)
    end)

    context
  end

  step "{word} is an Admin of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    ensure_membership_administrator(
      context,
      person_name,
      club_name(club_word_1, club_word_2, club_word_3)
    )
  end

  step "{word} is the only Admin of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)
    context = ensure_membership_administrator(context, person_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    role_id = Roles.membership_administrator_role_id(club_id)

    assert active_role_assignment_count(club_id, role_id) == 1
    context
  end

  step "{word} is an ordinary member of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)
    {context, _membership_id} = ensure_active_member(context, person_name, club_name)

    refute membership_administrator?(context, person_name, club_name)
    context
  end

  step "{word} makes {word} an Admin of {word} {word} {word}",
       %{args: [actor_name, target_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)
    {context, target_membership_id} = ensure_active_member(context, target_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    actor = fetch_person!(context, actor_name)
    target = fetch_person!(context, target_name)

    assert :ok =
             Membership.assign_membership_administrator_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target.person_id,
                 actor_person_id: actor.person_id
               },
               consistency: :strong
             )

    Map.put(context, :last_membership_administration_result, :ok)
  end

  step "{word} tries to make {word} an Admin of {word} {word} {word}",
       %{args: [actor_name, target_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)
    {context, target_membership_id} = ensure_active_member(context, target_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    actor = fetch_person!(context, actor_name)
    target = fetch_person!(context, target_name)

    assert {:error, :unauthorized} =
             result =
             Membership.assign_membership_administrator_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target.person_id,
                 actor_person_id: actor.person_id
               },
               consistency: :strong
             )

    Map.put(context, :last_membership_administration_result, result)
  end

  step "{word} tries to remove {word} as an Admin of {word} {word} {word}",
       %{args: [actor_name, target_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)
    {context, target_membership_id} = ensure_active_member(context, target_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    actor = fetch_person!(context, actor_name)
    target = fetch_person!(context, target_name)

    assert {:error, :last_membership_administrator} =
             result =
             Membership.remove_membership_administrator_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target.person_id,
                 actor_person_id: actor.person_id
               },
               consistency: :strong
             )

    Map.put(context, :last_membership_administration_result, result)
  end

  step "{word} should be an Admin of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    assert_membership_administrator(
      context,
      person_name,
      club_name(club_word_1, club_word_2, club_word_3)
    )
  end

  step "{word} should still be an Admin of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    assert_membership_administrator(
      context,
      person_name,
      club_name(club_word_1, club_word_2, club_word_3)
    )
  end

  step "{word} should not be an Admin of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = club_name(club_word_1, club_word_2, club_word_3)

    refute membership_administrator?(context, person_name, club_name)
    context
  end

  defp ensure_membership_administrator(context, person_name, club_name) do
    {context, membership_id} = ensure_active_member(context, person_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    role_id = Roles.membership_administrator_role_id(club_id)

    unless active_role_assignment?(club_id, membership_id, person.person_id, role_id) do
      assert :ok =
               App.dispatch(
                 %AssignMemberRole{
                   club_id: club_id,
                   membership_id: membership_id,
                   person_id: person.person_id,
                   role_id: role_id
                 },
                 consistency: :strong
               )
    end

    assert_membership_administrator(context, person_name, club_name)
  end

  defp assert_membership_administrator(context, person_name, club_name) do
    assert membership_administrator?(context, person_name, club_name)
    context
  end

  defp membership_administrator?(context, person_name, club_name) do
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    membership_id = active_membership_id!(club_id, person.person_id)
    role_id = Roles.membership_administrator_role_id(club_id)

    active_role_assignment?(club_id, membership_id, person.person_id, role_id) and
      Membership.person_has_club_permission?(
        club_id,
        person.person_id,
        Permissions.club_manage_members()
      )
  end

  defp ensure_active_member(context, person_name, club_name) do
    context = ensure_club(context, club_name)
    context = ensure_person(context, person_name)
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    membership_key = {club_name, person_name}

    case active_membership_id(club_id, person.person_id) do
      nil ->
        membership_id = Memba.ID.generate(:membership)

        assert :ok =
                 Membership.add_member(
                   %{
                     membership_id: membership_id,
                     club_id: club_id,
                     person_id: person.person_id
                   },
                   consistency: :strong
                 )

        {update_context_map(context, :memberships, membership_key, membership_id), membership_id}

      membership_id ->
        {update_context_map(context, :memberships, membership_key, membership_id), membership_id}
    end
  end

  defp ensure_club(context, club_name) do
    case get_in(context, [:clubs, club_name]) do
      nil ->
        case fetch_club_by_name(club_name) do
          nil ->
            club_id = Memba.ID.generate(:club)

            assert :ok =
                     Membership.create_club(
                       %{
                         club_id: club_id,
                         name: club_name,
                         slug: scenario_slug(context, club_name)
                       },
                       consistency: :strong
                     )

            update_context_map(context, :clubs, club_name, club_id)

          %ClubProjection{club_id: club_id} ->
            update_context_map(context, :clubs, club_name, club_id)
        end

      _club ->
        context
    end
  end

  defp ensure_person(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        context

      person_id when is_binary(person_id) ->
        context

      _missing ->
        person_id = Memba.ID.generate(:person)
        email = default_email_for(context, person_name)

        assert :ok =
                 Membership.create_person(
                   %{
                     person_id: person_id,
                     name: person_name,
                     email: email,
                     email_addresses: [%{email: email, is_primary: true}]
                   },
                   consistency: :strong
                 )

        update_context_map(context, :people, person_name, %{
          person_id: person_id,
          name: person_name,
          email: email
        })
    end
  end

  defp fetch_club_id!(context, club_name) do
    case get_in(context, [:clubs, club_name]) do
      club_id when is_binary(club_id) ->
        club_id

      %{club_id: club_id} when is_binary(club_id) ->
        club_id

      _missing ->
        case fetch_club_by_name(club_name) do
          %ClubProjection{club_id: club_id} -> club_id
          nil -> flunk("Expected #{club_name} to be known as a club")
        end
    end
  end

  defp fetch_person!(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        Membership.get_person(person_id) ||
          flunk("Expected #{person_name} to exist as a projected person")

      person_id when is_binary(person_id) ->
        Membership.get_person(person_id) ||
          flunk("Expected #{person_name} to exist as a projected person")

      _missing ->
        PersonProjection
        |> where([person], person.name == ^person_name)
        |> limit(1)
        |> Repo.one()
        |> case do
          nil -> flunk("Expected #{person_name} to be known as a person")
          person -> person
        end
    end
  end

  defp fetch_club_by_name(club_name) do
    ClubProjection
    |> where([club], club.name == ^club_name)
    |> limit(1)
    |> Repo.one()
  end

  defp active_membership_id!(club_id, person_id) do
    active_membership_id(club_id, person_id) ||
      flunk("Expected active membership for #{person_id} in #{club_id}")
  end

  defp active_membership_id(club_id, person_id) do
    MembershipProjection
    |> where([membership], membership.club_id == ^club_id)
    |> where([membership], membership.person_id == ^person_id)
    |> where([membership], membership.active == true)
    |> select([membership], membership.membership_id)
    |> limit(1)
    |> Repo.one()
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

  defp active_role_assignment_count(club_id, role_id) do
    RoleAssignmentProjection
    |> where([assignment], assignment.club_id == ^club_id)
    |> where([assignment], assignment.role_id == ^role_id)
    |> where([assignment], assignment.active == true)
    |> Repo.aggregate(:count, :membership_id)
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp club_name(word_1, word_2, word_3), do: Enum.join([word_1, word_2, word_3], " ")

  defp parse_person_list(text) do
    text
    |> String.replace(~r/,?\s+and\s+/, ", ")
    |> String.split(~r/\s*,\s*/, trim: true)
  end

  defp scenario_slug(context, club_name) do
    case Slug.default_from_name(club_name) do
      {:ok, slug} -> slug
      slug when is_binary(slug) -> slug
      _invalid -> "club-#{scenario_suffix(context)}"
    end
  end

  defp default_email_for(context, person_name) do
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
end
