defmodule Memba.Membership.RemoveCustomGroupMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.GroupMembershipSubscriptionRevocationReceipt

  test "a projected row without the canonical receipt cannot complete removal" do
    person_id = ID.generate(:person)
    group_membership_id = ID.generate(:group_membership)

    revocation_id =
      Memba.Messaging.PersonConversationSubscriptions.revocation_id(group_membership_id)

    Repo.insert!(%GroupMembershipSubscriptionRevocationReceipt{
      revocation_id: revocation_id,
      person_id: person_id,
      group_membership_id: group_membership_id,
      completed: true
    })

    refute Memba.Messaging.group_membership_subscription_revocation_completed?(
             person_id,
             group_membership_id,
             revocation_id
           )
  end

  test "a current group member removes a peer only after the durable revocation receipt" do
    ids = fixture!()
    club_members_before = Membership.list_active_members_of_club(ids.club_id)

    assert {:ok,
            %CustomGroupRemoval{
              transition: :member_removed,
              membership_id: target_membership_id,
              club_membership_id: target_membership_id,
              group_membership_id: target_group_membership_id,
              revocation_id: revocation_id,
              subscription_revocation_completed: true
            }} = remove(ids, ids.actor_person_id)

    assert target_membership_id == ids.target_membership_id
    assert target_group_membership_id == ids.target_group_membership_id
    assert Membership.list_active_members_of_club(ids.club_id) == club_members_before
    refute Membership.active_member_of_group?(ids.group_id, ids.target_person_id)

    assert %{completed: true, group_membership_id: ^target_group_membership_id} =
             Memba.Messaging.get_group_membership_subscription_revocation_receipt(revocation_id)
  end

  test "self-removal and removal of the last person are allowed" do
    ids = fixture!()

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.target_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.actor_person_id,
               group_membership_id: ids.owner_group_membership_id,
               club_membership_id: ids.owner_membership_id,
               person_id: ids.owner_person_id
             )

    actor_operation_id = Ecto.UUID.generate()

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             Membership.remove_custom_group_member(
               %{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 group_membership_id: ids.actor_group_membership_id,
                 club_membership_id: ids.actor_membership_id,
                 person_id: ids.actor_person_id,
                 actor_person_id: ids.actor_person_id,
                 removal_operation_id: actor_operation_id
               },
               consistency: :strong
             )

    assert Membership.list_active_members_of_group(ids.group_id) == []
    assert Enum.count(Membership.list_active_members_of_club(ids.club_id)) == 4
  end

  test "an active Admin outside the group removes a member without joining" do
    ids = fixture!()

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: ids.club_id,
                 membership_id: ids.admin_membership_id,
                 person_id: ids.admin_person_id,
                 role_id: Roles.membership_administrator_role_id(ids.club_id)
               },
               consistency: :strong
             )

    refute Membership.active_member_of_group?(ids.group_id, ids.admin_person_id)

    assert {:ok, %CustomGroupRemoval{transition: :member_removed}} =
             remove(ids, ids.admin_person_id)

    refute Membership.active_member_of_group?(ids.group_id, ids.admin_person_id)
  end

  test "unauthorized actors, target mismatches, and system groups are rejected" do
    ids = fixture!()

    assert {:error, :unauthorized} = remove(ids, ids.admin_person_id)

    assert {:error, :membership_person_mismatch} =
             remove(ids, ids.actor_person_id, person_id: ids.admin_person_id)

    assert {:error, :club_membership_identity_mismatch} =
             Membership.remove_custom_group_member(%{
               club_id: ids.club_id,
               group_id: ids.group_id,
               group_membership_id: ids.target_group_membership_id,
               club_membership_id: ids.target_membership_id,
               membership_id: ids.admin_membership_id,
               person_id: ids.target_person_id,
               actor_person_id: ids.actor_person_id,
               removal_operation_id: Ecto.UUID.generate()
             })

    for group_id <- [
          SystemGroups.everyone_group_id(ids.club_id),
          SystemGroups.admin_group_id(ids.club_id)
        ] do
      assert {:error, :system_group_not_allowed} =
               remove(ids, ids.actor_person_id,
                 group_id: group_id,
                 group_membership_id: ID.generate(:group_membership)
               )
    end
  end

  test "exact retry is event-free, conflicting reuse fails, and delayed old removal cannot end a re-add" do
    ids = fixture!()
    operation_id = Ecto.UUID.generate()

    assert {:ok, %CustomGroupRemoval{transition: :member_removed} = prior_outcome} =
             remove(ids, ids.actor_person_id, removal_operation_id: operation_id)

    version_after_removal = App.aggregate_state(Club, ids.club_id).stream_version

    assert {:ok, ^prior_outcome} =
             remove(ids, ids.actor_person_id, removal_operation_id: operation_id)

    assert App.aggregate_state(Club, ids.club_id).stream_version == version_after_removal

    new_group_membership_id = ID.generate(:group_membership)

    assert {:ok, %{transition: :member_added}} =
             Membership.add_custom_group_member(
               %{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 group_membership_id: new_group_membership_id,
                 membership_id: ids.target_membership_id,
                 person_id: ids.target_person_id,
                 actor_person_id: ids.actor_person_id
               },
               consistency: :strong
             )

    assert {:error, :removal_operation_id_already_used} =
             remove(ids, ids.actor_person_id,
               removal_operation_id: operation_id,
               group_membership_id: new_group_membership_id
             )

    assert {:error, :group_membership_not_current} =
             remove(ids, ids.actor_person_id, removal_operation_id: Ecto.UUID.generate())

    assert Membership.active_member_of_group?(ids.group_id, ids.target_person_id)
  end

  test "exact retry and conflicting reuse remain deterministic after the actor leaves the club" do
    ids = fixture!()
    operation_id = Ecto.UUID.generate()
    attrs = removal_attrs(ids, ids.actor_person_id, removal_operation_id: operation_id)

    assert {:ok, %CustomGroupRemoval{} = prior_outcome} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert :ok =
             Membership.remove_member(
               %{
                 club_id: ids.club_id,
                 membership_id: ids.actor_membership_id,
                 person_id: ids.actor_person_id
               },
               consistency: :strong
             )

    assert {:ok, ^prior_outcome} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert {:error, :removal_operation_id_already_used} =
             Membership.remove_custom_group_member(
               %{attrs | group_membership_id: ID.generate(:group_membership)},
               consistency: :strong
             )
  end

  test "exact retry and conflicting reuse remain deterministic after the target leaves the club" do
    ids = fixture!()
    operation_id = Ecto.UUID.generate()
    attrs = removal_attrs(ids, ids.actor_person_id, removal_operation_id: operation_id)

    assert {:ok, %CustomGroupRemoval{} = prior_outcome} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert :ok =
             Membership.remove_member(
               %{
                 club_id: ids.club_id,
                 membership_id: ids.target_membership_id,
                 person_id: ids.target_person_id
               },
               consistency: :strong
             )

    assert {:ok, ^prior_outcome} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert {:error, :removal_operation_id_already_used} =
             Membership.remove_custom_group_member(
               %{attrs | person_id: ids.owner_person_id},
               consistency: :strong
             )
  end

  test "ending a group membership preserves the target's club role" do
    ids = fixture!()

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: ids.club_id,
                 membership_id: ids.target_membership_id,
                 person_id: ids.target_person_id,
                 role_id: Roles.membership_administrator_role_id(ids.club_id)
               },
               consistency: :strong
             )

    assert Membership.person_has_club_permission?(
             ids.club_id,
             ids.target_person_id,
             Permissions.club_manage_members()
           )

    assert {:ok, %CustomGroupRemoval{}} = remove(ids, ids.actor_person_id)

    assert Membership.person_has_club_permission?(
             ids.club_id,
             ids.target_person_id,
             Permissions.club_manage_members()
           )
  end

  defp fixture! do
    ids = %{
      club_id: ID.generate(:club),
      group_id: ID.generate(:group),
      owner_person_id: ID.generate(:person),
      owner_membership_id: ID.generate(:membership),
      owner_group_membership_id: ID.generate(:group_membership),
      actor_person_id: ID.generate(:person),
      actor_membership_id: ID.generate(:membership),
      actor_group_membership_id: ID.generate(:group_membership),
      target_person_id: ID.generate(:person),
      target_membership_id: ID.generate(:membership),
      target_group_membership_id: ID.generate(:group_membership),
      admin_person_id: ID.generate(:person),
      admin_membership_id: ID.generate(:membership)
    }

    assert :ok =
             Membership.create_club(membership_club_attrs(club_id: ids.club_id),
               consistency: :strong
             )

    for {membership_id, person_id} <- [
          {ids.owner_membership_id, ids.owner_person_id},
          {ids.actor_membership_id, ids.actor_person_id},
          {ids.target_membership_id, ids.target_person_id},
          {ids.admin_membership_id, ids.admin_person_id}
        ] do
      assert :ok =
               Membership.create_person(
                 %{person_id: person_id, name: "Member", email: "#{person_id}@example.com"},
                 consistency: :strong
               )

      assert :ok =
               Membership.add_member(
                 %{club_id: ids.club_id, membership_id: membership_id, person_id: person_id},
                 consistency: :strong
               )
    end

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 group_membership_id: ids.owner_group_membership_id,
                 actor_person_id: ids.owner_person_id,
                 name: "Board"
               },
               consistency: :strong
             )

    for {group_membership_id, membership_id, person_id} <- [
          {ids.actor_group_membership_id, ids.actor_membership_id, ids.actor_person_id},
          {ids.target_group_membership_id, ids.target_membership_id, ids.target_person_id}
        ] do
      assert {:ok, %{transition: :member_added}} =
               Membership.add_custom_group_member(
                 %{
                   club_id: ids.club_id,
                   group_id: ids.group_id,
                   group_membership_id: group_membership_id,
                   membership_id: membership_id,
                   person_id: person_id,
                   actor_person_id: ids.owner_person_id
                 },
                 consistency: :strong
               )
    end

    ids
  end

  defp remove(ids, actor_person_id, opts \\ []) do
    ids
    |> removal_attrs(actor_person_id, opts)
    |> Membership.remove_custom_group_member(consistency: :strong)
  end

  defp removal_attrs(ids, actor_person_id, opts) do
    %{
      club_id: ids.club_id,
      group_id: Keyword.get(opts, :group_id, ids.group_id),
      group_membership_id:
        Keyword.get(opts, :group_membership_id, ids.target_group_membership_id),
      club_membership_id: Keyword.get(opts, :club_membership_id, ids.target_membership_id),
      person_id: Keyword.get(opts, :person_id, ids.target_person_id),
      actor_person_id: actor_person_id,
      removal_operation_id: Keyword.get(opts, :removal_operation_id, Ecto.UUID.generate())
    }
  end
end
