defmodule Memba.Membership.AddClubMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

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
end
