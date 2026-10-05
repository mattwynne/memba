defmodule Memba.Messaging.PostMemberMessageReply do
  @moduledoc """
  Prepare an in-app reply at a stable authorization checkpoint. This use case
  resolves the root, authoritative audience and current followers, but never
  dispatches the resulting command.
  """

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.Message
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Recipient
  alias Memba.Repo

  def prepare(attrs) when is_map(attrs) do
    AuthorizationCheckpoint.run(
      fn ->
        with {:ok, command} <- build_command(attrs),
             :ok <- authorize_sender(command) do
          {:ok, command}
        end
      end,
      projections: [ConversationFollowProjector]
    )
  end

  defp build_command(attrs) do
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
         recipients: recipients(root.club_id, conversation_id, group_id, sender_id)
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
    with %Message{club_id: ^club_id, group_access: access} <-
           App.aggregate_state(Message, conversation_id),
         {:ok, group_id, _level} <- canonical_group(access) do
      {:ok, group_id}
    else
      _ -> {:error, :not_current_member}
    end
  end

  defp canonical_group(access) when map_size(access) == 1 do
    [{group_id, level}] = Map.to_list(access)
    {:ok, group_id, level}
  end

  defp canonical_group(_), do: {:error, :not_current_member}

  defp authorize_sender(%PostMessageReply{} = command) do
    with {:ok, conversation_id} <- ID.cast(:message, command.conversation_id),
         {:ok, club_id} <- ID.cast(:club, command.club_id),
         {:ok, sender_id} <- ID.cast(:person, command.sender_id),
         %Message{message_id: ^conversation_id, club_id: ^club_id, group_access: access} <-
           App.aggregate_state(Message, conversation_id),
         {:ok, group_id, "write"} <- canonical_group(access),
         true <- Membership.active_member_of_group_authoritatively?(club_id, group_id, sender_id) do
      :ok
    else
      _ -> {:error, :not_current_member}
    end
  end

  defp recipients(club_id, conversation_id, group_id, sender_id) do
    followers =
      conversation_id
      |> Messaging.list_conversation_followers()
      |> Enum.filter(&(&1.club_id == club_id))
      |> Enum.map(& &1.member_id)
      |> MapSet.new()

    club_id
    |> Membership.list_active_members_of_group_authoritatively(group_id)
    |> Enum.filter(&MapSet.member?(followers, &1.id))
    |> Enum.reject(&(&1.id == sender_id))
    |> Enum.map(fn %{id: person_id, name: name, email: email} ->
      %Recipient{
        delivery_id: ID.generate(:delivery),
        person_id: person_id,
        name: name,
        email: email
      }
    end)
  end
end
