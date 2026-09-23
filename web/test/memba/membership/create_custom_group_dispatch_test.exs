defmodule Memba.Membership.CreateCustomGroupDispatchTest do
  use Memba.EventSourcedCase, async: false

  import Ecto.Query
  import ExUnit.CaptureLog

  alias Commanded.Commands.ExecutionResult
  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Commanded.EventStore.RecordedEvent
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Authorization
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.ProjectionBarrier

  test "create_custom_group/2 atomically creates an addressable group with its Admin creator" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    group_membership_id = Memba.ID.generate(:group_membership)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    create_member!(club_id, actor_membership_id, actor_person_id)
    assert :ok = EventStore.subscribe(App, club_id)

    assert %CreateCustomGroup{
             club_id: ^club_id,
             group_id: ^group_id,
             group_membership_id: ^group_membership_id,
             actor_person_id: ^actor_person_id,
             name: " Board "
           } =
             struct!(CreateCustomGroup, %{
               club_id: club_id,
               group_id: group_id,
               group_membership_id: group_membership_id,
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
                },
                %GroupMembershipStarted{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  club_membership_id: ^actor_membership_id,
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

    assert_receive {:events,
                    [
                      %RecordedEvent{
                        data: %GroupCreated{group_id: ^group_id}
                      },
                      %RecordedEvent{
                        data: %GroupEmailSlugAssigned{group_id: ^group_id}
                      },
                      %RecordedEvent{
                        data: %GroupMemberAdded{
                          group_id: ^group_id,
                          membership_id: ^actor_membership_id
                        }
                      },
                      %RecordedEvent{
                        data: %GroupMembershipStarted{
                          group_id: ^group_id,
                          club_membership_id: ^actor_membership_id
                        }
                      }
                    ]}

    club = App.aggregate_state(Club, club_id)

    assert %{name: "Board", email_slug: "board"} = club.groups[group_id]
    assert club.group_name_keys["board"] == group_id

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

  test "reusing the group and creator GroupMembership identities is an exact no-op retry" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    creator_group_membership_id = Memba.ID.generate(:group_membership)
    collision_group_id = Memba.ID.generate(:group)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)

    attrs = %{
      club_id: club_id,
      group_id: group_id,
      group_membership_id: creator_group_membership_id,
      actor_person_id: actor_person_id,
      name: "Board"
    }

    assert :ok = Membership.create_custom_group(attrs, consistency: :strong)

    assert :ok =
             create_custom_group(
               club_id,
               collision_group_id,
               actor_person_id,
               "Board!"
             )

    assert %{email_slug: "board-2"} =
             App.aggregate_state(Club, club_id).groups[collision_group_id]

    events_before_retry = group_events(club_id, group_id)

    assert {:ok, %ExecutionResult{events: [], aggregate_state: %Club{} = retried_club}} =
             Membership.create_custom_group(
               attrs,
               returning: :execution_result,
               consistency: :strong
             )

    assert %{email_slug: "board", name: "Board"} = retried_club.groups[group_id]

    assert {:error, :group_already_defined} =
             Membership.create_custom_group(
               %{attrs | group_membership_id: Memba.ID.generate(:group_membership)},
               consistency: :strong
             )

    assert group_events(club_id, group_id) == events_before_retry
    assert length(events_before_retry) == 4

    assert %GroupProjection{email_slug: "board", name: "Board"} =
             Repo.get(GroupProjection, group_id)

    assert [_creator_membership] =
             Repo.all(
               from group_membership in GroupMembership,
                 where: group_membership.group_id == ^group_id
             )
  end

  test "a stable group ID cannot be reused as another creator's apparent retry" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    {creator_membership_id, creator_person_id} = create_club_with_admin!(club_id)
    other_membership_id = Memba.ID.generate(:membership)
    other_person_id = Memba.ID.generate(:person)

    create_member!(club_id, other_membership_id, other_person_id)
    assign_admin!(club_id, other_membership_id, other_person_id)

    assert :ok = create_custom_group(club_id, group_id, creator_person_id)
    events_before_reuse = group_events(club_id, group_id)

    assert {:error, :group_already_defined} =
             create_custom_group(club_id, group_id, other_person_id)

    assert group_events(club_id, group_id) == events_before_reuse

    assert %GroupMembership{
             membership_id: ^creator_membership_id,
             person_id: ^creator_person_id,
             active: true
           } = Repo.get_by(GroupMembership, group_id: group_id)

    refute Repo.get_by(GroupMembership,
             group_id: group_id,
             membership_id: other_membership_id
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

  test "create_custom_group/2 reports authorization state mismatch when projection grants but aggregate denies" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    group_name = "Board Private Plans"
    {_membership_id, actor_person_id} = create_source_backed_member_without_admin_role!(club_id)

    grant_projected_manage_members!(club_id, actor_person_id)
    assert :ok = Authorization.authorize_manage_members(club_id, actor_person_id)

    log =
      capture_log(fn ->
        assert {:error, :authorization_state_mismatch} =
                 create_custom_group(club_id, group_id, actor_person_id, group_name)
      end)

    refute_partial_group(club_id, group_id)

    assert log =~ "custom_group_creation_authorization_state_mismatch"
    assert log =~ club_id
    assert log =~ actor_person_id
    assert log =~ group_id
    assert log =~ "Memba.Membership.Commands.CreateCustomGroup"
    assert log =~ "custom_group_creation"
    assert log =~ ~s("projected_grant":true)
    assert log =~ ~s("aggregate_authorized":false)
    refute log =~ group_name
  end

  test "create_custom_group/2 still returns unauthorized when projection also denies" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    {_membership_id, actor_person_id} = create_source_backed_member_without_admin_role!(club_id)

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

  test "concurrent same-name attempts serialize to one group and one creator membership" do
    club_id = Memba.ID.generate(:club)
    first_group_id = Memba.ID.generate(:group)
    second_group_id = Memba.ID.generate(:group)
    {first_membership_id, first_person_id} = create_club_with_admin!(club_id)
    second_membership_id = Memba.ID.generate(:membership)
    second_person_id = Memba.ID.generate(:person)

    create_member!(club_id, second_membership_id, second_person_id)
    assign_admin!(club_id, second_membership_id, second_person_id)

    results =
      [{first_group_id, first_person_id}, {second_group_id, second_person_id}]
      |> Task.async_stream(
        fn {group_id, actor_person_id} ->
          {group_id, create_custom_group(club_id, group_id, actor_person_id, "Board")}
        end,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &match?({_group_id, :ok}, &1)) == 1

    assert Enum.count(
             results,
             &match?({_group_id, {:error, :group_name_already_defined}}, &1)
           ) == 1

    [{successful_group_id, :ok}] =
      Enum.filter(results, &match?({_group_id, :ok}, &1))

    expected_creator =
      if successful_group_id == first_group_id do
        {first_membership_id, first_person_id}
      else
        {second_membership_id, second_person_id}
      end

    assert [
             %GroupMembership{
               membership_id: creator_membership_id,
               person_id: creator_person_id,
               active: true
             }
           ] =
             Repo.all(
               from group_membership in GroupMembership,
                 where: group_membership.group_id == ^successful_group_id
             )

    assert {creator_membership_id, creator_person_id} == expected_creator

    assert [%GroupProjection{name: "Board", email_slug: "board"}] =
             Repo.all(
               from group in GroupProjection,
                 where:
                   group.club_id == ^club_id and
                     group.name_uniqueness_key == "board"
             )
  end

  test "concurrent distinct names with one slug stem receive different replay-stable addresses" do
    club_id = Memba.ID.generate(:club)
    first_group_id = Memba.ID.generate(:group)
    second_group_id = Memba.ID.generate(:group)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)

    results =
      [{"Board!", first_group_id}, {"Board?", second_group_id}]
      |> Task.async_stream(
        fn {name, group_id} ->
          {group_id, create_custom_group(club_id, group_id, actor_person_id, name)}
        end,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.sort(results) == Enum.sort([{first_group_id, :ok}, {second_group_id, :ok}])

    slugs =
      club_id
      |> then(&App.aggregate_state(Club, &1))
      |> Map.fetch!(:groups)
      |> Map.take([first_group_id, second_group_id])
      |> Map.values()
      |> Enum.map(& &1.email_slug)
      |> Enum.sort()

    assert slugs == ["board", "board-2"]

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    replayed_slugs =
      club_id
      |> then(&App.aggregate_state(Club, &1))
      |> Map.fetch!(:groups)
      |> Map.take([first_group_id, second_group_id])
      |> Map.values()
      |> Enum.map(& &1.email_slug)
      |> Enum.sort()

    assert replayed_slugs == slugs
  end

  test "aggregate name uniqueness remains authoritative when its projection is missing" do
    club_id = Memba.ID.generate(:club)
    {_actor_membership_id, actor_person_id} = create_club_with_admin!(club_id)
    original_group_id = Memba.ID.generate(:group)
    duplicate_group_id = Memba.ID.generate(:group)

    assert :ok = create_custom_group(club_id, original_group_id, actor_person_id, "Board")

    assert {1, nil} =
             Repo.delete_all(
               from group in GroupProjection, where: group.group_id == ^original_group_id
             )

    assert {:error, :group_name_already_defined} =
             create_custom_group(club_id, duplicate_group_id, actor_person_id, " BOARD ")

    refute_partial_group(club_id, duplicate_group_id)
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

  defp create_source_backed_member_without_admin_role!(club_id) do
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    role_id = Roles.membership_administrator_role_id(club_id)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Projection Admin",
                 email: "#{person_id}@example.com"
               },
               consistency: :strong
             )

    events =
      [
        %ClubCreated{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
        %ClubRoleDefined{
          club_id: club_id,
          role_id: role_id,
          role_key: Roles.membership_administrator_key(),
          name: Roles.membership_administrator_name()
        },
        %ClubRolePermissionGranted{
          club_id: club_id,
          role_id: role_id,
          permission: Permissions.club_manage_members()
        },
        %GroupCreated{
          club_id: club_id,
          group_id: SystemGroups.everyone_group_id(club_id),
          group_key: SystemGroups.everyone_key(),
          name: SystemGroups.everyone_name()
        },
        %GroupEmailSlugAssigned{
          club_id: club_id,
          group_id: SystemGroups.everyone_group_id(club_id),
          email_slug: SystemGroups.everyone_email_slug()
        },
        %GroupCreated{
          club_id: club_id,
          group_id: SystemGroups.admin_group_id(club_id),
          group_key: SystemGroups.admin_key(),
          name: SystemGroups.admin_name()
        },
        %GroupEmailSlugAssigned{
          club_id: club_id,
          group_id: SystemGroups.admin_group_id(club_id),
          email_slug: SystemGroups.admin_email_slug()
        },
        %ClubMemberAdded{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        }
      ]
      |> Enum.map(&Mapper.map_to_event_data/1)

    assert :ok = EventStore.append_to_stream(App, club_id, 0, events)

    ProjectionBarrier.await!(
      [
        Memba.Membership.Projectors.Club,
        Memba.Membership.Projectors.Group,
        Memba.Membership.Projectors.Membership
      ],
      timeout: 5_000
    )

    {membership_id, person_id}
  end

  defp grant_projected_manage_members!(club_id, person_id) do
    membership_id =
      club_id
      |> Membership.list_active_members_of_club()
      |> Enum.find(&(&1.id == person_id))
      |> Map.fetch!(:membership_id)

    Repo.insert!(%MemberPermission{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
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

  defp group_events(club_id, group_id) do
    club_id
    |> then(&EventStore.stream_forward(App, &1))
    |> Enum.filter(fn
      %{data: %{group_id: ^group_id}} -> true
      _event -> false
    end)
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
