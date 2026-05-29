defmodule Memba.Messaging.MemberReceiptProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.MemberReceipt, as: MemberReceiptProjection
  alias Memba.Messaging.Recipient

  test "SendMessage is projected into member-facing sent receipt records" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob"])

    [alice, bob] = recipients
    alice_delivery_id = alice.delivery_id
    alice_person_id = alice.person_id
    bob_delivery_id = bob.delivery_id
    bob_person_id = bob.person_id

    assert [
             %MemberReceiptProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^alice_person_id,
               recipient_name: "Alice",
               receipt_status: "sent"
             },
             %MemberReceiptProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               recipient_id: ^bob_person_id,
               recipient_name: "Bob",
               receipt_status: "sent"
             }
           ] = Messaging.list_member_receipts(message_id)

    assert %MemberReceiptProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             receipt_status: "sent"
           } = Messaging.get_member_receipt(bob_delivery_id)

    assert %MemberReceiptProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             receipt_status: "sent"
           } = Messaging.get_member_receipt(message_id, bob_person_id)
  end

  test "member receipt projection applies the ADR 0006 status mapping" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob", "Carol", "Dana", "Erin", "Frank"])

    [_alice, bob, carol, dana, erin, frank] = recipients

    assert :ok =
             App.dispatch(
               %ReportDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: bob.delivery_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliveryDelayed{
                 message_id: message_id,
                 delivery_id: carol.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliveryBounced{
                 message_id: message_id,
                 delivery_id: dana.delivery_id,
                 reason: "mailbox does not exist"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliverySpamComplaint{
                 message_id: message_id,
                 delivery_id: erin.delivery_id,
                 reason: "recipient marked the message as spam"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: frank.delivery_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliveryOpened{
                 message_id: message_id,
                 delivery_id: frank.delivery_id
               },
               consistency: :strong
             )

    receipts_by_recipient =
      message_id
      |> Messaging.list_member_receipts()
      |> Map.new(&{&1.recipient_name, &1.receipt_status})

    assert receipts_by_recipient == %{
             "Alice" => "sent",
             "Bob" => "delivered",
             "Carol" => "delivery problem",
             "Dana" => "delivery problem",
             "Erin" => "delivery problem",
             "Frank" => "opened"
           }
  end

  test "member receipt queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_member_receipt(Ecto.UUID.generate()))
    assert is_nil(Messaging.get_member_receipt(nil))
    assert is_nil(Messaging.get_member_receipt("not-a-uuid"))

    assert is_nil(Messaging.get_member_receipt(Ecto.UUID.generate(), Ecto.UUID.generate()))
    assert is_nil(Messaging.get_member_receipt(nil, Ecto.UUID.generate()))
    assert is_nil(Messaging.get_member_receipt(Ecto.UUID.generate(), "not-a-uuid"))

    assert Messaging.list_member_receipts(Ecto.UUID.generate()) == []
    assert Messaging.list_member_receipts(nil) == []
    assert Messaging.list_member_receipts("not-a-uuid") == []
  end

  defp send_message_with_recipients(names) do
    [sender | _rest] =
      recipients =
      Enum.map(names, fn name ->
        %Recipient{
          delivery_id: Ecto.UUID.generate(),
          person_id: Ecto.UUID.generate(),
          name: name,
          email: email_for(name)
        }
      end)

    message_id = Ecto.UUID.generate()

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Ecto.UUID.generate(),
                 sender_id: sender.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    %{message_id: message_id, recipients: recipients}
  end

  defp email_for(name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}@example.test"
  end
end
