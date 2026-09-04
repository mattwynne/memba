defmodule Memba.EventSourcedCase do
  @moduledoc """
  Test helpers for event-sourced tests.

  EventStore writes are not protected by Ecto SQL sandbox transactions, and
  projection projectors may write from separate processes. This case resets the
  persistent EventStore schema and configured projection tables before each test.
  """

  use ExUnit.CaseTemplate

  @projection_versions_table :projection_versions
  @projectors [
    Memba.Membership.Projectors.Club,
    Memba.Membership.Projectors.ClubInvitation,
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Group,
    Memba.Membership.Projectors.GroupMembership,
    Memba.Membership.Projectors.Role,
    Memba.Membership.Projectors.Person,
    Memba.Messaging.Projectors.Message,
    Memba.Messaging.Projectors.ConversationGroupAccess,
    Memba.Messaging.Projectors.ConversationFollow,
    Memba.Messaging.Projectors.EmailDelivery,
    Memba.Messaging.Projectors.MemberEmailDelivery,
    Memba.Messaging.Projectors.MembaStaffEmailDelivery,
    Memba.Messaging.Projectors.InboundEmailSource
  ]
  @event_handlers [
    Memba.Membership.Policies.SystemGroupMembership
  ]
  @commanded_apps [Memba.Membership.App, Memba.Messaging.App]

  using do
    quote do
      alias Memba.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Memba.EventSourcedCase
      import Memba.MembershipFixtures
    end
  end

  setup tags do
    setup_event_sourced_sandbox(tags)
  end

  @doc """
  Set up database and EventStore isolation for tests that exercise event-sourced flows.
  """
  def setup_event_sourced_sandbox(tags) do
    if tags[:async] do
      raise "Memba.EventSourcedCase resets shared EventStore state and cannot be used with async: true"
    end

    subscriber_child_ids = stop_event_sourced_subscribers!()
    stop_commanded_aggregate_instances!()
    reset_event_sourced_storage!()
    reset_commanded_subscription_acks!()
    Memba.DataCase.setup_sandbox(tags)
    start_event_sourced_subscribers!(subscriber_child_ids)
    :ok
  end

  @doc """
  Reset shared event-sourced storage while keeping EventStore subscriber subscriptions coherent.

  Use this from tests that are not using `Memba.EventSourcedCase` but need to
  truncate EventStore/projection state. Resetting the tables while subscribers
  remain subscribed can leave later strong-consistency dispatches waiting for
  acknowledgements that will never arrive.
  """
  def reset_event_sourced_system! do
    subscriber_child_ids = stop_event_sourced_subscribers!()
    stop_commanded_aggregate_instances!()
    reset_event_sourced_storage!()
    reset_commanded_subscription_acks!()
    start_event_sourced_subscribers!(subscriber_child_ids)
    :ok
  end

  @doc """
  Stop cached Commanded aggregate instances.

  The next aggregate access will rehydrate from persisted EventStore events,
  which is useful for replay-safety tests.
  """
  def stop_event_sourced_aggregate_instances! do
    stop_commanded_aggregate_instances!()
  end

  @doc """
  Rebuild configured event-sourced projections from the retained EventStore history.

  This clears projection read models and Commanded subscription acknowledgements
  without deleting EventStore events, then restarts the supervised subscribers so
  callers can wait for them to replay with `Memba.ProjectionBarrier`.
  """
  def rebuild_event_sourced_projections! do
    subscriber_child_ids = stop_event_sourced_subscribers!()

    try do
      reset_projection_tables_in_sandbox!()
      reset_commanded_subscription_acks!()
      reset_event_store_subscription_checkpoints!()
    after
      start_event_sourced_subscribers!(subscriber_child_ids)
    end

    :ok
  end

  @doc """
  Reset persistent event-sourced storage used by tests.

  The reset runs outside the SQL sandbox so EventStore rows and projector writes
  are actually removed, not merely rolled back at the end of the current test.
  """
  def reset_event_sourced_storage! do
    with_connection(fn conn ->
      reset_event_store!(conn)
      reset_projection_tables!(conn)
    end)
  end

  defp stop_event_sourced_subscribers! do
    for {child_id, pid, :worker, [module]} <- Supervisor.which_children(Memba.Supervisor),
        module in event_sourced_subscribers() do
      if is_pid(pid) do
        :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
      end

      child_id
    end
  end

  defp start_event_sourced_subscribers!(child_ids) do
    Enum.each(child_ids, fn child_id ->
      case Supervisor.restart_child(Memba.Supervisor, child_id) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _info} -> :ok
        {:error, :running} -> :ok
      end
    end)
  end

  defp stop_commanded_aggregate_instances! do
    Enum.each(@commanded_apps, fn app ->
      supervisor_name = Module.concat([app, Commanded.Aggregates.Supervisor])

      if supervisor_pid = Process.whereis(supervisor_name) do
        supervisor_pid
        |> DynamicSupervisor.which_children()
        |> Enum.each(fn {_child_id, aggregate_pid, _type, _modules} ->
          if is_pid(aggregate_pid) do
            DynamicSupervisor.terminate_child(supervisor_pid, aggregate_pid)
          end
        end)
      end
    end)
  end

  defp reset_commanded_subscription_acks! do
    Enum.each(@commanded_apps, &Commanded.Subscriptions.reset/1)
  end

  defp reset_event_store_subscription_checkpoints! do
    Enum.each(event_sourced_subscribers(), fn subscriber ->
      :ok =
        Commanded.EventStore.delete_subscription(
          subscriber_commanded_app(subscriber),
          :all,
          inspect(subscriber)
        )
    end)
  end

  defp subscriber_commanded_app(subscriber) do
    subscriber_name = inspect(subscriber)

    cond do
      String.starts_with?(subscriber_name, "Memba.Messaging.") -> Memba.Messaging.App
      String.starts_with?(subscriber_name, "Memba.Membership.") -> Memba.Membership.App
    end
  end

  defp event_sourced_subscribers, do: @projectors ++ @event_handlers

  defp reset_event_store!(conn) do
    schema = event_store_schema()

    Postgrex.transaction(conn, fn transaction ->
      query!(transaction, ~s(SET LOCAL search_path TO #{quote_identifier(schema)};))
      query!(transaction, ~s(SET LOCAL eventstore.reset TO 'on';))

      query!(
        transaction,
        """
        TRUNCATE TABLE snapshots, subscriptions, stream_events, streams, events
        RESTART IDENTITY;
        """
      )

      query!(
        transaction,
        """
        INSERT INTO streams (stream_id, stream_uuid, stream_version)
        VALUES (0, '$all', 0);
        """
      )
    end)
  end

  defp reset_projection_tables!(conn) do
    tables = projection_tables()

    if tables != [] do
      query!(
        conn,
        "TRUNCATE TABLE #{projection_table_names(tables)} RESTART IDENTITY CASCADE;"
      )
    end
  end

  defp reset_projection_tables_in_sandbox! do
    tables = projection_tables()

    if tables != [] do
      Memba.Repo.query!(
        "TRUNCATE TABLE #{projection_table_names(tables)} RESTART IDENTITY CASCADE;"
      )
    end
  end

  defp with_connection(fun) do
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, conn} = Postgrex.start_link(connection_config())

    try do
      fun.(conn)
    after
      GenServer.stop(conn)
    end
  end

  defp connection_config do
    allowed_keys = [
      :connect_timeout,
      :database,
      :hostname,
      :parameters,
      :password,
      :port,
      :socket_dir,
      :ssl,
      :ssl_opts,
      :timeout,
      :types,
      :username
    ]

    Memba.Repo.config()
    |> Keyword.take(allowed_keys)
    |> Keyword.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp event_store_schema do
    Memba.EventStore.config()
    |> Keyword.fetch!(:schema)
    |> to_string()
  end

  defp projection_tables do
    :memba
    |> Application.get_env(:event_sourced_projection_tables, [])
    |> List.wrap()
    |> Enum.uniq()
    |> then(fn tables -> Enum.uniq([@projection_versions_table | tables]) end)
  end

  defp qualified_projection_table_name(table) do
    prefix = Application.get_env(:commanded_ecto_projections, :schema_prefix) || "public"

    [prefix, table]
    |> Enum.map(&quote_identifier/1)
    |> Enum.join(".")
  end

  defp projection_table_names(tables) do
    tables
    |> Enum.map(&qualified_projection_table_name/1)
    |> Enum.join(", ")
  end

  defp quote_identifier(identifier) do
    escaped =
      identifier
      |> to_string()
      |> String.replace(~s("), ~s(""))

    ~s("#{escaped}")
  end

  defp query!(conn, statement) do
    Postgrex.query!(conn, statement, [])
  end
end
