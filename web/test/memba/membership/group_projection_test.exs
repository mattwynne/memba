defmodule Memba.Membership.GroupProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.SystemGroups

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

  defp group_membership(group_id, membership_id) do
    Repo.one(
      from(group_membership in GroupMembershipProjection,
        where: group_membership.group_id == ^group_id,
        where: group_membership.membership_id == ^membership_id
      )
    )
  end
end
