defmodule Memba.Messaging.EmailDeliveryDispatcherTest do
  use Memba.DataCase, async: false

  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projectors.MemberEmailDelivery, as: MemberEmailDeliveryProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.ReadModelChanges

  describe "read-model change nudges" do
    test "subscribes to read-model changes and nudges dispatch for committed email delivery creation" do
      name = :"#{__MODULE__}.email_delivery_created"

      start_supervised!(
        {EmailDeliveryDispatcher, name: name, dispatch_enabled: true, dispatch_observer: self()}
      )

      event = %EmailDeliveryCreated{
        message_id: "msg_dispatch_nudge",
        delivery_id: "del_dispatch_nudge",
        recipient_id: "per_dispatch_nudge",
        recipient_name: "Ada Member",
        recipient_email: "ada@example.test"
      }

      insert_email_delivery!(
        delivery_id: event.delivery_id,
        message_id: event.message_id,
        recipient_id: event.recipient_id,
        recipient_name: event.recipient_name,
        recipient_address: event.recipient_email,
        status: "pending"
      )

      changes = %{
        messaging_email_delivery: %{
          delivery_id: event.delivery_id,
          message_id: event.message_id,
          status: "pending"
        }
      }

      assert :ok = ReadModelChanges.publish(EmailDeliveryProjector, event, %{}, changes)

      assert_receive {:email_delivery_dispatch_requested,
                      %{
                        source: :read_model_change,
                        projector: EmailDeliveryProjector,
                        source_event: ^event,
                        changes: ^changes,
                        claimed_delivery_ids: [claimed_delivery_id]
                      }}

      assert claimed_delivery_id == event.delivery_id

      assert %EmailDeliveryProjection{status: "dispatching"} =
               Repo.get!(EmailDeliveryProjection, event.delivery_id)
    end

    test "ignores unrelated read-model changes" do
      name = :"#{__MODULE__}.unrelated_changes"

      start_supervised!({EmailDeliveryDispatcher, name: name, dispatch_observer: self()})

      event = %EmailDeliveryDelivered{
        message_id: "msg_unrelated",
        delivery_id: "del_unrelated"
      }

      assert :ok =
               ReadModelChanges.publish(
                 MemberEmailDeliveryProjector,
                 event,
                 %{},
                 %{messaging_member_email_delivery: %{delivery_id: event.delivery_id}}
               )

      refute_receive {:email_delivery_dispatch_requested, _}
    end

    test "can leave read-model-change nudges observable without claiming in tests" do
      name = :"#{__MODULE__}.dispatch_disabled"

      start_supervised!(
        {EmailDeliveryDispatcher, name: name, dispatch_enabled: false, dispatch_observer: self()}
      )

      event = %EmailDeliveryCreated{
        message_id: "msg_dispatch_disabled",
        delivery_id: "del_dispatch_disabled",
        recipient_id: "per_dispatch_disabled",
        recipient_name: "Disabled Dispatcher",
        recipient_email: "disabled-dispatcher@example.test"
      }

      insert_email_delivery!(
        delivery_id: event.delivery_id,
        message_id: event.message_id,
        recipient_id: event.recipient_id,
        recipient_name: event.recipient_name,
        recipient_address: event.recipient_email,
        status: "pending"
      )

      assert :ok = ReadModelChanges.publish(EmailDeliveryProjector, event, %{}, %{})

      assert_receive {:email_delivery_dispatch_requested,
                      %{claimed_delivery_ids: [], source_event: ^event}}

      assert %EmailDeliveryProjection{status: "pending"} =
               Repo.get!(EmailDeliveryProjection, event.delivery_id)
    end
  end

  describe "claiming" do
    test "atomically moves one pending delivery to dispatching" do
      delivery =
        insert_email_delivery!(
          delivery_id: "del_claim_once",
          status: "pending",
          last_dispatch_attempted_at: nil
        )

      assert {:ok,
              %EmailDeliveryProjection{
                delivery_id: "del_claim_once",
                status: "dispatching",
                attempt_count: 0,
                last_dispatch_attempted_at: %DateTime{} = attempted_at
              }} = EmailDeliveryDispatcher.claim_pending_delivery(delivery.delivery_id)

      assert DateTime.compare(attempted_at, delivery.inserted_at) in [:gt, :eq]
    end

    test "does not claim a delivery that is no longer pending" do
      delivery = insert_email_delivery!(delivery_id: "del_already_sent", status: "sent")

      assert :not_claimed = EmailDeliveryDispatcher.claim_pending_delivery(delivery.delivery_id)

      assert %EmailDeliveryProjection{status: "sent", last_dispatch_attempted_at: nil} =
               Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
    end

    test "allows only one concurrent claimant for a pending delivery" do
      delivery = insert_email_delivery!(delivery_id: "del_concurrent_claim", status: "pending")

      results =
        1..2
        |> Task.async_stream(
          fn _index -> EmailDeliveryDispatcher.claim_pending_delivery(delivery.delivery_id) end,
          max_concurrency: 2,
          timeout: 1_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert 1 == Enum.count(results, &match?({:ok, %EmailDeliveryProjection{}}, &1))
      assert 1 == Enum.count(results, &(&1 == :not_claimed))

      assert %EmailDeliveryProjection{status: "dispatching"} =
               Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
    end

    test "claims pending deliveries while skipping already-claimed work" do
      first = insert_email_delivery!(delivery_id: "del_claim_all_first", status: "pending")
      second = insert_email_delivery!(delivery_id: "del_claim_all_second", status: "dispatching")

      assert [%EmailDeliveryProjection{delivery_id: claimed_id, status: "dispatching"}] =
               EmailDeliveryDispatcher.claim_pending_email_deliveries()

      assert claimed_id == first.delivery_id

      assert %EmailDeliveryProjection{status: "dispatching"} =
               Repo.get!(EmailDeliveryProjection, first.delivery_id)

      assert %EmailDeliveryProjection{status: "dispatching", last_dispatch_attempted_at: nil} =
               Repo.get!(EmailDeliveryProjection, second.delivery_id)
    end
  end

  defp insert_email_delivery!(attrs) when is_list(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert!(%EmailDeliveryProjection{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
      message_id: Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end),
      recipient_id: Keyword.get_lazy(attrs, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.get(attrs, :recipient_name, "Ada Member"),
      recipient_address: Keyword.get(attrs, :recipient_address, "ada@example.test"),
      channel: Keyword.get(attrs, :channel, "email"),
      status: Keyword.fetch!(attrs, :status),
      attempt_count: Keyword.get(attrs, :attempt_count, 0),
      latest_error: Keyword.get(attrs, :latest_error),
      latest_detail: Keyword.get(attrs, :latest_detail),
      last_dispatch_attempted_at: Keyword.get(attrs, :last_dispatch_attempted_at),
      sent_at: Keyword.get(attrs, :sent_at),
      failed_at: Keyword.get(attrs, :failed_at),
      inserted_at: Keyword.get(attrs, :inserted_at, now),
      updated_at: Keyword.get(attrs, :updated_at, now)
    })
  end
end
