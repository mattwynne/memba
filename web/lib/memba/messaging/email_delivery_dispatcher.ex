defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  The dispatcher subscribes to committed read-model changes and treats new
  `EmailDelivery` projection records as a nudge to look for pending delivery
  work. Later iteration tasks add claiming, provider delivery, and retry
  behaviour.
  """

  use GenServer

  import Ecto.Query

  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.ReadModelChanges
  alias Memba.Repo

  @name __MODULE__
  @pending_status "pending"
  @dispatching_status "dispatching"

  @doc """
  Atomically claim one pending email delivery for provider dispatch.

  A delivery is claimable only while its status is `pending`. The conditional
  update makes concurrent callers race on the database row: exactly one caller
  can move a given delivery to `dispatching`; later callers get `:not_claimed`.
  """
  def claim_pending_delivery(delivery_id) when is_binary(delivery_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    claim_query =
      from delivery in EmailDeliveryProjection,
        where: delivery.delivery_id == ^delivery_id and delivery.status == ^@pending_status

    case Repo.update_all(claim_query,
           set: [
             status: @dispatching_status,
             last_dispatch_attempted_at: now,
             updated_at: now
           ]
         ) do
      {1, nil} -> {:ok, Repo.get!(EmailDeliveryProjection, delivery_id)}
      {0, nil} -> :not_claimed
    end
  end

  def claim_pending_delivery(_delivery_id), do: :not_claimed

  @doc """
  Claim all currently pending email deliveries.

  This is a best-effort nudge handler, not a periodic sweep. It first reads the
  pending delivery IDs, then claims each ID with `claim_pending_delivery/1` so
  concurrent dispatcher invocations cannot claim the same delivery twice.
  """
  def claim_pending_email_deliveries do
    EmailDeliveryProjection
    |> where([delivery], delivery.status == ^@pending_status)
    |> order_by([delivery], asc: delivery.inserted_at, asc: delivery.delivery_id)
    |> select([delivery], delivery.delivery_id)
    |> Repo.all()
    |> Enum.flat_map(fn delivery_id ->
      case claim_pending_delivery(delivery_id) do
        {:ok, %EmailDeliveryProjection{} = delivery} -> [delivery]
        :not_claimed -> []
      end
    end)
  end

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
      dispatch_enabled: Keyword.get(opts, :dispatch_enabled, true),
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
    claimed_deliveries = claim_pending_email_deliveries(state)

    notify_dispatch_observer(state, payload, claimed_deliveries)

    {:noreply, state}
  end

  defp claim_pending_email_deliveries(%{dispatch_enabled: true}),
    do: claim_pending_email_deliveries()

  defp claim_pending_email_deliveries(%{dispatch_enabled: false}), do: []

  defp notify_dispatch_observer(%{dispatch_observer: nil}, _payload, _claimed_deliveries), do: :ok

  defp notify_dispatch_observer(%{dispatch_observer: observer}, payload, claimed_deliveries)
       when is_pid(observer) do
    send(
      observer,
      {:email_delivery_dispatch_requested,
       payload
       |> Map.put(:source, :read_model_change)
       |> Map.put(:claimed_delivery_ids, Enum.map(claimed_deliveries, & &1.delivery_id))}
    )

    :ok
  end
end
