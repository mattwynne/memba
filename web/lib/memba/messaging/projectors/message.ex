defmodule Memba.Messaging.Projectors.Message do
  @moduledoc """
  Projects message events into the Messaging message read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.Message",
    consistency: :strong

  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.Message, as: MessageProjection

  project(%MessageSent{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_message, %MessageProjection{
      message_id: event.message_id,
      club_id: event.club_id,
      sender_id: event.sender_id,
      subject: event.subject,
      body: event.body
    })
  end)
end
