defmodule Memba.Messaging.Policies.EstablishMessageSenderFollow do
  @moduledoc """
  Establishes sender follows only after a message or reply has been accepted.

  The Messaging-owned member cutoff aggregate is checked before dispatching the
  conversation follow, including for conversations first created after a
  custom-group cleanup completed.
  """

  use Commanded.Event.Handler,
    application: Memba.Messaging.App,
    name: "Memba.Messaging.Policies.EstablishMessageSenderFollow",
    consistency: :strong,
    start_from: :origin

  alias Memba.Messaging
  alias Memba.Messaging.Events.MessageSent

  @impl Commanded.Event.Handler
  def handle(%MessageSent{} = event, _metadata) do
    if MessageSent.sender_follow_requested?(event) do
      Messaging.establish_message_sender_follow(event)
    else
      :ok
    end
  end

  def handle(_event, _metadata), do: :ok
end
