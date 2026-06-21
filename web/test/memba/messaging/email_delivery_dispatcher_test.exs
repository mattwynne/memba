defmodule Memba.Messaging.EmailDeliveryDispatcherTest do
  use Memba.DataCase, async: false

  import ExUnit.CaptureLog

  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Raising
  alias Memba.Messaging.EmailDeliveryProviders.SelectiveFailure
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.OutboundMessageID
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projectors.MemberEmailDelivery, as: MemberEmailDeliveryProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.ReadModelChanges

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      Fake.reset()
    end)

    :ok
  end

  describe "read-model change nudges" do
    test "subscribes to read-model changes and nudges dispatch for committed email delivery creation" do
      name = :"#{__MODULE__}.email_delivery_created"

      start_supervised!(
        {EmailDeliveryDispatcher, name: name, dispatch_enabled: true, dispatch_observer: self()}
      )

      club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kootenay-mountaineering-club"
        )

      sender =
        insert_membership_person!(
          name: "Alice Sender",
          email: "alice.sender@example.com"
        )

      message =
        insert_message_projection!(
          club_id: club.club_id,
          sender_id: sender.person_id,
          subject: "Dispatch nudge",
          body: "Dispatch this message."
        )

      recipient_id = Memba.ID.generate(:person)

      event = %EmailDeliveryCreated{
        message_id: message.message_id,
        delivery_id: Memba.ID.generate(:delivery),
        recipient_id: recipient_id,
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

      assert %EmailDeliveryProjection{status: "sent", sent_at: %DateTime{}} =
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

  describe "provider handoff" do
    test "builds the provider request from projected delivery and message context" do
      club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kootenay-mountaineering-club"
        )

      sender =
        insert_membership_person!(
          name: "Alice Sender",
          email: "alice.sender@example.com"
        )

      message =
        insert_message_projection!(
          club_id: club.club_id,
          sender_id: sender.person_id,
          subject: "Trip planning night",
          body: "Bring route ideas."
        )

      recipient_id = Memba.ID.generate(:person)

      delivery =
        insert_email_delivery!(
          message_id: message.message_id,
          recipient_id: recipient_id,
          recipient_name: "Bob Member",
          recipient_address: "bob.member@example.com",
          status: "dispatching"
        )

      assert :ok = EmailDeliveryDispatcher.deliver_to_provider(delivery)

      assert [
               %EmailDeliveryRequest{
                 message_id: message_id,
                 club_id: club_id,
                 delivery_id: delivery_id,
                 outbound_message_id: outbound_message_id,
                 recipient_id: ^recipient_id,
                 recipient_name: "Bob Member",
                 recipient_address: "bob.member@example.com",
                 club_name: "Kootenay Mountaineering Club",
                 club_slug: "kootenay-mountaineering-club",
                 sender_name: "Alice Sender",
                 sender_address: "alice.sender@example.com",
                 channel: :email,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               }
             ] = Fake.deliveries()

      assert message_id == message.message_id
      assert club_id == club.club_id
      assert delivery_id == delivery.delivery_id
      assert outbound_message_id == delivery.outbound_message_id
    end

    test "builds reply provider requests with conversation context" do
      club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kootenay-mountaineering-club"
        )

      alice =
        insert_membership_person!(
          name: "Alice Sender",
          email: "alice.sender@example.com"
        )

      bob =
        insert_membership_person!(
          name: "Bob Replier",
          email: "bob.replier@example.com"
        )

      root_message =
        insert_message_projection!(
          club_id: club.club_id,
          sender_id: alice.person_id,
          subject: "Trip planning night",
          body: "Bring route ideas."
        )

      reply_message =
        insert_message_projection!(
          club_id: club.club_id,
          sender_id: bob.person_id,
          conversation_id: root_message.message_id,
          reply_to_message_id: root_message.message_id,
          subject: "Trip planning night",
          body: "I can bring maps."
        )

      recipient_id = Memba.ID.generate(:person)

      delivery =
        insert_email_delivery!(
          message_id: reply_message.message_id,
          recipient_id: recipient_id,
          recipient_name: "Carol Member",
          recipient_address: "carol.member@example.com",
          status: "dispatching"
        )

      assert :ok = EmailDeliveryDispatcher.deliver_to_provider(delivery)

      assert [
               %EmailDeliveryRequest{
                 message_id: reply_message_id,
                 club_id: club_id,
                 delivery_id: delivery_id,
                 outbound_message_id: outbound_message_id,
                 recipient_id: ^recipient_id,
                 recipient_name: "Carol Member",
                 recipient_address: "carol.member@example.com",
                 club_name: "Kootenay Mountaineering Club",
                 club_slug: "kootenay-mountaineering-club",
                 sender_name: "Bob Replier",
                 sender_address: "bob.replier@example.com",
                 conversation_id: conversation_id,
                 reply_to_message_id: reply_to_message_id,
                 conversation_url: conversation_url,
                 stop_follow_url: stop_follow_url,
                 reply_to_sender_name: "Alice Sender",
                 reply_to_body: "Bring route ideas.",
                 subject: "Trip planning night",
                 body: "I can bring maps."
               }
             ] = Fake.deliveries()

      assert reply_message_id == reply_message.message_id
      assert club_id == club.club_id
      assert delivery_id == delivery.delivery_id
      assert outbound_message_id == delivery.outbound_message_id
      assert conversation_id == root_message.message_id
      assert reply_to_message_id == root_message.message_id
      assert conversation_url =~ "/messages/#{root_message.message_id}"
      assert stop_follow_url =~ "/messages/conversations/stop-following/"

      token = stop_follow_url |> String.split("/") |> List.last()

      assert {:ok,
              %{
                club_id: club_id,
                conversation_id: conversation_id,
                member_id: member_id
              }} = ConversationStopFollowToken.verify(token)

      assert club_id == club.club_id
      assert conversation_id == root_message.message_id
      assert member_id == recipient_id
    end

    test "does not call the provider when the delivery's message projection is missing" do
      message_id = Memba.ID.generate(:message)

      delivery =
        insert_email_delivery!(
          message_id: message_id,
          status: "dispatching"
        )

      assert {:error, {:missing_message_projection, ^message_id}} =
               EmailDeliveryDispatcher.deliver_to_provider(delivery)

      assert Fake.deliveries() == []
    end
  end

  describe "dispatch outcomes" do
    test "marks a claimed delivery as sent when the provider accepts it" do
      %{message: message, delivery: delivery} = insert_dispatchable_delivery!(status: "pending")

      assert [
               %EmailDeliveryProjection{
                 delivery_id: delivery_id,
                 status: "sent",
                 attempt_count: 0,
                 latest_error: nil,
                 latest_detail: nil,
                 sent_at: %DateTime{} = sent_at,
                 failed_at: nil
               }
             ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

      assert delivery_id == delivery.delivery_id
      assert DateTime.compare(sent_at, delivery.inserted_at) in [:gt, :eq]

      assert [%EmailDeliveryRequest{message_id: message_id, delivery_id: ^delivery_id}] =
               Fake.deliveries()

      assert message_id == message.message_id

      assert %EmailDeliveryProjection{status: "sent", sent_at: ^sent_at} =
               Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
    end

    test "marks a claimed delivery as failed and persists diagnostics when the provider errors" do
      Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

      %{delivery: delivery} = insert_dispatchable_delivery!(status: "pending")

      assert [
               %EmailDeliveryProjection{
                 delivery_id: delivery_id,
                 status: "failed",
                 attempt_count: 1,
                 latest_error: "unavailable",
                 latest_detail: ":unavailable",
                 sent_at: nil,
                 failed_at: %DateTime{} = failed_at
               }
             ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

      assert delivery_id == delivery.delivery_id
      assert DateTime.compare(failed_at, delivery.inserted_at) in [:gt, :eq]

      assert %EmailDeliveryProjection{
               status: "failed",
               attempt_count: 1,
               latest_error: "unavailable",
               latest_detail: ":unavailable",
               sent_at: nil,
               failed_at: ^failed_at
             } = Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
    end

    test "marks a claimed delivery as failed when the provider raises unexpectedly" do
      Application.put_env(:memba, :messaging_email_delivery_provider, Raising)

      %{delivery: delivery} = insert_dispatchable_delivery!(status: "pending")

      log =
        capture_log(fn ->
          assert [
                   %EmailDeliveryProjection{
                     delivery_id: delivery_id,
                     status: "failed",
                     attempt_count: 1,
                     latest_error: "provider_exception",
                     latest_detail: latest_detail,
                     sent_at: nil,
                     failed_at: %DateTime{} = failed_at
                   }
                 ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

          assert delivery_id == delivery.delivery_id
          assert latest_detail =~ "RuntimeError"
          assert latest_detail =~ "provider exploded"
          assert DateTime.compare(failed_at, delivery.inserted_at) in [:gt, :eq]
        end)

      assert log =~ "email_delivery_provider_exception"
      assert log =~ "provider exploded"

      assert %EmailDeliveryProjection{
               status: "failed",
               attempt_count: 1,
               latest_error: "provider_exception",
               latest_detail: latest_detail,
               sent_at: nil,
               failed_at: %DateTime{}
             } = Repo.get!(EmailDeliveryProjection, delivery.delivery_id)

      assert latest_detail =~ "provider exploded"
    end

    test "continues dispatching other deliveries when one recipient fails" do
      start_supervised!(SelectiveFailure)
      SelectiveFailure.reset()
      SelectiveFailure.fail_addresses(["failing.member@example.test"])
      Application.put_env(:memba, :messaging_email_delivery_provider, SelectiveFailure)

      club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kootenay-mountaineering-club"
        )

      sender =
        insert_membership_person!(
          name: "Alice Sender",
          email: "alice.sender@example.com"
        )

      message =
        insert_message_projection!(
          club_id: club.club_id,
          sender_id: sender.person_id,
          subject: "Trip planning night",
          body: "Bring route ideas."
        )

      failing_delivery =
        insert_email_delivery!(
          message_id: message.message_id,
          recipient_name: "Failing Member",
          recipient_address: "failing.member@example.test",
          status: "pending"
        )

      successful_delivery =
        insert_email_delivery!(
          message_id: message.message_id,
          recipient_name: "Successful Member",
          recipient_address: "successful.member@example.test",
          status: "pending"
        )

      assert [
               %EmailDeliveryProjection{
                 delivery_id: failing_delivery_id,
                 status: "failed",
                 attempt_count: 1,
                 latest_error: "selective_failure",
                 latest_detail: latest_detail,
                 failed_at: %DateTime{}
               },
               %EmailDeliveryProjection{
                 delivery_id: successful_delivery_id,
                 status: "sent",
                 attempt_count: 0,
                 latest_error: nil,
                 latest_detail: nil,
                 sent_at: %DateTime{}
               }
             ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

      assert failing_delivery_id == failing_delivery.delivery_id
      assert successful_delivery_id == successful_delivery.delivery_id
      assert latest_detail =~ "failing.member@example.test"

      assert [
               %EmailDeliveryRequest{recipient_address: "failing.member@example.test"},
               %EmailDeliveryRequest{recipient_address: "successful.member@example.test"}
             ] = SelectiveFailure.deliveries()

      assert %EmailDeliveryProjection{status: "failed", attempt_count: 1} =
               Repo.get!(EmailDeliveryProjection, failing_delivery.delivery_id)

      assert %EmailDeliveryProjection{status: "sent", attempt_count: 0} =
               Repo.get!(EmailDeliveryProjection, successful_delivery.delivery_id)
    end
  end

  describe "manual retry" do
    test "retries a failed delivery through the internal Messaging API and marks it sent" do
      failed_at =
        DateTime.utc_now() |> DateTime.add(-120, :second) |> DateTime.truncate(:microsecond)

      %{message: message, delivery: delivery} =
        insert_dispatchable_delivery!(
          status: "failed",
          attempt_count: 1,
          latest_error: "unavailable",
          latest_detail: ":unavailable",
          failed_at: failed_at
        )

      assert {:ok,
              %EmailDeliveryProjection{
                delivery_id: delivery_id,
                message_id: message_id,
                status: "sent",
                attempt_count: 2,
                latest_error: nil,
                latest_detail: nil,
                last_dispatch_attempted_at: %DateTime{} = attempted_at,
                sent_at: %DateTime{} = sent_at,
                failed_at: nil
              }} = Messaging.retry_failed_email_delivery(delivery.delivery_id)

      assert delivery_id == delivery.delivery_id
      assert message_id == message.message_id
      assert DateTime.compare(attempted_at, failed_at) in [:gt, :eq]
      assert DateTime.compare(sent_at, attempted_at) in [:gt, :eq]

      assert [%EmailDeliveryRequest{message_id: ^message_id, delivery_id: ^delivery_id}] =
               Fake.deliveries()

      assert 1 ==
               Repo.aggregate(
                 from(projected_delivery in EmailDeliveryProjection,
                   where: projected_delivery.message_id == ^message.message_id
                 ),
                 :count
               )
    end

    test "retries a failed delivery and records fresh diagnostics when the provider still errors" do
      Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

      failed_at =
        DateTime.utc_now() |> DateTime.add(-120, :second) |> DateTime.truncate(:microsecond)

      %{delivery: delivery} =
        insert_dispatchable_delivery!(
          status: "failed",
          attempt_count: 1,
          latest_error: "old_error",
          latest_detail: "old detail",
          failed_at: failed_at
        )

      assert {:ok,
              %EmailDeliveryProjection{
                delivery_id: delivery_id,
                status: "failed",
                attempt_count: 2,
                latest_error: "unavailable",
                latest_detail: ":unavailable",
                last_dispatch_attempted_at: %DateTime{} = attempted_at,
                sent_at: nil,
                failed_at: %DateTime{} = retried_failed_at
              }} = Messaging.retry_failed_email_delivery(delivery.delivery_id)

      assert delivery_id == delivery.delivery_id
      assert DateTime.compare(attempted_at, failed_at) in [:gt, :eq]
      assert DateTime.compare(retried_failed_at, attempted_at) in [:gt, :eq]

      assert %EmailDeliveryProjection{
               status: "failed",
               attempt_count: 2,
               latest_error: "unavailable",
               latest_detail: ":unavailable",
               failed_at: ^retried_failed_at
             } = Repo.get!(EmailDeliveryProjection, delivery.delivery_id)
    end

    test "does not retry invalid, missing, or non-failed deliveries" do
      pending_delivery =
        insert_email_delivery!(delivery_id: Memba.ID.generate(:delivery), status: "pending")

      assert {:error, :invalid_delivery_id} =
               Messaging.retry_failed_email_delivery("not-a-delivery-id")

      assert {:error, :not_found} =
               Messaging.retry_failed_email_delivery(Memba.ID.generate(:delivery))

      assert {:error, {:not_retryable, "pending"}} =
               Messaging.retry_failed_email_delivery(pending_delivery.delivery_id)

      assert [] = Fake.deliveries()

      assert %EmailDeliveryProjection{status: "pending", last_dispatch_attempted_at: nil} =
               Repo.get!(EmailDeliveryProjection, pending_delivery.delivery_id)
    end
  end

  defp insert_email_delivery!(attrs) when is_list(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    delivery_id = Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end)
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)

    Repo.insert!(%EmailDeliveryProjection{
      delivery_id: delivery_id,
      message_id: message_id,
      outbound_message_id:
        Keyword.get(
          attrs,
          :outbound_message_id,
          OutboundMessageID.for_delivery(delivery_id, message_id)
        ),
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

  defp insert_dispatchable_delivery!(attrs) when is_list(attrs) do
    club =
      insert_membership_club!(
        name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club"),
        slug: Keyword.get(attrs, :club_slug, "kootenay-mountaineering-club")
      )

    sender =
      insert_membership_person!(
        name: Keyword.get(attrs, :sender_name, "Alice Sender"),
        email: Keyword.get(attrs, :sender_email, "alice.sender@example.com")
      )

    message =
      insert_message_projection!(
        club_id: club.club_id,
        sender_id: sender.person_id,
        subject: Keyword.get(attrs, :subject, "Trip planning night"),
        body: Keyword.get(attrs, :body, "Bring route ideas.")
      )

    delivery =
      insert_email_delivery!(
        message_id: message.message_id,
        recipient_id:
          Keyword.get_lazy(attrs, :recipient_id, fn -> Memba.ID.generate(:person) end),
        recipient_name: Keyword.get(attrs, :recipient_name, "Bob Member"),
        recipient_address: Keyword.get(attrs, :recipient_address, "bob.member@example.com"),
        status: Keyword.fetch!(attrs, :status),
        attempt_count: Keyword.get(attrs, :attempt_count, 0),
        latest_error: Keyword.get(attrs, :latest_error),
        latest_detail: Keyword.get(attrs, :latest_detail),
        last_dispatch_attempted_at: Keyword.get(attrs, :last_dispatch_attempted_at),
        sent_at: Keyword.get(attrs, :sent_at),
        failed_at: Keyword.get(attrs, :failed_at)
      )

    %{club: club, sender: sender, message: message, delivery: delivery}
  end

  defp insert_message_projection!(attrs) when is_list(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)

    Repo.insert!(%MessageProjection{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.fetch!(attrs, :body),
      inserted_at: Keyword.get(attrs, :inserted_at, now),
      updated_at: Keyword.get(attrs, :updated_at, now)
    })
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
