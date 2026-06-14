defmodule Memba.Accounts.AuthEmailRequestTest do
  use Memba.DataCase, async: true

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailRequest
  alias Memba.AuthEmailProgressChanges
  alias Memba.Repo

  describe "create_auth_email_request/2" do
    test "creates an opaque progress request without storing a submitted email by default" do
      now = ~U[2026-06-13 12:00:00.000000Z]

      assert {:ok, %AuthEmailRequest{} = request} =
               Accounts.create_auth_email_request(%{}, now: now)

      assert Memba.ID.valid?(:auth_email_request, request.request_id)
      assert request.status == "created"
      assert request.recipient_email == nil
      assert request.provider == nil
      assert request.provider_message_id == nil
      assert request.provider_message_stream == nil
      assert request.expires_at == DateTime.add(now, 30 * 60, :second)
      assert request.retain_until == DateTime.add(now, 7 * 24 * 60 * 60, :second)

      assert Accounts.get_auth_email_request(request.request_id).request_id == request.request_id
      assert Accounts.get_auth_email_request("not-a-request-id") == nil
    end

    test "stores an optional normalized internal recipient email only when supplied" do
      assert {:ok, %AuthEmailRequest{} = request} =
               Accounts.create_auth_email_request(%{recipient_email: " Pat@Memba.IO "})

      assert request.recipient_email == "pat@memba.io"
      refute Map.has_key?(Map.from_struct(request), :submitted_email)
      refute Map.has_key?(Map.from_struct(request), :raw_email)
    end
  end

  describe "status transitions" do
    test "marks a request sent with provider correlation data" do
      now = ~U[2026-06-13 12:00:00.000000Z]
      sent_at = DateTime.add(now, 2, :second)
      {:ok, request} = Accounts.create_auth_email_request(%{}, now: now)

      assert {:ok, %AuthEmailRequest{} = sent_request} =
               Accounts.mark_auth_email_sent(
                 request.request_id,
                 %{
                   recipient_email: " ALICE@EXAMPLE.COM ",
                   provider: "postmark",
                   provider_message_id: "postmark-message-123",
                   provider_message_stream: "outbound-authentication"
                 },
                 now: sent_at
               )

      assert sent_request.status == "sent"
      assert sent_request.recipient_email == "alice@example.com"
      assert sent_request.provider == "postmark"
      assert sent_request.provider_message_id == "postmark-message-123"
      assert sent_request.provider_message_stream == "outbound-authentication"
      assert sent_request.sent_at == sent_at
    end

    test "records provider progress while preserving request correlation" do
      now = ~U[2026-06-13 12:00:00.000000Z]
      delivered_at = DateTime.add(now, 9, :second)
      {:ok, request} = Accounts.create_auth_email_request(%{}, now: now)
      {:ok, request} = Accounts.mark_auth_email_sent(request.request_id, %{}, now: now)

      assert {:ok, %AuthEmailRequest{} = accepted_request} =
               Accounts.record_auth_email_provider_accepted(
                 request.request_id,
                 %{
                   provider: "postmark",
                   provider_message_id: "postmark-message-123",
                   provider_event_id: "postmark-event-456",
                   provider_event_type: "Delivered"
                 },
                 now: delivered_at
               )

      assert accepted_request.request_id == request.request_id
      assert accepted_request.status == "provider_accepted"
      assert accepted_request.provider == "postmark"
      assert accepted_request.provider_message_id == "postmark-message-123"
      assert accepted_request.provider_event_id == "postmark-event-456"
      assert accepted_request.provider_event_type == "Delivered"
      assert accepted_request.provider_reported_at == delivered_at
    end
  end

  describe "committed progress notifications" do
    test "publishes narrow notifications after auth-email progress commits" do
      {:ok, request} = Accounts.create_auth_email_request()

      :ok = AuthEmailProgressChanges.subscribe(request.request_id)

      assert {:ok, %AuthEmailRequest{} = sent_request} =
               Accounts.mark_auth_email_sent(request.request_id, %{
                 recipient_email: "alice@example.com"
               })

      assert sent_request.status == "sent"

      assert_receive {:auth_email_progress_changed, %{request_id: request_id} = payload}
      assert request_id == request.request_id
      assert Map.keys(payload) == [:request_id]

      assert Accounts.get_auth_email_request(request.request_id).status == "sent"

      assert {:ok, %AuthEmailRequest{} = accepted_request} =
               Accounts.record_auth_email_provider_accepted(request.request_id)

      assert accepted_request.status == "provider_accepted"

      assert_receive {:auth_email_progress_changed, %{request_id: request_id} = payload}
      assert request_id == request.request_id
      assert Map.keys(payload) == [:request_id]

      assert Accounts.get_auth_email_request(request.request_id).status == "provider_accepted"
    end

    test "does not publish or rewrite state for duplicate provider progress events" do
      accepted_at = ~U[2026-06-13 12:00:09.000000Z]
      duplicate_at = DateTime.add(accepted_at, 60, :second)

      {:ok, request} = Accounts.create_auth_email_request()
      {:ok, request} = Accounts.mark_auth_email_sent(request.request_id)

      :ok = AuthEmailProgressChanges.subscribe(request.request_id)

      attrs = %{
        provider: "postmark",
        provider_message_id: "postmark-message-123",
        provider_event_id: "postmark-event-456",
        provider_event_type: "Delivery"
      }

      assert {:ok, %AuthEmailRequest{} = accepted_request} =
               Accounts.record_auth_email_provider_accepted(request.request_id, attrs,
                 now: accepted_at
               )

      assert accepted_request.status == "provider_accepted"
      assert accepted_request.provider_reported_at == accepted_at

      assert_receive {:auth_email_progress_changed, %{request_id: request_id}}
      assert request_id == request.request_id

      assert {:ok, %AuthEmailRequest{} = duplicate_request} =
               Accounts.record_auth_email_provider_accepted(request.request_id, attrs,
                 now: duplicate_at
               )

      assert duplicate_request.status == "provider_accepted"
      assert duplicate_request.provider_reported_at == accepted_request.provider_reported_at
      assert duplicate_request.updated_at == accepted_request.updated_at
      refute_receive {:auth_email_progress_changed, _payload}, 50

      persisted_request = Repo.get!(AuthEmailRequest, request.request_id)
      assert persisted_request.provider_reported_at == accepted_request.provider_reported_at
      assert persisted_request.updated_at == accepted_request.updated_at
    end
  end

  describe "expiry and cleanup" do
    test "identifies user-facing expiry after 30 minutes" do
      now = ~U[2026-06-13 12:00:00.000000Z]
      {:ok, request} = Accounts.create_auth_email_request(%{}, now: now)

      refute Accounts.auth_email_request_expired?(request,
               now: DateTime.add(now, 29 * 60, :second)
             )

      assert Accounts.auth_email_request_expired?(request,
               now: DateTime.add(now, 30 * 60, :second)
             )
    end

    test "deletes rows only after the seven-day retention window" do
      old_now = ~U[2026-06-01 12:00:00.000000Z]
      current_now = ~U[2026-06-13 12:00:00.000000Z]
      {:ok, old_request} = Accounts.create_auth_email_request(%{}, now: old_now)
      {:ok, retained_request} = Accounts.create_auth_email_request(%{}, now: current_now)

      assert {1, nil} = Accounts.delete_retained_auth_email_requests(now: current_now)

      assert Repo.get(AuthEmailRequest, old_request.request_id) == nil
      assert Repo.get(AuthEmailRequest, retained_request.request_id)
    end
  end
end
