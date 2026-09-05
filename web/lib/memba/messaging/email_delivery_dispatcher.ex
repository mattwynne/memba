defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  The dispatcher subscribes to committed read-model changes and treats new
  `EmailDelivery` projection records as a nudge to look for pending delivery
  work. It also owns the provider handoff request-building boundary and
  persisted dispatch outcomes so command application services do not call email
  providers directly. Failed deliveries can be retried through the explicit
  manual retry API; the dispatcher does not perform automatic retry sweeps.
  """

  use GenServer

  import Ecto.Query
  require Logger

  alias Memba.Membership
  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.EmailDeliveryStatus
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projections.ConversationGroupAccess
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.ReadModelChanges
  alias Memba.Repo
  alias MembaWeb.ClubSite

  @name __MODULE__
  @pending_status EmailDeliveryStatus.pending()
  @dispatching_status EmailDeliveryStatus.dispatching()
  @sent_status EmailDeliveryStatus.sent()
  @failed_status EmailDeliveryStatus.failed()

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
      {1, nil} ->
        delivery = Repo.get!(EmailDeliveryProjection, delivery_id)
        log_dispatch_claimed(delivery)
        {:ok, delivery}

      {0, nil} ->
        log_dispatch_claim_skipped(delivery_id)
        :not_claimed
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
      :ok ->
        log_provider_success(delivery)
        mark_delivery_sent(delivery)

      {:error, reason} ->
        log_provider_error(delivery, reason)
        mark_delivery_failed(delivery, reason)
    end
  end

  @doc """
  Retry one failed email delivery by handing it to the configured provider.

  This is the manual/internal retry boundary. It atomically moves a failed
  delivery to `dispatching` before calling the provider so concurrent retry
  attempts cannot both hand the same failed delivery to the provider. Provider
  failure is persisted on the delivery and returned as a successful API result
  containing the updated failed read model; lookup/retryability problems return
  `{:error, reason}`.
  """
  def retry_failed_delivery(delivery_id) when is_binary(delivery_id) do
    with {:ok, %EmailDeliveryProjection{} = delivery} <- claim_failed_delivery(delivery_id) do
      {:ok, dispatch_claimed_retry_delivery(delivery)}
    end
  end

  def retry_failed_delivery(_delivery_id), do: {:error, :invalid_delivery_id}

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
      request
      |> deliver_request_to_provider(delivery)
      |> normalize_provider_result()
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
    Logger.debug("email_delivery_dispatch_nudged",
      delivery_id: payload_delivery_id(payload),
      source_event: inspect(EmailDeliveryCreated)
    )

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

  defp dispatch_pending_email_deliveries(%{dispatch_enabled: false}) do
    Logger.debug("email_delivery_dispatch_disabled")
    []
  end

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

  defp claim_failed_delivery(delivery_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    claim_query =
      from delivery in EmailDeliveryProjection,
        where: delivery.delivery_id == ^delivery_id and delivery.status == ^@failed_status

    case Repo.update_all(claim_query,
           set: [
             status: @dispatching_status,
             last_dispatch_attempted_at: now,
             updated_at: now
           ]
         ) do
      {1, nil} ->
        delivery = Repo.get!(EmailDeliveryProjection, delivery_id)
        log_retry_claimed(delivery)
        {:ok, delivery}

      {0, nil} ->
        error = failed_delivery_retry_error(delivery_id)
        log_retry_skipped(delivery_id, error)
        error
    end
  end

  defp failed_delivery_retry_error(delivery_id) do
    case Repo.get(EmailDeliveryProjection, delivery_id) do
      nil -> {:error, :not_found}
      %EmailDeliveryProjection{status: status} -> {:error, {:not_retryable, status}}
    end
  end

  defp dispatch_claimed_retry_delivery(%EmailDeliveryProjection{} = delivery) do
    case deliver_to_provider(delivery) do
      :ok ->
        log_provider_success(delivery)
        mark_delivery_sent(delivery, increment_attempt_count?: true)

      {:error, reason} ->
        log_provider_error(delivery, reason)
        mark_delivery_failed(delivery, reason)
    end
  end

  defp mark_delivery_sent(%EmailDeliveryProjection{} = delivery, opts \\ []) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    increment_attempt_count? = Keyword.get(opts, :increment_attempt_count?, false)

    updates = [
      set: [
        status: @sent_status,
        latest_error: nil,
        latest_detail: nil,
        sent_at: now,
        failed_at: nil,
        updated_at: now
      ]
    ]

    updates =
      if increment_attempt_count? do
        Keyword.put(updates, :inc, attempt_count: 1)
      else
        updates
      end

    delivery
    |> outcome_query()
    |> Repo.update_all(updates)

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
      reply_context = reply_context(message, club, delivery)

      {:ok,
       %EmailDeliveryRequest{
         message_id: message.message_id,
         club_id: message.club_id,
         delivery_id: delivery.delivery_id,
         outbound_message_id: delivery.outbound_message_id,
         recipient_id: delivery.recipient_id,
         recipient_name: delivery.recipient_name,
         recipient_address: delivery.recipient_address,
         audience_group_id: audience_group_id(message),
         club_name: club_name(club),
         club_slug: club_slug(club),
         sender_name: sender_name,
         sender_address: sender_address,
         conversation_id: message.conversation_id,
         reply_to_message_id: message.reply_to_message_id,
         in_reply_to_outbound_message_id:
           Map.get(reply_context, :in_reply_to_outbound_message_id),
         references_outbound_message_ids:
           Map.get(reply_context, :references_outbound_message_ids),
         conversation_url: Map.get(reply_context, :conversation_url),
         stop_follow_url: Map.get(reply_context, :stop_follow_url),
         reply_to_sender_name: Map.get(reply_context, :reply_to_sender_name),
         reply_to_body: Map.get(reply_context, :reply_to_body),
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

  defp deliver_request_to_provider(
         %EmailDeliveryRequest{} = request,
         %EmailDeliveryProjection{} = delivery
       ) do
    EmailDeliveryProvider.deliver(request)
  rescue
    exception ->
      stacktrace = __STACKTRACE__

      Logger.error(
        "email_delivery_provider_exception\n" <> Exception.format(:error, exception, stacktrace),
        delivery_id: delivery.delivery_id,
        message_id: delivery.message_id,
        provider: inspect(EmailDeliveryProvider.configured_provider()),
        event: "email_delivery_provider_exception"
      )

      {:error, {:provider_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_provider_result(:ok), do: :ok
  defp normalize_provider_result({:error, reason}), do: {:error, reason}
  defp normalize_provider_result(other), do: {:error, {:unexpected_provider_response, other}}

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

  defp audience_group_id(%MessageProjection{conversation_id: conversation_id}) do
    ConversationGroupAccess
    |> where([access], access.conversation_id == ^conversation_id)
    |> order_by([access], asc: access.group_id)
    |> select([access], access.group_id)
    |> limit(1)
    |> Repo.one()
  end

  defp reply_context(%MessageProjection{reply_to_message_id: nil}, _club, _delivery), do: %{}

  defp reply_context(%MessageProjection{} = message, club, %EmailDeliveryProjection{} = delivery) do
    message
    |> base_reply_context(club, delivery)
    |> Map.merge(reply_threading_context(message, delivery))
    |> Map.merge(replied_to_message_context(message.reply_to_message_id))
  end

  defp base_reply_context(
         %MessageProjection{club_id: club_id, conversation_id: conversation_id},
         club,
         %EmailDeliveryProjection{recipient_id: recipient_id}
       ) do
    %{
      conversation_url: ClubSite.url(club, "/messages/#{conversation_id}"),
      stop_follow_url: stop_follow_url(club, club_id, conversation_id, recipient_id)
    }
  end

  defp stop_follow_url(club, club_id, conversation_id, member_id) do
    case ConversationStopFollowToken.sign(%{
           club_id: club_id,
           conversation_id: conversation_id,
           member_id: member_id
         }) do
      {:ok, token} ->
        ClubSite.url(club, "/messages/conversations/stop-following/#{token}")

      {:error, :invalid} ->
        nil
    end
  end

  defp replied_to_message_context(nil), do: %{}

  defp replied_to_message_context(reply_to_message_id) do
    case Repo.get(MessageProjection, reply_to_message_id) do
      %MessageProjection{} = message ->
        sender = Membership.get_person(message.sender_id)

        %{
          reply_to_sender_name: person_name(sender),
          reply_to_body: message.body
        }

      nil ->
        %{}
    end
  end

  defp person_name(%{name: name}), do: name
  defp person_name(_person), do: nil

  defp reply_threading_context(
         %MessageProjection{
           conversation_id: conversation_id,
           reply_to_message_id: reply_to_message_id
         },
         %EmailDeliveryProjection{recipient_id: recipient_id}
       ) do
    in_reply_to_outbound_message_id =
      outbound_message_id_for_message(reply_to_message_id, recipient_id)

    references_outbound_message_ids =
      [conversation_id, reply_to_message_id]
      |> Enum.uniq()
      |> Enum.map(&outbound_message_id_for_message(&1, recipient_id))
      |> Enum.reject(&is_nil/1)

    %{
      in_reply_to_outbound_message_id: in_reply_to_outbound_message_id,
      references_outbound_message_ids: references_outbound_message_ids
    }
  end

  defp outbound_message_id_for_message(nil, _recipient_id), do: nil

  defp outbound_message_id_for_message(message_id, recipient_id) do
    same_recipient_outbound_message_id(message_id, recipient_id) ||
      first_outbound_message_id(message_id)
  end

  defp same_recipient_outbound_message_id(message_id, recipient_id) do
    EmailDeliveryProjection
    |> where([delivery], delivery.message_id == ^message_id)
    |> where([delivery], delivery.recipient_id == ^recipient_id)
    |> order_by([delivery], asc: delivery.inserted_at, asc: delivery.delivery_id)
    |> select([delivery], delivery.outbound_message_id)
    |> limit(1)
    |> Repo.one()
  end

  defp first_outbound_message_id(message_id) do
    EmailDeliveryProjection
    |> where([delivery], delivery.message_id == ^message_id)
    |> order_by([delivery], asc: delivery.inserted_at, asc: delivery.delivery_id)
    |> select([delivery], delivery.outbound_message_id)
    |> limit(1)
    |> Repo.one()
  end

  defp log_dispatch_claimed(%EmailDeliveryProjection{} = delivery) do
    Logger.info(
      "email_delivery_dispatch_claimed",
      delivery_metadata(delivery, @dispatching_status)
    )
  end

  defp log_dispatch_claim_skipped(delivery_id) do
    Logger.debug("email_delivery_dispatch_claim_skipped",
      delivery_id: delivery_id,
      expected_status: @pending_status
    )
  end

  defp log_retry_claimed(%EmailDeliveryProjection{} = delivery) do
    Logger.info("email_delivery_retry_claimed", delivery_metadata(delivery, @dispatching_status))
  end

  defp log_retry_skipped(delivery_id, error) do
    Logger.debug("email_delivery_retry_skipped",
      delivery_id: delivery_id,
      reason: inspect(error)
    )
  end

  defp log_provider_success(%EmailDeliveryProjection{} = delivery) do
    Logger.info("email_delivery_provider_success", delivery_metadata(delivery, @sent_status))
  end

  defp log_provider_error(%EmailDeliveryProjection{} = delivery, reason) do
    Logger.warning(
      "email_delivery_provider_error",
      Keyword.merge(delivery_metadata(delivery, @failed_status), reason: inspect(reason))
    )
  end

  defp delivery_metadata(%EmailDeliveryProjection{} = delivery, status) do
    [
      delivery_id: delivery.delivery_id,
      message_id: delivery.message_id,
      status: status,
      provider: inspect(EmailDeliveryProvider.configured_provider())
    ]
  end

  defp payload_delivery_id(%{source_event: %EmailDeliveryCreated{delivery_id: delivery_id}}),
    do: delivery_id

  defp payload_delivery_id(_payload), do: nil
end
