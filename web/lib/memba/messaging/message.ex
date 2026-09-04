defmodule Memba.Messaging.Message do
  @moduledoc """
  Message aggregate for the Messaging bounded context.

  One aggregate represents one conversation entry: either the root club message
  or a reply message. Each aggregate owns the per-email delivery records created
  for that message.

  Conversations are modeled without a separate conversation aggregate. The root
  message records `conversation_id == message_id`; replies use their own
  `message_id` and point at the root with `conversation_id`, keeping reply
  delivery receipts in the reply message's stream while leaving a clean key for
  conversation projections and future follower rules.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.EmailDeliveryBounced
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelayed
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Events.EmailDeliverySpamComplaint
  alias Memba.Messaging.Recipient

  @behaviour Aggregate

  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body,
    delivery_statuses: %{},
    email_delivery_ids: MapSet.new(),
    recipient_ids: MapSet.new()
  ]

  @impl Aggregate
  def execute(%__MODULE__{message_id: nil}, %SendMessage{} = command) do
    with :ok <- validate_id(:message, command.message_id, :invalid_message_id),
         {:ok, conversation_id, reply_to_message_id} <-
           normalize_conversation_reference(
             command.message_id,
             command.conversation_id,
             command.reply_to_message_id
           ) do
      message_events(command, conversation_id, reply_to_message_id)
    end
  end

  def execute(%__MODULE__{}, %SendMessage{}), do: {:error, :already_sent}

  def execute(%__MODULE__{message_id: nil}, %PostMessageReply{} = command) do
    with :ok <- validate_id(:message, command.message_id, :invalid_message_id),
         {:ok, conversation_id, reply_to_message_id} <-
           normalize_required_reply_reference(
             command.message_id,
             command.conversation_id,
             command.reply_to_message_id
           ) do
      message_events(command, conversation_id, reply_to_message_id)
    end
  end

  def execute(%__MODULE__{}, %PostMessageReply{}), do: {:error, :already_sent}

  def execute(%__MODULE__{} = message, %ReportEmailDeliveryDelivered{} = command) do
    report_status(message, command, :delivered, EmailDeliveryDelivered)
  end

  def execute(%__MODULE__{} = message, %ReportEmailDeliveryDelayed{} = command) do
    report_status_with_reason(message, command, :delayed, EmailDeliveryDelayed)
  end

  def execute(%__MODULE__{} = message, %ReportEmailDeliveryBounced{} = command) do
    report_status_with_reason(message, command, :bounced, EmailDeliveryBounced)
  end

  def execute(%__MODULE__{} = message, %ReportEmailDeliverySpamComplaint{} = command) do
    report_status_with_reason(message, command, :spam_complaint, EmailDeliverySpamComplaint)
  end

  @impl Aggregate
  def apply(%__MODULE__{} = message, %MessageSent{} = event) do
    %__MODULE__{
      message
      | message_id: event.message_id,
        club_id: event.club_id,
        sender_id: event.sender_id,
        conversation_id: event.conversation_id || event.message_id,
        reply_to_message_id: event.reply_to_message_id,
        subject: event.subject,
        body: event.body
    }
  end

  def apply(%__MODULE__{} = message, %EmailDeliveryCreated{} = event) do
    %__MODULE__{
      message
      | email_delivery_ids: MapSet.put(message.email_delivery_ids, event.delivery_id),
        delivery_statuses:
          Map.put(message.delivery_statuses, event.delivery_id, %{
            status: :sent,
            reason: nil
          }),
        recipient_ids: MapSet.put(message.recipient_ids, event.recipient_id)
    }
  end

  def apply(%__MODULE__{} = message, %EmailDeliveryDelivered{} = event) do
    put_delivery_status(message, event.delivery_id, :delivered)
  end

  def apply(%__MODULE__{} = message, %EmailDeliveryDelayed{} = event) do
    put_delivery_status(message, event.delivery_id, :delayed, event.reason)
  end

  def apply(%__MODULE__{} = message, %EmailDeliveryBounced{} = event) do
    put_delivery_status(message, event.delivery_id, :bounced, event.reason)
  end

  def apply(%__MODULE__{} = message, %EmailDeliverySpamComplaint{} = event) do
    put_delivery_status(message, event.delivery_id, :spam_complaint, event.reason)
  end

  def apply(%__MODULE__{} = message, %ConversationFollowed{}), do: message
  def apply(%__MODULE__{} = message, %ConversationUnfollowed{}), do: message
  def apply(%__MODULE__{} = message, %ConversationAccessGrantedToGroup{}), do: message

  # Deprecated replay shim only: EmailDeliveryOpened is no longer a tracked
  # product status. Keep this no-op so historic events can rehydrate aggregates
  # without changing current delivery state. Do not extend.
  def apply(%__MODULE__{} = message, %EmailDeliveryOpened{}) do
    message
  end

  defp report_status(%__MODULE__{} = message, command, next_status, event_module) do
    with :ok <- validate_delivery_command(message, command),
         :ok <- validate_status_transition(message, command.delivery_id, next_status, nil) do
      struct(event_module, message_id: command.message_id, delivery_id: command.delivery_id)
    end
  end

  defp report_status_with_reason(%__MODULE__{} = message, command, next_status, event_module) do
    with :ok <- validate_delivery_command(message, command),
         {:ok, reason} <- normalize_text(command.reason, :invalid_reason),
         :ok <- validate_status_transition(message, command.delivery_id, next_status, reason) do
      struct(event_module,
        message_id: command.message_id,
        delivery_id: command.delivery_id,
        reason: reason
      )
    end
  end

  defp validate_delivery_command(%__MODULE__{} = message, command) do
    with :ok <- validate_id(:message, command.message_id, :invalid_message_id),
         :ok <- validate_id(:delivery, command.delivery_id, :invalid_delivery_id),
         :ok <- validate_message_sent(message),
         :ok <- validate_message_identity(message, command.message_id) do
      validate_known_delivery(message, command.delivery_id)
    end
  end

  defp validate_message_sent(%__MODULE__{message_id: nil}), do: {:error, :message_not_sent}
  defp validate_message_sent(%__MODULE__{}), do: :ok

  defp validate_message_identity(%__MODULE__{message_id: message_id}, message_id), do: :ok
  defp validate_message_identity(%__MODULE__{}, _message_id), do: {:error, :message_id_mismatch}

  defp message_events(command, conversation_id, reply_to_message_id) do
    with :ok <- validate_id(:message, command.message_id, :invalid_message_id),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:person, command.sender_id, :invalid_sender_id),
         {:ok, audience_group_id} <-
           normalize_command_audience_group_id(command, conversation_id, reply_to_message_id),
         {:ok, subject} <- normalize_text(command.subject, :invalid_subject),
         {:ok, body} <- normalize_text(command.body, :invalid_body),
         {:ok, recipients} <- normalize_command_recipients(command) do
      message_sent = %MessageSent{
        message_id: command.message_id,
        club_id: command.club_id,
        sender_id: command.sender_id,
        conversation_id: conversation_id,
        reply_to_message_id: reply_to_message_id,
        subject: subject,
        body: body
      }

      [message_sent] ++
        conversation_access_events(
          command,
          conversation_id,
          reply_to_message_id,
          audience_group_id
        ) ++
        Enum.map(recipients, &email_delivery_created(command.message_id, &1))
    end
  end

  defp normalize_conversation_reference(message_id, conversation_id, reply_to_message_id) do
    conversation_id = conversation_id || ConversationReference.root_conversation_id(message_id)

    with :ok <- validate_id(:message, conversation_id, :invalid_conversation_id),
         :ok <- validate_optional_id(:message, reply_to_message_id, :invalid_reply_to_message_id),
         :ok <- validate_conversation_shape(message_id, conversation_id, reply_to_message_id) do
      {:ok, conversation_id, reply_to_message_id}
    end
  end

  defp normalize_required_reply_reference(message_id, conversation_id, reply_to_message_id) do
    with :ok <- validate_id(:message, conversation_id, :invalid_conversation_id),
         :ok <- validate_id(:message, reply_to_message_id, :invalid_reply_to_message_id),
         :ok <- validate_conversation_shape(message_id, conversation_id, reply_to_message_id) do
      {:ok, conversation_id, reply_to_message_id}
    end
  end

  defp validate_optional_id(_type, nil, _error), do: :ok

  defp validate_optional_id(type, value, error) do
    validate_id(type, value, error)
  end

  defp validate_conversation_shape(message_id, message_id, nil), do: :ok

  defp validate_conversation_shape(message_id, message_id, _reply_to_message_id),
    do: {:error, :invalid_conversation_reference}

  defp validate_conversation_shape(message_id, _conversation_id, message_id),
    do: {:error, :invalid_conversation_reference}

  defp validate_conversation_shape(_message_id, _conversation_id, nil),
    do: {:error, :reply_to_message_required}

  defp validate_conversation_shape(_message_id, _conversation_id, _reply_to_message_id),
    do: :ok

  defp validate_known_delivery(%__MODULE__{} = message, delivery_id) do
    if MapSet.member?(message.email_delivery_ids, delivery_id) do
      :ok
    else
      {:error, :unknown_delivery}
    end
  end

  defp validate_status_transition(%__MODULE__{} = message, delivery_id, next_status, reason) do
    %{status: current_status, reason: current_reason} =
      Map.fetch!(message.delivery_statuses, delivery_id)

    cond do
      current_status == next_status and current_reason == reason ->
        []

      current_status == next_status ->
        {:error, :conflicting_delivery_status_reason}

      valid_transition?(current_status, next_status) ->
        :ok

      true ->
        {:error, :invalid_delivery_status_transition}
    end
  end

  defp valid_transition?(:sent, :delivered), do: true
  defp valid_transition?(:sent, :delayed), do: true
  defp valid_transition?(:sent, :bounced), do: true
  defp valid_transition?(:sent, :spam_complaint), do: true
  defp valid_transition?(:delayed, :delivered), do: true
  defp valid_transition?(:delayed, :bounced), do: true
  defp valid_transition?(:delayed, :spam_complaint), do: true
  defp valid_transition?(_current_status, _next_status), do: false

  defp put_delivery_status(%__MODULE__{} = message, delivery_id, status, reason \\ nil) do
    %__MODULE__{
      message
      | delivery_statuses:
          Map.put(message.delivery_statuses, delivery_id, %{
            status: status,
            reason: reason
          })
    }
  end

  defp email_delivery_created(message_id, %Recipient{} = recipient) do
    %EmailDeliveryCreated{
      message_id: message_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_email: recipient.email
    }
  end

  defp conversation_access_events(
         %SendMessage{message_id: message_id} = command,
         conversation_id,
         nil,
         audience_group_id
       )
       when message_id == conversation_id and not is_nil(audience_group_id) do
    [
      %ConversationAccessGrantedToGroup{
        conversation_id: conversation_id,
        club_id: command.club_id,
        group_id: audience_group_id,
        access_level: "write"
      }
    ]
  end

  defp conversation_access_events(
         _command,
         _conversation_id,
         _reply_to_message_id,
         _audience_group_id
       ),
       do: []

  defp normalize_command_audience_group_id(
         %SendMessage{message_id: message_id, audience_group_id: audience_group_id},
         conversation_id,
         nil
       )
       when message_id == conversation_id do
    case audience_group_id do
      nil ->
        {:ok, nil}

      audience_group_id ->
        with :ok <- validate_id(:group, audience_group_id, :invalid_audience_group_id) do
          {:ok, audience_group_id}
        end
    end
  end

  defp normalize_command_audience_group_id(
         %SendMessage{},
         _conversation_id,
         _reply_to_message_id
       ),
       do: {:ok, nil}

  defp normalize_command_audience_group_id(
         %PostMessageReply{},
         _conversation_id,
         _reply_to_message_id
       ),
       do: {:ok, nil}

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
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

  defp normalize_command_recipients(%SendMessage{} = command) do
    with {:ok, recipients} <- normalize_recipients(command.recipients, allow_empty?: false),
         :ok <- validate_sender_recipient(command.sender_id, recipients) do
      {:ok, recipients}
    end
  end

  defp normalize_command_recipients(%PostMessageReply{} = command) do
    with {:ok, recipients} <- normalize_recipients(command.recipients, allow_empty?: true),
         :ok <- validate_reply_author_excluded(command.sender_id, recipients) do
      {:ok, recipients}
    end
  end

  defp normalize_recipients(recipients, opts) when is_list(recipients) do
    allow_empty? = Keyword.fetch!(opts, :allow_empty?)

    cond do
      recipients == [] and allow_empty? ->
        {:ok, []}

      recipients == [] ->
        {:error, :invalid_recipients}

      true ->
        normalize_non_empty_recipients(recipients)
    end
  end

  defp normalize_recipients(_recipients, _opts), do: {:error, :invalid_recipients}

  defp normalize_non_empty_recipients(recipients) do
    with {:ok, recipients} <- normalize_each_recipient(recipients),
         :ok <- validate_unique(recipients, & &1.delivery_id, :duplicate_delivery),
         :ok <- validate_unique(recipients, & &1.person_id, :duplicate_recipient) do
      {:ok, recipients}
    end
  end

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
    with :ok <- validate_id(:delivery, recipient.delivery_id, :invalid_delivery_id),
         :ok <- validate_id(:person, recipient.person_id, :invalid_recipient_id),
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

  defp validate_reply_author_excluded(sender_id, recipients) do
    if Enum.any?(recipients, &(&1.person_id == sender_id)) do
      {:error, :reply_author_in_recipients}
    else
      :ok
    end
  end
end
