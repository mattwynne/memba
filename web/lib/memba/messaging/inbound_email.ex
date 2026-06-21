defmodule Memba.Messaging.InboundEmail do
  @moduledoc """
  Provider-neutral inbound email data for club-message intake.

  Provider webhook controllers and parsers should translate their payload shape
  into this structure before Messaging applies club routing, sender
  authorization, body policy, and idempotency rules.
  """

  alias Memba.ID
  alias Memba.Messaging.InboundEmailAttachment
  alias Memba.Messaging.InboundEmailReplyHeaders

  @enforce_keys [
    :provider,
    :provider_message_id,
    :from_address,
    :recipient_addresses,
    :subject
  ]
  defstruct [
    :provider,
    :provider_message_id,
    :provider_event_id,
    :from_address,
    :recipient_addresses,
    :subject,
    :text_body,
    :html_body,
    :original_message_id,
    in_reply_to_message_ids: [],
    references_message_ids: [],
    attachments: []
  ]

  @type t :: %__MODULE__{
          provider: String.t(),
          provider_message_id: String.t(),
          provider_event_id: String.t() | nil,
          from_address: String.t(),
          recipient_addresses: [String.t()],
          subject: String.t(),
          text_body: String.t() | nil,
          html_body: String.t() | nil,
          original_message_id: String.t() | nil,
          in_reply_to_message_ids: [String.t()],
          references_message_ids: [String.t()],
          attachments: [InboundEmailAttachment.t()]
        }

  @doc """
  Build a provider-neutral inbound email from atom- or string-keyed attrs.
  """
  @spec new(map()) :: {:ok, t()} | {:error, atom() | {:missing_required_attribute, atom()}}
  def new(attrs) when is_map(attrs) do
    with {:ok, provider} <- fetch_required(attrs, :provider),
         {:ok, provider} <- normalize_required_string(provider, :invalid_provider),
         {:ok, provider_message_id} <- fetch_required(attrs, :provider_message_id),
         {:ok, provider_message_id} <-
           normalize_required_string(provider_message_id, :invalid_provider_message_id),
         {:ok, from_address} <- fetch_required(attrs, :from_address),
         {:ok, from_address} <- normalize_email(from_address, :invalid_from_address),
         {:ok, recipient_addresses} <- fetch_required(attrs, :recipient_addresses),
         {:ok, recipient_addresses} <- normalize_recipient_addresses(recipient_addresses),
         {:ok, subject} <- fetch_required(attrs, :subject),
         {:ok, subject} <- normalize_subject(subject),
         {:ok, provider_event_id} <-
           normalize_optional_string(
             fetch_optional(attrs, :provider_event_id),
             :invalid_provider_event_id
           ),
         {:ok, text_body} <-
           normalize_optional_body(fetch_optional(attrs, :text_body), :invalid_text_body),
         {:ok, html_body} <-
           normalize_optional_body(fetch_optional(attrs, :html_body), :invalid_html_body),
         {:ok, original_message_id} <-
           normalize_optional_string(
             fetch_optional(attrs, :original_message_id),
             :invalid_original_message_id
           ),
         {:ok, in_reply_to_message_ids} <- normalize_message_ids(in_reply_to_values(attrs)),
         {:ok, references_message_ids} <- normalize_message_ids(references_values(attrs)),
         {:ok, attachments} <- normalize_attachments(fetch_optional(attrs, :attachments)) do
      {:ok,
       %__MODULE__{
         provider: provider,
         provider_message_id: provider_message_id,
         provider_event_id: provider_event_id,
         from_address: from_address,
         recipient_addresses: recipient_addresses,
         subject: subject,
         text_body: text_body,
         html_body: html_body,
         original_message_id: original_message_id,
         in_reply_to_message_ids: in_reply_to_message_ids,
         references_message_ids: references_message_ids,
         attachments: attachments
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_inbound_email}

  @doc """
  Return the deterministic aggregate identity for a provider message.
  """
  @spec identity(t()) :: String.t()
  def identity(%__MODULE__{provider: provider, provider_message_id: provider_message_id}) do
    ID.deterministic(:inbound_email, [provider, provider_message_id])
  end

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> value
      %{^string_key => value} -> value
      _attrs -> nil
    end
  end

  defp normalize_required_string(value, error) when is_binary(value) do
    value = value |> String.trim() |> String.downcase()

    if value == "" do
      {:error, error}
    else
      {:ok, value}
    end
  end

  defp normalize_required_string(_value, error), do: {:error, error}

  defp normalize_subject(subject) when is_binary(subject), do: {:ok, String.trim(subject)}
  defp normalize_subject(_subject), do: {:error, :invalid_subject}

  defp normalize_optional_string(nil, _error), do: {:ok, nil}

  defp normalize_optional_string(value, _error) when is_binary(value) do
    case String.trim(value) do
      "" -> {:ok, nil}
      value -> {:ok, value}
    end
  end

  defp normalize_optional_string(_value, error), do: {:error, error}

  defp normalize_optional_body(nil, _error), do: {:ok, nil}
  defp normalize_optional_body(value, _error) when is_binary(value), do: {:ok, value}
  defp normalize_optional_body(_value, error), do: {:error, error}

  defp normalize_message_ids(value) do
    {:ok, InboundEmailReplyHeaders.message_ids(value)}
  end

  defp normalize_recipient_addresses(addresses) when is_list(addresses) and addresses != [] do
    addresses
    |> Enum.reduce_while({:ok, []}, fn address, {:ok, normalized_addresses} ->
      case normalize_email(address, :invalid_recipient_address) do
        {:ok, normalized_address} ->
          {:cont, {:ok, [normalized_address | normalized_addresses]}}

        {:error, :invalid_recipient_address} ->
          {:halt, {:error, :invalid_recipient_addresses}}
      end
    end)
    |> case do
      {:ok, normalized_addresses} -> {:ok, Enum.reverse(normalized_addresses)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_recipient_addresses(_addresses), do: {:error, :invalid_recipient_addresses}

  defp normalize_email(email, error) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if valid_email?(email) do
      {:ok, email}
    else
      {:error, error}
    end
  end

  defp normalize_email(_email, error), do: {:error, error}

  defp valid_email?(email) do
    case String.split(email, "@") do
      [local, domain] -> local != "" and domain != "" and String.contains?(domain, ".")
      _other -> false
    end
  end

  defp normalize_attachments(nil), do: {:ok, []}
  defp normalize_attachments([]), do: {:ok, []}

  defp normalize_attachments(attachments) when is_list(attachments) do
    attachments
    |> Enum.reduce_while({:ok, []}, fn attachment, {:ok, normalized_attachments} ->
      case InboundEmailAttachment.new(attachment) do
        {:ok, normalized_attachment} ->
          {:cont, {:ok, [normalized_attachment | normalized_attachments]}}

        {:error, :invalid_attachment} ->
          {:halt, {:error, :invalid_attachment}}
      end
    end)
    |> case do
      {:ok, normalized_attachments} -> {:ok, Enum.reverse(normalized_attachments)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_attachments(_attachments), do: {:error, :invalid_attachments}

  defp in_reply_to_values(attrs) do
    [
      fetch_optional(attrs, :in_reply_to_message_ids),
      fetch_optional(attrs, :in_reply_to_message_id)
    ]
  end

  defp references_values(attrs) do
    [
      fetch_optional(attrs, :references_message_ids),
      fetch_optional(attrs, :reference_message_ids),
      fetch_optional(attrs, :references_message_id),
      fetch_optional(attrs, :reference_message_id)
    ]
  end
end
