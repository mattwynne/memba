defmodule Memba.Messaging.EmailDeliveryStatusConstraintsTest do
  use Memba.DataCase, async: true

  alias Memba.Messaging.EmailDeliveryStatus
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection

  @valid_statuses EmailDeliveryStatus.valid_statuses()

  test "shared status vocabulary lists dispatch lifecycle and provider webhook statuses" do
    assert EmailDeliveryStatus.dispatch_lifecycle_statuses() ==
             ~w(pending dispatching sent failed)

    assert EmailDeliveryStatus.provider_webhook_statuses() ==
             ~w(delivered delayed bounced spam_complaint)

    assert EmailDeliveryStatus.valid_statuses() == @valid_statuses
    assert EmailDeliveryStatus.valid?("pending")
    refute EmailDeliveryStatus.valid?("not-a-delivery-status")
  end

  test "database constraint allows dispatch lifecycle and provider webhook statuses" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    rows =
      @valid_statuses
      |> Enum.with_index()
      |> Enum.map(fn {status, index} ->
        email_delivery_row(
          status: status,
          recipient_name: "Recipient #{index}",
          recipient_address: "recipient-#{index}@example.test",
          inserted_at: now,
          updated_at: now
        )
      end)

    assert {inserted_count, nil} = Repo.insert_all(EmailDeliveryProjection, rows)
    assert inserted_count == length(@valid_statuses)
  end

  test "database constraint rejects statuses outside the delivery vocabulary" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    assert_raise Postgrex.Error, ~r/messaging_email_deliveries_status_check/, fn ->
      Repo.insert_all(EmailDeliveryProjection, [
        email_delivery_row(
          status: "not-a-delivery-status",
          recipient_name: "Invalid Recipient",
          recipient_address: "invalid-recipient@example.test",
          inserted_at: now,
          updated_at: now
        )
      ])
    end
  end

  defp email_delivery_row(attrs) when is_list(attrs) do
    %{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
      message_id: Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end),
      recipient_id: Keyword.get_lazy(attrs, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      recipient_address: Keyword.fetch!(attrs, :recipient_address),
      channel: "email",
      status: Keyword.fetch!(attrs, :status),
      inserted_at: Keyword.fetch!(attrs, :inserted_at),
      updated_at: Keyword.fetch!(attrs, :updated_at)
    }
  end
end
