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
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Person,
    Memba.Messaging.Projectors.Message,
    Memba.Messaging.Projectors.EmailDelivery,
    Memba.Messaging.Projectors.MemberEmailDelivery,
    Memba.Messaging.Projectors.MembaStaffEmailDelivery
  ]

  using do
    quote do
      alias Memba.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Memba.EventSourcedCase
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

    projector_child_ids = stop_event_sourced_projectors!()
    reset_event_sourced_storage!()
    Memba.DataCase.setup_sandbox(tags)
    start_event_sourced_projectors!(projector_child_ids)
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

  defp stop_event_sourced_projectors! do
    for {child_id, pid, :worker, [module]} <- Supervisor.which_children(Memba.Supervisor),
        module in @projectors do
      if is_pid(pid) do
        :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
      end

      child_id
    end
  end

  defp start_event_sourced_projectors!(child_ids) do
    Enum.each(child_ids, fn child_id ->
      case Supervisor.restart_child(Memba.Supervisor, child_id) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _info} -> :ok
        {:error, :running} -> :ok
      end
    end)
  end

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
      table_names =
        tables
        |> Enum.map(&qualified_projection_table_name/1)
        |> Enum.join(", ")

      query!(conn, "TRUNCATE TABLE #{table_names} RESTART IDENTITY CASCADE;")
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
