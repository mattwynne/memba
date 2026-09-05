defmodule Memba.Membership.CreateClubDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "Membership app dispatch routes CreateClub to the Club aggregate" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    command = %CreateClub{
      club_id: club_id,
      name: "Kootenay Mountaineering Club",
      slug: "kmc"
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 5,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kmc"
                },
                %ClubRoleDefined{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  role_key: "admin",
                  name: "Admin"
                },
                %ClubRolePermissionGranted{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  permission: "club.manage_members"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^everyone_group_id,
                  group_key: "everyone",
                  name: "Everyone"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  group_key: "admin",
                  name: "Admin"
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                name: "Kootenay Mountaineering Club",
                slug: "kmc",
                groups: %{
                  ^everyone_group_id => %{group_key: "everyone"},
                  ^admin_group_id => %{group_key: "admin"}
                },
                roles: %{^role_id => %{role_key: "admin"}},
                role_permissions: %{^role_id => default_role_permissions}
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert MapSet.member?(default_role_permissions, Permissions.club_manage_members())

    assert %Club{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc",
             groups: %{
               ^everyone_group_id => %{group_key: "everyone"},
               ^admin_group_id => %{group_key: "admin"}
             },
             roles: %{^role_id => %{role_key: "admin"}},
             role_permissions: %{^role_id => persisted_role_permissions}
           } =
             App.aggregate_state(Club, club_id)

    assert MapSet.member?(persisted_role_permissions, Permissions.club_manage_members())
  end

  test "Membership.create_club succeeds when the system-group policy subscriber has just restarted" do
    club_id = Memba.ID.generate(:club)

    restart_system_group_membership_from_first_subscription!()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 5
            }} =
             Membership.create_club(
               %{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong,
               returning: :execution_result,
               timeout: 1_000
             )
  end

  test "CreateGroup appends missing email-slug facts to existing system groups only once" do
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

    commands = [
      %CreateGroup{
        club_id: club_id,
        group_id: everyone_group_id,
        group_key: SystemGroups.everyone_key(),
        email_slug: "everyone",
        name: SystemGroups.everyone_name()
      },
      %CreateGroup{
        club_id: club_id,
        group_id: admin_group_id,
        group_key: SystemGroups.admin_key(),
        email_slug: "admin",
        name: SystemGroups.admin_name()
      }
    ]

    Enum.with_index(commands, 6)
    |> Enum.each(fn {command, expected_version} ->
      assert {:ok,
              %ExecutionResult{
                aggregate_uuid: ^club_id,
                aggregate_version: ^expected_version,
                events: [
                  %GroupEmailSlugAssigned{
                    club_id: ^club_id,
                    group_id: group_id,
                    email_slug: email_slug
                  }
                ]
              }} =
               App.dispatch(command, returning: :execution_result, consistency: :strong)

      assert group_id == command.group_id
      assert email_slug == command.email_slug
    end)

    Enum.each(commands, fn command ->
      assert {:ok, %ExecutionResult{aggregate_version: 7, events: []}} =
               App.dispatch(command, returning: :execution_result, consistency: :strong)
    end)

    events = EventStore.stream_forward(App, club_id) |> Enum.map(& &1.data)

    assert 2 == Enum.count(events, &match?(%GroupCreated{}, &1))
    assert 2 == Enum.count(events, &match?(%GroupEmailSlugAssigned{}, &1))
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
              aggregate_version: 6,
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
    role_id = Memba.ID.generate(:role)
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
              aggregate_version: 6,
              events: [
                %ClubRoleDefined{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  role_key: "custom_membership_manager",
                  name: "Custom Membership Manager"
                }
              ]
            }} =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: "custom_membership_manager",
                 name: "Custom Membership Manager"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 7,
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
              aggregate_version: 8,
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
              aggregate_version: 9,
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
                roles: %{^role_id => %{role_key: "custom_membership_manager"}},
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

  test "Membership app dispatch routes group commands to the Club aggregate" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
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
              aggregate_version: 6,
              events: [
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  group_key: "trail_crew",
                  name: "Trail Crew"
                }
              ]
            }} =
             App.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: "trail_crew",
                 name: "Trail Crew"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: " trail_crew ",
                 name: " Trail Crew "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 7,
              events: [
                %GroupMemberAdded{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id
                }
              ]
            }} =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              aggregate_version: 8,
              events: [
                %GroupMemberRemoved{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  membership_id: ^membership_id,
                  person_id: ^person_id
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                groups: %{^group_id => %{group_key: "trail_crew"}},
                group_memberships: %{
                  {^group_id, ^membership_id} => %{
                    person_id: ^person_id,
                    active: false
                  }
                }
              }
            }} =
             App.dispatch(
               %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  defp restart_system_group_membership_from_first_subscription! do
    child_id = system_group_membership_child_id!()

    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    assert :ok = EventStore.delete_subscription(App, :all, inspect(SystemGroupMembership))

    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, pid} when is_pid(pid) -> pid
      {:ok, pid, _info} when is_pid(pid) -> pid
      {:error, :running} -> flunk("system-group policy child was still running after termination")
      {:error, reason} -> flunk("failed to restart system-group policy child: #{inspect(reason)}")
    end
  end

  defp system_group_membership_child_id! do
    Supervisor.which_children(Memba.Supervisor)
    |> Enum.find_value(fn
      {child_id, _pid, :worker, [SystemGroupMembership]} -> child_id
      _child -> nil
    end)
    |> case do
      nil -> flunk("system-group policy child was not supervised")
      child_id -> child_id
    end
  end
end
