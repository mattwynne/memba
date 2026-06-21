defmodule MembaWeb.ResendInboundEmailParser do
  @moduledoc """
  Parses Resend `email.received` webhook payloads into provider-neutral inbound email attrs.
  """

  @provider "resend"
  @email_regex ~r/[A-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+/iu

  alias MembaWeb.InboundEmailHeaders

  @doc """
  Translate a Resend inbound webhook payload into attrs accepted by Messaging's
  provider-neutral inbound email API.
  """
  def parse(payload) when is_map(payload) do
    with :ok <- require_received_event(payload),
         {:ok, data} <- fetch_required_map(payload, [:data, "data"], "data"),
         {:ok, provider_message_id} <- provider_message_id(data),
         {:ok, from_address} <- from_address(data),
         {:ok, recipient_addresses} <- recipient_addresses(data),
         {:ok, subject} <- required_binary(data, [:subject, "subject"], "data.subject"),
         {:ok, text_body} <- optional_binary(data, [:text, "text"], :invalid_text_body),
         {:ok, html_body} <- optional_binary(data, [:html, "html"], :invalid_html_body),
         {:ok, attachments} <- attachments(data) do
      headers = value(data, [:headers, "headers"])

      {:ok,
       %{
         provider: @provider,
         provider_message_id: provider_message_id,
         provider_event_id:
           optional_trimmed_string(value(payload, [:id, "id", :event_id, "event_id"])),
         from_address: from_address,
         recipient_addresses: recipient_addresses,
         subject: String.trim(subject),
         text_body: text_body,
         html_body: html_body,
         original_message_id: InboundEmailHeaders.original_message_id(headers),
         in_reply_to_message_ids: InboundEmailHeaders.reply_message_ids(headers, "in-reply-to"),
         references_message_ids: InboundEmailHeaders.reply_message_ids(headers, "references"),
         attachments: attachments,
         headers: headers
       }}
    end
  end

  def parse(_payload), do: {:error, :invalid_payload}

  defp require_received_event(payload) do
    event_type = value(payload, [:type, "type", :event, "event"])

    case normalize_token(event_type) do
      "emailreceived" -> :ok
      _other -> {:error, {:unsupported_event_type, present_string(event_type)}}
    end
  end

  defp provider_message_id(data) do
    data
    |> value([:email_id, "email_id", :id, "id"])
    |> required_trimmed_string("data.email_id", :invalid_provider_message_id)
  end

  defp from_address(data) do
    with {:ok, from} <- fetch_required(data, [:from, "from"], "data.from") do
      case addresses_from_value(from) do
        [from_address | _rest] -> {:ok, from_address}
        [] -> {:error, :invalid_from_address}
      end
    end
  end

  defp recipient_addresses(data) do
    with {:ok, to} <- fetch_required(data, [:to, "to"], "data.to") do
      recipient_addresses =
        [to, value(data, [:cc, "cc"]), value(data, [:bcc, "bcc"])]
        |> Enum.flat_map(&addresses_from_value/1)

      case recipient_addresses do
        [] -> {:error, :invalid_recipient_addresses}
        recipient_addresses -> {:ok, recipient_addresses}
      end
    end
  end

  defp attachments(data) do
    case value(data, [:attachments, "attachments"]) do
      nil ->
        {:ok, []}

      attachments when is_list(attachments) ->
        attachments
        |> Enum.reduce_while({:ok, []}, fn attachment, {:ok, normalized_attachments} ->
          case attachment(attachment) do
            {:ok, normalized_attachment} ->
              {:cont, {:ok, [normalized_attachment | normalized_attachments]}}

            {:error, _reason} = error ->
              {:halt, error}
          end
        end)
        |> case do
          {:ok, normalized_attachments} -> {:ok, Enum.reverse(normalized_attachments)}
          {:error, reason} -> {:error, reason}
        end

      _other ->
        {:error, :invalid_attachments}
    end
  end

  defp attachment(attachment) when is_map(attachment) do
    with {:ok, size} <- attachment_size(value(attachment, [:size, "size"])) do
      {:ok,
       %{
         filename:
           optional_trimmed_string(value(attachment, [:filename, "filename", :name, "name"])),
         content_type:
           optional_trimmed_string(
             value(attachment, [:content_type, "content_type", :contentType, "contentType"])
           ),
         size: size,
         content_id:
           optional_trimmed_string(
             value(attachment, [:content_id, "content_id", :contentId, "contentId"])
           )
       }}
    end
  end

  defp attachment(_attachment), do: {:error, :invalid_attachments}

  defp attachment_size(nil), do: {:ok, nil}
  defp attachment_size(size) when is_integer(size) and size >= 0, do: {:ok, size}

  defp attachment_size(size) when is_binary(size) do
    case Integer.parse(String.trim(size)) do
      {size, ""} when size >= 0 -> {:ok, size}
      _invalid -> {:error, :invalid_attachments}
    end
  end

  defp attachment_size(_size), do: {:error, :invalid_attachments}

  defp addresses_from_value(nil), do: []

  defp addresses_from_value(address) when is_binary(address) do
    @email_regex
    |> Regex.scan(address)
    |> List.flatten()
    |> Enum.map(&normalize_email/1)
    |> Enum.uniq()
  end

  defp addresses_from_value(addresses) when is_list(addresses) do
    Enum.flat_map(addresses, &addresses_from_value/1)
  end

  defp addresses_from_value(address) when is_map(address) do
    address
    |> value([:email, "email", :address, "address"])
    |> addresses_from_value()
  end

  defp addresses_from_value(_value), do: []

  defp normalize_email(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  defp fetch_required_map(map, keys, label) do
    with {:ok, value} <- fetch_required(map, keys, label) do
      case value do
        value when is_map(value) -> {:ok, value}
        _other -> {:error, :invalid_payload}
      end
    end
  end

  defp required_binary(map, keys, label) do
    with {:ok, value} <- fetch_required(map, keys, label) do
      case value do
        value when is_binary(value) -> {:ok, value}
        _other -> {:error, :invalid_payload}
      end
    end
  end

  defp optional_binary(map, keys, error) do
    case value(map, keys) do
      nil -> {:ok, nil}
      value when is_binary(value) -> {:ok, value}
      _other -> {:error, error}
    end
  end

  defp required_trimmed_string(nil, label, _error),
    do: {:error, {:missing_required_attribute, label}}

  defp required_trimmed_string(value, label, _error) when is_binary(value) do
    case String.trim(value) do
      "" -> {:error, {:missing_required_attribute, label}}
      trimmed -> {:ok, trimmed}
    end
  end

  defp required_trimmed_string(_value, _label, error), do: {:error, error}

  defp fetch_required(map, keys, label) when is_map(map) do
    keys
    |> Enum.find_value(fn key ->
      if Map.has_key?(map, key), do: {:found, Map.get(map, key)}
    end)
    |> case do
      {:found, nil} -> {:error, {:missing_required_attribute, label}}
      {:found, value} -> {:ok, value}
      nil -> {:error, {:missing_required_attribute, label}}
    end
  end

  defp fetch_required(_map, _keys, label), do: {:error, {:missing_required_attribute, label}}

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

  defp normalize_token(nil), do: nil

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[\s_.-]+/, "")
  end
end
