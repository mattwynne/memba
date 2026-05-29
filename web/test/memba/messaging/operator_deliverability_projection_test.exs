defmodule Memba.Messaging.OperatorDeliverabilityProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.OperatorDeliverability, as: OperatorDeliverabilityProjection
  alias Memba.Messaging.Recipient

  test "SendMessage is projected into operator deliverability records" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob"])

    [alice, bob] = recipients
    alice_delivery_id = alice.delivery_id
    alice_person_id = alice.person_id
    bob_delivery_id = bob.delivery_id
    bob_person_id = bob.person_id

    assert [
             %OperatorDeliverabilityProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^alice_person_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.test",
               channel: "email",
               status: "sent",
               reason: nil
             },
             %OperatorDeliverabilityProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               recipient_id: ^bob_person_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.test",
               channel: "email",
               status: "sent",
               reason: nil
             }
           ] = Messaging.list_operator_deliverabilities(message_id)

    assert %OperatorDeliverabilityProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent",
             reason: nil
           } = Messaging.get_operator_deliverability(bob_delivery_id)

    assert %OperatorDeliverabilityProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent",
             reason: nil
           } = Messaging.get_operator_deliverability(message_id, bob_person_id)
  end

  test "operator deliverability projection keeps detailed statuses and reason text" do
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

    deliverabilities_by_recipient =
      message_id
      |> Messaging.list_operator_deliverabilities()
      |> Map.new(&{&1.recipient_name, {&1.status, &1.reason}})

    assert deliverabilities_by_recipient == %{
             "Alice" => {"sent", nil},
             "Bob" => {"delivered", nil},
             "Carol" => {"delayed", "recipient server is temporarily unavailable"},
             "Dana" => {"bounced", "mailbox does not exist"},
             "Erin" => {"spam complaint", "recipient marked the message as spam"},
             "Frank" => {"opened", nil}
           }
  end

  test "operator deliverability clears prior delay reason when delivery recovers" do
    %{message_id: message_id, recipients: [_alice, bob]} =
      send_message_with_recipients(["Alice", "Bob"])

    assert :ok =
             App.dispatch(
               %ReportDeliveryDelayed{
                 message_id: message_id,
                 delivery_id: bob.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: bob.delivery_id
               },
               consistency: :strong
             )

    assert %OperatorDeliverabilityProjection{
             status: "delivered",
             reason: nil
           } = Messaging.get_operator_deliverability(message_id, bob.person_id)
  end

  test "operator deliverability queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_operator_deliverability(Ecto.UUID.generate()))
    assert is_nil(Messaging.get_operator_deliverability(nil))
    assert is_nil(Messaging.get_operator_deliverability("not-a-uuid"))

    assert is_nil(Messaging.get_operator_deliverability(Ecto.UUID.generate(), Ecto.UUID.generate()))
    assert is_nil(Messaging.get_operator_deliverability(nil, Ecto.UUID.generate()))
    assert is_nil(Messaging.get_operator_deliverability(Ecto.UUID.generate(), "not-a-uuid"))

    assert Messaging.list_operator_deliverabilities(Ecto.UUID.generate()) == []
    assert Messaging.list_operator_deliverabilities(nil) == []
    assert Messaging.list_operator_deliverabilities("not-a-uuid") == []
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
