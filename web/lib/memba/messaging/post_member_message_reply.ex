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
  alias Memba.Messaging.Message
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.Recipient
  alias Memba.Messaging.ReplyCommand

  def prepare(attrs) when is_map(attrs) do
    AuthorizationCheckpoint.run(
      fn ->
        with {:ok, command} <- ReplyCommand.prepare(attrs, &recipients/4),
             :ok <- authorize_sender(command) do
          {:ok, command}
        end
      end,
      projections: [ConversationFollowProjector]
    )
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
