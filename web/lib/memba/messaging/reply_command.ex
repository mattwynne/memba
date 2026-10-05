defmodule Memba.Messaging.ReplyCommand do
  @moduledoc """
  Construct a reply against the projected root and authoritative conversation
  audience. The caller supplies its recipient policy; authorization and dispatch
  belong to the surrounding use case.
  """

  alias Memba.ID
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.ConversationAudience
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def prepare(attrs, recipients) when is_map(attrs) and is_function(recipients, 4) do
    with {:ok, message_id} <- required(attrs, :message_id),
         {:ok, conversation_id} <- required(attrs, :conversation_id),
         {:ok, sender_id} <- required(attrs, :sender_id),
         {:ok, body} <- required(attrs, :body),
         {:ok, root} <- root(conversation_id),
         {:ok, group_id} <- authoritative_group(conversation_id, root.club_id) do
      {:ok,
       %PostMessageReply{
         operation_intent: Map.get(attrs, "operation_intent"),
         message_id: message_id,
         club_id: root.club_id,
         sender_id: sender_id,
         conversation_id: conversation_id,
         reply_to_message_id: ConversationReference.reply_to_message_id(conversation_id),
         subject: root.subject,
         body: body,
         recipients: recipients.(root.club_id, conversation_id, group_id, sender_id)
       }}
    end
  end

  defp required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _ -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp root(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      case Repo.get(MessageProjection, conversation_id) do
        %MessageProjection{} = message -> {:ok, message}
        nil -> {:error, :conversation_not_found}
      end
    else
      :error -> {:error, :invalid_conversation_id}
    end
  end

  defp authoritative_group(conversation_id, club_id) do
    case ConversationAudience.resolve(conversation_id) do
      {:ok, %{club_id: ^club_id, group_id: group_id}} -> {:ok, group_id}
      _missing_ambiguous_or_foreign -> {:error, :not_current_member}
    end
  end
end
