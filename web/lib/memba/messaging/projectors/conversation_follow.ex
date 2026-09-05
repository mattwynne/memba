defmodule Memba.Messaging.Projectors.ConversationFollow do
  @moduledoc """
  Projects conversation follow events and auto-follow message events into the follow read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.ConversationFollow",
    consistency: :strong

  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection

  project(%MessageSent{} = event, fn multi ->
    if MessageSent.sender_follows_conversation?(event) do
      conversation_id =
        event.conversation_id || ConversationReference.root_conversation_id(event.message_id)

      upsert_follow(multi, event.club_id, conversation_id, event.sender_id, true)
    else
      multi
    end
  end)

  project(%ConversationFollowed{} = event, fn multi ->
    upsert_follow(multi, event.club_id, event.conversation_id, event.member_id, true)
  end)

  project(%ConversationUnfollowed{} = event, fn multi ->
    upsert_follow(multi, event.club_id, event.conversation_id, event.member_id, false)
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end

  defp upsert_follow(multi, club_id, conversation_id, member_id, following) do
    now = DateTime.utc_now(:microsecond)
    follow_id = ConversationFollowers.follow_id(conversation_id, member_id)

    Ecto.Multi.insert(
      multi,
      {:messaging_conversation_follow, follow_id},
      %ConversationFollowProjection{
        follow_id: follow_id,
        club_id: club_id,
        conversation_id: conversation_id,
        member_id: member_id,
        following: following,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: club_id,
          conversation_id: conversation_id,
          member_id: member_id,
          following: following,
          updated_at: now
        ]
      ],
      conflict_target: :follow_id
    )
  end
end
