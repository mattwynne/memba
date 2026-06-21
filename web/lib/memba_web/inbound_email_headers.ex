defmodule MembaWeb.InboundEmailHeaders do
  @moduledoc """
  Provider-neutral helpers for extracting threading headers from inbound webhooks.

  Postmark and Resend expose header names and values in different shapes. This
  module keeps case-insensitive header lookup and RFC Message-ID normalization in
  one place while provider parsers remain responsible for provider-specific
  payload validation.
  """

  alias Memba.Messaging.InboundEmailReplyHeaders

  @doc """
  Return the original RFC Message-ID header value, if present.
  """
  def original_message_id(headers) do
    headers
    |> header_value("message-id")
    |> optional_trimmed_string()
  end

  @doc """
  Return normalized RFC Message-ID values from all matching reply header values.

  `header_name` is matched case-insensitively and should be a lower-case header
  name such as `"in-reply-to"` or `"references"`.
  """
  def reply_message_ids(headers, header_name) when is_binary(header_name) do
    headers
    |> header_values(header_name)
    |> InboundEmailReplyHeaders.message_ids()
  end

  defp header_value(headers, name) when is_map(headers) do
    Enum.find_value(headers, fn {header_name, value} ->
      if normalize_header_name(header_name) == name, do: value
    end)
  end

  defp header_value(headers, name) when is_list(headers) do
    Enum.find_value(headers, fn
      header when is_map(header) ->
        header_name = value(header, [:Name, "Name", :name, "name"])

        if normalize_header_name(header_name) == name do
          value(header, [:Value, "Value", :value, "value"])
        end

      _header ->
        nil
    end)
  end

  defp header_value(_headers, _name), do: nil

  defp header_values(headers, name) when is_map(headers) do
    headers
    |> Enum.filter(fn {header_name, _value} -> normalize_header_name(header_name) == name end)
    |> Enum.map(fn {_header_name, value} -> value end)
  end

  defp header_values(headers, name) when is_list(headers) do
    headers
    |> Enum.flat_map(fn
      header when is_map(header) ->
        header_name = value(header, [:Name, "Name", :name, "name"])

        if normalize_header_name(header_name) == name do
          [value(header, [:Value, "Value", :value, "value"])]
        else
          []
        end

      _header ->
        []
    end)
  end

  defp header_values(_headers, _name), do: []

  defp normalize_header_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_header_name(_name), do: nil

  defp value(map, keys) when is_map(map) do
    Enum.find_value(keys, fn key ->
      if Map.has_key?(map, key), do: Map.get(map, key)
    end)
  end

  defp value(_map, _keys), do: nil

  defp optional_trimmed_string(nil), do: nil

  defp optional_trimmed_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp optional_trimmed_string(value), do: present_string(value)

  defp present_string(nil), do: nil
  defp present_string(value) when is_binary(value), do: value
  defp present_string(value), do: to_string(value)
end
