defmodule Memba.Membership.ClubCommandDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "prepared create dispatch emits normalized club and default role/group events" do
    club_id = Memba.ID.generate(:club)

    assert {:ok, command} =
             ClubCommands.prepare_create(%{
               "club_id" => club_id,
               "name" => " Kootenay Mountaineering Club "
             })

    role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kootenay-mountaineering-club"
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
              ]
            }} =
             CommandDispatch.dispatch(
               command,
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{club_id: ^club_id, name: "Kootenay Mountaineering Club"} =
             ClubGroupQueries.get_club(club_id)
  end

  test "create preparation accepts an address-safe slug override and rejects invalid slugs" do
    club_id = Memba.ID.generate(:club)

    assert {:ok, command} =
             ClubCommands.prepare_create(%{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })

    role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
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
              ]
            }} =
             CommandDispatch.dispatch(
               command,
               returning: :execution_result,
               consistency: :strong
             )

    assert {:error, :invalid_format} =
             ClubCommands.prepare_create(%{
               club_id: Memba.ID.generate(:club),
               name: "Kootenay Mountaineering Club",
               slug: "kmc club!"
             })
  end

  test "create preparation rejects duplicate slugs before dispatching a new club" do
    existing_club_id = Memba.ID.generate(:club)
    duplicate_club_id = Memba.ID.generate(:club)

    assert {:ok, command} =
             ClubCommands.prepare_create(%{
               club_id: existing_club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:error, :slug_taken} =
             ClubCommands.prepare_create(%{
               club_id: duplicate_club_id,
               name: "KMC Duplicate Club",
               slug: "kmc"
             })

    assert %ClubProjection{club_id: ^existing_club_id, slug: "kmc"} =
             ClubGroupQueries.get_club_by_slug("kmc")

    assert is_nil(ClubGroupQueries.get_club(duplicate_club_id))
  end

  test "prepared update dispatch emits normalized club changes and updates the projection" do
    club_id = Memba.ID.generate(:club)

    assert {:ok, create} =
             ClubCommands.prepare_create(%{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })

    assert :ok = CommandDispatch.dispatch(create, consistency: :strong)

    assert {:ok, update} =
             ClubCommands.prepare_update(%{
               "club_id" => club_id,
               "name" => " KMC Alpine Club ",
               "slug" => "kmc-alpine"
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubUpdated{
                  club_id: ^club_id,
                  name: "KMC Alpine Club",
                  slug: "kmc-alpine"
                }
              ]
            }} =
             CommandDispatch.dispatch(
               update,
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{
             club_id: ^club_id,
             name: "KMC Alpine Club",
             slug: "kmc-alpine"
           } = ClubGroupQueries.get_club(club_id)
  end

  test "update preparation rejects invalid and duplicate slugs before dispatch" do
    kootenay_id = Memba.ID.generate(:club)
    nelson_id = Memba.ID.generate(:club)

    assert {:ok, kootenay} =
             ClubCommands.prepare_create(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })

    assert :ok = CommandDispatch.dispatch(kootenay, consistency: :strong)

    assert {:ok, nelson} =
             ClubCommands.prepare_create(%{
               club_id: nelson_id,
               name: "Nelson Cycling Club",
               slug: "nelson-cycling"
             })

    assert :ok = CommandDispatch.dispatch(nelson, consistency: :strong)

    assert {:error, :invalid_format} =
             ClubCommands.prepare_update(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "KMC Club!"
             })

    assert {:error, :slug_taken} =
             ClubCommands.prepare_update(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "nelson-cycling"
             })
  end
end
