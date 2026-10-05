defmodule Memba.Messaging.EmailHandoffRecovery do
  @moduledoc """
  Durable provider handoff ledger. A recorded in-flight attempt means the provider
  *may* have accepted it, even if its caller died before making an HTTP request.
  A lease is longer than the provider HTTP timeout; recovered attempts are never
  described as failed merely because their outcome is unknown.
  """
  import Ecto.Query
  require Logger

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Projections.EmailDelivery
  alias Memba.Messaging.Projections.EmailHandoffAttempt
  alias Memba.Repo

  @lease_seconds 600
  @search_wait_seconds 600
  @lookup_outage_wait_seconds 1800
  @search_interval_seconds 60
  @max_attempts 3

  def start(%EmailDelivery{} = delivery, %EmailDeliveryRequest{} = request) do
    Repo.transaction(fn ->
      locked = Repo.get!(EmailDelivery, delivery.delivery_id, lock: "FOR UPDATE")

      if locked.status != "dispatching" or locked.active_attempt_id != nil do
        Repo.rollback(:not_claimed)
      end

      now = now()
      provider = EmailDeliveryProvider.configured_provider() |> Atom.to_string()
      previous = latest_unconfirmed_request(delivery.delivery_id)

      if previous && previous.provider not in [provider, "legacy_unknown"] do
        Repo.rollback(:provider_changed)
      end

      attempt =
        Repo.insert!(%EmailHandoffAttempt{
          delivery_id: delivery.delivery_id,
          provider: provider,
          request: :erlang.term_to_binary(request),
          state: "in_flight",
          started_at: now
        })

      locked
      |> Ecto.Changeset.change(
        active_attempt_id: attempt.id,
        attempt_count: locked.attempt_count + 1
      )
      |> Repo.update!()

      attempt
    end)
  end

  def finish(%EmailHandoffAttempt{} = attempt, result) do
    Repo.transaction(fn ->
      delivery = Repo.get!(EmailDelivery, attempt.delivery_id, lock: "FOR UPDATE")

      if delivery.active_attempt_id == attempt.id and delivery.status == "dispatching" do
        current = Repo.get!(EmailHandoffAttempt, attempt.id)
        now = now()

        {status, state, detail} =
          case result do
            :ok ->
              {"sent", "accepted", nil}

            {:error, reason} ->
              {"uncertain", "uncertain", inspect(reason, limit: 50, printable_limit: 2_000)}
          end

        Repo.update!(
          Ecto.Changeset.change(current, state: state, detail: detail, resolved_at: now)
        )

        Repo.update!(
          Ecto.Changeset.change(delivery,
            status: status,
            active_attempt_id: nil,
            latest_error: if(detail, do: "handoff_uncertain"),
            latest_detail: detail,
            sent_at: if(status == "sent", do: now),
            failed_at: nil
          )
        )
      else
        # A late response after lease expiry must not overwrite a webhook or
        # reconciliation outcome. Record it, if still unresolved, for audit.
        current = Repo.get!(EmailHandoffAttempt, attempt.id)

        if current.state in ["in_flight", "uncertain", "unconfirmed"] do
          state = if result == :ok, do: "accepted", else: "uncertain"

          Repo.update!(
            Ecto.Changeset.change(current,
              state: state,
              detail: inspect(result),
              resolved_at: now()
            )
          )
        end

        latest =
          EmailHandoffAttempt
          |> where([a], a.delivery_id == ^delivery.delivery_id)
          |> order_by([a], desc: a.id)
          |> limit(1)
          |> Repo.one!()

        if result == :ok and latest.id == attempt.id and
             delivery.status in ["uncertain", "pending"] and is_nil(delivery.active_attempt_id) do
          Repo.update!(
            Ecto.Changeset.change(delivery,
              status: "sent",
              latest_error: nil,
              latest_detail: nil,
              sent_at: now()
            )
          )
        else
          delivery
        end
      end
    end)
    |> case do
      {:ok, delivery} -> delivery
      {:error, reason} -> raise "handoff outcome transaction failed: #{inspect(reason)}"
    end
  end

  @doc "Scan expired leases and uncertain handoffs; invoke from startup and a periodic tick on every node."
  def sweep do
    cutoff = DateTime.add(now(), -@lease_seconds, :second)

    EmailDelivery
    |> where([d], d.status == "dispatching" and d.last_dispatch_attempted_at <= ^cutoff)
    |> select([d], d.delivery_id)
    |> Repo.all()
    |> Enum.each(&expire/1)

    EmailDelivery
    |> where([d], d.status == "uncertain")
    |> select([d], d.delivery_id)
    |> Repo.all()
    |> Enum.each(&reconcile/1)
  end

  defp expire(delivery_id) do
    Repo.transaction(fn ->
      delivery = Repo.get!(EmailDelivery, delivery_id, lock: "FOR UPDATE")

      if delivery && delivery.status == "dispatching" &&
           DateTime.diff(now(), delivery.last_dispatch_attempted_at, :second) >= @lease_seconds do
        if delivery.active_attempt_id do
          attempt = Repo.get!(EmailHandoffAttempt, delivery.active_attempt_id)

          Repo.update!(
            Ecto.Changeset.change(attempt, state: "uncertain", detail: "worker lease expired")
          )

          Repo.update!(
            Ecto.Changeset.change(delivery,
              status: "uncertain",
              active_attempt_id: nil,
              latest_error: "handoff_uncertain",
              latest_detail: "worker lease expired"
            )
          )
        else
          if delivery.claim_version == 0 do
            # Pre-migration dispatching rows have no ledger. They may already
            # have reached Postmark; do not silently release them for resend.
            Repo.insert!(%EmailHandoffAttempt{
              delivery_id: delivery.delivery_id,
              provider: "legacy_unknown",
              request: <<>>,
              state: "uncertain",
              detail: "pre-ledger handoff outcome unknown",
              started_at: delivery.last_dispatch_attempted_at
            })

            Repo.update!(
              Ecto.Changeset.change(delivery,
                status: "uncertain",
                attempt_count: delivery.attempt_count + 1,
                latest_error: "handoff_uncertain",
                latest_detail: "pre-ledger handoff outcome unknown"
              )
            )
          else
            # Crash while preparing request, before any provider attempt was recorded.
            Repo.update!(Ecto.Changeset.change(delivery, status: "pending"))
          end
        end
      end
    end)
  end

  defp reconcile(delivery_id) do
    # Row lock serializes reconciliation across nodes, including the decision to
    # retry. Never hold this lock while sending; the pending claimant owns that.
    Repo.transaction(fn ->
      delivery = Repo.get!(EmailDelivery, delivery_id, lock: "FOR UPDATE")

      if delivery && delivery.status == "uncertain" do
        attempt =
          EmailHandoffAttempt
          |> where([a], a.delivery_id == ^delivery_id)
          |> order_by([a], desc: a.id)
          |> limit(1)
          |> Repo.one!()

        age = DateTime.diff(now(), attempt.started_at, :second)
        since_check = DateTime.diff(now(), attempt.updated_at, :second)

        if attempt.state == "accepted" do
          Repo.update!(
            Ecto.Changeset.change(delivery,
              status: "sent",
              latest_error: nil,
              latest_detail: nil,
              sent_at: now()
            )
          )
        else
          exhausted? = delivery.latest_error == "retry_budget_exhausted"

          if since_check >= @search_interval_seconds and
               (attempt.state != "unconfirmed" or
                  (exhausted? and searchable?(attempt))) do
            case lookup(attempt, delivery) do
              {:ok, %{message_ids: [_ | _] = ids} = match} ->
                record_reconciled_handoff(delivery, attempt, ids, match)

              :not_found when exhausted? ->
                touch_attempt(attempt)

              :not_found when age >= @search_wait_seconds ->
                release_inconclusive(delivery, attempt, "provider search inconclusive after wait")

              :not_found ->
                :waiting

              {:error, reason} ->
                Logger.warning("email_delivery_reconciliation_unavailable",
                  delivery_id: delivery_id,
                  reason: inspect(reason)
                )

                cond do
                  exhausted? ->
                    touch_attempt(attempt)

                  age >= @lookup_outage_wait_seconds ->
                    release_inconclusive(
                      delivery,
                      attempt,
                      "provider lookup unavailable: #{inspect(reason)}"
                    )

                  true ->
                    # A failed lookup is not evidence of non-acceptance. Keep trying.
                    Repo.update!(
                      Ecto.Changeset.change(attempt,
                        detail: "provider lookup unavailable: #{inspect(reason)}"
                      )
                    )
                end
            end
          end
        end
      end
    end)
  end

  defp touch_attempt(attempt),
    do: Repo.update!(Ecto.Changeset.change(attempt, updated_at: now()))

  defp searchable?(%EmailHandoffAttempt{provider: provider}) do
    provider == Atom.to_string(Postmark) or
      (provider == "legacy_unknown" and EmailDeliveryProvider.configured_provider() == Postmark)
  end

  defp record_reconciled_handoff(delivery, attempt, ids, match) do
    duplicate_count = length(ids) - 1

    detail =
      "Postmark accepted #{length(ids)} message(s): #{Enum.join(ids, ", ")}" <>
        if(match.complete?, do: "", else: " (search incomplete; further duplicates possible)")

    Repo.update!(
      Ecto.Changeset.change(attempt, state: "accepted", detail: detail, resolved_at: now())
    )

    if duplicate_count > 0 do
      Logger.error("email_delivery_duplicate_provider_handoffs",
        delivery_id: delivery.delivery_id,
        message_ids: ids,
        duplicate_count: duplicate_count,
        search_complete: match.complete?
      )
    end

    Repo.update!(
      Ecto.Changeset.change(delivery,
        status: "sent",
        sent_at: now(),
        latest_error: if(duplicate_count > 0, do: "duplicate_provider_handoff"),
        latest_detail: if(duplicate_count > 0 or not match.complete?, do: detail)
      )
    )
  end

  defp release_inconclusive(delivery, attempt, reason) do
    Repo.update!(
      Ecto.Changeset.change(attempt, state: "unconfirmed", detail: reason, resolved_at: now())
    )

    if delivery.attempt_count < @max_attempts do
      Repo.update!(
        Ecto.Changeset.change(delivery,
          status: "pending",
          latest_error: "handoff_uncertain",
          latest_detail: "prior attempt unconfirmed; automatic retry may duplicate"
        )
      )
    else
      Logger.error("email_delivery_handoff_needs_attention",
        delivery_id: delivery.delivery_id,
        attempt_count: delivery.attempt_count,
        reason: reason
      )

      Repo.update!(
        Ecto.Changeset.change(delivery,
          latest_error: "retry_budget_exhausted",
          latest_detail: "retry budget exhausted; provider acceptance unknown"
        )
      )
    end
  end

  defp lookup(%EmailHandoffAttempt{} = attempt, delivery) do
    if searchable?(attempt) do
      lookup = Application.get_env(:memba, :email_handoff_postmark_lookup, Postmark)
      lookup.find_handoff(delivery.delivery_id, delivery.recipient_address, attempt.started_at)
    else
      # Other providers have no searchable handoff. Resend deduplicates a retry
      # within 24 hours using the same request snapshot and key.
      :not_found
    end
  end

  def request(%EmailHandoffAttempt{request: <<>>}), do: nil

  def request(%EmailHandoffAttempt{request: bytes}) do
    case :erlang.binary_to_term(bytes, [:safe]) do
      %EmailDeliveryRequest{} = request -> request
    end
  end

  def latest_unconfirmed_request(delivery_id) do
    EmailHandoffAttempt
    |> where([a], a.delivery_id == ^delivery_id and a.state == "unconfirmed")
    |> order_by([a], desc: a.id)
    |> limit(1)
    |> Repo.one()
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
