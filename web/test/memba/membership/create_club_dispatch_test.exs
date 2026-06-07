defmodule Memba.Membership.CreateClubDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles

  test "Membership app dispatch routes CreateClub to the Club aggregate" do
    club_id = Memba.ID.generate(:club)

    command = %CreateClub{
      club_id: club_id,
      name: "Kootenay Mountaineering Club",
      slug: "kmc"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 1,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kmc"
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                name: "Kootenay Mountaineering Club",
                slug: "kmc"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %Club{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc"
           } =
             App.aggregate_state(Club, club_id)
  end

  test "Membership app rejects a duplicate CreateClub for the same aggregate identity" do
    command = %CreateClub{
      club_id: Memba.ID.generate(:club),
      name: "Kootenay Mountaineering Club",
      slug: "kmc"
    }

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_created} = App.dispatch(command)
  end

  test "Membership app dispatch routes UpdateClub to the Club aggregate" do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    command = %UpdateClub{
      club_id: club_id,
      name: "KMC Alpine Club",
      slug: "kmc-alpine"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 2,
              events: [
                %ClubUpdated{
                  club_id: ^club_id,
                  name: "KMC Alpine Club",
                  slug: "kmc-alpine"
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                name: "KMC Alpine Club",
                slug: "kmc-alpine"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)
  end

  test "Membership app dispatch routes role and permission commands to the Club aggregate" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 2,
              events: [
                %ClubRoleDefined{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  role_key: "membership_administrator",
                  name: "Membership Administrator"
                }
              ]
            }} =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: Roles.membership_administrator_key(),
                 name: Roles.membership_administrator_name()
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 3,
              events: [
                %ClubRolePermissionGranted{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  permission: "club.manage_members"
                }
              ]
            }} =
             App.dispatch(
               %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: role_id,
                 permission: Permissions.club_manage_members()
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 4,
              events: [
                %MemberRoleAssigned{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id,
                  role_id: ^role_id
                }
              ]
            }} =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 5,
              events: [
                %MemberRoleRemoved{
                  club_id: ^club_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id,
                  role_id: ^role_id
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                roles: %{^role_id => %{role_key: "membership_administrator"}},
                role_assignments: %{}
              }
            }} =
             App.dispatch(
               %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end
end
