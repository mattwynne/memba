defmodule MembaWeb.PostmarkInboundEmailParser do
  @moduledoc """
  Parses Postmark inbound webhook payloads into provider-neutral inbound email attrs.
  """

  @provider "postmark"
  @provider_message_id_keys [:MessageID, "MessageID", :message_id, "message_id"]
  @email_regex ~r/[A-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+/iu

  alias MembaWeb.InboundEmailHeaders

  @doc """
  Translate a Postmark inbound webhook payload into attrs accepted by Messaging's
  provider-neutral inbound email API.
  """
  def parse(payload) when is_map(payload) do
    with {:ok, provider_message_id} <- provider_message_id(payload),
         {:ok, from_address} <- from_address(payload),
         {:ok, recipient_addresses} <- recipient_addresses(payload),
         {:ok, subject} <- required_binary(payload, [:Subject, "Subject"], "Subject"),
         {:ok, text_body} <-
           optional_binary(payload, [:TextBody, "TextBody"], :invalid_text_body),
         {:ok, html_body} <-
           optional_binary(payload, [:HtmlBody, "HtmlBody"], :invalid_html_body),
         {:ok, attachments} <- attachments(payload) do
      headers = value(payload, [:Headers, "Headers"])

      {:ok,
       %{
         provider: @provider,
         provider_message_id: provider_message_id,
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

  defp provider_message_id(payload) do
    # Postmark's top-level MessageID is the stable inbound retry identity.
    # The RFC Message-ID can appear in Headers and belongs to the original
    # sender message, so it is intentionally not used for provider idempotency.
    payload
    |> value(@provider_message_id_keys)
    |> required_trimmed_string("MessageID", :invalid_provider_message_id)
  end

  defp from_address(payload) do
    [value(payload, [:FromFull, "FromFull"]), value(payload, [:From, "From"])]
    |> Enum.flat_map(&addresses_from_value/1)
    |> case do
      [from_address | _rest] -> {:ok, from_address}
      [] -> {:error, :invalid_from_address}
    end
  end

  defp recipient_addresses(payload) do
    [
      value(payload, [:OriginalRecipient, "OriginalRecipient"]),
      value(payload, [:ToFull, "ToFull"]),
      value(payload, [:To, "To"]),
      value(payload, [:CcFull, "CcFull"]),
      value(payload, [:Cc, "Cc"]),
      value(payload, [:BccFull, "BccFull"]),
      value(payload, [:Bcc, "Bcc"])
    ]
    |> Enum.flat_map(&addresses_from_value/1)
    |> Enum.uniq()
    |> case do
      [] -> {:error, :invalid_recipient_addresses}
      recipient_addresses -> {:ok, recipient_addresses}
    end
  end

  defp attachments(payload) do
    case value(payload, [:Attachments, "Attachments"]) do
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
    with {:ok, size} <-
           attachment_size(value(attachment, [:ContentLength, "ContentLength", :size, "size"])) do
      {:ok,
       %{
         filename:
           optional_trimmed_string(value(attachment, [:Name, "Name", :filename, "filename"])),
         content_type:
           optional_trimmed_string(
             value(attachment, [
               :ContentType,
               "ContentType",
               :content_type,
               "content_type",
               :contentType,
               "contentType"
             ])
           ),
         size: size,
         content_id:
           optional_trimmed_string(
             value(attachment, [
               :ContentID,
               "ContentID",
               :ContentId,
               "ContentId",
               :content_id,
               "content_id",
               :contentId,
               "contentId"
             ])
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
    |> value([:Email, "Email", :email, "email", :address, "address"])
    |> addresses_from_value()
  end

  defp addresses_from_value(_value), do: []

  defp normalize_email(email) do
    email
    |> String.trim()
    |> String.downcase()
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
end
