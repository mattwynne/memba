defmodule Memba.Membership.Policies.SystemGroupMembership do
  @moduledoc """
  Keeps built-in group memberships aligned with membership and role lifecycle events.

  This strongly consistent policy starts from origin so a first subscription replays
  history instead of skipping events persisted during subscriber startup. The Club
  aggregate handles the replay with idempotent commands. The release backfill still
  seeds historic clubs that existed before these system-group facts were introduced.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.SystemGroupMembership",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned, as: LegacyMemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved, as: LegacyMemberRoleRemoved
  alias Memba.Membership.Projectors.GroupMembership
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  @impl Commanded.Event.Handler
  def handle(%ClubMemberAdded{} = event, _metadata) do
    handle_member_added(event)
  end

  def handle(%LegacyMemberAdded{} = event, _metadata) do
    handle_member_added(event)
  end

  def handle(%ClubMemberRemoved{club_id: club_id, person_id: person_id}, _metadata)
      when not is_binary(club_id) or not is_binary(person_id) do
    :ok
  end

  def handle(%LegacyMemberRemoved{club_id: club_id, person_id: person_id}, _metadata)
      when not is_binary(club_id) or not is_binary(person_id) do
    :ok
  end

  def handle(%ClubMemberRemoved{} = event, _metadata) do
    handle_member_removed(event)
  end

  def handle(%LegacyMemberRemoved{} = event, _metadata) do
    handle_member_removed(event)
  end

  def handle(%ClubRoleAssignedToMember{} = event, _metadata) do
    handle_role_assigned(event)
  end

  def handle(%LegacyMemberRoleAssigned{} = event, _metadata) do
    handle_role_assigned(event)
  end

  def handle(%ClubRoleRemovedFromMember{} = event, _metadata) do
    handle_role_removed(event)
  end

  def handle(%LegacyMemberRoleRemoved{} = event, _metadata) do
    handle_role_removed(event)
  end

  defp handle_member_added(event) do
    dispatch(add_group_member(event, SystemGroups.everyone_group_id(event.club_id)))
  end

  defp handle_member_removed(event) do
    dispatch_all([
      remove_group_member(event, SystemGroups.everyone_group_id(event.club_id)),
      remove_group_member(event, SystemGroups.admin_group_id(event.club_id))
    ])
  end

  defp handle_role_assigned(event) do
    if admin_role?(event.club_id, event.role_id) do
      dispatch(add_group_member(event, SystemGroups.admin_group_id(event.club_id)))
    else
      :ok
    end
  end

  defp handle_role_removed(event) do
    if admin_role?(event.club_id, event.role_id) do
      dispatch(remove_group_member(event, SystemGroups.admin_group_id(event.club_id)))
    else
      :ok
    end
  end

  defp admin_role?(club_id, role_id) do
    role_id == Roles.membership_administrator_role_id(club_id)
  end

  defp add_group_member(event, group_id) do
    %AddGroupMember{
      club_id: event.club_id,
      group_id: group_id,
      membership_id: event.membership_id,
      person_id: event.person_id
    }
  end

  defp remove_group_member(event, group_id) do
    %RemoveGroupMember{
      club_id: event.club_id,
      group_id: group_id,
      membership_id: event.membership_id,
      person_id: event.person_id
    }
  end

  defp dispatch_all(commands) do
    Enum.reduce_while(commands, :ok, fn command, :ok ->
      case dispatch(command) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp dispatch(command) do
    case App.dispatch(command, consistency: [GroupMembership]) do
      :ok -> :ok
      {:error, reason} when reason in [:not_created, :group_not_defined] -> :ok
      {:error, _reason} = error -> error
    end
  end
end
