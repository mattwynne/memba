defmodule Memba.Membership.GroupCommandEventModulesTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignGroupEmailSlug
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved

  test "group IDs use the Membership group typed ID prefix and cast by type" do
    group_id = ID.generate(:group)

    assert String.starts_with?(group_id, "grp_")
    assert {:ok, ^group_id} = ID.cast(:group, group_id)
    assert ID.valid?(:group, group_id)
    refute ID.valid?(:club, group_id)
  end

  test "group IDs can be deterministic for system group identities" do
    club_id = ID.generate(:club)

    group_id = ID.deterministic(:group, ["system-group", club_id, "everyone"])

    assert String.starts_with?(group_id, "grp_")
    assert group_id == ID.deterministic(:group, ["system-group", club_id, "everyone"])
    assert group_id != ID.deterministic(:group, ["system-group", club_id, "admin"])
  end

  test "group commands carry club, group, membership, and person identities" do
    ids = group_membership_ids()

    assert %CreateGroup{
             club_id: ids.club_id,
             group_id: ids.group_id,
             group_key: "everyone",
             name: "Everyone"
           } ==
             struct!(CreateGroup, %{
               club_id: ids.club_id,
               group_id: ids.group_id,
               group_key: "everyone",
               name: "Everyone"
             })

    assert %AssignGroupEmailSlug{
             club_id: ids.club_id,
             group_id: ids.group_id,
             email_slug: "everyone"
           } ==
             struct!(AssignGroupEmailSlug, %{
               club_id: ids.club_id,
               group_id: ids.group_id,
               email_slug: "everyone"
             })

    assert %AddGroupMember{
             club_id: ids.club_id,
             group_id: ids.group_id,
             membership_id: ids.membership_id,
             person_id: ids.person_id
           } == struct!(AddGroupMember, ids)

    assert %RemoveGroupMember{
             club_id: ids.club_id,
             group_id: ids.group_id,
             membership_id: ids.membership_id,
             person_id: ids.person_id
           } == struct!(RemoveGroupMember, ids)
  end

  test "group events carry the same identities and are JSON encodable" do
    ids = group_membership_ids()

    assert_json_encodable(%GroupCreated{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_key: "admin",
      name: "Admin"
    })

    assert_json_encodable(%GroupEmailSlugAssigned{
      club_id: ids.club_id,
      group_id: ids.group_id,
      email_slug: "admin"
    })

    assert_json_encodable(struct!(GroupMemberAdded, ids))
    assert_json_encodable(struct!(GroupMemberRemoved, ids))
  end

  defp group_membership_ids do
    %{
      club_id: ID.generate(:club),
      group_id: ID.generate(:group),
      membership_id: ID.generate(:membership),
      person_id: ID.generate(:person)
    }
  end

  defp assert_json_encodable(event) do
    assert {:ok, encoded} = Jason.encode(event)
    assert {:ok, decoded} = Jason.decode(encoded)
    assert decoded["club_id"] == event.club_id
    assert decoded["group_id"] == event.group_id
  end
end
