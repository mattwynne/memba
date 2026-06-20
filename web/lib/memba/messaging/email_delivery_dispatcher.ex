defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  The dispatcher subscribes to committed read-model changes and treats new
  `EmailDelivery` projection records as a nudge to look for pending delivery
  work. It also owns the provider handoff request-building boundary so command
  application services do not call email providers directly. Later iteration
  tasks add persisted success/failure outcomes and retry behaviour.
  """

  use GenServer

  import Ecto.Query

  alias Memba.Membership
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Recipient
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

  @doc """
  Hand email delivery work to the configured provider.

  For normal asynchronous dispatch, the dispatcher builds provider requests from
  committed read-model state: the `EmailDelivery` projection supplies
  per-recipient delivery data and the `Message` projection supplies message,
  club, and sender IDs. Membership's public query API enriches the request with
  sender and club display context.

  A temporary `SendMessage` clause preserves the existing synchronous caller
  while keeping provider request-building and adapter calls out of
  `Memba.Messaging`. A later iteration task removes that synchronous caller once
  dispatcher success/failure persistence is in place.
  """
  def deliver_to_provider(work)

  def deliver_to_provider(%EmailDeliveryProjection{} = delivery) do
    with {:ok, request} <- email_delivery_request(delivery) do
      EmailDeliveryProvider.deliver(request)
    end
  end

  def deliver_to_provider(%SendMessage{} = command) do
    club = Membership.get_club(command.club_id)
    sender = Membership.get_person(command.sender_id)
    sender_address = Membership.get_person_primary_email(command.sender_id)

    Enum.reduce_while(command.recipients, :ok, fn %Recipient{} = recipient, :ok ->
      request = email_delivery_request(command, recipient, club, sender, sender_address)

      case EmailDeliveryProvider.deliver(request) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
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

  defp email_delivery_request(
         %SendMessage{} = command,
         %Recipient{} = recipient,
         club,
         sender,
         sender_address
       ) do
    %EmailDeliveryRequest{
      message_id: command.message_id,
      club_id: command.club_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_address: recipient.email,
      club_name: club_name(club),
      club_slug: club_slug(club),
      sender_name: sender.name,
      sender_address: sender_address,
      channel: :email,
      subject: command.subject,
      body: command.body
    }
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
