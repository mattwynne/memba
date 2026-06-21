defmodule Memba.Messaging.Projectors.Message do
  @moduledoc """
  Projects message events into the Messaging message read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.Message",
    consistency: :strong

  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.Message, as: MessageProjection

  project(%MessageSent{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_message, %MessageProjection{
      message_id: event.message_id,
      club_id: event.club_id,
      sender_id: event.sender_id,
      conversation_id:
        event.conversation_id || ConversationReference.root_conversation_id(event.message_id),
      reply_to_message_id: event.reply_to_message_id,
      subject: event.subject,
      body: event.body
    })
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
