defmodule Memba.Membership.AddClubMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.ClubCommands
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubMember
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.MembershipQueries
  alias Memba.Membership.ClubGroupQueries

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Roles

  test "legacy membership-ID aggregate write model is not available" do
    refute Code.ensure_loaded?(Memba.Membership.Membership)
  end

  test "Membership app routes member activation and removal to the Club aggregate" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    replacement_person_id = Memba.ID.generate(:person)
    replacement_membership_id = Memba.ID.generate(:membership)
    admin_role_id = Roles.membership_administrator_role_id(club_id)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    command = %AddClubMember{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubMemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                },
                %ClubRoleAssignedToMember{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id,
                  role_id: ^admin_role_id
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                active_memberships: %{^membership_id => ^person_id}
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert [
             %{stream_version: 8, data: %ClubMemberAdded{membership_id: ^membership_id}},
             %{
               stream_version: 9,
               data: %ClubRoleAssignedToMember{
                 membership_id: ^membership_id,
                 role_id: ^admin_role_id,
                 assignment_source: "automatic_first_club_member"
               }
             }
           ] =
             App
             |> EventStore.stream_forward(club_id)
             |> Enum.slice(7, 2)

    assert :ok =
             App.dispatch(
               %AddClubMember{
                 membership_id: replacement_membership_id,
                 club_id: club_id,
                 person_id: replacement_person_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: replacement_membership_id,
                 person_id: replacement_person_id,
                 role_id: admin_role_id
               },
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubMemberRemoved{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                active_memberships: %{^replacement_membership_id => ^replacement_person_id}
              }
            }} =
             App.dispatch(
               %RemoveClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "Membership app requires the routed Club aggregate to exist" do
    command = %AddClubMember{
      membership_id: Memba.ID.generate(:membership),
      club_id: Memba.ID.generate(:club),
      person_id: Memba.ID.generate(:person)
    }

    assert {:error, :not_created} = App.dispatch(command)
  end

  test "AddMember preparation and dispatch prevent duplicate active club memberships" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Alice",
                       email: "alice@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubMemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                },
                %ClubRoleAssignedToMember{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id,
                  assignment_source: "automatic_first_club_member"
                }
              ]
            }} =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: membership_id,
                       club_id: club_id,
                       person_id: person_id
                     }) do
                CommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    assert MembershipQueries.active_member_of_club?(club_id, person_id)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       "membership_id" => membership_id,
                       "club_id" => club_id,
                       "person_id" => person_id
                     }) do
                CommandDispatch.dispatch(command)
              end)

    assert {:error, :already_active_member} =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: Memba.ID.generate(:membership),
                       club_id: club_id,
                       person_id: person_id
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert [%{id: ^person_id, membership_id: ^membership_id}] =
             ClubGroupQueries.list_active_members_of_club(club_id)

    replacement_person_id = Memba.ID.generate(:person)
    replacement_membership_id = Memba.ID.generate(:membership)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: replacement_person_id,
                       name: "Bob",
                       email: "bob@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: replacement_membership_id,
                       club_id: club_id,
                       person_id: replacement_person_id
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: replacement_membership_id,
                 person_id: replacement_person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [%ClubMemberRemoved{membership_id: ^membership_id}]
            }} =
             (with {:ok, command} <- ClubMember.Remove.prepare(%{membership_id: membership_id}) do
                CommandDispatch.dispatch(command,
                  returning: :execution_result,
                  consistency: :strong
                )
              end)

    refute MembershipQueries.active_member_of_club?(club_id, person_id)

    assert [%{id: ^replacement_person_id, membership_id: ^replacement_membership_id}] =
             ClubGroupQueries.list_active_members_of_club(club_id)
  end
end
