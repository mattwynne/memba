defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  The dispatcher subscribes to committed read-model changes and treats new
  `EmailDelivery` projection records as a nudge to look for pending delivery
  work. Later iteration tasks add claiming, provider delivery, and retry
  behaviour.
  """

  use GenServer

  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.ReadModelChanges

  @name __MODULE__

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, @name)

    if name do
      GenServer.start_link(__MODULE__, opts, name: name)
    else
      GenServer.start_link(__MODULE__, opts)
    end
  end

  @impl GenServer
  def init(opts) do
    :ok = Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())

    state = %{
      dispatch_observer: Keyword.get(opts, :dispatch_observer)
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(
        {:read_model_changed,
         %{
           projector: EmailDeliveryProjector,
           source_event: %EmailDeliveryCreated{}
         } = payload},
        state
      ) do
    send(self(), {:dispatch_pending_email_deliveries, payload})

    {:noreply, state}
  end

  def handle_info({:read_model_changed, _payload}, state) do
    {:noreply, state}
  end

  def handle_info({:dispatch_pending_email_deliveries, payload}, state) do
    notify_dispatch_observer(state, payload)

    {:noreply, state}
  end

  defp notify_dispatch_observer(%{dispatch_observer: nil}, _payload), do: :ok

  defp notify_dispatch_observer(%{dispatch_observer: observer}, payload) when is_pid(observer) do
    send(
      observer,
      {:email_delivery_dispatch_requested, Map.put(payload, :source, :read_model_change)}
    )

    :ok
  end
end
