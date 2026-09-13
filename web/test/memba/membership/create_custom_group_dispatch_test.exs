defmodule Memba.Membership.CreateCustomGroupDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Roles

  test "create_custom_group/2 atomically creates an addressable group with its Admin creator" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)

    assert %CreateCustomGroup{
             club_id: ^club_id,
             group_id: ^group_id,
             actor_person_id: ^actor_person_id,
             name: " Board "
           } =
             struct!(CreateCustomGroup, %{
               club_id: club_id,
               group_id: group_id,
               actor_person_id: actor_person_id,
               name: " Board "
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  group_key: nil,
                  name: "Board"
                },
                %GroupEmailSlugAssigned{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  email_slug: "board"
                },
                %GroupMemberAdded{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  membership_id: ^actor_membership_id,
                  person_id: ^actor_person_id
                }
              ]
            }} =
             Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: actor_person_id,
                 name: " Board "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %{name: "Board", email_slug: "board"} =
             App.aggregate_state(Club, club_id).groups[group_id]

    assert %GroupProjection{
             club_id: ^club_id,
             group_id: ^group_id,
             email_slug: "board",
             group_key: nil,
             name: "Board"
           } = Repo.get(GroupProjection, group_id)

    assert %GroupMembership{
             club_id: ^club_id,
             group_id: ^group_id,
             membership_id: ^actor_membership_id,
             person_id: ^actor_person_id,
             active: true
           } =
             Repo.get_by(GroupMembership,
               group_id: group_id,
               membership_id: actor_membership_id
             )
  end

  test "create_custom_group/2 requires an authenticated actor identity" do
    club_id = Memba.ID.generate(:club)

    create_club!(club_id)

    assert {:error, {:missing_required_attribute, :actor_person_id}} =
             Membership.create_custom_group(%{
               club_id: club_id,
               group_id: Memba.ID.generate(:group),
               name: "Board"
             })

    assert {:error, :invalid_actor_person_id} =
             Membership.create_custom_group(%{
               club_id: club_id,
               group_id: Memba.ID.generate(:group),
               actor_person_id: "not-a-person-id",
               name: "Board"
             })
  end

  test "create_custom_group/2 rejects a nonexistent actor without appending or projecting a group" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    create_club_with_admin!(club_id)

    assert {:error, :unauthorized} =
             create_custom_group(club_id, group_id, Memba.ID.generate(:person))

    refute_partial_group(club_id, group_id)
  end

  test "create_custom_group/2 rejects an inactive former Admin without appending or projecting a group" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)

    create_club_with_admin!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    assign_admin!(club_id, actor_membership_id, actor_person_id)

    assert :ok =
             Membership.remove_member(
               %{
                 club_id: club_id,
                 membership_id: actor_membership_id,
                 person_id: actor_person_id
               },
               consistency: :strong
             )

    assert {:error, :unauthorized} = create_custom_group(club_id, group_id, actor_person_id)
    refute_partial_group(club_id, group_id)
  end

  test "create_custom_group/2 rejects an ordinary active member without appending or projecting a group" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)

    create_club_with_admin!(club_id)
    create_member!(club_id, Memba.ID.generate(:membership), actor_person_id)

    assert {:error, :unauthorized} = create_custom_group(club_id, group_id, actor_person_id)
    refute_partial_group(club_id, group_id)
  end

  test "create_custom_group/2 rejects an Admin from another club without appending or projecting a group" do
    destination_club_id = Memba.ID.generate(:club)
    foreign_club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)
    destination_membership_id = Memba.ID.generate(:membership)

    create_club_with_admin!(destination_club_id)
    create_club!(foreign_club_id)
    create_member!(destination_club_id, destination_membership_id, actor_person_id)
    add_member!(foreign_club_id, Memba.ID.generate(:membership), actor_person_id)

    assert {:error, :unauthorized} =
             create_custom_group(destination_club_id, group_id, actor_person_id)

    refute_partial_group(destination_club_id, group_id)
  end

  test "create_custom_group/2 rejects case and outer-space variants of an existing group name" do
    club_id = Memba.ID.generate(:club)
    {actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)
    original_group_id = Memba.ID.generate(:group)

    assert :ok =
             create_custom_group(club_id, original_group_id, actor_person_id, "Board")

    for duplicate_name <- ["Board", "bOaRd", " Board "] do
      duplicate_group_id = Memba.ID.generate(:group)

      assert {:error, :group_name_already_defined} =
               create_custom_group(
                 club_id,
                 duplicate_group_id,
                 actor_person_id,
                 duplicate_name
               )

      refute_partial_group(club_id, duplicate_group_id)
    end

    assert %GroupMembership{
             membership_id: ^actor_membership_id,
             person_id: ^actor_person_id
           } = Repo.get_by(GroupMembership, group_id: original_group_id)
  end

  test "create_custom_group/2 protects Everyone and Admin names case-insensitively" do
    club_id = Memba.ID.generate(:club)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)

    for protected_name <- [" everyone ", "aDmIn"] do
      group_id = Memba.ID.generate(:group)

      assert {:error, :group_name_already_defined} =
               create_custom_group(club_id, group_id, actor_person_id, protected_name)

      refute_partial_group(club_id, group_id)
    end
  end

  test "custom group names and allocated email slugs are scoped to one Club stream" do
    first_club_id = Memba.ID.generate(:club)
    second_club_id = Memba.ID.generate(:club)
    first_group_id = Memba.ID.generate(:group)
    second_group_id = Memba.ID.generate(:group)
    {_first_membership_id, first_actor_person_id} = create_club_with_admin!(first_club_id)
    {_second_membership_id, second_actor_person_id} = create_club_with_admin!(second_club_id)

    assert :ok =
             create_custom_group(first_club_id, first_group_id, first_actor_person_id, "Board")

    assert :ok =
             create_custom_group(second_club_id, second_group_id, second_actor_person_id, "Board")

    assert %{name: "Board", email_slug: "board"} =
             App.aggregate_state(Club, first_club_id).groups[first_group_id]

    assert %{name: "Board", email_slug: "board"} =
             App.aggregate_state(Club, second_club_id).groups[second_group_id]
  end

  test "create_custom_group/2 allocates the first available club-local slug including system slugs" do
    club_id = Memba.ID.generate(:club)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)

    groups = [
      {Memba.ID.generate(:group), "Huts & maintenance", "huts-maintenance"},
      {Memba.ID.generate(:group), "Huts maintenance", "huts-maintenance-2"},
      {Memba.ID.generate(:group), "Huts--maintenance", "huts-maintenance-3"},
      {Memba.ID.generate(:group), "Admin!", "admin-2"}
    ]

    for {group_id, name, expected_slug} <- groups do
      assert :ok = create_custom_group(club_id, group_id, actor_person_id, name)

      assert %{name: ^name, email_slug: ^expected_slug} =
               App.aggregate_state(Club, club_id).groups[group_id]
    end
  end

  test "create_custom_group/2 retains non-ASCII display names and uses the fallback slug" do
    club_id = Memba.ID.generate(:club)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)
    first_group_id = Memba.ID.generate(:group)
    second_group_id = Memba.ID.generate(:group)

    assert :ok =
             create_custom_group(club_id, first_group_id, actor_person_id, " 董事会 ")

    assert :ok =
             create_custom_group(club_id, second_group_id, actor_person_id, "Совет")

    assert %{name: "董事会", email_slug: "group"} =
             App.aggregate_state(Club, club_id).groups[first_group_id]

    assert %{name: "Совет", email_slug: "group-2"} =
             App.aggregate_state(Club, club_id).groups[second_group_id]
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club"
               ),
               consistency: :strong
             )
  end

  defp create_club_with_admin!(club_id) do
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)

    create_member!(club_id, membership_id, person_id)

    {membership_id, person_id}
  end

  defp create_member!(club_id, membership_id, person_id) do
    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Test Member",
                 email: "#{person_id}@example.com"
               },
               consistency: :strong
             )

    add_member!(club_id, membership_id, person_id)
  end

  defp add_member!(club_id, membership_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )
  end

  defp assign_admin!(club_id, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )
  end

  defp create_custom_group(club_id, group_id, actor_person_id, name \\ "Board") do
    Membership.create_custom_group(
      %{
        club_id: club_id,
        group_id: group_id,
        actor_person_id: actor_person_id,
        name: name
      },
      consistency: :strong
    )
  end

  defp refute_partial_group(club_id, group_id) do
    refute Map.has_key?(App.aggregate_state(Club, club_id).groups, group_id)
    refute Repo.get(GroupProjection, group_id)
    refute Repo.get_by(GroupMembership, group_id: group_id)

    refute Enum.any?(EventStore.stream_forward(App, club_id), fn
             %{data: %{group_id: ^group_id}} -> true
             _event -> false
           end)
  end
end
