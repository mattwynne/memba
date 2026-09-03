defmodule Memba.Membership.Policies.SystemGroupMembership do
  @moduledoc """
  Keeps built-in group memberships aligned with membership and role lifecycle events.

  The release backfill seeds existing clubs. This strongly consistent policy starts
  from current events only and holds no process state, so future lifecycle events can
  be handled idempotently by the Club aggregate.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.SystemGroupMembership",
    consistency: :strong,
    start_from: :current

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Projectors.GroupMembership
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  @impl Commanded.Event.Handler
  def handle(%MemberAdded{} = event, _metadata) do
    dispatch(add_group_member(event, SystemGroups.everyone_group_id(event.club_id)))
  end

  def handle(%MemberRemoved{club_id: club_id, person_id: person_id}, _metadata)
      when not is_binary(club_id) or not is_binary(person_id) do
    :ok
  end

  def handle(%MemberRemoved{} = event, _metadata) do
    dispatch_all([
      remove_group_member(event, SystemGroups.everyone_group_id(event.club_id)),
      remove_group_member(event, SystemGroups.admin_group_id(event.club_id))
    ])
  end

  def handle(%MemberRoleAssigned{} = event, _metadata) do
    if admin_role?(event.club_id, event.role_id) do
      dispatch(add_group_member(event, SystemGroups.admin_group_id(event.club_id)))
    else
      :ok
    end
  end

  def handle(%MemberRoleRemoved{} = event, _metadata) do
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
