defmodule Memba.Membership.ClubTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignGroupEmailSlug
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.ReconcileLegacyAdminHistory
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
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

  describe "execute/2 AddClubMember and RemoveClubMember" do
    test "emits membership and automatic Admin assignment together for the first activation" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      admin_role_id = Roles.membership_administrator_role_id(club_id)
      club = created_club(club_id)

      add_command = %AddClubMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id
      }

      assert [
               %ClubMemberAdded{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id
               },
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id,
                 role_id: ^admin_role_id,
                 assigned_by_person_id: nil
               }
             ] = Club.execute(club, add_command)
    end

    test "emits only membership activation for a later member" do
      club_id = Memba.ID.generate(:club)
      first_membership_id = Memba.ID.generate(:membership)
      later_membership_id = Memba.ID.generate(:membership)
      first_person_id = Memba.ID.generate(:person)
      later_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> Club.apply(%ClubMemberAdded{
          club_id: club_id,
          membership_id: first_membership_id,
          person_id: first_person_id
        })

      assert %ClubMemberAdded{
               club_id: ^club_id,
               membership_id: ^later_membership_id,
               person_id: ^later_person_id
             } =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: later_membership_id,
                 person_id: later_person_id
               })
    end

    test "rejects final-member removal before custom-group cleanup or sole-Admin removal" do
      club_id = Memba.ID.generate(:club)
      admin_role_id = Roles.membership_administrator_role_id(club_id)
      custom_group_id = Memba.ID.generate(:group)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> assign_member_role(membership_id, person_id, admin_role_id)
        |> create_group(custom_group_id, nil, "Board")
        |> add_group_member(custom_group_id, membership_id, person_id)

      assert %{
               {^custom_group_id, ^membership_id} => %{
                 person_id: ^person_id,
                 active: true
               }
             } = club.group_memberships

      assert {:error, :last_active_member} =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "rejects sole-Admin removal before custom-group cleanup while another member remains" do
      club_id = Memba.ID.generate(:club)
      admin_role_id = Roles.membership_administrator_role_id(club_id)
      custom_group_id = Memba.ID.generate(:group)
      admin_membership_id = Memba.ID.generate(:membership)
      admin_person_id = Memba.ID.generate(:person)
      ordinary_membership_id = Memba.ID.generate(:membership)
      ordinary_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(admin_membership_id, admin_person_id)
        |> assign_member_role(admin_membership_id, admin_person_id, admin_role_id)
        |> activate_member(ordinary_membership_id, ordinary_person_id)
        |> create_group(custom_group_id, nil, "Board")
        |> add_group_member(custom_group_id, admin_membership_id, admin_person_id)

      assert %{
               {^custom_group_id, ^admin_membership_id} => %{
                 person_id: ^admin_person_id,
                 active: true
               }
             } = club.group_memberships

      assert {:error, :last_membership_administrator} =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: admin_membership_id,
                 person_id: admin_person_id
               })
    end

    test "removes an Admin when a replacement remains and updates both decision-state sets" do
      club_id = Memba.ID.generate(:club)
      admin_role_id = Roles.membership_administrator_role_id(club_id)
      first_membership_id = Memba.ID.generate(:membership)
      first_person_id = Memba.ID.generate(:person)
      replacement_membership_id = Memba.ID.generate(:membership)
      replacement_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(first_membership_id, first_person_id)
        |> assign_member_role(first_membership_id, first_person_id, admin_role_id)
        |> activate_member(replacement_membership_id, replacement_person_id)
        |> assign_member_role(replacement_membership_id, replacement_person_id, admin_role_id)

      assert %ClubMemberRemoved{
               club_id: ^club_id,
               membership_id: ^first_membership_id,
               person_id: ^first_person_id
             } =
               event =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: first_membership_id,
                 person_id: first_person_id
               })

      club = Club.apply(club, event)

      refute Map.has_key?(club.active_memberships, first_membership_id)

      assert Map.get(club.active_memberships, replacement_membership_id) ==
               replacement_person_id

      assert MapSet.equal?(
               club.active_admin_membership_ids,
               MapSet.new([replacement_membership_id])
             )
    end

    test "ends every active custom-group membership in the club-member removal decision" do
      club_id = Memba.ID.generate(:club)
      departing_membership_id = Memba.ID.generate(:membership)
      departing_person_id = Memba.ID.generate(:person)
      remaining_membership_id = Memba.ID.generate(:membership)
      remaining_person_id = Memba.ID.generate(:person)

      [first_custom_group_id, second_custom_group_id, inactive_custom_group_id] =
        Enum.sort([
          Memba.ID.generate(:group),
          Memba.ID.generate(:group),
          Memba.ID.generate(:group)
        ])

      everyone_group_id = SystemGroups.everyone_group_id(club_id)
      admin_group_id = SystemGroups.admin_group_id(club_id)

      club =
        club_id
        |> created_club()
        |> activate_member(departing_membership_id, departing_person_id)
        |> activate_member(remaining_membership_id, remaining_person_id)
        |> create_group(everyone_group_id, SystemGroups.everyone_key(), "Everyone")
        |> create_group(admin_group_id, SystemGroups.admin_key(), "Admin")
        |> create_group(first_custom_group_id, "board", "Board")
        |> create_group(second_custom_group_id, "trips", "Trips")
        |> create_group(inactive_custom_group_id, "events", "Events")
        |> add_group_member(
          everyone_group_id,
          departing_membership_id,
          departing_person_id
        )
        |> add_group_member(admin_group_id, departing_membership_id, departing_person_id)
        |> add_group_member(
          first_custom_group_id,
          departing_membership_id,
          departing_person_id
        )
        |> add_group_member(
          second_custom_group_id,
          departing_membership_id,
          departing_person_id
        )
        |> add_group_member(
          inactive_custom_group_id,
          departing_membership_id,
          departing_person_id
        )
        |> remove_group_member(
          inactive_custom_group_id,
          departing_membership_id,
          departing_person_id
        )

      assert [
               %ClubMemberRemoved{
                 club_id: ^club_id,
                 membership_id: ^departing_membership_id,
                 person_id: ^departing_person_id
               },
               %GroupMemberRemoved{
                 club_id: ^club_id,
                 group_id: ^first_custom_group_id,
                 membership_id: ^departing_membership_id,
                 person_id: ^departing_person_id
               },
               %GroupMemberRemoved{
                 club_id: ^club_id,
                 group_id: ^second_custom_group_id,
                 membership_id: ^departing_membership_id,
                 person_id: ^departing_person_id
               }
             ] =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: departing_membership_id,
                 person_id: departing_person_id
               })
    end

    test "treats an exact active membership identity as an idempotent activation" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> Club.apply(%ClubMemberAdded{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        })

      assert [] =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert {:error, :membership_id_already_used} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: Memba.ID.generate(:person)
               })
    end

    test "rejects a different membership identity for an active person" do
      club_id = Memba.ID.generate(:club)
      active_membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> Club.apply(%ClubMemberAdded{
          club_id: club_id,
          membership_id: active_membership_id,
          person_id: person_id
        })

      assert {:error, :already_active_member} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: person_id
               })
    end

    test "rejects membership IDs removed through the native lifecycle" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> Club.apply(%ClubMemberAdded{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        })
        |> Club.apply(%ClubMemberRemoved{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        })

      assert {:error, :membership_id_already_used} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "rejects membership IDs removed through historic Everyone compatibility facts" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      everyone_group_id = SystemGroups.everyone_group_id(club_id)
      admin_role_id = Roles.membership_administrator_role_id(club_id)

      club =
        club_id
        |> created_club()
        |> Club.apply(%GroupMemberAdded{
          club_id: club_id,
          group_id: everyone_group_id,
          membership_id: membership_id,
          person_id: person_id
        })
        |> Club.apply(%GroupMemberRemoved{
          club_id: club_id,
          group_id: everyone_group_id,
          membership_id: membership_id,
          person_id: person_id
        })

      assert {:error, :membership_id_already_used} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      new_membership_id = Memba.ID.generate(:membership)

      assert [
               %ClubMemberAdded{
                 club_id: ^club_id,
                 membership_id: ^new_membership_id,
                 person_id: ^person_id
               },
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^new_membership_id,
                 person_id: ^person_id,
                 role_id: ^admin_role_id
               }
             ] =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: new_membership_id,
                 person_id: person_id
               })
    end

    test "requires an existing Club and validates every command identity" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      assert {:error, :not_created} =
               Club.execute(%Club{}, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      club = created_club(club_id)

      assert {:error, :invalid_club_id} =
               Club.execute(club, %AddClubMember{
                 club_id: Memba.ID.generate(:club),
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert {:error, :invalid_membership_id} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: "not-a-uuid",
                 person_id: person_id
               })

      assert {:error, :invalid_person_id} =
               Club.execute(club, %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: "not-a-uuid"
               })
    end

    test "removal requires the active membership's club and person identities" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> Club.apply(%ClubMemberAdded{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        })

      assert {:error, :invalid_club_id} =
               Club.execute(club, %RemoveClubMember{
                 club_id: Memba.ID.generate(:club),
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert {:error, :membership_person_mismatch} =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: Memba.ID.generate(:person)
               })

      assert {:error, :not_found} =
               Club.execute(club, %RemoveClubMember{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: person_id
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

  describe "execute/2 ReconcileLegacyAdminHistory" do
    test "appends all missing canonical Admin facts in dependency order and is then a no-op" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)

      command = %ReconcileLegacyAdminHistory{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id
      }

      assert [
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
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id,
                 role_id: ^role_id,
                 assigned_by_person_id: nil,
                 assignment_source: "legacy_projection_reconciliation"
               }
             ] = events = Club.execute(club, command)

      assert [] =
               club
               |> apply_events(events)
               |> Club.execute(command)
    end

    test "appends only permission and assignment when the canonical Admin role exists" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_membership_administrator_role(role_id)

      assert [
               %ClubRolePermissionGranted{
                 club_id: ^club_id,
                 role_id: ^role_id,
                 permission: "club.manage_members"
               },
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id,
                 role_id: ^role_id,
                 assigned_by_person_id: nil,
                 assignment_source: "legacy_projection_reconciliation"
               }
             ] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "appends only assignment when role and permission exist" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_membership_administrator_role(role_id)
        |> grant_manage_members_permission(role_id)

      assert [
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id,
                 role_id: ^role_id,
                 assigned_by_person_id: nil,
                 assignment_source: "legacy_projection_reconciliation"
               }
             ] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "appends a missing permission when role and equivalent assignment already exist" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_membership_administrator_role(role_id)
        |> assign_member_role(membership_id, person_id, role_id)

      assert [
               %ClubRolePermissionGranted{
                 club_id: ^club_id,
                 role_id: ^role_id,
                 permission: "club.manage_members"
               }
             ] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "returns no events when all canonical Admin facts already exist" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_membership_administrator_role(role_id)
        |> grant_manage_members_permission(role_id)
        |> assign_member_role(membership_id, person_id, role_id)

      assert [] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "returns no events when the complete historic Admin role definition already exists" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_historic_membership_administrator_role(role_id)
        |> grant_manage_members_permission(role_id)
        |> assign_member_role(membership_id, person_id, role_id)

      assert [] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "appends permission and assignment when only the historic Admin role definition exists" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_historic_membership_administrator_role(role_id)

      assert [
               %ClubRolePermissionGranted{
                 club_id: ^club_id,
                 role_id: ^role_id,
                 permission: "club.manage_members"
               },
               %ClubRoleAssignedToMember{
                 club_id: ^club_id,
                 membership_id: ^membership_id,
                 person_id: ^person_id,
                 role_id: ^role_id,
                 assigned_by_person_id: nil,
                 assignment_source: "legacy_projection_reconciliation"
               }
             ] =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })
    end

    test "rejects a conflicting deterministic Admin role definition before appending missing facts" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_role(role_id, Roles.membership_administrator_key(), "Administrator")

      assert {:error, :conflicting_legacy_admin_role_definition} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert %{} = club.role_permissions
      assert %{} = club.role_assignments
    end

    test "rejects an Admin role key mapped to another role before appending missing facts" do
      club_id = Memba.ID.generate(:club)
      other_role_id = Memba.ID.generate(:role)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_role(other_role_id, Roles.membership_administrator_key(), "Custom Admin")

      assert {:error, :legacy_admin_role_key_conflict} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      refute Map.has_key?(club.roles, Roles.membership_administrator_role_id(club_id))
      assert %{} = club.role_permissions
      assert %{} = club.role_assignments
    end

    test "rejects a historic Admin role key mapped to another role before appending missing facts" do
      club_id = Memba.ID.generate(:club)
      other_role_id = Memba.ID.generate(:role)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_role(
          other_role_id,
          Roles.historic_membership_administrator_key(),
          Roles.historic_membership_administrator_name()
        )

      assert {:error, :legacy_admin_role_key_conflict} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      refute Map.has_key?(club.roles, Roles.membership_administrator_role_id(club_id))
      assert %{} = club.role_permissions
      assert %{} = club.role_assignments
    end

    test "rejects an existing Admin assignment for the membership when it names another person" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      other_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)
        |> define_membership_administrator_role(role_id)
        |> assign_member_role(membership_id, other_person_id, role_id)

      assert {:error, :legacy_admin_assignment_person_mismatch} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert %{} = club.role_permissions
    end

    test "requires the target membership and person to be the active pair" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      other_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)

      assert {:error, :membership_person_mismatch} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: other_person_id
               })

      assert {:error, :not_found} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: person_id
               })
    end

    test "requires an existing club and valid typed IDs" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      assert {:error, :not_created} =
               Club.execute(%Club{}, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               })

      club =
        club_id
        |> created_club()
        |> activate_member(membership_id, person_id)

      assert {:error, :invalid_club_id} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: Memba.ID.generate(:club),
                 membership_id: membership_id,
                 person_id: person_id
               })

      assert {:error, :invalid_membership_id} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: "not-a-uuid",
                 person_id: person_id
               })

      assert {:error, :invalid_person_id} =
               Club.execute(club, %ReconcileLegacyAdminHistory{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: "not-a-uuid"
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

    test "rejects a non-ASCII case variant from trusted group creation" do
      club_id = Memba.ID.generate(:club)

      club =
        club_id
        |> created_club()
        |> create_group(Memba.ID.generate(:group), "uppercase_sigma", "Σ")

      assert {:error, :group_name_already_defined} =
               Club.execute(club, %CreateGroup{
                 club_id: club_id,
                 group_id: Memba.ID.generate(:group),
                 email_slug: "lowercase-sigma",
                 group_key: "lowercase_sigma",
                 name: " σ "
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

  describe "execute/2 AddCustomGroupMember authorization" do
    test "uses the actor's current active custom-group membership" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      actor_membership_id = Memba.ID.generate(:membership)
      actor_person_id = Memba.ID.generate(:person)
      target_membership_id = Memba.ID.generate(:membership)
      target_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Board")
        |> activate_member(actor_membership_id, actor_person_id)
        |> activate_member(target_membership_id, target_person_id)
        |> add_group_member(group_id, actor_membership_id, actor_person_id)

      command = %AddCustomGroupMember{
        club_id: club_id,
        group_id: group_id,
        group_membership_id: Memba.ID.generate(:group_membership),
        membership_id: target_membership_id,
        person_id: target_person_id,
        actor_person_id: actor_person_id
      }

      assert [
               %GroupMemberAdded{
                 club_id: ^club_id,
                 group_id: ^group_id,
                 membership_id: ^target_membership_id,
                 person_id: ^target_person_id
               },
               %Memba.Membership.Events.GroupMembershipStarted{}
             ] = Club.execute(club, command)

      club = remove_group_member(club, group_id, actor_membership_id, actor_person_id)

      assert {:error, :unauthorized} = Club.execute(club, command)
    end

    test "rejects a fresh identity for an already-active legacy custom-group relation" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      actor_membership_id = Memba.ID.generate(:membership)
      actor_person_id = Memba.ID.generate(:person)
      target_membership_id = Memba.ID.generate(:membership)
      target_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Board")
        |> activate_member(actor_membership_id, actor_person_id)
        |> activate_member(target_membership_id, target_person_id)
        |> add_group_member(group_id, actor_membership_id, actor_person_id)
        |> add_group_member(group_id, target_membership_id, target_person_id)

      command = %AddCustomGroupMember{
        club_id: club_id,
        group_id: group_id,
        group_membership_id: Memba.ID.generate(:group_membership),
        membership_id: target_membership_id,
        person_id: target_person_id,
        actor_person_id: actor_person_id
      }

      assert {:error, :group_membership_already_current} = Club.execute(club, command)
    end

    test "uses the actor's current active club membership and manage-members permission" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      role_id = Memba.ID.generate(:role)
      actor_membership_id = Memba.ID.generate(:membership)
      actor_person_id = Memba.ID.generate(:person)
      target_membership_id = Memba.ID.generate(:membership)
      target_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Board")
        |> define_role(role_id, "membership-manager", "Membership manager")
        |> grant_manage_members_permission(role_id)
        |> activate_member(actor_membership_id, actor_person_id)
        |> assign_member_role(actor_membership_id, actor_person_id, role_id)
        |> activate_member(target_membership_id, target_person_id)

      command = %AddCustomGroupMember{
        club_id: club_id,
        group_id: group_id,
        group_membership_id: Memba.ID.generate(:group_membership),
        membership_id: target_membership_id,
        person_id: target_person_id,
        actor_person_id: actor_person_id
      }

      assert [%GroupMemberAdded{}, %Memba.Membership.Events.GroupMembershipStarted{}] =
               Club.execute(club, command)

      inactive_actor_club =
        Club.apply(club, %ClubMemberRemoved{
          club_id: club_id,
          membership_id: actor_membership_id,
          person_id: actor_person_id
        })

      assert {:error, :unauthorized} = Club.execute(inactive_actor_club, command)

      actor_without_permission_club =
        Club.apply(club, %ClubRoleRemovedFromMember{
          club_id: club_id,
          membership_id: actor_membership_id,
          person_id: actor_person_id,
          role_id: role_id
        })

      assert {:error, :unauthorized} = Club.execute(actor_without_permission_club, command)
    end

    test "uses the current active target and custom-group identity" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      actor_membership_id = Memba.ID.generate(:membership)
      actor_person_id = Memba.ID.generate(:person)
      target_membership_id = Memba.ID.generate(:membership)
      target_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> create_group(group_id, nil, "Board")
        |> activate_member(actor_membership_id, actor_person_id)
        |> activate_member(target_membership_id, target_person_id)
        |> add_group_member(group_id, actor_membership_id, actor_person_id)

      command = %AddCustomGroupMember{
        club_id: club_id,
        group_id: group_id,
        group_membership_id: Memba.ID.generate(:group_membership),
        membership_id: target_membership_id,
        person_id: target_person_id,
        actor_person_id: actor_person_id
      }

      inactive_target_club =
        Club.apply(club, %ClubMemberRemoved{
          club_id: club_id,
          membership_id: target_membership_id,
          person_id: target_person_id
        })

      assert {:error, :member_not_active} = Club.execute(inactive_target_club, command)

      assert {:error, :membership_person_mismatch} =
               Club.execute(club, %{
                 command
                 | person_id: Memba.ID.generate(:person)
               })

      assert {:error, :group_not_defined} =
               Club.execute(club, %{
                 command
                 | group_id: Memba.ID.generate(:group)
               })

      for system_group_id <- [
            SystemGroups.everyone_group_id(club_id),
            SystemGroups.admin_group_id(club_id)
          ] do
        system_group_club = create_group(club, system_group_id, nil, "System")

        assert {:error, :system_group_not_allowed} =
                 Club.execute(system_group_club, %{command | group_id: system_group_id})
      end
    end
  end

  describe "execute/2 AssignClubRoleToMember and RemoveClubRoleFromMember" do
    test "emits role assignment and role removal events for a member" do
      club_id = Memba.ID.generate(:club)
      role_id = Memba.ID.generate(:role)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)
      actor_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> define_role(role_id, "treasurer", "Treasurer")
        |> grant_manage_members_permission(role_id)
        |> activate_member(membership_id, person_id)

      assert %ClubRoleAssignedToMember{
               club_id: ^club_id,
               membership_id: ^membership_id,
               person_id: ^person_id,
               role_id: ^role_id,
               assigned_by_person_id: ^actor_person_id
             } =
               Club.execute(club, %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id,
                 assigned_by_person_id: actor_person_id
               })

      club = assign_member_role(club, membership_id, person_id, role_id)

      assert %ClubRoleRemovedFromMember{
               club_id: ^club_id,
               membership_id: ^membership_id,
               person_id: ^person_id,
               role_id: ^role_id,
               removed_by_person_id: ^actor_person_id
             } =
               Club.execute(club, %RemoveClubRoleFromMember{
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
        |> activate_member(membership_id, person_id)

      assert {:error, :role_assignment_not_found} =
               Club.execute(club, %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               })

      club = assign_member_role(club, membership_id, person_id, role_id)

      assert {:error, :role_already_assigned} =
               Club.execute(club, %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               })
    end

    test "rejects assigning a role to an inactive membership" do
      club_id = Memba.ID.generate(:club)
      role_id = Memba.ID.generate(:role)

      club =
        club_id
        |> created_club()
        |> define_role(role_id, "treasurer", "Treasurer")

      assert {:error, :member_not_active} =
               Club.execute(club, %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: Memba.ID.generate(:person),
                 role_id: role_id
               })
    end

    test "rejects removing the sole active Admin assignment" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)
        |> activate_member(membership_id, person_id)
        |> assign_member_role(membership_id, person_id, role_id)

      assert {:error, :last_membership_administrator} =
               Club.execute(club, %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               })
    end

    test "allows removing an Admin assignment when another active Admin remains" do
      club_id = Memba.ID.generate(:club)
      role_id = Roles.membership_administrator_role_id(club_id)
      first_membership_id = Memba.ID.generate(:membership)
      first_person_id = Memba.ID.generate(:person)
      second_membership_id = Memba.ID.generate(:membership)
      second_person_id = Memba.ID.generate(:person)

      club =
        club_id
        |> created_club()
        |> define_membership_administrator_role(role_id)
        |> activate_member(first_membership_id, first_person_id)
        |> activate_member(second_membership_id, second_person_id)
        |> assign_member_role(first_membership_id, first_person_id, role_id)
        |> assign_member_role(second_membership_id, second_person_id, role_id)

      assert %ClubRoleRemovedFromMember{
               club_id: ^club_id,
               membership_id: ^first_membership_id,
               person_id: ^first_person_id,
               role_id: ^role_id
             } =
               Club.execute(club, %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: first_membership_id,
                 person_id: first_person_id,
                 role_id: role_id
               })
    end

    test "rejects assigning a role that has not been defined" do
      club_id = Memba.ID.generate(:club)

      assert {:error, :role_not_defined} =
               Club.execute(created_club(club_id), %AssignClubRoleToMember{
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
             Club.apply(club, %ClubRoleRemovedFromMember{
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

  defp apply_events(%Club{} = club, events) do
    Enum.reduce(List.wrap(events), club, fn event, club -> Club.apply(club, event) end)
  end

  defp created_club(club_id) do
    Club.apply(%Club{}, %ClubCreated{
      club_id: club_id,
      name: "Kootenay Mountaineering Club",
      slug: "kmc"
    })
  end

  defp define_membership_administrator_role(%Club{} = club, role_id) do
    define_role(
      club,
      role_id,
      Roles.membership_administrator_key(),
      Roles.membership_administrator_name()
    )
  end

  defp define_historic_membership_administrator_role(%Club{} = club, role_id) do
    define_role(
      club,
      role_id,
      Roles.historic_membership_administrator_key(),
      Roles.historic_membership_administrator_name()
    )
  end

  defp define_role(%Club{} = club, role_id, role_key, name) do
    Club.apply(club, %ClubRoleDefined{
      club_id: club.club_id,
      role_id: role_id,
      role_key: role_key,
      name: name
    })
  end

  defp grant_manage_members_permission(%Club{} = club, role_id) do
    Club.apply(club, %ClubRolePermissionGranted{
      club_id: club.club_id,
      role_id: role_id,
      permission: Permissions.club_manage_members()
    })
  end

  defp activate_member(%Club{} = club, membership_id, person_id) do
    Club.apply(club, %ClubMemberAdded{
      club_id: club.club_id,
      membership_id: membership_id,
      person_id: person_id
    })
  end

  defp assign_member_role(%Club{} = club, membership_id, person_id, role_id) do
    Club.apply(club, %ClubRoleAssignedToMember{
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
