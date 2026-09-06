defmodule Memba.Membership.SystemGroups.Backfill do
  @moduledoc """
  Reusable, restartable release backfill for built-in conversation groups.

  The backfill scans current owning-context projections in dependency order and
  appends only missing facts through idempotent commands. Cursors live only in
  this process, so a later run after failure starts from the beginning and relies
  on aggregate idempotency plus missing-row source queries to avoid duplicate
  facts.
  """

  require Logger

  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Projectors.Group
  alias Memba.Membership.Projectors.GroupMembership
  alias Memba.Messaging
  alias Memba.Messaging.Projectors.ConversationGroupAccess

  @default_page_size 500

  # Run 34047959394 appended this Everyone grant before its release command timed
  # out. Keep the exact evidence-scoped repair idempotent; do not infer repairs
  # from multi-group access, which can become valid when shared audiences arrive.
  @known_erroneous_everyone_access [
    %{
      conversation_id: "msg_ec4465c4-f306-4b4b-af68-53810f5a87e2",
      club_id: "clb_9d87f308-9ccd-40a4-a613-0c11bb003cb9",
      group_id: "grp_1f75d34f-2a18-3606-cd4d-6df61f989811"
    }
  ]

  @type phase ::
          :system_group_definitions
          | :everyone_group_memberships
          | :admin_group_memberships
          | :known_erroneous_everyone_access_cleanup
          | :everyone_conversation_access

  @type phase_summary :: %{
          pages: non_neg_integer(),
          source_count: non_neg_integer(),
          dispatched_count: non_neg_integer()
        }

  @doc """
  Run all system-group backfill phases in dependency order.

  Options:

    * `:page_size` - positive integer page size, default #{@default_page_size}.
    * `:after_command` - optional one-arity or three-arity callback invoked after
      each successful command. This is useful for instrumentation and failure
      simulation in tests.
  """
  @spec run!(keyword()) :: %{phase() => phase_summary()}
  def run!(opts \\ []) when is_list(opts) do
    page_size = page_size!(Keyword.get(opts, :page_size, @default_page_size))

    Logger.info("system_groups_backfill start page_size=#{page_size}")

    summaries =
      [
        :system_group_definitions,
        :everyone_group_memberships,
        :admin_group_memberships,
        :known_erroneous_everyone_access_cleanup,
        :everyone_conversation_access
      ]
      |> Enum.reduce(%{}, fn phase, summaries ->
        summary = run_phase(phase, page_size, opts)
        Map.put(summaries, phase, summary)
      end)

    await_projectors!()
    Logger.info("system_groups_backfill complete summary=#{inspect(summaries)}")
    summaries
  end

  defp run_phase(phase, page_size, opts) do
    Logger.info("system_groups_backfill phase=#{phase} start")

    summary =
      page_phase(phase, nil, page_size, opts, %{
        pages: 0,
        source_count: 0,
        dispatched_count: 0
      })

    Logger.info("system_groups_backfill phase=#{phase} complete counts=#{inspect(summary)}")

    summary
  end

  defp page_phase(phase, cursor, page_size, opts, summary) do
    page = fetch_page(phase, cursor, page_size)
    entries = Map.fetch!(page, :entries)
    source_count = Map.fetch!(page, :source_count)
    next_cursor = Map.fetch!(page, :next_cursor)

    Logger.info(
      "system_groups_backfill phase=#{phase} cursor=#{inspect(cursor)} " <>
        "source_count=#{source_count} missing_count=#{length(entries)}"
    )

    Enum.each(entries, &dispatch_entry!(phase, &1, opts))

    summary = %{
      pages: summary.pages + 1,
      source_count: summary.source_count + source_count,
      dispatched_count: summary.dispatched_count + length(entries)
    }

    case next_cursor do
      nil -> summary
      next_cursor -> page_phase(phase, next_cursor, page_size, opts, summary)
    end
  end

  defp fetch_page(:system_group_definitions, cursor, page_size) do
    Membership.list_system_group_definition_backfill_page(cursor, page_size)
  end

  defp fetch_page(:everyone_group_memberships, cursor, page_size) do
    Membership.list_everyone_group_membership_backfill_page(cursor, page_size)
  end

  defp fetch_page(:admin_group_memberships, cursor, page_size) do
    Membership.list_admin_group_membership_backfill_page(cursor, page_size)
  end

  defp fetch_page(:known_erroneous_everyone_access_cleanup, cursor, page_size) do
    remaining_entries =
      Enum.filter(@known_erroneous_everyone_access, fn entry ->
        is_nil(cursor) or entry.conversation_id > cursor
      end)

    source_entries = Enum.take(remaining_entries, page_size)

    entries =
      Enum.filter(source_entries, fn entry ->
        Messaging.group_has_conversation_access?(
          entry.conversation_id,
          entry.group_id,
          :read
        )
      end)

    next_cursor =
      if length(remaining_entries) > length(source_entries) do
        source_entries |> List.last() |> Map.fetch!(:conversation_id)
      end

    %{
      entries: entries,
      next_cursor: next_cursor,
      source_count: length(source_entries)
    }
  end

  defp fetch_page(:everyone_conversation_access, cursor, page_size) do
    Messaging.list_everyone_conversation_access_backfill_page(cursor, page_size)
  end

  defp dispatch_entry!(:system_group_definitions = phase, entry, opts) do
    command = %CreateGroup{
      club_id: entry.club_id,
      group_id: entry.group_id,
      email_slug: entry.email_slug,
      group_key: entry.group_key,
      name: entry.name
    }

    dispatch_membership!(phase, command, [Group])
    after_command!(opts, phase, entry, command)
  end

  defp dispatch_entry!(phase, entry, opts)
       when phase in [:everyone_group_memberships, :admin_group_memberships] do
    command = %AddGroupMember{
      club_id: entry.club_id,
      group_id: entry.group_id,
      membership_id: entry.membership_id,
      person_id: entry.person_id
    }

    dispatch_membership!(phase, command, [GroupMembership])
    after_command!(opts, phase, entry, command)
  end

  defp dispatch_entry!(:everyone_conversation_access = phase, entry, opts) do
    attrs = %{
      conversation_id: entry.conversation_id,
      club_id: entry.club_id,
      group_id: entry.group_id,
      access_level: :write
    }

    case Messaging.grant_initial_conversation_access_to_group(attrs,
           consistency: :eventual
         ) do
      :ok -> :ok
      {:ok, _result} -> :ok
      {:error, reason} -> raise backfill_error(phase, attrs, reason)
      other -> raise backfill_error(phase, attrs, {:unexpected_dispatch_result, other})
    end

    after_command!(opts, phase, entry, attrs)
  end

  defp dispatch_entry!(:known_erroneous_everyone_access_cleanup = phase, entry, opts) do
    attrs = %{
      conversation_id: entry.conversation_id,
      club_id: entry.club_id,
      group_id: entry.group_id
    }

    case Messaging.revoke_conversation_access_from_group(attrs, consistency: :eventual) do
      :ok -> :ok
      {:ok, _result} -> :ok
      {:error, reason} -> raise backfill_error(phase, attrs, reason)
      other -> raise backfill_error(phase, attrs, {:unexpected_dispatch_result, other})
    end

    after_command!(opts, phase, entry, attrs)
  end

  defp dispatch_membership!(phase, command, _consistency) do
    case MembershipApp.dispatch(command, consistency: :eventual) do
      :ok -> :ok
      {:ok, _result} -> :ok
      {:error, reason} -> raise backfill_error(phase, command, reason)
      other -> raise backfill_error(phase, command, {:unexpected_dispatch_result, other})
    end
  end

  defp await_projectors! do
    timeout =
      Application.get_env(:memba, :system_groups_backfill_projection_barrier_timeout, 60_000)

    Memba.ProjectionBarrier.await!([Group, GroupMembership, ConversationGroupAccess],
      timeout: timeout
    )
  end

  defp after_command!(opts, phase, entry, command) do
    case Keyword.get(opts, :after_command) do
      nil ->
        :ok

      callback when is_function(callback, 1) ->
        callback.(%{phase: phase, entry: entry, command: command})

      callback when is_function(callback, 3) ->
        callback.(phase, entry, command)
    end
  end

  defp backfill_error(phase, command, reason) do
    "system_groups_backfill failed phase=#{phase} command=#{inspect(command)} reason=#{inspect(reason)}"
  end

  defp page_size!(page_size) when is_integer(page_size) and page_size > 0, do: page_size

  defp page_size!(page_size) do
    raise ArgumentError,
          "system groups backfill page_size must be a positive integer, got: #{inspect(page_size)}"
  end
end
