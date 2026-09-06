defmodule Memba.ProjectionBarrier do
  @moduledoc """
  Waits for Commanded Ecto projectors to catch up to an EventStore checkpoint.

  A projection barrier is satisfied when every selected projector's durable
  EventStore subscription has acknowledged events up to the target event
  number. Subscription positions are used instead of Ecto `projection_versions`
  because projectors acknowledge irrelevant events without projecting them.
  This is useful for read-your-writes checks and for acceptance tests that need
  deterministic negative assertions.
  """

  alias Memba.Repo

  @default_timeout 1_000
  @default_poll_interval 10

  @type projector :: module() | String.t()
  @type result :: %{
          checkpoint: non_neg_integer(),
          projectors: %{String.t() => non_neg_integer()}
        }

  @doc """
  Wait until each projector has processed the requested checkpoint.

  Options:

    * `:checkpoint` - event number to wait for. Defaults to the current
      EventStore checkpoint when `await/2` is called.
    * `:timeout` - maximum time to wait in milliseconds. Defaults to 1,000ms.
    * `:poll_interval` - polling interval in milliseconds. Defaults to 10ms.
  """
  @spec await([projector()], keyword()) :: {:ok, result()} | {:error, :timeout, result()}
  def await(projectors, opts \\ []) when is_list(projectors) do
    checkpoint = Keyword.get_lazy(opts, :checkpoint, &current_checkpoint/0)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    poll_interval = Keyword.get(opts, :poll_interval, @default_poll_interval)
    projector_names = Enum.map(projectors, &projector_name/1)
    deadline = System.monotonic_time(:millisecond) + timeout

    wait_until_satisfied(projector_names, checkpoint, deadline, poll_interval)
  end

  @doc """
  Like `await/2`, but raises if the barrier is not satisfied before timeout.
  """
  @spec await!([projector()], keyword()) :: result()
  def await!(projectors, opts \\ []) do
    case await(projectors, opts) do
      {:ok, result} ->
        result

      {:error, :timeout, result} ->
        raise "Projection barrier timed out waiting for #{format_projectors(result.projectors)} " <>
                "to reach checkpoint #{result.checkpoint}"
    end
  end

  @doc """
  Return the latest global EventStore event number.
  """
  @spec current_checkpoint() :: non_neg_integer()
  def current_checkpoint do
    schema = event_store_schema()

    %{rows: [[checkpoint]]} =
      Repo.query!(
        ~s|SELECT stream_version FROM #{quote_identifier(schema)}.streams WHERE stream_uuid = '$all'|
      )

    checkpoint || 0
  end

  defp wait_until_satisfied(projector_names, checkpoint, deadline, poll_interval) do
    positions = projector_positions(projector_names)

    if barrier_satisfied?(positions, checkpoint) do
      {:ok, result(checkpoint, positions)}
    else
      now = System.monotonic_time(:millisecond)

      if now >= deadline do
        {:error, :timeout, result(checkpoint, positions)}
      else
        Process.sleep(min(poll_interval, max(deadline - now, 0)))
        wait_until_satisfied(projector_names, checkpoint, deadline, poll_interval)
      end
    end
  end

  defp projector_positions(projector_names) do
    initial_positions = Map.new(projector_names, &{&1, 0})
    schema = event_store_schema()

    %{rows: rows} =
      Repo.query!(
        """
        SELECT subscription_name, COALESCE(last_seen, 0)
        FROM #{quote_identifier(schema)}.subscriptions
        WHERE stream_uuid = '$all' AND subscription_name = ANY($1)
        """,
        [projector_names]
      )

    Enum.reduce(rows, initial_positions, fn [subscription_name, event_number], positions ->
      Map.put(positions, subscription_name, event_number)
    end)
  end

  defp barrier_satisfied?(positions, checkpoint) do
    Enum.all?(positions, fn {_projector_name, event_number} -> event_number >= checkpoint end)
  end

  defp result(checkpoint, positions) do
    %{checkpoint: checkpoint, projectors: positions}
  end

  defp projector_name(projector) when is_atom(projector) do
    case Code.ensure_loaded(projector) do
      {:module, ^projector} ->
        inspect(projector)

      {:error, reason} ->
        raise ArgumentError,
              "projection barrier projector #{inspect(projector)} is not available: #{inspect(reason)}"
    end
  end

  defp projector_name(projector) when is_binary(projector) do
    String.trim_leading(projector, "Elixir.")
  end

  defp event_store_schema do
    Memba.EventStore.config()
    |> Keyword.fetch!(:schema)
    |> to_string()
  end

  defp quote_identifier(identifier) do
    escaped =
      identifier
      |> to_string()
      |> String.replace(~s("), ~s(""))

    ~s("#{escaped}")
  end

  defp format_projectors(projectors) do
    projectors
    |> Enum.map(fn {projector, position} -> "#{projector} at #{position}" end)
    |> Enum.join(", ")
  end
end
