defmodule Memba.Membership.WriteApiTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.ClubMember
  alias Memba.Membership.CommandDispatch, as: MembershipCommandDispatch

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
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
                %ClubMemberAdded{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id
                },
                %ClubRoleAssignedToMember{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id,
                  role_id: ^admin_role_id
                }
              ]
            }} =
             (with {:ok, command} <- AddMember.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    assert {:ok, %ExecutionResult{aggregate_uuid: ^club_id, events: []}} =
             (with {:ok, command} <- AddMember.prepare(attrs) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    assert {:error, :already_active_member} =
             (with {:ok, command} <-
                     AddMember.prepare(%{attrs | membership_id: Memba.ID.generate(:membership)}) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
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
                %ClubRoleAssignedToMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^role_id,
                  assigned_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_assign(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       role_id: role_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)
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
               %AssignClubRoleToMember{
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
                %ClubRoleRemovedFromMember{
                  club_id: ^club_id,
                  membership_id: ^target_membership_id,
                  person_id: ^target_person_id,
                  role_id: ^admin_role_id,
                  removed_by_person_id: ^actor_person_id
                }
              ]
            }} =
             (with {:ok, command} <-
                     ClubMember.Role.prepare_remove_administrator(%{
                       club_id: club_id,
                       membership_id: target_membership_id,
                       person_id: target_person_id,
                       actor_person_id: actor_person_id
                     }) do
                MembershipCommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)
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
             (with {:ok, command} <-
                     ClubMember.Remove.prepare(%{
                       club_id: club_id,
                       membership_id: membership_id,
                       person_id: person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp create_club!(club_id) do
    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(membership_club_attrs(club_id: club_id)) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
  end

  defp add_member!(club_id, membership_id, person_id) do
    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       club_id: club_id,
                       membership_id: membership_id,
                       person_id: person_id
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)
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
