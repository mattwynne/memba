defmodule Memba.Messaging.Message do
  @moduledoc """
  Message aggregate for the Messaging bounded context.

  One aggregate represents one club message and owns the per-recipient delivery
  records created for that message.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.RecipientDeliveryCreated
  alias Memba.Messaging.Recipient

  @behaviour Aggregate

  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :subject,
    :body,
    recipient_delivery_ids: MapSet.new(),
    recipient_ids: MapSet.new()
  ]

  @impl Aggregate
  def execute(%__MODULE__{message_id: nil}, %SendMessage{} = command) do
    with :ok <- validate_uuid(command.message_id, :invalid_message_id),
         :ok <- validate_uuid(command.club_id, :invalid_club_id),
         :ok <- validate_uuid(command.sender_id, :invalid_sender_id),
         {:ok, subject} <- normalize_text(command.subject, :invalid_subject),
         {:ok, body} <- normalize_text(command.body, :invalid_body),
         {:ok, recipients} <- normalize_recipients(command.recipients),
         :ok <- validate_sender_recipient(command.sender_id, recipients) do
      [
        %MessageSent{
          message_id: command.message_id,
          club_id: command.club_id,
          sender_id: command.sender_id,
          subject: subject,
          body: body
        }
        | Enum.map(recipients, &recipient_delivery_created(command.message_id, &1))
      ]
    end
  end

  def execute(%__MODULE__{}, %SendMessage{}), do: {:error, :already_sent}

  @impl Aggregate
  def apply(%__MODULE__{} = message, %MessageSent{} = event) do
    %__MODULE__{
      message
      | message_id: event.message_id,
        club_id: event.club_id,
        sender_id: event.sender_id,
        subject: event.subject,
        body: event.body
    }
  end

  def apply(%__MODULE__{} = message, %RecipientDeliveryCreated{} = event) do
    %__MODULE__{
      message
      | recipient_delivery_ids: MapSet.put(message.recipient_delivery_ids, event.delivery_id),
        recipient_ids: MapSet.put(message.recipient_ids, event.recipient_id)
    }
  end

  defp recipient_delivery_created(message_id, %Recipient{} = recipient) do
    %RecipientDeliveryCreated{
      message_id: message_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_email: recipient.email
    }
  end

  defp validate_uuid(value, error) do
    case Ecto.UUID.cast(value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end

  defp normalize_text(text, error) when is_binary(text) do
    case String.trim(text) do
      "" -> {:error, error}
      trimmed_text -> {:ok, trimmed_text}
    end
  end

  defp normalize_text(_text, error), do: {:error, error}

  defp normalize_recipients(recipients) when is_list(recipients) and recipients != [] do
    with {:ok, recipients} <- normalize_each_recipient(recipients),
         :ok <- validate_unique(recipients, & &1.delivery_id, :duplicate_delivery),
         :ok <- validate_unique(recipients, & &1.person_id, :duplicate_recipient) do
      {:ok, recipients}
    end
  end

  defp normalize_recipients(_recipients), do: {:error, :invalid_recipients}

  defp normalize_each_recipient(recipients) do
    Enum.reduce_while(recipients, {:ok, []}, fn recipient, {:ok, normalized_recipients} ->
      case normalize_recipient(recipient) do
        {:ok, normalized_recipient} ->
          {:cont, {:ok, [normalized_recipient | normalized_recipients]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized_recipients} -> {:ok, Enum.reverse(normalized_recipients)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_recipient(%Recipient{} = recipient) do
    with :ok <- validate_uuid(recipient.delivery_id, :invalid_delivery_id),
         :ok <- validate_uuid(recipient.person_id, :invalid_recipient_id),
         {:ok, name} <- normalize_text(recipient.name, :invalid_recipient_name),
         {:ok, email} <- normalize_email(recipient.email) do
      {:ok, %Recipient{recipient | name: name, email: email}}
    end
  end

  defp normalize_recipient(_recipient), do: {:error, :invalid_recipient}

  defp normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if valid_email?(email) do
      {:ok, email}
    else
      {:error, :invalid_recipient_email}
    end
  end

  defp normalize_email(_email), do: {:error, :invalid_recipient_email}

  defp valid_email?(email) do
    case String.split(email, "@") do
      [local, domain] -> local != "" and domain != "" and String.contains?(domain, ".")
      _other -> false
    end
  end

  defp validate_unique(recipients, field_fun, error) do
    values = Enum.map(recipients, field_fun)

    if Enum.uniq(values) == values do
      :ok
    else
      {:error, error}
    end
  end

  defp validate_sender_recipient(sender_id, recipients) do
    if Enum.any?(recipients, &(&1.person_id == sender_id)) do
      :ok
    else
      {:error, :sender_not_in_recipients}
    end
  end
end
