defmodule Memba.Membership.ClubTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignGroupEmailSlug
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
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  describe "execute/2 CreateClub" do
    test "emits ClubCreated, initializes the default Admin bundle, and creates system groups" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      everyone_group_id = SystemGroups.everyone_group_id(club_id)
      admin_group_id = SystemGroups.admin_group_id(club_id)

      command = %CreateClub{
        club_id: club_id,
        name: " Kootenay Mountaineering Club ",
        slug: "kmc"
      }

      assert [
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
               %GroupEmailSlugAssigned{
                 club_id: ^club_id,
                 group_id: ^everyone_group_id,
                 email_slug: "everyone"
               },
               %GroupCreated{
                 club_id: ^club_id,
                 group_id: ^admin_group_id,
                 group_key: "admin",
                 name: "Admin"
               },
               %GroupEmailSlugAssigned{
                 club_id: ^club_id,
                 group_id: ^admin_group_id,
                 email_slug: "admin"
               }
             ] = Club.execute(%Club{}, command)
    end

    test "rejects missing or malformed club UUIDs" do
      assert {:error, :invalid_club_id} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: nil,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               })

      assert {:error, :invalid_club_id} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: "not-a-uuid",
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               })
    end

    test "rejects blank club names" do
      assert {:error, :invalid_name} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: Memba.ID.generate(:club),
                 name: "  ",
                 slug: "kmc"
               })
    end

    test "rejects missing club slugs" do
      assert {:error, :invalid_format} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: Memba.ID.generate(:club),
                 name: "Kootenay Mountaineering Club"
               })
    end

    test "rejects creating the same aggregate twice" do
      club_id = Memba.ID.generate(:club)

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert {:error, :already_created} =
               Club.execute(club, %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               })
    end
  end

  describe "execute/2 UpdateClub" do
    test "emits ClubUpdated for an existing club" do
      club_id = Memba.ID.generate(:club)

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert %ClubUpdated{
               club_id: ^club_id,
               name: "KMC Alpine Club",
               slug: "kmc-alpine"
             } =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: " KMC Alpine Club ",
                 slug: "kmc-alpine"
               })
    end

    test "rejects updating a club that has not been created" do
      assert {:error, :not_created} =
               Club.execute(%Club{}, %UpdateClub{
                 club_id: Memba.ID.generate(:club),
                 name: "KMC Alpine Club",
                 slug: "kmc-alpine"
               })
    end

    test "rejects invalid updated club names and slugs" do
      club_id = Memba.ID.generate(:club)

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert {:error, :invalid_name} =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: " ",
                 slug: "kmc-alpine"
               })

      assert {:error, :invalid_format} =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: "KMC Alpine Club",
                 slug: "KMC Alpine!"
               })
    end
  end

  describe "execute/2 DefineClubRole" do
    test "emits ClubRoleDefined for the default Admin role" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      club = created_club(club_id)

      assert %ClubRoleDefined{
               club_id: ^club_id,
               role_id: ^role_id,
               role_key: "admin",
               name: "Admin"
             } =
               Club.execute(club, %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: Roles.membership_administrator_key(),
                 name: " Admin "
               })
    end

    test "rejects duplicate role IDs and duplicate built-in role keys" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)

      assert {:error, :role_already_defined} =
               Club.execute(club, %DefineClubRole{
                 club_id: club_id,
                 role_id: role_id,
                 role_key: "custom_membership_administrator",
                 name: "Custom Admin"
               })

      assert {:error, :role_key_already_defined} =
               Club.execute(club, %DefineClubRole{
                 club_id: club_id,
                 role_id: Memba.ID.generate(:role),
                 role_key: Roles.membership_administrator_key(),
                 name: "Admin"
               })
    end

    test "rejects defining a role before the club exists" do
      assert {:error, :not_created} =
               Club.execute(%Club{}, %DefineClubRole{
                 club_id: Memba.ID.generate(:club),
                 role_id: Memba.ID.generate(:role),
                 role_key: Roles.membership_administrator_key(),
                 name: Roles.membership_administrator_name()
               })
    end
  end

  describe "execute/2 GrantClubRolePermission" do
    test "emits ClubRolePermissionGranted for club.manage_members" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)

      assert %ClubRolePermissionGranted{
               club_id: ^club_id,
               role_id: ^role_id,
               permission: "club.manage_members"
             } =
               Club.execute(club, %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: role_id,
                 permission: Permissions.club_manage_members()
               })
    end

    test "rejects unknown roles, unknown permissions, and duplicate grants" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      unknown_role_id = Memba.ID.generate(:role)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)

      assert {:error, :role_not_defined} =
               Club.execute(club, %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: unknown_role_id,
                 permission: Permissions.club_manage_members()
               })

      assert {:error, :invalid_permission} =
               Club.execute(club, %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: role_id,
                 permission: "club.manage_trips"
               })

      club = grant_manage_members_permission(club, role_id)

      assert {:error, :permission_already_granted} =
               Club.execute(club, %GrantClubRolePermission{
                 club_id: club_id,
                 role_id: role_id,
                 permission: Permissions.club_manage_members()
               })
    end
  end

  describe "execute/2 group commands" do
    test "emits group definition and membership events for an existing club" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      club = created_club(club_id)

      assert [
               %GroupCreated{
                 club_id: ^club_id,
                 group_id: ^group_id,
                 group_key: "everyone",
                 name: "Everyone"
               },
               %GroupEmailSlugAssigned{
                 club_id: ^club_id,
                 group_id: ^group_id,
                 email_slug: "everyone"
               }
             ] =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: "everyone",
                 group_key: "everyone",
                 name: " Everyone "
               })

      club = create_group(club, group_id, "everyone", "Everyone")

      assert %GroupMemberAdded{
               club_id: ^club_id,
               group_id: ^group_id,
               membership_id: ^membership_id,
               person_id: ^person_id
             } =
               Club.execute(club, %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      club = add_group_member(club, group_id, membership_id, person_id)

      assert %GroupMemberRemoved{
               club_id: ^club_id,
               group_id: ^group_id,
               membership_id: ^membership_id,
               person_id: ^person_id
             } =
               Club.execute(club, %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "new group creation carries its normalized email slug as a separate fact" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      club = created_club(club_id)

      assert [
               %GroupCreated{
                 club_id: ^club_id,
                 group_id: ^group_id,
                 group_key: "trip_planners",
                 name: "Trip Planners"
               },
               %GroupEmailSlugAssigned{
                 club_id: ^club_id,
                 group_id: ^group_id,
                 email_slug: "trip-planners"
               }
             ] =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: " Trip-Planners ",
                 group_key: "trip_planners",
                 name: " Trip Planners "
               })
    end

    test "new group creation requires an email slug" do
      club_id = Memba.ID.generate(:club)
      club = created_club(club_id)

      assert {:error, :invalid_format} =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: Memba.ID.generate(:group),
                 group_key: "trip_planners",
                 name: "Trip Planners"
               })
    end

    test "matching historic Everyone and Admin definitions append their missing slug fact once" do
      club_id = Memba.ID.generate(:club)

      historic_club =
        club_id
        |> created_club()
        |> create_group(
          SystemGroups.everyone_group_id(club_id),
          SystemGroups.everyone_key(),
          SystemGroups.everyone_name()
        )
        |> create_group(
          SystemGroups.admin_group_id(club_id),
          SystemGroups.admin_key(),
          SystemGroups.admin_name()
        )

      Enum.each(
        [
          {
            SystemGroups.everyone_group_id(club_id),
            SystemGroups.everyone_key(),
            SystemGroups.everyone_name(),
            "everyone"
          },
          {
            SystemGroups.admin_group_id(club_id),
            SystemGroups.admin_key(),
            SystemGroups.admin_name(),
            "admin"
          }
        ],
        fn {group_id, group_key, name, email_slug} ->
          command = %CreateGroup{
            club_id: club_id,
            group_id: group_id,
            email_slug: String.upcase(email_slug),
            group_key: group_key,
            name: name
          }

          assert %GroupEmailSlugAssigned{
                   club_id: ^club_id,
                   group_id: ^group_id,
                   email_slug: ^email_slug
                 } = event = Club.execute(historic_club, command)

          assert [] =
                   historic_club
                   |> Club.apply(event)
                   |> Club.execute(command)
        end
      )
    end

    test "creates each group once and rejects conflicting group IDs or keys" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, "everyone", "Everyone")

      assert [] =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: " everyone ",
                 name: " Everyone "
               })

      assert {:error, :group_already_defined} =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: "admin",
                 name: "Admin"
               })

      assert {:error, :group_key_already_defined} =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: Memba.ID.generate(:group),
                 group_key: "everyone",
                 name: "Everyone"
               })
    end

    test "rejects a new group before creation when its email slug is already defined" do
      club_id = Memba.ID.generate(:club)
      first_group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(first_group_id, nil, "Trip Planners")
        |> assign_group_email_slug(first_group_id, "trip-planners")

      assert {:error, :group_email_slug_already_defined} =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: Memba.ID.generate(:group),
                 email_slug: " TRIP-PLANNERS ",
                 name: "Other Trip Planners"
               })
    end

    test "assigns one normalized email slug to a group" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Trip Planners")

      assert %GroupEmailSlugAssigned{
               club_id: ^club_id,
               group_id: ^group_id,
               email_slug: "trip-planners"
             } =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: " Trip-Planners "
               })
    end

    test "makes an assigned email slug immutable and assignment idempotent" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Trip Planners")
        |> assign_group_email_slug(group_id, "trip-planners")

      assert [] =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: " TRIP-PLANNERS "
               })

      assert {:error, :group_email_slug_already_assigned} =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: "trips"
               })
    end

    test "requires email slugs to be unique within the club" do
      club_id = Memba.ID.generate(:club)
      first_group_id = Memba.ID.generate(:group)
      second_group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(first_group_id, nil, "Trip Planners")
        |> create_group(second_group_id, nil, "Trips")
        |> assign_group_email_slug(first_group_id, "trip-planners")

      assert {:error, :group_email_slug_already_defined} =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: second_group_id,
                 email_slug: " TRIP-PLANNERS "
               })
    end

    test "rejects invalid email slugs and assignment outside the command club" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Trip Planners")

      assert {:error, :invalid_format} =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: "trip_planners"
               })

      assert {:error, :invalid_club_id} =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: Memba.ID.generate(:club),
                 group_id: group_id,
                 email_slug: "trip-planners"
               })

      assert {:error, :group_not_defined} =
               Club.execute(club, %AssignGroupEmailSlug{
                 club_id: club_id,
                 group_id: Memba.ID.generate(:group),
                 email_slug: "trip-planners"
               })
    end

    test "requires group memberships to belong to a group in the command club" do
      club_id = Memba.ID.generate(:club)
      other_club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club = created_club(club_id)

      ids = %{
        club_id: club_id,
        group_id: group_id,
        membership_id: membership_id,
        person_id: person_id
      }

      assert {:error, :group_not_defined} =
               Club.execute(club, struct!(AddGroupMember, ids))

      assert {:error, :group_not_defined} =
               Club.execute(club, struct!(RemoveGroupMember, ids))

      club = create_group(club, group_id, "everyone", "Everyone")

      assert {:error, :invalid_club_id} =
               Club.execute(
                 club,
                 struct!(AddGroupMember, %{ids | club_id: other_club_id})
               )

      assert {:error, :invalid_club_id} =
               Club.execute(
                 club,
                 struct!(RemoveGroupMember, %{ids | club_id: other_club_id})
               )
    end

    test "adds and removes group memberships idempotently" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, "everyone", "Everyone")

      command = %AddGroupMember{
        club_id: club_id,
        group_id: group_id,
        membership_id: membership_id,
        person_id: person_id
      }

      assert %GroupMemberAdded{} = Club.execute(club, command)

      club = add_group_member(club, group_id, membership_id, person_id)

      assert [] = Club.execute(club, command)

      remove_command = %RemoveGroupMember{
        club_id: club_id,
        group_id: group_id,
        membership_id: membership_id,
        person_id: person_id
      }

      assert %GroupMemberRemoved{} = Club.execute(club, remove_command)

      club = remove_group_member(club, group_id, membership_id, person_id)

      assert [] = Club.execute(club, remove_command)
      assert %GroupMemberAdded{} = Club.execute(club, command)
    end

    test "rejects group membership commands with mismatched person identities" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      other_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, "everyone", "Everyone")
        |> add_group_member(group_id, membership_id, person_id)

      assert {:error, :group_membership_person_mismatch} =
               Club.execute(club, %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: other_person_id
               })

      assert {:error, :group_membership_person_mismatch} =
               Club.execute(club, %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: other_person_id
               })
    end

    test "rejects group commands before the club exists" do
      ids = group_membership_ids()

      assert {:error, :not_created} =
               Club.execute(%Club{}, %CreateGroup{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 name: "Everyone"
               })

      assert {:error, :not_created} =
               Club.execute(%Club{}, %AssignGroupEmailSlug{
                 club_id: ids.club_id,
                 group_id: ids.group_id,
                 email_slug: "everyone"
               })

      assert {:error, :not_created} =
               Club.execute(%Club{}, struct!(AddGroupMember, ids))

      assert {:error, :not_created} =
               Club.execute(%Club{}, struct!(RemoveGroupMember, ids))
    end
  end

  describe "execute/2 AssignMemberRole and RemoveMemberRole" do
    test "emits role assignment and role removal events for a member" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      actor_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)
        |> grant_manage_members_permission(role_id)

      assert %MemberRoleAssigned{
               club_id: ^club_id,
               membership_id: ^membership_id,
               person_id: ^person_id,
               role_id: ^role_id,
               assigned_by_person_id: ^actor_person_id
             } =
               Club.execute(club, %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id,
                 assigned_by_person_id: actor_person_id
               })

      club = assign_member_role(club, membership_id, person_id, role_id)

      assert %MemberRoleRemoved{
               club_id: ^club_id,
               membership_id: ^membership_id,
               person_id: ^person_id,
               role_id: ^role_id,
               removed_by_person_id: ^actor_person_id
             } =
               Club.execute(club, %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id,
                 removed_by_person_id: actor_person_id
               })
    end

    test "rejects duplicate assignments and removing missing assignments" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)

      assert {:error, :role_assignment_not_found} =
               Club.execute(club, %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               })

      club = assign_member_role(club, membership_id, person_id, role_id)

      assert {:error, :role_already_assigned} =
               Club.execute(club, %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               })
    end

    test "rejects assigning a role that has not been defined" do
      club_id = Memba.ID.generate(:club)

      assert {:error, :role_not_defined} =
               Club.execute(created_club(club_id), %AssignMemberRole{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: Memba.ID.generate(:person),
                 role_id: Memba.ID.generate(:role)
               })
    end
  end

  test "apply/2 records the created club identity and name" do
    club_id = Memba.ID.generate(:club)

    assert %Club{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc"
           } =
             Club.apply(%Club{}, %ClubCreated{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })
  end

  test "apply/2 records updated club name and slug" do
    club_id = Memba.ID.generate(:club)

    club =
      Club.apply(%Club{}, %ClubCreated{
        club_id: club_id,
        name: "Kootenay Mountaineering Club",
        slug: "kmc"
      })

    assert %Club{
             club_id: ^club_id,
             name: "KMC Alpine Club",
             slug: "kmc-alpine"
           } =
             Club.apply(club, %ClubUpdated{
               club_id: club_id,
               name: "KMC Alpine Club",
               slug: "kmc-alpine"
             })
  end

  test "apply/2 records role definitions, role permission grants, and role assignments" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    club =
      club_id
      |> created_club()
      |> define_membership_administrator_role(role_id)
      |> grant_manage_members_permission(role_id)
      |> assign_member_role(membership_id, person_id, role_id)

    assert %{
             ^role_id => %{
               role_id: ^role_id,
               role_key: "admin",
               name: "Admin"
             }
           } = club.roles

    membership_administrator_key = Roles.membership_administrator_key()
    assert %{^membership_administrator_key => ^role_id} = club.role_keys

    assert %{^role_id => granted_permissions} = club.role_permissions
    assert MapSet.member?(granted_permissions, Permissions.club_manage_members())

    assert %{{^membership_id, ^role_id} => %{person_id: ^person_id}} = club.role_assignments

    assert %Club{role_assignments: %{}} =
             Club.apply(club, %MemberRoleRemoved{
               club_id: club_id,
               membership_id: membership_id,
               person_id: person_id,
               role_id: role_id
             })
  end

  test "apply/2 records group definitions and current group membership state" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    club =
      club_id
      |> created_club()
      |> create_group(group_id, "everyone", "Everyone")
      |> add_group_member(group_id, membership_id, person_id)

    assert %{
             ^group_id => %{
               email_slug: nil,
               group_id: ^group_id,
               group_key: "everyone",
               name: "Everyone"
             }
           } = club.groups

    assert %{"everyone" => ^group_id} = club.group_keys

    club = assign_group_email_slug(club, group_id, "everyone")

    assert %{^group_id => %{email_slug: "everyone"}} = club.groups
    assert %{"everyone" => ^group_id} = club.group_email_slugs

    assert %{
             {^group_id, ^membership_id} => %{
               person_id: ^person_id,
               active: true
             }
           } = club.group_memberships

    assert %Club{
             group_memberships: %{
               {^group_id, ^membership_id} => %{
                 person_id: ^person_id,
                 active: false
               }
             }
           } =
             Club.apply(club, %GroupMemberRemoved{
               club_id: club_id,
               group_id: group_id,
               membership_id: membership_id,
               person_id: person_id
             })
  end

  defp created_club(club_id) do
    Club.apply(%Club{}, %ClubCreated{
      club_id: club_id,
      name: "Kootenay Mountaineering Club",
      slug: "kmc"
    })
  end

  defp define_membership_administrator_role(%Club{} = club, role_id) do
    Club.apply(club, %ClubRoleDefined{
      club_id: club.club_id,
      role_id: role_id,
      role_key: Roles.membership_administrator_key(),
      name: Roles.membership_administrator_name()
    })
  end

  defp grant_manage_members_permission(%Club{} = club, role_id) do
    Club.apply(club, %ClubRolePermissionGranted{
      club_id: club.club_id,
      role_id: role_id,
      permission: Permissions.club_manage_members()
    })
  end

  defp assign_member_role(%Club{} = club, membership_id, person_id, role_id) do
    Club.apply(club, %MemberRoleAssigned{
      club_id: club.club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: role_id
    })
  end

  defp create_group(%Club{} = club, group_id, group_key, name) do
    Club.apply(club, %GroupCreated{
      club_id: club.club_id,
      group_id: group_id,
      group_key: group_key,
      name: name
    })
  end

  defp assign_group_email_slug(%Club{} = club, group_id, email_slug) do
    Club.apply(club, %GroupEmailSlugAssigned{
      club_id: club.club_id,
      group_id: group_id,
      email_slug: email_slug
    })
  end

  defp add_group_member(%Club{} = club, group_id, membership_id, person_id) do
    Club.apply(club, %GroupMemberAdded{
      club_id: club.club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id
    })
  end

  defp remove_group_member(%Club{} = club, group_id, membership_id, person_id) do
    Club.apply(club, %GroupMemberRemoved{
      club_id: club.club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id
    })
  end

  defp group_membership_ids do
    %{
      club_id: Memba.ID.generate(:club),
      group_id: Memba.ID.generate(:group),
      membership_id: Memba.ID.generate(:membership),
      person_id: Memba.ID.generate(:person)
    }
  end
end
