defmodule Memba.Membership.GroupProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Projectors.Group
  alias Memba.Membership.Projectors.GroupMembership
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.SystemGroups

  test "group projectors are configured for strong consistency" do
    assert %{start: {Group, :start_link, [group_opts]}} = Group.child_spec([])
    assert Keyword.fetch!(group_opts, :consistency) == :strong

    assert %{start: {GroupMembership, :start_link, [group_membership_opts]}} =
             GroupMembership.child_spec([])

    assert Keyword.fetch!(group_membership_opts, :consistency) == :strong
  end

  test "CreateClub projects the deterministic system groups" do
    club_id = Memba.ID.generate(:club)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    assert %GroupProjection{
             group_id: ^everyone_group_id,
             club_id: ^club_id,
             group_key: "everyone",
             name: "Everyone"
           } = Repo.get(GroupProjection, everyone_group_id)

    assert %GroupProjection{
             group_id: ^admin_group_id,
             club_id: ^club_id,
             group_key: "admin",
             name: "Admin"
           } = Repo.get(GroupProjection, admin_group_id)
  end

  test "AddGroupMember projects an active group membership row" do
    club_id = Memba.ID.generate(:club)
    group_id = SystemGroups.everyone_group_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)

    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %GroupMembershipProjection{
             club_id: ^club_id,
             group_id: ^group_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             active: true
           } = group_membership(group_id, membership_id)
  end

  test "group membership projection toggles one current-state row while events retain history" do
    club_id = Memba.ID.generate(:club)
    group_id = SystemGroups.everyone_group_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club!(club_id)

    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %GroupMembershipProjection{active: true, inserted_at: inserted_at} =
             group_membership(group_id, membership_id)

    assert :ok =
             App.dispatch(
               %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %GroupMembershipProjection{
             active: false,
             inserted_at: ^inserted_at
           } = group_membership(group_id, membership_id)

    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %GroupMembershipProjection{
             active: true,
             inserted_at: ^inserted_at
           } = group_membership(group_id, membership_id)

    assert 1 == group_membership_count(group_id, membership_id)

    assert [GroupMemberAdded, GroupMemberRemoved, GroupMemberAdded] ==
             club_id
             |> group_membership_events(group_id, membership_id)
             |> Enum.map(& &1.__struct__)
  end

  defp create_club!(club_id) do
    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )
  end

  defp group_membership_count(group_id, membership_id) do
    Repo.aggregate(
      from(group_membership in GroupMembershipProjection,
        where: group_membership.group_id == ^group_id,
        where: group_membership.membership_id == ^membership_id
      ),
      :count
    )
  end

  defp group_membership(group_id, membership_id) do
    Repo.one(
      from(group_membership in GroupMembershipProjection,
        where: group_membership.group_id == ^group_id,
        where: group_membership.membership_id == ^membership_id
      )
    )
  end

  defp group_membership_events(club_id, group_id, membership_id) do
    App
    |> Commanded.EventStore.stream_forward(club_id)
    |> Enum.map(& &1.data)
    |> Enum.filter(fn
      %{group_id: ^group_id, membership_id: ^membership_id} -> true
      _event -> false
    end)
  end
end
