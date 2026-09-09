defmodule Memba.Membership.WriteApiTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Roles

  test "add_member/2 delegates duplicate and first-member decisions to Club state" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    admin_role_id = Roles.membership_administrator_role_id(club_id)

    create_club!(club_id)

    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person_id,
      active: true
    })

    attrs = %{club_id: club_id, membership_id: membership_id, person_id: person_id}

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %MemberAdded{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id
                },
                %MemberRoleAssigned{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id,
                  role_id: ^admin_role_id
                }
              ]
            }} =
             Membership.add_member(attrs,
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{aggregate_uuid: ^club_id, events: []}} =
             Membership.add_member(attrs,
               returning: :execution_result,
               consistency: :strong
             )

    assert {:error, :already_active_member} =
             Membership.add_member(
               %{attrs | membership_id: Memba.ID.generate(:membership)},
               consistency: :strong
             )
  end

  test "role assignment delegates target activity to Club state when its projection is absent" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    role_id = Memba.ID.generate(:role)

    create_club!(club_id)
    add_member!(club_id, actor_membership_id, actor_person_id)
    add_member!(club_id, target_membership_id, target_person_id)
    define_role!(club_id, role_id)

    Repo.delete_all(
      from membership in MembershipProjection,
        where: membership.membership_id == ^target_membership_id
    )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %MemberRoleAssigned{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  assigned_by_person_id: ^actor_person_id
                }
              ]
            }} =
             Membership.assign_member_role_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id,
                 role_id: role_id,
                 actor_person_id: actor_person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "Admin removal delegates the Admin floor to Club state when its projection is stale" do
    club_id = Memba.ID.generate(:club)
    actor_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    admin_role_id = Roles.membership_administrator_role_id(club_id)

    create_club!(club_id)
    add_member!(club_id, actor_membership_id, actor_person_id)
    add_member!(club_id, target_membership_id, target_person_id)

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id,
                 role_id: admin_role_id
               },
               consistency: :strong
             )

    Repo.delete_all(
      from assignment in RoleAssignment,
        where: assignment.membership_id == ^actor_membership_id,
        where: assignment.role_id == ^admin_role_id
    )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %MemberRoleRemoved{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^admin_role_id,
                  removed_by_person_id: ^actor_person_id
                }
              ]
            }} =
             Membership.remove_membership_administrator_as_club_member(
               %{
                 club_id: club_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id,
                 actor_person_id: actor_person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "remove_member/2 uses explicit routing identity but delegates the member floor to Club state" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    create_club!(club_id)
    add_member!(club_id, membership_id, person_id)

    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: Memba.ID.generate(:person),
      active: true
    })

    assert {:error, :last_active_member} =
             Membership.remove_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id),
               consistency: :strong
             )
  end

  defp add_member!(club_id, membership_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )
  end

  defp define_role!(club_id, role_id) do
    assert :ok =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 name: "Roster Helper"
               },
               consistency: :strong
             )
  end
end
