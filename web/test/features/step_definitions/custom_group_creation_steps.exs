defmodule Memba.Cucumber.CustomGroupCreationSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.GroupName
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Repo

  @kmc_name "Kootenay Mountaineering Club"
  @nelson_name "Nelson Paddling Club"

  step "Kootenay Mountaineering Club has club email slug {string}",
       %{args: [slug]} = context do
    ensure_club(context, @kmc_name, slug)
  end

  step "Alice and Dan are its club admins", context do
    Enum.reduce(["Alice", "Dan"], context, fn person_name, context ->
      ensure_admin(context, @kmc_name, person_name)
    end)
  end

  step "Bob and Eve are its ordinary active club members", context do
    Enum.reduce(["Bob", "Eve"], context, fn person_name, context ->
      ensure_ordinary_member(context, @kmc_name, person_name)
    end)
  end

  step ~r/^(\w+) creates the custom group "([^"]+)" in (.+)$/,
       %{args: [actor_name, group_name, club_name]} = context do
    {context, creation} = attempt_creation(context, actor_name, club_name, group_name)
    assert creation.result == :ok
    remember_created_group(context, creation)
  end

  step ~r/^(\w+) tries to create the custom group "([^"]+)" in (.+)$/,
       %{args: [actor_name, group_name, club_name]} = context do
    {context, _creation} = attempt_creation(context, actor_name, club_name, group_name)
    context
  end

  step ~r/^(\w+) tries to create a custom group named "([^"]+)" in (.+)$/,
       %{args: [actor_name, group_name, club_name]} = context do
    {context, _creation} = attempt_creation(context, actor_name, club_name, group_name)
    context
  end

  step ~r/^Board should belong to (.+)$/,
       %{args: [club_name]} = context do
    club_id = club_id!(context, club_name)
    assert %GroupProjection{club_id: ^club_id} = custom_group!(club_id, "Board")
    context
  end

  step ~r/^(\w+) should be its only member$/,
       %{args: [person_name]} = context do
    creation = Map.fetch!(context, :last_custom_group_creation)

    assert [%{id: person_id}] =
             Membership.list_active_members_of_group(creation.group_id)

    assert person_id == person_id!(context, person_name)
    context
  end

  step ~r/^(\w+) belongs to the custom group (.+)$/,
       %{args: [person_name, group_name]} = context do
    {context, group} = ensure_custom_group(context, @kmc_name, group_name, slug_for(group_name))
    add_group_member(context, @kmc_name, group.group_id, person_name)
  end

  step "Bob belongs to Elected committee", context do
    group = custom_group!(club_id!(context, @kmc_name), "Elected committee")
    add_group_member(context, @kmc_name, group.group_id, "Bob")
  end

  step ~r/^no custom group named "([^"]+)" should be created$/,
       %{args: [group_name]} = context do
    refute custom_group(club_id!(context, @kmc_name), group_name)
    context
  end

  step ~r/^(.+) has a custom group named "([^"]+)"$/,
       %{args: [club_name, group_name]} = context do
    club_name = canonical_club_name(club_name)
    context = ensure_club(context, club_name, default_club_slug(club_name))
    {context, _group} = ensure_custom_group(context, club_name, group_name, slug_for(group_name))
    context
  end

  step "she should be told that the group name is already in use", context do
    assert Map.fetch!(context, :last_custom_group_creation).result ==
             {:error, :group_name_already_defined}

    context
  end

  step "no additional group should be created", context do
    creation = Map.fetch!(context, :last_custom_group_creation)
    assert custom_group_count(creation.club_id) == creation.group_count_before
    context
  end

  step "each club should have its own Board group", context do
    kmc_board = custom_group!(club_id!(context, @kmc_name), "Board")
    nelson_board = custom_group!(club_id!(context, @nelson_name), "Board")

    refute kmc_board.group_id == nelson_board.group_id
    assert kmc_board.email_slug == "board"
    assert nelson_board.email_slug == "board"
    context
  end

  step "the existing system group should be unchanged", context do
    assert current_system_groups(Map.fetch!(context, :last_custom_group_creation).club_id) ==
             Map.fetch!(context, :system_groups_before_creation)

    context
  end

  step "Alice and Dan concurrently try to create the custom group {string}",
       %{args: [group_name]} = context do
    club_id = club_id!(context, @kmc_name)

    results =
      ["Alice", "Dan"]
      |> Task.async_stream(
        fn actor_name ->
          group_id = Memba.ID.generate(:group)

          %{
            actor_name: actor_name,
            actor_person_id: person_id!(context, actor_name),
            group_id: group_id,
            result:
              Membership.create_custom_group(
                %{
                  club_id: club_id,
                  group_id: group_id,
                  actor_person_id: person_id!(context, actor_name),
                  name: group_name
                },
                consistency: :strong
              )
          }
        end,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.map(fn {:ok, result} -> result end)

    Map.put(context, :concurrent_custom_group_creations, results)
  end

  step "Kootenay Mountaineering Club should have exactly one Board group", context do
    club_id = club_id!(context, @kmc_name)
    assert [board] = custom_groups_named(club_id, "Board")
    put_context(context, :groups, {@kmc_name, "Board"}, board.group_id)
  end

  step "only its successful creator should join through creation", context do
    successful_creation =
      context
      |> Map.fetch!(:concurrent_custom_group_creations)
      |> Enum.find(&(&1.result == :ok))

    assert successful_creation

    board = custom_group!(club_id!(context, @kmc_name), "Board")
    assert [%{id: member_id}] = Membership.list_active_members_of_group(board.group_id)
    assert member_id == successful_creation.actor_person_id
    context
  end

  step "the other admin should be told that the name is already in use", context do
    results = Map.fetch!(context, :concurrent_custom_group_creations)
    assert Enum.count(results, &(&1.result == :ok)) == 1

    assert Enum.count(
             results,
             &(&1.result == {:error, :group_name_already_defined})
           ) == 1

    context
  end

  step ~r/^(\w+) should have the stored email slug "([^"]+)"$/,
       %{args: [group_name, expected_slug]} = context do
    assert custom_group!(club_id!(context, @kmc_name), group_name).email_slug == expected_slug
    context
  end

  step ~r/^(\w+)'s email address should be "([^"]+)"$/,
       %{args: [group_name, expected_address]} = context do
    assert group_address(context, @kmc_name, group_name) == expected_address
    context
  end

  step ~r/^KMC has the custom group "([^"]+)" with stored email slug "([^"]+)"$/,
       %{args: [group_name, email_slug]} = context do
    {context, _group} = ensure_custom_group(context, @kmc_name, group_name, email_slug)
    context
  end

  step ~r/^"([^"]+)" should be an (.+) conversation$/,
       %{args: [subject, group_name]} = context do
    group = custom_group!(club_id!(context, @kmc_name), group_name)

    assert Enum.any?(
             Messaging.list_conversations_for_group(group.group_id),
             &(&1.subject == subject)
           )

    context
  end

  step "its stored email slug should still be {string}",
       %{args: [expected_slug]} = context do
    message = Map.fetch!(context, :sent_message)

    group =
      context
      |> Map.get(:groups, %{})
      |> Enum.find_value(fn
        {{@kmc_name, _group_name}, group_id} ->
          candidate = Membership.get_group(group_id)

          if Enum.any?(
               Messaging.list_conversations_for_group(group_id),
               &(&1.message_id == message.message_id)
             ),
             do: candidate

        _other ->
          nil
      end)

    assert %{email_slug: ^expected_slug} = group
    context
  end

  step ~r/^(.+)'s address should remain "([^"]+)"$/,
       %{args: [group_name, expected_address]} = context do
    assert group_address(context, @kmc_name, group_name) == expected_address
    context
  end

  step "Nelson Paddling Club has a Board group with stored email slug {string}",
       %{args: [email_slug]} = context do
    context = ensure_club(context, @nelson_name, default_club_slug(@nelson_name))
    {context, _group} = ensure_custom_group(context, @nelson_name, "Board", email_slug)
    context
  end

  defp attempt_creation(context, actor_name, club_name, group_name) do
    club_name = canonical_club_name(club_name)
    club_id = club_id!(context, club_name)
    group_id = Memba.ID.generate(:group)
    system_groups_before = current_system_groups(club_id)

    creation = %{
      actor_name: actor_name,
      club_id: club_id,
      club_name: club_name,
      group_count_before: custom_group_count(club_id),
      group_id: group_id,
      name: group_name,
      result:
        Membership.create_custom_group(
          %{
            club_id: club_id,
            group_id: group_id,
            actor_person_id: person_id!(context, actor_name),
            name: group_name
          },
          consistency: :strong
        )
    }

    context =
      context
      |> Map.put(:last_custom_group_creation, creation)
      |> Map.put(:system_groups_before_creation, system_groups_before)

    {context, creation}
  end

  defp remember_created_group(context, creation) do
    group = Membership.get_group(creation.group_id)

    context
    |> Map.put(:last_custom_group_creation, Map.put(creation, :name, group.name))
    |> put_context(:groups, {creation.club_name, group.name}, creation.group_id)
  end

  defp ensure_club(context, club_name, slug) do
    club_name = canonical_club_name(club_name)

    case get_in(context, [:clubs, club_name]) do
      club_id when is_binary(club_id) ->
        assert Membership.get_club(club_id).slug == slug
        context

      nil ->
        club_id = Memba.ID.generate(:club)

        assert :ok =
                 Membership.create_club(
                   %{club_id: club_id, name: club_name, slug: slug},
                   consistency: :strong
                 )

        put_context(context, :clubs, club_name, club_id)
    end
  end

  defp ensure_admin(context, club_name, person_name) do
    context = ensure_ordinary_member(context, club_name, person_name)
    club_id = club_id!(context, club_name)
    membership_id = membership_id!(context, club_name, person_name)
    person_id = person_id!(context, person_name)
    role_id = Roles.membership_administrator_role_id(club_id)

    unless Membership.person_has_club_permission?(
             club_id,
             person_id,
             Permissions.club_manage_members()
           ) do
      assert :ok =
               App.dispatch(
                 %AssignClubRoleToMember{
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

  defp ensure_ordinary_member(context, club_name, person_name) do
    context = ensure_person(context, person_name)
    club_id = club_id!(context, club_name)
    person_id = person_id!(context, person_name)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )

    put_context(
      context,
      :memberships,
      {canonical_club_name(club_name), person_name},
      membership_id
    )
  end

  defp ensure_person(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        context

      nil ->
        person_id = Memba.ID.generate(:person)
        email = "#{String.downcase(person_name)}-#{scenario_suffix(context)}@example.test"

        assert :ok =
                 Membership.create_person(
                   %{
                     person_id: person_id,
                     name: person_name,
                     email_addresses: [%{email: email, is_primary: true}]
                   },
                   consistency: :strong
                 )

        put_context(context, :people, person_name, %{
          person_id: person_id,
          email: email,
          name: person_name
        })
    end
  end

  defp ensure_custom_group(context, club_name, group_name, email_slug) do
    club_name = canonical_club_name(club_name)
    club_id = club_id!(context, club_name)

    case custom_group(club_id, group_name) do
      %GroupProjection{} = group ->
        assert group.email_slug == email_slug
        {put_context(context, :groups, {club_name, group_name}, group.group_id), group}

      nil ->
        group_id = Memba.ID.generate(:group)

        assert :ok =
                 App.dispatch(
                   %CreateGroup{
                     club_id: club_id,
                     group_id: group_id,
                     group_key: nil,
                     email_slug: email_slug,
                     name: group_name
                   },
                   consistency: :strong
                 )

        group = Membership.get_group(group_id)
        {put_context(context, :groups, {club_name, group_name}, group_id), group}
    end
  end

  defp add_group_member(context, club_name, group_id, person_name) do
    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id!(context, club_name),
                 group_id: group_id,
                 membership_id: membership_id!(context, club_name, person_name),
                 person_id: person_id!(context, person_name)
               },
               consistency: :strong
             )

    context
  end

  defp custom_group(club_id, name) do
    club_id
    |> custom_groups_named(name)
    |> List.first()
  end

  defp custom_group!(club_id, name) do
    custom_group(club_id, name) ||
      flunk("Expected club #{club_id} to have custom group #{inspect(name)}")
  end

  defp custom_groups_named(club_id, name) do
    uniqueness_key = GroupName.uniqueness_key(name)

    GroupProjection
    |> where([group], group.club_id == ^club_id)
    |> where([group], is_nil(group.group_key))
    |> Repo.all()
    |> Enum.filter(&(GroupName.uniqueness_key(&1.name) == uniqueness_key))
  end

  defp custom_group_count(club_id) do
    GroupProjection
    |> where([group], group.club_id == ^club_id)
    |> where([group], is_nil(group.group_key))
    |> Repo.aggregate(:count, :group_id)
  end

  defp current_system_groups(club_id) do
    [
      Membership.get_group(SystemGroups.everyone_group_id(club_id)),
      Membership.get_group(SystemGroups.admin_group_id(club_id))
    ]
  end

  defp group_address(context, club_name, group_name) do
    club = Membership.get_club(club_id!(context, club_name))
    group = custom_group!(club.club_id, group_name)
    ClubInboundEmailAddress.address(club, group.email_slug)
  end

  defp club_id!(context, club_name) do
    context
    |> Map.fetch!(:clubs)
    |> Map.fetch!(canonical_club_name(club_name))
  end

  defp person_id!(context, person_name) do
    context
    |> Map.fetch!(:people)
    |> Map.fetch!(person_name)
    |> Map.fetch!(:person_id)
  end

  defp membership_id!(context, club_name, person_name) do
    context
    |> Map.fetch!(:memberships)
    |> Map.fetch!({canonical_club_name(club_name), person_name})
  end

  defp put_context(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp canonical_club_name("KMC"), do: @kmc_name
  defp canonical_club_name(club_name), do: club_name

  defp default_club_slug(@kmc_name), do: "kmc"
  defp default_club_slug(@nelson_name), do: "nelson"

  defp default_club_slug(club_name) do
    club_name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp slug_for(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp scenario_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
  end
end
