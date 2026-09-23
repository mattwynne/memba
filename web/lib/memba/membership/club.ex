defmodule Memba.Membership.Club do
  @moduledoc """
  Club aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignGroupEmailSlug
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.EndGroupMembership
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.ReconcileLegacyAdminHistory
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Commands.StartGroupMembership
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.CustomGroupSlug
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned, as: LegacyMemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved, as: LegacyMemberRoleRemoved
  alias Memba.Membership.GroupMembership
  alias Memba.Membership.GroupName
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Membership.SystemGroups

  @behaviour Aggregate

  defstruct [
    :club_id,
    :name,
    :slug,
    active_admin_membership_ids: MapSet.new(),
    active_memberships: %{},
    groups: %{},
    group_email_slugs: %{},
    group_keys: %{},
    group_name_keys: %{},
    group_memberships: %{},
    first_class_group_memberships: %{},
    current_group_membership_ids: %{},
    group_membership_endings: %{},
    native_membership_ids: MapSet.new(),
    roles: %{},
    role_keys: %{},
    role_permissions: %{},
    role_assignments: %{}
  ]

  @impl Aggregate
  def execute(%__MODULE__{club_id: nil}, %CreateClub{} = command) do
    with :ok <- validate_club_id(command.club_id),
         {:ok, name} <- GroupName.normalize(command.name),
         {:ok, slug} <- Slug.validate(command.slug) do
      membership_administrator_role_id = Roles.membership_administrator_role_id(command.club_id)

      [
        %ClubCreated{club_id: command.club_id, name: name, slug: slug},
        %ClubRoleDefined{
          club_id: command.club_id,
          role_id: membership_administrator_role_id,
          role_key: Roles.membership_administrator_key(),
          name: Roles.membership_administrator_name()
        },
        %ClubRolePermissionGranted{
          club_id: command.club_id,
          role_id: membership_administrator_role_id,
          permission: Permissions.club_manage_members()
        },
        %GroupCreated{
          club_id: command.club_id,
          group_id: SystemGroups.everyone_group_id(command.club_id),
          group_key: SystemGroups.everyone_key(),
          name: SystemGroups.everyone_name()
        },
        %GroupEmailSlugAssigned{
          club_id: command.club_id,
          group_id: SystemGroups.everyone_group_id(command.club_id),
          email_slug: SystemGroups.everyone_email_slug()
        },
        %GroupCreated{
          club_id: command.club_id,
          group_id: SystemGroups.admin_group_id(command.club_id),
          group_key: SystemGroups.admin_key(),
          name: SystemGroups.admin_name()
        },
        %GroupEmailSlugAssigned{
          club_id: command.club_id,
          group_id: SystemGroups.admin_group_id(command.club_id),
          email_slug: SystemGroups.admin_email_slug()
        }
      ]
    end
  end

  def execute(%__MODULE__{}, %CreateClub{}), do: {:error, :already_created}

  def execute(%__MODULE__{club_id: nil}, %CreateCustomGroup{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %CreateCustomGroup{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <-
           validate_id(
             :group_membership,
             command.group_membership_id,
             :invalid_group_membership_id
           ),
         :ok <- validate_id(:person, command.actor_person_id, :invalid_actor_person_id),
         {:ok, name} <- GroupName.normalize(command.name),
         {:ok, creator_membership_id} <-
           active_admin_membership_id(club, command.actor_person_id),
         :ok <- ensure_group_name_available(club, command.group_id, name) do
      email_slug =
        CustomGroupSlug.allocate(
          name,
          occupied_group_email_slugs(club, command.group_id)
        )

      create_custom_group_decision(
        club,
        command,
        creator_membership_id,
        name,
        email_slug
      )
    end
  end

  def execute(%__MODULE__{club_id: nil}, %AddCustomGroupMember{}),
    do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AddCustomGroupMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <-
           validate_id(
             :group_membership,
             command.group_membership_id,
             :invalid_group_membership_id
           ),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- validate_id(:person, command.actor_person_id, :invalid_actor_person_id),
         :ok <- ensure_custom_group(club, command.group_id),
         :ok <-
           authorize_custom_group_admission_actor(
             club,
             command.group_id,
             command.actor_person_id
           ),
         :ok <-
           ensure_active_custom_group_target(
             club,
             command.membership_id,
             command.person_id
           ) do
      add_custom_group_member_decision(club, command)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %StartGroupMembership{}),
    do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %StartGroupMembership{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <-
           validate_id(
             :group_membership,
             command.group_membership_id,
             :invalid_group_membership_id
           ),
         :ok <-
           validate_id(:membership, command.club_membership_id, :invalid_club_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- ensure_custom_group(club, command.group_id),
         :ok <-
           ensure_active_custom_group_target(
             club,
             command.club_membership_id,
             command.person_id
           ) do
      case start_group_membership_decision(club, command) do
        %GroupMembershipStarted{} = event ->
          [
            %GroupMemberAdded{
              club_id: command.club_id,
              group_id: command.group_id,
              membership_id: command.club_membership_id,
              person_id: command.person_id
            },
            event
          ]

        other_result ->
          other_result
      end
    end
  end

  def execute(%__MODULE__{club_id: nil}, %EndGroupMembership{}),
    do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %EndGroupMembership{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <-
           validate_id(
             :group_membership,
             command.group_membership_id,
             :invalid_group_membership_id
           ),
         :ok <-
           validate_id(:membership, command.club_membership_id, :invalid_club_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- validate_non_empty_string(command.idempotency_key, :invalid_idempotency_key),
         :ok <- validate_non_empty_string(command.reason, :invalid_reason),
         :ok <- ensure_custom_group(club, command.group_id) do
      case end_group_membership_decision(club, command) do
        %GroupMembershipEnded{} = event ->
          [
            event,
            %GroupMemberRemoved{
              club_id: command.club_id,
              group_id: command.group_id,
              membership_id: command.club_membership_id,
              person_id: command.person_id
            }
          ]

        other_result ->
          other_result
      end
    end
  end

  def execute(%__MODULE__{club_id: nil}, %AddClubMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AddClubMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id) do
      add_member_decision(club, command)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %RemoveClubMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %RemoveClubMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           ensure_active_membership_identity(
             club,
             command.membership_id,
             command.person_id
           ),
         :ok <- ensure_member_removal_keeps_active_member(club),
         :ok <-
           ensure_member_removal_keeps_active_admin(
             club,
             command.membership_id
           ) do
      club_member_removed = %ClubMemberRemoved{
        club_id: command.club_id,
        membership_id: command.membership_id,
        person_id: command.person_id
      }

      group_membership_endings =
        current_custom_group_membership_endings(club, command.membership_id)

      legacy_group_membership_removals =
        active_custom_group_membership_removals(club, command.membership_id)

      case group_membership_endings ++
             [club_member_removed] ++
             legacy_group_membership_removals do
        [single_event] -> single_event
        events -> events
      end
    end
  end

  def execute(%__MODULE__{club_id: nil}, %DefineClubRole{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %DefineClubRole{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         {:ok, name} <- GroupName.normalize(command.name),
         {:ok, role_key} <- normalize_role_key(command.role_key),
         :ok <- ensure_role_id_available(club, command.role_id),
         :ok <- ensure_role_key_available(club, role_key) do
      %ClubRoleDefined{
        club_id: command.club_id,
        role_id: command.role_id,
        role_key: role_key,
        name: name
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %GrantClubRolePermission{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %GrantClubRolePermission{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         :ok <- ensure_role_exists(club, command.role_id),
         :ok <- validate_permission(command.permission),
         :ok <- ensure_permission_not_granted(club, command.role_id, command.permission) do
      %ClubRolePermissionGranted{
        club_id: command.club_id,
        role_id: command.role_id,
        permission: command.permission
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %CreateGroup{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %CreateGroup{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         {:ok, name} <- GroupName.normalize(command.name),
         {:ok, group_key} <- normalize_group_key(command.group_key),
         {:ok, email_slug} <- normalize_optional_group_email_slug(command.email_slug) do
      create_group_decision(club, command, group_key, name, email_slug)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %AssignGroupEmailSlug{}),
    do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AssignGroupEmailSlug{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         {:ok, email_slug} <- Slug.normalize_for_lookup(command.email_slug),
         :ok <- ensure_group_exists(club, command.group_id) do
      assign_group_email_slug_decision(club, command, email_slug)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %AddGroupMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AddGroupMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- ensure_group_exists(club, command.group_id) do
      add_group_member_decision(club, command)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %RemoveGroupMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %RemoveGroupMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- ensure_group_exists(club, command.group_id) do
      remove_group_member_decision(club, command)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %AssignClubRoleToMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AssignClubRoleToMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_optional_id(:person, command.assigned_by_person_id, :invalid_actor_person_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         :ok <- ensure_role_exists(club, command.role_id),
         :ok <-
           ensure_active_role_assignment_target(
             club,
             command.membership_id,
             command.person_id
           ),
         :ok <- ensure_role_assignment_available(club, command.membership_id, command.role_id) do
      %ClubRoleAssignedToMember{
        club_id: command.club_id,
        membership_id: command.membership_id,
        person_id: command.person_id,
        role_id: command.role_id,
        assigned_by_person_id: command.assigned_by_person_id,
        assignment_source: "explicit_command"
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %RemoveClubRoleFromMember{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %RemoveClubRoleFromMember{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_optional_id(:person, command.removed_by_person_id, :invalid_actor_person_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         :ok <- ensure_role_exists(club, command.role_id),
         :ok <-
           ensure_active_role_assignment_target(
             club,
             command.membership_id,
             command.person_id
           ),
         :ok <-
           ensure_role_assignment_exists(
             club,
             command.membership_id,
             command.person_id,
             command.role_id
           ),
         :ok <-
           ensure_admin_role_removal_keeps_active_admin(
             club,
             command.membership_id,
             command.role_id
           ) do
      %ClubRoleRemovedFromMember{
        club_id: command.club_id,
        membership_id: command.membership_id,
        person_id: command.person_id,
        role_id: command.role_id,
        removed_by_person_id: command.removed_by_person_id
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %ReconcileLegacyAdminHistory{}),
    do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %ReconcileLegacyAdminHistory{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           ensure_active_membership_identity(
             club,
             command.membership_id,
             command.person_id
           ),
         :ok <- ensure_legacy_admin_role_definition_reconcilable(club),
         :ok <- ensure_legacy_admin_role_key_reconcilable(club),
         :ok <- ensure_legacy_admin_assignment_reconcilable(club, command) do
      reconcile_legacy_admin_history_decision(club, command)
    end
  end

  def execute(%__MODULE__{club_id: nil}, %UpdateClub{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %UpdateClub{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         {:ok, name} <- GroupName.normalize(command.name),
         {:ok, slug} <- Slug.validate(command.slug) do
      %ClubUpdated{club_id: command.club_id, name: name, slug: slug}
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = club, %ClubCreated{} = event) do
    %__MODULE__{club | club_id: event.club_id, name: event.name, slug: event.slug}
  end

  def apply(%__MODULE__{} = club, %ClubRoleDefined{} = event) do
    role = %{role_id: event.role_id, role_key: event.role_key, name: event.name}

    %__MODULE__{
      club
      | roles: Map.put(club.roles, event.role_id, role),
        role_keys: put_role_key(club.role_keys, event.role_key, event.role_id)
    }
  end

  def apply(%__MODULE__{} = club, %ClubRolePermissionGranted{} = event) do
    permissions =
      club.role_permissions
      |> Map.get(event.role_id, MapSet.new())
      |> MapSet.put(event.permission)

    %__MODULE__{
      club
      | role_permissions: Map.put(club.role_permissions, event.role_id, permissions)
    }
  end

  def apply(%__MODULE__{} = club, %ClubUpdated{} = event) do
    %__MODULE__{club | name: event.name, slug: event.slug}
  end

  def apply(%__MODULE__{} = club, %GroupCreated{} = event) do
    group = %{
      email_slug: nil,
      group_id: event.group_id,
      group_key: event.group_key,
      name: event.name
    }

    %__MODULE__{
      club
      | groups: Map.put(club.groups, event.group_id, group),
        group_keys: put_group_key(club.group_keys, event.group_key, event.group_id),
        group_name_keys:
          Map.put(
            club.group_name_keys,
            GroupName.uniqueness_key(event.name),
            event.group_id
          )
    }
  end

  def apply(%__MODULE__{} = club, %GroupEmailSlugAssigned{} = event) do
    group =
      club.groups
      |> Map.fetch!(event.group_id)
      |> Map.put(:email_slug, event.email_slug)

    %__MODULE__{
      club
      | groups: Map.put(club.groups, event.group_id, group),
        group_email_slugs: Map.put(club.group_email_slugs, event.email_slug, event.group_id)
    }
  end

  def apply(%__MODULE__{} = club, %GroupMemberAdded{} = event) do
    group_membership = %{person_id: event.person_id, active: true}
    group_membership_key = group_membership_key(event.group_id, event.membership_id)

    club =
      %__MODULE__{
        club
        | group_memberships:
            Map.put(club.group_memberships, group_membership_key, group_membership)
      }

    apply_everyone_compatibility_membership(club, event, :activate)
  end

  def apply(%__MODULE__{} = club, %GroupMemberRemoved{} = event) do
    group_membership = %{person_id: event.person_id, active: false}
    group_membership_key = group_membership_key(event.group_id, event.membership_id)

    club =
      %__MODULE__{
        club
        | group_memberships:
            Map.put(club.group_memberships, group_membership_key, group_membership)
      }

    apply_everyone_compatibility_membership(club, event, :deactivate)
  end

  def apply(%__MODULE__{} = club, %GroupMembershipStarted{} = event) do
    membership = %GroupMembership{
      club_id: event.club_id,
      group_id: event.group_id,
      group_membership_id: event.group_membership_id,
      club_membership_id: event.club_membership_id,
      person_id: event.person_id,
      status: :current
    }

    relation_key = group_membership_key(event.group_id, event.club_membership_id)

    %__MODULE__{
      club
      | first_class_group_memberships:
          Map.put(club.first_class_group_memberships, event.group_membership_id, membership),
        current_group_membership_ids:
          Map.put(club.current_group_membership_ids, relation_key, event.group_membership_id),
        group_memberships:
          Map.put(club.group_memberships, relation_key, %{
            person_id: event.person_id,
            active: true
          })
    }
  end

  def apply(%__MODULE__{} = club, %GroupMembershipEnded{} = event) do
    membership = Map.fetch!(club.first_class_group_memberships, event.group_membership_id)

    membership = %GroupMembership{
      membership
      | status: :ended,
        end_idempotency_key: event.idempotency_key,
        end_reason: event.reason
    }

    relation_key = group_membership_key(event.group_id, event.club_membership_id)

    {current_group_membership_ids, group_memberships} =
      case Map.get(club.current_group_membership_ids, relation_key) do
        current_id when current_id == event.group_membership_id ->
          {
            Map.delete(club.current_group_membership_ids, relation_key),
            Map.put(club.group_memberships, relation_key, %{
              person_id: event.person_id,
              active: false
            })
          }

        _later_or_missing_membership ->
          {club.current_group_membership_ids, club.group_memberships}
      end

    ending_signature = group_membership_ending_signature(event)

    %__MODULE__{
      club
      | first_class_group_memberships:
          Map.put(club.first_class_group_memberships, event.group_membership_id, membership),
        current_group_membership_ids: current_group_membership_ids,
        group_memberships: group_memberships,
        group_membership_endings:
          Map.put(club.group_membership_endings, event.idempotency_key, ending_signature)
    }
  end

  def apply(%__MODULE__{} = club, %ClubMemberAdded{} = event) do
    apply_club_member_added(club, event)
  end

  def apply(%__MODULE__{} = club, %LegacyMemberAdded{} = event) do
    apply_club_member_added(club, event)
  end

  def apply(%__MODULE__{} = club, %ClubMemberRemoved{} = event) do
    apply_club_member_removed(club, event)
  end

  def apply(%__MODULE__{} = club, %LegacyMemberRemoved{} = event) do
    apply_club_member_removed(club, event)
  end

  def apply(%__MODULE__{} = club, %ClubRoleAssignedToMember{} = event) do
    apply_club_role_assigned_to_member(club, event)
  end

  def apply(%__MODULE__{} = club, %LegacyMemberRoleAssigned{} = event) do
    apply_club_role_assigned_to_member(club, event)
  end

  def apply(%__MODULE__{} = club, %ClubRoleRemovedFromMember{} = event) do
    apply_club_role_removed_from_member(club, event)
  end

  def apply(%__MODULE__{} = club, %LegacyMemberRoleRemoved{} = event) do
    apply_club_role_removed_from_member(club, event)
  end

  defp apply_club_member_added(%__MODULE__{} = club, event) do
    club =
      %__MODULE__{
        club
        | active_memberships:
            Map.put(club.active_memberships, event.membership_id, event.person_id),
          native_membership_ids: MapSet.put(club.native_membership_ids, event.membership_id)
      }

    derive_active_admin_membership_ids(club)
  end

  defp apply_club_member_removed(%__MODULE__{} = club, event) do
    club =
      %__MODULE__{
        club
        | active_memberships: Map.delete(club.active_memberships, event.membership_id),
          native_membership_ids: MapSet.put(club.native_membership_ids, event.membership_id)
      }

    derive_active_admin_membership_ids(club)
  end

  defp apply_club_role_assigned_to_member(%__MODULE__{} = club, event) do
    assignment = %{person_id: event.person_id}
    assignment_key = role_assignment_key(event.membership_id, event.role_id)

    club =
      %__MODULE__{
        club
        | role_assignments: Map.put(club.role_assignments, assignment_key, assignment)
      }

    derive_active_admin_membership_ids(club)
  end

  defp apply_club_role_removed_from_member(%__MODULE__{} = club, event) do
    assignment_key = role_assignment_key(event.membership_id, event.role_id)

    club =
      %__MODULE__{
        club
        | role_assignments: Map.delete(club.role_assignments, assignment_key)
      }

    derive_active_admin_membership_ids(club)
  end

  defp validate_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, ^club_id} -> :ok
      _other -> {:error, :invalid_club_id}
    end
  end

  defp validate_existing_club_id(%__MODULE__{club_id: club_id}, club_id), do: :ok
  defp validate_existing_club_id(%__MODULE__{}, _club_id), do: {:error, :invalid_club_id}

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end

  defp validate_optional_id(_type, nil, _error), do: :ok
  defp validate_optional_id(_type, "", _error), do: :ok

  defp validate_optional_id(type, value, error) do
    validate_id(type, value, error)
  end

  defp validate_non_empty_string(value, _error) when is_binary(value) and value != "", do: :ok
  defp validate_non_empty_string(_value, error), do: {:error, error}

  defp add_member_decision(%__MODULE__{} = club, %AddClubMember{} = command) do
    case Map.fetch(club.active_memberships, command.membership_id) do
      {:ok, person_id} when person_id == command.person_id ->
        []

      {:ok, _different_person_id} ->
        {:error, :membership_id_already_used}

      :error ->
        add_inactive_member_decision(club, command)
    end
  end

  defp add_inactive_member_decision(%__MODULE__{} = club, %AddClubMember{} = command) do
    cond do
      membership_id_recorded?(club, command.membership_id) ->
        {:error, :membership_id_already_used}

      command.person_id in Map.values(club.active_memberships) ->
        {:error, :already_active_member}

      true ->
        club_member_added = %ClubMemberAdded{
          club_id: command.club_id,
          membership_id: command.membership_id,
          person_id: command.person_id
        }

        if map_size(club.active_memberships) == 0 do
          [
            club_member_added,
            %ClubRoleAssignedToMember{
              club_id: command.club_id,
              membership_id: command.membership_id,
              person_id: command.person_id,
              role_id: Roles.membership_administrator_role_id(command.club_id),
              assignment_source: "automatic_first_club_member"
            }
          ]
        else
          club_member_added
        end
    end
  end

  defp membership_id_recorded?(%__MODULE__{} = club, membership_id) do
    MapSet.member?(club.native_membership_ids, membership_id) or
      Map.has_key?(
        club.group_memberships,
        group_membership_key(SystemGroups.everyone_group_id(club.club_id), membership_id)
      )
  end

  defp ensure_active_membership_identity(%__MODULE__{} = club, membership_id, person_id) do
    case Map.fetch(club.active_memberships, membership_id) do
      {:ok, ^person_id} -> :ok
      {:ok, _different_person_id} -> {:error, :membership_person_mismatch}
      :error -> {:error, :not_found}
    end
  end

  defp normalize_role_key(nil), do: {:ok, nil}
  defp normalize_role_key(""), do: {:ok, nil}

  defp normalize_role_key(role_key) when is_binary(role_key) do
    case String.trim(role_key) do
      "" -> {:ok, nil}
      trimmed_role_key -> {:ok, trimmed_role_key}
    end
  end

  defp normalize_role_key(_role_key), do: {:error, :invalid_role_key}

  defp normalize_group_key(nil), do: {:ok, nil}
  defp normalize_group_key(""), do: {:ok, nil}

  defp normalize_group_key(group_key) when is_binary(group_key) do
    case String.trim(group_key) do
      "" -> {:ok, nil}
      trimmed_group_key -> {:ok, trimmed_group_key}
    end
  end

  defp normalize_group_key(_group_key), do: {:error, :invalid_group_key}

  defp ensure_role_id_available(%__MODULE__{} = club, role_id) do
    if Map.has_key?(club.roles, role_id) do
      {:error, :role_already_defined}
    else
      :ok
    end
  end

  defp ensure_role_key_available(_club, nil), do: :ok

  defp ensure_role_key_available(%__MODULE__{} = club, role_key) do
    if Map.has_key?(club.role_keys, role_key) do
      {:error, :role_key_already_defined}
    else
      :ok
    end
  end

  defp ensure_role_exists(%__MODULE__{} = club, role_id) do
    if Map.has_key?(club.roles, role_id) do
      :ok
    else
      {:error, :role_not_defined}
    end
  end

  defp validate_permission(permission) do
    if Permissions.valid?(permission) do
      :ok
    else
      {:error, :invalid_permission}
    end
  end

  defp ensure_permission_not_granted(%__MODULE__{} = club, role_id, permission) do
    granted_permissions = Map.get(club.role_permissions, role_id, MapSet.new())

    if MapSet.member?(granted_permissions, permission) do
      {:error, :permission_already_granted}
    else
      :ok
    end
  end

  defp ensure_role_assignment_available(%__MODULE__{} = club, membership_id, role_id) do
    if Map.has_key?(club.role_assignments, role_assignment_key(membership_id, role_id)) do
      {:error, :role_already_assigned}
    else
      :ok
    end
  end

  defp ensure_active_role_assignment_target(%__MODULE__{} = club, membership_id, person_id) do
    if Map.get(club.active_memberships, membership_id) == person_id do
      :ok
    else
      {:error, :member_not_active}
    end
  end

  defp ensure_role_assignment_exists(%__MODULE__{} = club, membership_id, person_id, role_id) do
    assignment_key = role_assignment_key(membership_id, role_id)

    case Map.fetch(club.role_assignments, assignment_key) do
      {:ok, %{person_id: ^person_id}} -> :ok
      {:ok, %{}} -> {:error, :role_assignment_person_mismatch}
      :error -> {:error, :role_assignment_not_found}
    end
  end

  defp ensure_legacy_admin_role_definition_reconcilable(%__MODULE__{} = club) do
    role_id = Roles.membership_administrator_role_id(club.club_id)

    case Map.fetch(club.roles, role_id) do
      {:ok, role} ->
        if legacy_admin_role_definition?(role) do
          :ok
        else
          {:error, :conflicting_legacy_admin_role_definition}
        end

      :error ->
        :ok
    end
  end

  defp legacy_admin_role_definition?(%{role_key: role_key, name: name}) do
    {role_key, name} in [
      {Roles.membership_administrator_key(), Roles.membership_administrator_name()},
      {Roles.historic_membership_administrator_key(),
       Roles.historic_membership_administrator_name()}
    ]
  end

  defp legacy_admin_role_definition?(_role), do: false

  defp ensure_legacy_admin_role_key_reconcilable(%__MODULE__{} = club) do
    role_id = Roles.membership_administrator_role_id(club.club_id)

    Enum.reduce_while(legacy_admin_role_keys(), :ok, fn role_key, :ok ->
      case Map.fetch(club.role_keys, role_key) do
        {:ok, ^role_id} -> {:cont, :ok}
        {:ok, _other_role_id} -> {:halt, {:error, :legacy_admin_role_key_conflict}}
        :error -> {:cont, :ok}
      end
    end)
  end

  defp legacy_admin_role_keys do
    [
      Roles.membership_administrator_key(),
      Roles.historic_membership_administrator_key()
    ]
  end

  defp ensure_legacy_admin_assignment_reconcilable(
         %__MODULE__{} = club,
         %ReconcileLegacyAdminHistory{} = command
       ) do
    role_id = Roles.membership_administrator_role_id(club.club_id)
    assignment_key = role_assignment_key(command.membership_id, role_id)

    case Map.fetch(club.role_assignments, assignment_key) do
      {:ok, %{person_id: person_id}} when person_id == command.person_id -> :ok
      {:ok, %{}} -> {:error, :legacy_admin_assignment_person_mismatch}
      :error -> :ok
    end
  end

  defp ensure_admin_role_removal_keeps_active_admin(
         %__MODULE__{} = club,
         membership_id,
         role_id
       ) do
    admin_role_id = Roles.membership_administrator_role_id(club.club_id)

    if role_id == admin_role_id and
         MapSet.member?(club.active_admin_membership_ids, membership_id) and
         MapSet.size(club.active_admin_membership_ids) == 1 do
      {:error, :last_membership_administrator}
    else
      :ok
    end
  end

  defp ensure_member_removal_keeps_active_member(%__MODULE__{} = club) do
    if map_size(club.active_memberships) == 1 do
      {:error, :last_active_member}
    else
      :ok
    end
  end

  defp ensure_member_removal_keeps_active_admin(%__MODULE__{} = club, membership_id) do
    if MapSet.member?(club.active_admin_membership_ids, membership_id) and
         MapSet.size(club.active_admin_membership_ids) == 1 do
      {:error, :last_membership_administrator}
    else
      :ok
    end
  end

  defp current_custom_group_membership_endings(
         %__MODULE__{} = club,
         departing_club_membership_id
       ) do
    club.first_class_group_memberships
    |> Enum.flat_map(fn
      {_group_membership_id,
       %GroupMembership{
         status: :current,
         group_id: group_id,
         group_membership_id: group_membership_id,
         club_membership_id: ^departing_club_membership_id,
         person_id: person_id
       }} ->
        group = %{club_id: club.club_id, group_id: group_id}

        if SystemGroups.custom_group?(group) do
          [
            %GroupMembershipEnded{
              club_id: club.club_id,
              group_id: group_id,
              group_membership_id: group_membership_id,
              club_membership_id: departing_club_membership_id,
              person_id: person_id,
              idempotency_key: club_departure_group_membership_end_key(group_membership_id),
              reason: "club_membership_ended"
            }
          ]
        else
          []
        end

      {_group_membership_id, _other_group_membership} ->
        []
    end)
    |> Enum.sort_by(& &1.group_membership_id)
  end

  defp club_departure_group_membership_end_key(group_membership_id) do
    "club-membership-ended:" <> group_membership_id
  end

  defp active_custom_group_membership_removals(
         %__MODULE__{} = club,
         departing_membership_id
       ) do
    club.group_memberships
    |> Enum.flat_map(fn
      {{group_id, ^departing_membership_id}, %{active: true, person_id: person_id}} ->
        group = %{club_id: club.club_id, group_id: group_id}

        if SystemGroups.custom_group?(group) do
          [
            %GroupMemberRemoved{
              club_id: club.club_id,
              group_id: group_id,
              membership_id: departing_membership_id,
              person_id: person_id
            }
          ]
        else
          []
        end

      {_group_membership_key, _group_membership} ->
        []
    end)
    |> Enum.sort_by(& &1.group_id)
  end

  defp create_group_decision(
         %__MODULE__{} = club,
         %CreateGroup{} = command,
         group_key,
         name,
         email_slug
       ) do
    case Map.fetch(club.groups, command.group_id) do
      {:ok, %{group_key: ^group_key, name: ^name}} ->
        assign_optional_group_email_slug_decision(club, command, email_slug)

      {:ok, %{}} ->
        {:error, :group_already_defined}

      :error ->
        # Keep the established structural-key error ahead of display-name collisions.
        with :ok <- ensure_group_key_available(club, group_key),
             :ok <- ensure_group_name_available(club, command.group_id, name),
             :ok <- require_new_group_email_slug(email_slug),
             :ok <- ensure_optional_group_email_slug_available(club, email_slug) do
          group_created_event = %GroupCreated{
            club_id: command.club_id,
            group_id: command.group_id,
            group_key: group_key,
            name: name
          }

          group_creation_events(group_created_event, command, email_slug)
        end
    end
  end

  defp create_custom_group_decision(
         %__MODULE__{} = club,
         %CreateCustomGroup{} = command,
         creator_membership_id,
         name,
         email_slug
       ) do
    case Map.fetch(club.groups, command.group_id) do
      {:ok, %{email_slug: ^email_slug, group_key: nil, name: ^name}} ->
        if exact_custom_group_creation_retry?(club, command, creator_membership_id) do
          []
        else
          {:error, :group_already_defined}
        end

      {:ok, %{}} ->
        {:error, :group_already_defined}

      :error ->
        case optional_group_membership_started_events(
               club,
               command,
               creator_membership_id,
               command.actor_person_id
             ) do
          {:error, _reason} = error ->
            error

          first_class_events ->
            [
              %GroupCreated{
                club_id: command.club_id,
                group_id: command.group_id,
                group_key: nil,
                name: name
              },
              %GroupEmailSlugAssigned{
                club_id: command.club_id,
                group_id: command.group_id,
                email_slug: email_slug
              },
              %GroupMemberAdded{
                club_id: command.club_id,
                group_id: command.group_id,
                membership_id: creator_membership_id,
                person_id: command.actor_person_id
              }
              | first_class_events
            ]
        end
    end
  end

  defp exact_custom_group_creation_retry?(
         %__MODULE__{} = club,
         %CreateCustomGroup{} = command,
         creator_membership_id
       ) do
    case Map.get(
           club.group_memberships,
           group_membership_key(command.group_id, creator_membership_id)
         ) do
      %{active: true, person_id: actor_person_id} ->
        relation_key = group_membership_key(command.group_id, creator_membership_id)

        actor_person_id == command.actor_person_id and
          Map.get(club.current_group_membership_ids, relation_key) ==
            command.group_membership_id and
          exact_current_creator_group_membership?(
            club,
            command,
            creator_membership_id
          )

      _group_membership ->
        false
    end
  end

  defp exact_current_creator_group_membership?(
         %__MODULE__{} = club,
         %CreateCustomGroup{} = command,
         creator_club_membership_id
       ) do
    case Map.get(club.first_class_group_memberships, command.group_membership_id) do
      %GroupMembership{
        status: :current,
        club_id: club_id,
        group_id: group_id,
        club_membership_id: club_membership_id,
        person_id: person_id
      } ->
        club_id == command.club_id and group_id == command.group_id and
          club_membership_id == creator_club_membership_id and
          person_id == command.actor_person_id

      _missing_or_ended_membership ->
        false
    end
  end

  defp active_admin_membership_id(%__MODULE__{} = club, actor_person_id) do
    case Enum.find(club.active_admin_membership_ids, fn membership_id ->
           Map.get(club.active_memberships, membership_id) == actor_person_id
         end) do
      nil -> {:error, :unauthorized}
      membership_id -> {:ok, membership_id}
    end
  end

  defp authorize_custom_group_admission_actor(
         %__MODULE__{} = club,
         group_id,
         actor_person_id
       ) do
    authorized? =
      Enum.any?(club.active_memberships, fn
        {membership_id, ^actor_person_id} ->
          active_group_membership?(club, group_id, membership_id, actor_person_id) or
            membership_has_permission?(
              club,
              membership_id,
              actor_person_id,
              Permissions.club_manage_members()
            )

        {_membership_id, _other_person_id} ->
          false
      end)

    if authorized?, do: :ok, else: {:error, :unauthorized}
  end

  defp active_group_membership?(%__MODULE__{} = club, group_id, membership_id, person_id) do
    case Map.get(club.group_memberships, group_membership_key(group_id, membership_id)) do
      %{active: true, person_id: ^person_id} -> true
      _missing_inactive_or_mismatched -> false
    end
  end

  defp membership_has_permission?(
         %__MODULE__{} = club,
         membership_id,
         person_id,
         permission
       ) do
    Enum.any?(club.role_assignments, fn
      {{^membership_id, role_id}, %{person_id: ^person_id}} ->
        club.role_permissions
        |> Map.get(role_id, MapSet.new())
        |> MapSet.member?(permission)

      {_assignment_key, _assignment} ->
        false
    end)
  end

  defp ensure_active_custom_group_target(
         %__MODULE__{} = club,
         membership_id,
         person_id
       ) do
    case Map.fetch(club.active_memberships, membership_id) do
      {:ok, ^person_id} -> :ok
      {:ok, _different_person_id} -> {:error, :membership_person_mismatch}
      :error -> {:error, :member_not_active}
    end
  end

  defp ensure_group_name_available(%__MODULE__{} = club, group_id, name) do
    case Map.fetch(club.group_name_keys, GroupName.uniqueness_key(name)) do
      :error -> :ok
      {:ok, ^group_id} -> :ok
      {:ok, _other_group_id} -> {:error, :group_name_already_defined}
    end
  end

  defp reconcile_legacy_admin_history_decision(
         %__MODULE__{} = club,
         %ReconcileLegacyAdminHistory{} = command
       ) do
    role_id = Roles.membership_administrator_role_id(club.club_id)
    permission = Permissions.club_manage_members()

    []
    |> append_missing_legacy_admin_role_definition(club, command, role_id)
    |> append_missing_legacy_admin_permission(club, command, role_id, permission)
    |> append_missing_legacy_admin_assignment(club, command, role_id)
  end

  defp append_missing_legacy_admin_role_definition(events, %__MODULE__{} = club, command, role_id) do
    if Map.has_key?(club.roles, role_id) do
      events
    else
      events ++
        [
          %ClubRoleDefined{
            club_id: command.club_id,
            role_id: role_id,
            role_key: Roles.membership_administrator_key(),
            name: Roles.membership_administrator_name()
          }
        ]
    end
  end

  defp append_missing_legacy_admin_permission(
         events,
         %__MODULE__{} = club,
         command,
         role_id,
         permission
       ) do
    granted_permissions = Map.get(club.role_permissions, role_id, MapSet.new())

    if MapSet.member?(granted_permissions, permission) do
      events
    else
      events ++
        [
          %ClubRolePermissionGranted{
            club_id: command.club_id,
            role_id: role_id,
            permission: permission
          }
        ]
    end
  end

  defp append_missing_legacy_admin_assignment(events, %__MODULE__{} = club, command, role_id) do
    assignment_key = role_assignment_key(command.membership_id, role_id)

    if Map.has_key?(club.role_assignments, assignment_key) do
      events
    else
      events ++
        [
          %ClubRoleAssignedToMember{
            club_id: command.club_id,
            membership_id: command.membership_id,
            person_id: command.person_id,
            role_id: role_id,
            assigned_by_person_id: nil,
            assignment_source: "legacy_projection_reconciliation"
          }
        ]
    end
  end

  defp occupied_group_email_slugs(%__MODULE__{} = club, group_id) do
    current_group_email_slug =
      case Map.get(club.groups, group_id) do
        %{email_slug: email_slug} -> email_slug
        nil -> nil
      end

    club.group_email_slugs
    |> Map.delete(current_group_email_slug)
    |> Map.keys()
    |> MapSet.new()
  end

  defp normalize_optional_group_email_slug(nil), do: {:ok, nil}
  defp normalize_optional_group_email_slug(email_slug), do: Slug.normalize_for_lookup(email_slug)

  defp require_new_group_email_slug(nil), do: {:error, :invalid_format}
  defp require_new_group_email_slug(_email_slug), do: :ok

  defp ensure_optional_group_email_slug_available(_club, nil), do: :ok

  defp ensure_optional_group_email_slug_available(%__MODULE__{} = club, email_slug) do
    ensure_group_email_slug_available(club, email_slug)
  end

  defp group_creation_events(%GroupCreated{} = event, _command, nil), do: event

  defp group_creation_events(%GroupCreated{} = event, %CreateGroup{} = command, email_slug) do
    [
      event,
      group_email_slug_assigned_event(command, email_slug)
    ]
  end

  defp assign_optional_group_email_slug_decision(_club, _command, nil), do: []

  defp assign_optional_group_email_slug_decision(
         %__MODULE__{} = club,
         %CreateGroup{} = command,
         email_slug
       ) do
    assign_group_email_slug_decision(
      club,
      %AssignGroupEmailSlug{
        club_id: command.club_id,
        group_id: command.group_id,
        email_slug: email_slug
      },
      email_slug
    )
  end

  defp ensure_group_key_available(_club, nil), do: :ok

  defp ensure_group_key_available(%__MODULE__{} = club, group_key) do
    if Map.has_key?(club.group_keys, group_key) do
      {:error, :group_key_already_defined}
    else
      :ok
    end
  end

  defp assign_group_email_slug_decision(
         %__MODULE__{} = club,
         %AssignGroupEmailSlug{} = command,
         email_slug
       ) do
    case Map.fetch!(club.groups, command.group_id) do
      %{email_slug: ^email_slug} ->
        []

      %{email_slug: nil} ->
        with :ok <- ensure_group_email_slug_available(club, email_slug) do
          group_email_slug_assigned_event(command, email_slug)
        end

      %{email_slug: _email_slug} ->
        {:error, :group_email_slug_already_assigned}
    end
  end

  defp group_email_slug_assigned_event(command, email_slug) do
    %GroupEmailSlugAssigned{
      club_id: command.club_id,
      group_id: command.group_id,
      email_slug: email_slug
    }
  end

  defp ensure_group_email_slug_available(%__MODULE__{} = club, email_slug) do
    if Map.has_key?(club.group_email_slugs, email_slug) do
      {:error, :group_email_slug_already_defined}
    else
      :ok
    end
  end

  defp ensure_group_exists(%__MODULE__{} = club, group_id) do
    if Map.has_key?(club.groups, group_id) do
      :ok
    else
      {:error, :group_not_defined}
    end
  end

  defp ensure_custom_group(%__MODULE__{} = club, group_id) do
    with :ok <- ensure_group_exists(club, group_id),
         true <- SystemGroups.custom_group?(%{club_id: club.club_id, group_id: group_id}) do
      :ok
    else
      false -> {:error, :system_group_not_allowed}
      {:error, _reason} = error -> error
    end
  end

  defp add_group_member_decision(%__MODULE__{} = club, %AddGroupMember{} = command) do
    case Map.fetch(
           club.group_memberships,
           group_membership_key(command.group_id, command.membership_id)
         ) do
      {:ok, %{person_id: person_id}} when person_id != command.person_id ->
        {:error, :group_membership_person_mismatch}

      {:ok, %{active: true}} ->
        []

      {:ok, %{active: false}} ->
        group_member_added_event(command)

      :error ->
        group_member_added_event(command)
    end
  end

  defp add_custom_group_member_decision(
         %__MODULE__{} = club,
         %AddCustomGroupMember{} = command
       ) do
    case Map.fetch(
           club.group_memberships,
           group_membership_key(command.group_id, command.membership_id)
         ) do
      {:ok, %{person_id: person_id}} when person_id != command.person_id ->
        {:error, :group_membership_person_mismatch}

      {:ok, %{active: true}} ->
        exact_current_custom_group_admission_retry(club, command)

      {:ok, %{active: false}} ->
        new_custom_group_admission_decision(club, command)

      :error ->
        new_custom_group_admission_decision(club, command)
    end
  end

  defp exact_current_custom_group_admission_retry(
         %__MODULE__{} = club,
         %AddCustomGroupMember{} = command
       ) do
    relation_key = group_membership_key(command.group_id, command.membership_id)

    if Map.get(club.current_group_membership_ids, relation_key) == command.group_membership_id and
         exact_current_group_membership?(club, command.group_membership_id, command) do
      []
    else
      {:error, :group_membership_already_current}
    end
  end

  defp new_custom_group_admission_decision(
         %__MODULE__{} = club,
         %AddCustomGroupMember{} = command
       ) do
    relation_key = group_membership_key(command.group_id, command.membership_id)

    case Map.fetch(club.first_class_group_memberships, command.group_membership_id) do
      {:ok, %GroupMembership{status: :ended}} ->
        {:error, :group_membership_already_ended}

      {:ok, %GroupMembership{}} ->
        {:error, :group_membership_id_already_used}

      :error ->
        if Map.has_key?(club.current_group_membership_ids, relation_key) do
          {:error, :group_membership_already_current}
        else
          custom_group_admission_events(club, command)
        end
    end
  end

  defp custom_group_admission_events(%__MODULE__{} = club, %AddCustomGroupMember{} = command) do
    legacy_event = group_member_added_event(command)

    case optional_group_membership_started_events(
           club,
           command,
           command.membership_id,
           command.person_id
         ) do
      [] -> legacy_event
      {:error, _reason} = error -> error
      first_class_events -> [legacy_event | first_class_events]
    end
  end

  defp optional_group_membership_started_events(_club, %{group_membership_id: nil}, _id, _person),
    do: []

  defp optional_group_membership_started_events(
         %__MODULE__{} = club,
         command,
         club_membership_id,
         person_id
       ) do
    case start_group_membership_decision(club, %StartGroupMembership{
           club_id: command.club_id,
           group_id: command.group_id,
           group_membership_id: command.group_membership_id,
           club_membership_id: club_membership_id,
           person_id: person_id
         }) do
      [] -> []
      %GroupMembershipStarted{} = event -> [event]
      {:error, _reason} = error -> error
    end
  end

  defp start_group_membership_decision(
         %__MODULE__{} = club,
         %StartGroupMembership{} = command
       ) do
    relation_key = group_membership_key(command.group_id, command.club_membership_id)

    case Map.fetch(club.first_class_group_memberships, command.group_membership_id) do
      {:ok, %GroupMembership{} = existing} ->
        if exact_group_membership_start?(existing, command) do
          []
        else
          {:error, :group_membership_id_already_used}
        end

      :error ->
        if current_group_membership_relation?(club, relation_key) do
          {:error, :group_membership_already_current}
        else
          %GroupMembershipStarted{
            club_id: command.club_id,
            group_id: command.group_id,
            group_membership_id: command.group_membership_id,
            club_membership_id: command.club_membership_id,
            person_id: command.person_id
          }
        end
    end
  end

  defp current_group_membership_relation?(%__MODULE__{} = club, relation_key) do
    Map.has_key?(club.current_group_membership_ids, relation_key) or
      match?(%{active: true}, Map.get(club.group_memberships, relation_key))
  end

  defp exact_current_group_membership?(%__MODULE__{} = club, group_membership_id, command) do
    case Map.get(club.first_class_group_memberships, group_membership_id) do
      %GroupMembership{status: :current} = membership ->
        exact_group_membership_start?(membership, command)

      _missing_or_ended_membership ->
        false
    end
  end

  defp exact_group_membership_start?(%GroupMembership{} = membership, command) do
    membership.club_id == command.club_id and
      membership.group_id == command.group_id and
      membership.group_membership_id == command.group_membership_id and
      membership.club_membership_id == command_club_membership_id(command) and
      membership.person_id == command.person_id
  end

  defp command_club_membership_id(%{club_membership_id: club_membership_id}),
    do: club_membership_id

  defp command_club_membership_id(%{membership_id: club_membership_id}),
    do: club_membership_id

  defp end_group_membership_decision(%__MODULE__{} = club, %EndGroupMembership{} = command) do
    signature = group_membership_ending_signature(command)

    case Map.fetch(club.group_membership_endings, command.idempotency_key) do
      {:ok, ^signature} ->
        []

      {:ok, _different_signature} ->
        {:error, :idempotency_key_already_used}

      :error ->
        end_group_membership_without_recorded_key(club, command)
    end
  end

  defp end_group_membership_without_recorded_key(
         %__MODULE__{} = club,
         %EndGroupMembership{} = command
       ) do
    case Map.fetch(club.first_class_group_memberships, command.group_membership_id) do
      :error ->
        {:error, :group_membership_not_found}

      {:ok, %GroupMembership{} = membership} ->
        with :ok <- ensure_group_membership_end_identity(membership, command) do
          end_current_group_membership(club, membership, command)
        end
    end
  end

  defp ensure_group_membership_end_identity(%GroupMembership{} = membership, command) do
    if exact_group_membership_start?(membership, command) do
      :ok
    else
      {:error, :group_membership_identity_mismatch}
    end
  end

  defp end_current_group_membership(
         %__MODULE__{},
         %GroupMembership{status: :ended},
         _command
       ),
       do: []

  defp end_current_group_membership(
         %__MODULE__{} = club,
         %GroupMembership{} = membership,
         %EndGroupMembership{} = command
       ) do
    relation_key = group_membership_key(command.group_id, command.club_membership_id)

    if Map.get(club.current_group_membership_ids, relation_key) == command.group_membership_id do
      %GroupMembershipEnded{
        club_id: command.club_id,
        group_id: command.group_id,
        group_membership_id: command.group_membership_id,
        club_membership_id: command.club_membership_id,
        person_id: command.person_id,
        idempotency_key: command.idempotency_key,
        reason: command.reason
      }
    else
      # An exact delayed command can never end a later admission.
      case membership.status do
        :ended -> []
        :current -> {:error, :group_membership_not_current}
      end
    end
  end

  defp group_membership_ending_signature(event_or_command) do
    {
      event_or_command.club_id,
      event_or_command.group_id,
      event_or_command.group_membership_id,
      event_or_command.club_membership_id,
      event_or_command.person_id,
      event_or_command.reason
    }
  end

  defp remove_group_member_decision(%__MODULE__{} = club, %RemoveGroupMember{} = command) do
    case Map.fetch(
           club.group_memberships,
           group_membership_key(command.group_id, command.membership_id)
         ) do
      {:ok, %{person_id: person_id}} when person_id != command.person_id ->
        {:error, :group_membership_person_mismatch}

      {:ok, %{active: true}} ->
        %GroupMemberRemoved{
          club_id: command.club_id,
          group_id: command.group_id,
          membership_id: command.membership_id,
          person_id: command.person_id
        }

      {:ok, %{active: false}} ->
        []

      :error ->
        []
    end
  end

  defp group_member_added_event(%{
         club_id: club_id,
         group_id: group_id,
         membership_id: membership_id,
         person_id: person_id
       }) do
    %GroupMemberAdded{
      club_id: club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp put_role_key(role_keys, nil, _role_id), do: role_keys
  defp put_role_key(role_keys, role_key, role_id), do: Map.put(role_keys, role_key, role_id)

  defp apply_everyone_compatibility_membership(
         %__MODULE__{club_id: club_id} = club,
         event,
         lifecycle
       )
       when is_binary(club_id) do
    everyone_group_id = SystemGroups.everyone_group_id(club_id)

    if event.group_id == everyone_group_id and
         not MapSet.member?(club.native_membership_ids, event.membership_id) do
      active_memberships =
        case lifecycle do
          :activate ->
            Map.put(club.active_memberships, event.membership_id, event.person_id)

          :deactivate ->
            Map.delete(club.active_memberships, event.membership_id)
        end

      club = %__MODULE__{club | active_memberships: active_memberships}
      derive_active_admin_membership_ids(club)
    else
      club
    end
  end

  defp apply_everyone_compatibility_membership(%__MODULE__{} = club, _event, _lifecycle),
    do: club

  defp derive_active_admin_membership_ids(%__MODULE__{} = club) do
    admin_role_id = Roles.membership_administrator_role_id(club.club_id)

    active_admin_membership_ids =
      Enum.reduce(club.role_assignments, MapSet.new(), fn
        {{membership_id, ^admin_role_id}, _assignment}, active_admin_membership_ids ->
          if Map.has_key?(club.active_memberships, membership_id) do
            MapSet.put(active_admin_membership_ids, membership_id)
          else
            active_admin_membership_ids
          end

        _role_assignment, active_admin_membership_ids ->
          active_admin_membership_ids
      end)

    %__MODULE__{club | active_admin_membership_ids: active_admin_membership_ids}
  end

  defp role_assignment_key(membership_id, role_id), do: {membership_id, role_id}

  defp put_group_key(group_keys, nil, _group_id), do: group_keys

  defp put_group_key(group_keys, group_key, group_id),
    do: Map.put(group_keys, group_key, group_id)

  defp group_membership_key(group_id, membership_id), do: {group_id, membership_id}
end
