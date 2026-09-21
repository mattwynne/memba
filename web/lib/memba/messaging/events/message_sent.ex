defmodule Memba.Messaging.Events.MessageSent do
  @moduledoc """
  Event raised when a club message has been accepted for sending.

  `sender_follows_conversation` records whether this send establishes a follower
  relationship for the sender. Historic events predate the field and are
  interpreted as following so replay preserves their original projection.

  `sender_membership_generation` causally orders generated sender follows
  against group-membership cleanup. Historic facts without it use generation
  zero.

  New sends set `sender_follow_requested` when acceptance should establish the
  sender follow. A strong Messaging policy handles that request only after this
  fact is committed and checks durable member/group cleanup cutoffs first.
  Historic facts predate the field and retain their original direct
  `sender_follows_conversation` replay behavior.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :club_id, :sender_id, :subject, :body]
  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :audience_group_id,
    :subject,
    :body,
    :sender_membership_generation,
    sender_follow_requested: false,
    sender_follows_conversation: true
  ]

  def sender_follows_conversation?(%__MODULE__{sender_follows_conversation: false}), do: false
  def sender_follows_conversation?(%__MODULE__{}), do: true

  def sender_follow_requested?(%__MODULE__{sender_follow_requested: true}), do: true
  def sender_follow_requested?(%__MODULE__{}), do: false
end
