defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  The dispatcher subscribes to committed read-model changes and treats new
  `EmailDelivery` projection records as a nudge to look for pending delivery
  work. It also owns the provider handoff request-building boundary and
  persisted dispatch outcomes so command application services do not call email
  providers directly. Later iteration tasks add retry behaviour.
  """

  use GenServer

  import Ecto.Query

  alias Memba.Membership
  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.ReadModelChanges
  alias Memba.Repo

  @name __MODULE__
  @pending_status "pending"
  @dispatching_status "dispatching"
  @sent_status "sent"
  @failed_status "failed"

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

  @doc """
  Claim all currently pending email deliveries and dispatch each claimed record.

  Provider acceptance marks a claimed delivery as `sent`. Provider/request
  errors mark the individual delivery as `failed`, increment the persisted
  attempt count, and store the latest error diagnostics. Each claimed delivery
  is handled independently so one failure does not prevent later claimed
  deliveries from being attempted.
  """
  def dispatch_pending_email_deliveries do
    claim_pending_email_deliveries()
    |> Enum.map(&dispatch_claimed_delivery/1)
  end

  @doc """
  Hand one already-claimed delivery to the provider and persist the outcome.
  """
  def dispatch_claimed_delivery(%EmailDeliveryProjection{} = delivery) do
    case deliver_to_provider(delivery) do
      :ok -> mark_delivery_sent(delivery)
      {:error, reason} -> mark_delivery_failed(delivery, reason)
    end
  end

  @doc """
  Hand email delivery work to the configured provider.

  For normal asynchronous dispatch, the dispatcher builds provider requests from
  committed read-model state: the `EmailDelivery` projection supplies
  per-recipient delivery data and the `Message` projection supplies message,
  club, and sender IDs. Membership's public query API enriches the request with
  sender and club display context.
  """
  def deliver_to_provider(work)

  def deliver_to_provider(%EmailDeliveryProjection{} = delivery) do
    with {:ok, request} <- email_delivery_request(delivery) do
      EmailDeliveryProvider.deliver(request)
    end
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
    claimed_deliveries = dispatch_pending_email_deliveries(state)

    notify_dispatch_observer(state, payload, claimed_deliveries)

    {:noreply, state}
  end

  defp dispatch_pending_email_deliveries(%{dispatch_enabled: true}),
    do: dispatch_pending_email_deliveries()

  defp dispatch_pending_email_deliveries(%{dispatch_enabled: false}), do: []

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

  defp mark_delivery_sent(%EmailDeliveryProjection{} = delivery) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    delivery
    |> outcome_query()
    |> Repo.update_all(
      set: [
        status: @sent_status,
        latest_error: nil,
        latest_detail: nil,
        sent_at: now,
        failed_at: nil,
        updated_at: now
      ]
    )

    Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
  end

  defp mark_delivery_failed(%EmailDeliveryProjection{} = delivery, reason) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    {latest_error, latest_detail} = delivery_error_diagnostics(reason)

    delivery
    |> outcome_query()
    |> Repo.update_all(
      set: [
        status: @failed_status,
        latest_error: latest_error,
        latest_detail: latest_detail,
        failed_at: now,
        updated_at: now
      ],
      inc: [attempt_count: 1]
    )

    Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
  end

  defp outcome_query(%EmailDeliveryProjection{} = delivery) do
    from projected_delivery in EmailDeliveryProjection,
      where:
        projected_delivery.delivery_id == ^delivery.delivery_id and
          projected_delivery.status == ^@dispatching_status
  end

  defp delivery_error_diagnostics(reason) do
    {delivery_error_name(reason), inspect(reason, limit: 50, printable_limit: 2_000)}
  end

  defp delivery_error_name(reason) when is_atom(reason), do: Atom.to_string(reason)

  defp delivery_error_name(reason) when is_binary(reason), do: reason

  defp delivery_error_name(reason) when is_tuple(reason) and tuple_size(reason) > 0 do
    reason
    |> elem(0)
    |> delivery_error_name()
  end

  defp delivery_error_name(reason), do: inspect(reason, limit: 10, printable_limit: 200)

  defp email_delivery_request(%EmailDeliveryProjection{} = delivery) do
    with %MessageProjection{} = message <- Repo.get(MessageProjection, delivery.message_id),
         {:ok, channel} <- request_channel(delivery.channel),
         {:ok, sender_name, sender_address} <- sender_context(message.sender_id) do
      club = Membership.get_club(message.club_id)

      {:ok,
       %EmailDeliveryRequest{
         message_id: message.message_id,
         club_id: message.club_id,
         delivery_id: delivery.delivery_id,
         recipient_id: delivery.recipient_id,
         recipient_name: delivery.recipient_name,
         recipient_address: delivery.recipient_address,
         club_name: club_name(club),
         club_slug: club_slug(club),
         sender_name: sender_name,
         sender_address: sender_address,
         channel: channel,
         subject: message.subject,
         body: message.body
       }}
    else
      nil -> {:error, {:missing_message_projection, delivery.message_id}}
      {:error, _reason} = error -> error
    end
  end

  defp request_channel("email"), do: {:ok, :email}
  defp request_channel(channel), do: {:error, {:unsupported_delivery_channel, channel}}

  defp sender_context(sender_id) do
    with %{name: sender_name} <- Membership.get_person(sender_id),
         sender_address when is_binary(sender_address) <-
           Membership.get_person_primary_email(sender_id) do
      {:ok, sender_name, sender_address}
    else
      nil -> {:error, {:missing_sender_context, sender_id}}
    end
  end

  defp club_name(%{name: name}), do: name
  defp club_name(_club), do: nil

  defp club_slug(%{slug: slug}), do: slug
  defp club_slug(_club), do: nil
end
