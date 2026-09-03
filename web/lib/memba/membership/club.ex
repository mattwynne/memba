defmodule Memba.Membership.Club do
  @moduledoc """
  Club aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
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
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Membership.SystemGroups

  @behaviour Aggregate

  defstruct [
    :club_id,
    :name,
    :slug,
    groups: %{},
    group_keys: %{},
    group_memberships: %{},
    roles: %{},
    role_keys: %{},
    role_permissions: %{},
    role_assignments: %{}
  ]

  @impl Aggregate
  def execute(%__MODULE__{club_id: nil}, %CreateClub{} = command) do
    with :ok <- validate_club_id(command.club_id),
         {:ok, name} <- normalize_name(command.name),
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
        %GroupCreated{
          club_id: command.club_id,
          group_id: SystemGroups.admin_group_id(command.club_id),
          group_key: SystemGroups.admin_key(),
          name: SystemGroups.admin_name()
        }
      ]
    end
  end

  def execute(%__MODULE__{}, %CreateClub{}), do: {:error, :already_created}

  def execute(%__MODULE__{club_id: nil}, %DefineClubRole{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %DefineClubRole{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         {:ok, name} <- normalize_name(command.name),
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
         {:ok, name} <- normalize_name(command.name),
         {:ok, group_key} <- normalize_group_key(command.group_key) do
      create_group_decision(club, command, group_key, name)
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

  def execute(%__MODULE__{club_id: nil}, %AssignMemberRole{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %AssignMemberRole{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_optional_id(:person, command.assigned_by_person_id, :invalid_actor_person_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         :ok <- ensure_role_exists(club, command.role_id),
         :ok <- ensure_role_assignment_available(club, command.membership_id, command.role_id) do
      %MemberRoleAssigned{
        club_id: command.club_id,
        membership_id: command.membership_id,
        person_id: command.person_id,
        role_id: command.role_id,
        assigned_by_person_id: command.assigned_by_person_id
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %RemoveMemberRole{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %RemoveMemberRole{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_optional_id(:person, command.removed_by_person_id, :invalid_actor_person_id),
         :ok <- validate_id(:role, command.role_id, :invalid_role_id),
         :ok <- ensure_role_exists(club, command.role_id),
         :ok <-
           ensure_role_assignment_exists(
             club,
             command.membership_id,
             command.person_id,
             command.role_id
           ) do
      %MemberRoleRemoved{
        club_id: command.club_id,
        membership_id: command.membership_id,
        person_id: command.person_id,
        role_id: command.role_id,
        removed_by_person_id: command.removed_by_person_id
      }
    end
  end

  def execute(%__MODULE__{club_id: nil}, %UpdateClub{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %UpdateClub{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         {:ok, name} <- normalize_name(command.name),
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
    group = %{group_id: event.group_id, group_key: event.group_key, name: event.name}

    %__MODULE__{
      club
      | groups: Map.put(club.groups, event.group_id, group),
        group_keys: put_group_key(club.group_keys, event.group_key, event.group_id)
    }
  end

  def apply(%__MODULE__{} = club, %GroupMemberAdded{} = event) do
    group_membership = %{person_id: event.person_id, active: true}
    group_membership_key = group_membership_key(event.group_id, event.membership_id)

    %__MODULE__{
      club
      | group_memberships:
          Map.put(club.group_memberships, group_membership_key, group_membership)
    }
  end

  def apply(%__MODULE__{} = club, %GroupMemberRemoved{} = event) do
    group_membership = %{person_id: event.person_id, active: false}
    group_membership_key = group_membership_key(event.group_id, event.membership_id)

    %__MODULE__{
      club
      | group_memberships:
          Map.put(club.group_memberships, group_membership_key, group_membership)
    }
  end

  def apply(%__MODULE__{} = club, %MemberRoleAssigned{} = event) do
    assignment = %{person_id: event.person_id}
    assignment_key = role_assignment_key(event.membership_id, event.role_id)

    %__MODULE__{
      club
      | role_assignments: Map.put(club.role_assignments, assignment_key, assignment)
    }
  end

  def apply(%__MODULE__{} = club, %MemberRoleRemoved{} = event) do
    assignment_key = role_assignment_key(event.membership_id, event.role_id)

    %__MODULE__{club | role_assignments: Map.delete(club.role_assignments, assignment_key)}
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

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp normalize_name(_name), do: {:error, :invalid_name}

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

  defp ensure_role_assignment_exists(%__MODULE__{} = club, membership_id, person_id, role_id) do
    assignment_key = role_assignment_key(membership_id, role_id)

    case Map.fetch(club.role_assignments, assignment_key) do
      {:ok, %{person_id: ^person_id}} -> :ok
      {:ok, %{}} -> {:error, :role_assignment_person_mismatch}
      :error -> {:error, :role_assignment_not_found}
    end
  end

  defp create_group_decision(%__MODULE__{} = club, %CreateGroup{} = command, group_key, name) do
    case Map.fetch(club.groups, command.group_id) do
      {:ok, %{group_key: ^group_key, name: ^name}} ->
        []

      {:ok, %{}} ->
        {:error, :group_already_defined}

      :error ->
        with :ok <- ensure_group_key_available(club, group_key) do
          %GroupCreated{
            club_id: command.club_id,
            group_id: command.group_id,
            group_key: group_key,
            name: name
          }
        end
    end
  end

  defp ensure_group_key_available(_club, nil), do: :ok

  defp ensure_group_key_available(%__MODULE__{} = club, group_key) do
    if Map.has_key?(club.group_keys, group_key) do
      {:error, :group_key_already_defined}
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

  defp group_member_added_event(%AddGroupMember{} = command) do
    %GroupMemberAdded{
      club_id: command.club_id,
      group_id: command.group_id,
      membership_id: command.membership_id,
      person_id: command.person_id
    }
  end

  defp put_role_key(role_keys, nil, _role_id), do: role_keys
  defp put_role_key(role_keys, role_key, role_id), do: Map.put(role_keys, role_key, role_id)

  defp role_assignment_key(membership_id, role_id), do: {membership_id, role_id}

  defp put_group_key(group_keys, nil, _group_id), do: group_keys
  defp put_group_key(group_keys, group_key, group_id), do: Map.put(group_keys, group_key, group_id)

  defp group_membership_key(group_id, membership_id), do: {group_id, membership_id}
end
