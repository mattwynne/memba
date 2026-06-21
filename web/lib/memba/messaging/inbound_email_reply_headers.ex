defmodule Memba.Messaging.InboundEmailReplyHeaders do
  @moduledoc """
  Parses RFC Message-ID values from inbound email reply-threading headers.
  """

  alias Memba.Messaging.OutboundMessageID

  @message_id_regex ~r/<([^<>\s]+@[^<>\s]+)>|([^\s,<>]+@[^\s,<>]+)/

  @doc """
  Extract normalized RFC Message-ID values from one or more header values.

  Values are returned in header order, deduplicated, and normalized to angle
  brackets so they can be compared with persisted outbound Message-ID values.
  Malformed tokens are ignored; an unrecognized reply header should simply fail
  to match later routing rather than reject the email during parsing.
  """
  def message_ids(value) do
    value
    |> collect_message_ids()
    |> Enum.map(&normalize_message_id/1)
    |> Enum.reject(&is_nil/1)
    |> unique_in_order()
  end

  defp collect_message_ids(nil), do: []

  defp collect_message_ids(value) when is_binary(value) do
    value
    |> unfold_header_value()
    |> scan_message_ids()
  end

  defp collect_message_ids(values) when is_list(values) do
    Enum.flat_map(values, &collect_message_ids/1)
  end

  defp collect_message_ids(_value), do: []

  defp unfold_header_value(value) do
    String.replace(value, ~r/\r?\n[ \t]+/, " ")
  end

  defp scan_message_ids(value) do
    @message_id_regex
    |> Regex.scan(value, capture: :all_but_first)
    |> Enum.map(fn captures ->
      captures
      |> Enum.reject(&(&1 == ""))
      |> List.first()
    end)
  end

  defp normalize_message_id(nil), do: nil

  defp normalize_message_id(value) when is_binary(value) do
    value
    |> String.trim(" \t\r\n<>\"'()[];,")
    |> OutboundMessageID.normalize()
  end

  defp unique_in_order(message_ids) do
    {_seen, message_ids} =
      Enum.reduce(message_ids, {MapSet.new(), []}, fn message_id, {seen, message_ids} ->
        if MapSet.member?(seen, message_id) do
          {seen, message_ids}
        else
          {MapSet.put(seen, message_id), [message_id | message_ids]}
        end
      end)

    Enum.reverse(message_ids)
  end
end
