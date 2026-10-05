defmodule Memba.Messaging.EmailDeliveryReportTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.EmailDeliveryReport
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint

  test "prepares all four provider-neutral status commands without changing supplied values" do
    attrs = %{message_id: "message", delivery_id: "delivery", reason: "  temporary  "}

    assert {:ok, %ReportEmailDeliveryDelivered{message_id: "message", delivery_id: "delivery"}} =
             EmailDeliveryReport.delivered(attrs)

    for {prepare, module} <- [
          {:delayed, ReportEmailDeliveryDelayed},
          {:bounced, ReportEmailDeliveryBounced},
          {:spam_complaint, ReportEmailDeliverySpamComplaint}
        ] do
      assert {:ok, command} = apply(EmailDeliveryReport, prepare, [attrs])
      assert command.__struct__ == module
      assert command.message_id == "message"
      assert command.delivery_id == "delivery"
      assert command.reason == "  temporary  "
    end
  end

  test "accepts string keys and gives atom keys precedence even for nil values" do
    attrs = %{"message_id" => "message", "delivery_id" => "delivery", "reason" => "reason"}

    assert {:ok, %ReportEmailDeliveryDelayed{reason: "reason"}} =
             EmailDeliveryReport.delayed(attrs)

    assert {:ok, %ReportEmailDeliveryDelayed{message_id: nil, reason: nil}} =
             attrs
             |> Map.merge(%{message_id: nil, reason: nil})
             |> EmailDeliveryReport.delayed()
  end

  test "missing fields return the same errors in message, delivery, reason order" do
    for prepare <- [:delivered, :delayed, :bounced, :spam_complaint] do
      assert {:error, {:missing_required_attribute, :message_id}} =
               apply(EmailDeliveryReport, prepare, [%{}])

      assert {:error, {:missing_required_attribute, :delivery_id}} =
               apply(EmailDeliveryReport, prepare, [%{message_id: "message"}])
    end

    for prepare <- [:delayed, :bounced, :spam_complaint] do
      assert {:error, {:missing_required_attribute, :reason}} =
               apply(EmailDeliveryReport, prepare, [
                 %{message_id: "message", delivery_id: "delivery"}
               ])
    end
  end
end
