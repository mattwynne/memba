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

    create_club_with_admin!(destination_club_id)
    create_club!(foreign_club_id)
    create_member!(foreign_club_id, Memba.ID.generate(:membership), actor_person_id)

    assert {:error, :unauthorized} =
             create_custom_group(destination_club_id, group_id, actor_person_id)

    refute_partial_group(destination_club_id, group_id)
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
    create_club!(club_id)

    create_member!(
      club_id,
      Memba.ID.generate(:membership),
      Memba.ID.generate(:person)
    )
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

  defp create_custom_group(club_id, group_id, actor_person_id) do
    Membership.create_custom_group(
      %{
        club_id: club_id,
        group_id: group_id,
        actor_person_id: actor_person_id,
        name: "Board"
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
