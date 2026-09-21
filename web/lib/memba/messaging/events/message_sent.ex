defmodule Memba.Messaging.Events.MessageSent do
  @moduledoc """
  Event raised when a club message has been accepted for sending.

  `sender_follows_conversation` records whether this send establishes a follower
  relationship for the sender. Historic events predate the field and are
  interpreted as following so replay preserves their original projection.

  `sender_membership_generation` causally orders generated sender follows
  against group-membership cleanup. Historic facts without it use generation
  zero. New reply sends establish the authoritative root-stream follow with a
  `ConversationFollowed` fact before this event is dispatched.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :club_id, :sender_id, :subject, :body]
  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body,
    :sender_membership_generation,
    sender_follows_conversation: true
  ]

  def sender_follows_conversation?(%__MODULE__{sender_follows_conversation: false}), do: false
  def sender_follows_conversation?(%__MODULE__{}), do: true
end
