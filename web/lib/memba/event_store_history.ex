defmodule Memba.EventStoreHistory do
  @moduledoc """
  Canonical per-stream history bounded by the shared EventStore `$all` position.

  Commanded stream records expose source ordering; this helper joins immutable
  event IDs to `$all` so cutover decisions never confuse stream version with a
  global fence.
  """

  alias Commanded.EventStore
  alias Memba.Repo

  def stream_forward_at_global_position(app, event_store, stream_id, position)
      when is_integer(position) and position >= 0 do
    records =
      case EventStore.stream_forward(app, stream_id) do
        {:error, :stream_not_found} -> []
        stream -> Enum.to_list(stream)
      end

    positions = global_positions(event_store, Enum.map(records, & &1.event_id))
    Enum.filter(records, &(Map.fetch!(positions, &1.event_id) <= position))
  end

  defp global_positions(_event_store, []), do: %{}

  defp global_positions(event_store, event_ids) do
    schema = event_store.config() |> Keyword.fetch!(:schema) |> to_string()

    Repo.query!(
      """
      SELECT event.event_id::text, all_event.stream_version
      FROM #{quote_identifier(schema)}.events AS event
      JOIN #{quote_identifier(schema)}.stream_events AS all_event
        ON all_event.event_id = event.event_id
      JOIN #{quote_identifier(schema)}.streams AS all_stream
        ON all_stream.stream_id = all_event.stream_id
       AND all_stream.stream_uuid = '$all'
      WHERE event.event_id::text = ANY($1::text[])
      """,
      [event_ids]
    ).rows
    |> Map.new(fn [event_id, position] -> {event_id, position} end)
  end

  defp quote_identifier(identifier) do
    escaped = identifier |> to_string() |> String.replace(~s("), ~s(""))
    ~s("#{escaped}")
  end
end
