defmodule Memba.Membership.CommandDispatch do
  @moduledoc """
  Web-facing Commanded adapter for prepared Membership commands.

  Preserve the established transition result and explicit Commanded returning
  contracts. Policy/backfill dispatches still use the application directly.
  """
  require Logger

  alias Memba.BuildInfo
  alias Memba.Membership.App
  alias Memba.Membership.Authorization

  alias Memba.Membership.Commands.{
    CreateCustomGroup,
    AddCustomGroupMember,
    RemoveCustomGroupMember
  }

  alias Memba.Membership.{CustomGroupAdmission, CustomGroupRemoval}
  alias Memba.Membership.Events.{GroupMemberAdded, GroupMemberRemoved}
  alias Memba.Membership.Policies.SystemGroupMembership

  alias Memba.Membership.Commands.{
    RemoveClubMember,
    AssignClubRoleToMember,
    RemoveClubRoleFromMember,
    AddPersonEmailAddress,
    ReplacePersonEmailAddresses,
    RemovePersonEmailAddress,
    MakePersonEmailAddressPrimary,
    VerifyPersonEmailAddress,
    CreatePerson,
    CreateClub,
    UpdateClub,
    AddClubMember,
    AcceptClubMemberInvitation
  }

  def dispatch(command, opts \\ [])

  def dispatch(%CreateCustomGroup{} = command, opts) do
    command |> raw_dispatch(opts) |> diagnose_custom_group_authorization(command)
  end

  def dispatch(%AddCustomGroupMember{} = command, opts) do
    dispatch_custom_group_admission(command, opts)
  end

  def dispatch(%RemoveCustomGroupMember{} = command, opts) do
    dispatch_custom_group_removal(command, opts)
  end

  # Match member lifecycle consistency: a re-add must not outrun the prior
  # removal's follow cleanup on the same Club stream.
  def dispatch(%AddClubMember{} = command, opts) do
    raw_dispatch(command, system_group_membership_consistency(opts))
  end

  def dispatch(%RemoveClubMember{} = command, opts) do
    raw_dispatch(command, system_group_membership_consistency(opts))
  end

  def dispatch(%AssignClubRoleToMember{} = command, opts) do
    raw_dispatch(command, system_group_membership_consistency(opts))
  end

  def dispatch(%RemoveClubRoleFromMember{} = command, opts) do
    raw_dispatch(command, system_group_membership_consistency(opts))
  end

  def dispatch(%AddPersonEmailAddress{} = command, opts), do: raw_dispatch(command, opts)
  def dispatch(%ReplacePersonEmailAddresses{} = command, opts), do: raw_dispatch(command, opts)
  def dispatch(%RemovePersonEmailAddress{} = command, opts), do: raw_dispatch(command, opts)
  def dispatch(%MakePersonEmailAddressPrimary{} = command, opts), do: raw_dispatch(command, opts)
  def dispatch(%VerifyPersonEmailAddress{} = command, opts), do: raw_dispatch(command, opts)

  def dispatch(%CreateClub{} = command, opts), do: raw_dispatch(command, opts)
  def dispatch(%UpdateClub{} = command, opts), do: raw_dispatch(command, opts)

  # CreatePerson preserves the caller's consistency and Commanded returning mode.
  def dispatch(%CreatePerson{} = command, opts), do: raw_dispatch(command, opts)

  def dispatch(%AcceptClubMemberInvitation{} = command, opts), do: raw_dispatch(command, opts)

  @doc false
  def system_group_membership_consistency(dispatch_opts) do
    Keyword.update(
      dispatch_opts,
      :consistency,
      [SystemGroupMembership],
      &include_system_group_membership_consistency/1
    )
  end

  defp include_system_group_membership_consistency(:strong), do: :strong
  defp include_system_group_membership_consistency(:eventual), do: [SystemGroupMembership]

  defp include_system_group_membership_consistency(handlers) when is_list(handlers) do
    if Enum.any?(handlers, &system_group_membership_handler?/1) do
      handlers
    else
      [SystemGroupMembership | handlers]
    end
  end

  defp include_system_group_membership_consistency(consistency), do: consistency

  defp system_group_membership_handler?(SystemGroupMembership), do: true

  defp system_group_membership_handler?(handler) when is_binary(handler) do
    handler == inspect(SystemGroupMembership)
  end

  defp system_group_membership_handler?(_handler), do: false

  defp raw_dispatch(command, opts) do
    case App.dispatch(command, opts) do
      :ok -> :ok
      {:ok, _result} = ok -> ok
      {:error, _reason} = error -> error
    end
  end

  defp dispatch_custom_group_admission(command, dispatch_opts) do
    if explicit_commanded_returning_mode?(dispatch_opts) do
      raw_dispatch(command, dispatch_opts)
    else
      dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

      case raw_dispatch(command, dispatch_opts) do
        {:ok, %Commanded.Commands.ExecutionResult{} = result} ->
          {:ok, custom_group_admission(command, result)}

        {:error, _reason} = error ->
          error
      end
    end
  end

  defp dispatch_custom_group_removal(command, dispatch_opts) do
    if explicit_commanded_returning_mode?(dispatch_opts) do
      raw_dispatch(command, dispatch_opts)
    else
      dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

      case raw_dispatch(command, dispatch_opts) do
        {:ok, %Commanded.Commands.ExecutionResult{} = result} ->
          {:ok, custom_group_removal(command, result)}

        {:error, _reason} = error ->
          error
      end
    end
  end

  defp explicit_commanded_returning_mode?(dispatch_opts) do
    Keyword.has_key?(dispatch_opts, :returning) or
      Keyword.get(dispatch_opts, :include_execution_result) == true or
      Keyword.get(dispatch_opts, :include_aggregate_version) == true
  end

  defp custom_group_admission(command, %Commanded.Commands.ExecutionResult{events: events}) do
    transition =
      if Enum.any?(events, fn
           %GroupMemberAdded{
             club_id: club_id,
             group_id: group_id,
             membership_id: membership_id,
             person_id: person_id
           } ->
             club_id == command.club_id and group_id == command.group_id and
               membership_id == command.membership_id and person_id == command.person_id

           _event ->
             false
         end) do
        :member_added
      else
        :already_member
      end

    %CustomGroupAdmission{
      club_id: command.club_id,
      group_id: command.group_id,
      membership_id: command.membership_id,
      person_id: command.person_id,
      actor_person_id: command.actor_person_id,
      transition: transition
    }
  end

  defp custom_group_removal(command, %Commanded.Commands.ExecutionResult{events: events}) do
    unless Enum.empty?(events) or
             Enum.any?(events, fn
               %GroupMemberRemoved{removal_operation_id: operation_id} ->
                 operation_id == command.removal_operation_id

               _event ->
                 false
             end) do
      raise "custom-group removal dispatch returned an unexpected event set"
    end

    %CustomGroupRemoval{
      club_id: command.club_id,
      group_id: command.group_id,
      membership_id: command.membership_id,
      person_id: command.person_id,
      actor_person_id: command.actor_person_id,
      removal_operation_id: command.removal_operation_id,
      transition: :member_removed
    }
  end

  defp diagnose_custom_group_authorization(
         {:error, :unauthorized},
         %CreateCustomGroup{} = command
       ) do
    case Authorization.authorize_manage_members(command.club_id, command.actor_person_id) do
      :ok ->
        log_custom_group_authorization_state_mismatch(command, true, :ok)
        {:error, :authorization_state_mismatch}

      {:error, :unauthorized} ->
        {:error, :unauthorized}

      other ->
        log_custom_group_authorization_state_mismatch(command, false, other)
        {:error, :authorization_state_mismatch}
    end
  end

  defp diagnose_custom_group_authorization(result, %CreateCustomGroup{}), do: result

  defp log_custom_group_authorization_state_mismatch(
         %CreateCustomGroup{} = command,
         projected_grant,
         projection_authorization_result
       ) do
    event = %{
      event: "custom_group_creation_authorization_state_mismatch",
      club_id: command.club_id,
      actor_person_id: command.actor_person_id,
      group_id: command.group_id,
      command_name: inspect(command.__struct__),
      command_classification: "custom_group_creation",
      projected_grant: projected_grant,
      projection_authorization_result: inspect(projection_authorization_result),
      aggregate_authorized: false,
      git_sha: git_sha()
    }

    Logger.error("custom_group_creation_authorization_state_mismatch #{Jason.encode!(event)}",
      event: "custom_group_creation_authorization_state_mismatch",
      club_id: command.club_id,
      actor_person_id: command.actor_person_id,
      group_id: command.group_id,
      command_name: inspect(command.__struct__),
      command_classification: "custom_group_creation",
      projected_grant: projected_grant,
      aggregate_authorized: false,
      git_sha: event.git_sha
    )
  end

  defp git_sha do
    case BuildInfo.git_sha() do
      {:ok, sha} -> sha
      :error -> nil
    end
  end
end
