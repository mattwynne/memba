defmodule Memba.Messaging.MembaStaffEmailDeliveryProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliveryOpened
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Messaging.Recipient

  test "SendMessage is projected into Memba staff email email deliveries" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob"])

    [alice, bob] = recipients
    alice_delivery_id = alice.delivery_id
    alice_person_id = alice.person_id
    bob_delivery_id = bob.delivery_id
    bob_person_id = bob.person_id

    assert [
             %MembaStaffEmailDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^alice_person_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.test",
               channel: "email",
               status: "sent",
               reason: nil
             },
             %MembaStaffEmailDeliveryProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               recipient_id: ^bob_person_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.test",
               channel: "email",
               status: "sent",
               reason: nil
             }
           ] = Messaging.list_operator_email_deliveries(message_id)

    assert %MembaStaffEmailDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent",
             reason: nil
           } = Messaging.get_memba_staff_email_delivery(bob_delivery_id)

    assert %MembaStaffEmailDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent",
             reason: nil
           } = Messaging.get_memba_staff_email_delivery(message_id, bob_person_id)
  end

  test "Memba staff email delivery projection keeps detailed statuses and reason text" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob", "Carol", "Dana", "Erin", "Frank"])

    [_alice, bob, carol, dana, erin, frank] = recipients

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: bob.delivery_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelayed{
                 message_id: message_id,
                 delivery_id: carol.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryBounced{
                 message_id: message_id,
                 delivery_id: dana.delivery_id,
                 reason: "mailbox does not exist"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliverySpamComplaint{
                 message_id: message_id,
                 delivery_id: erin.delivery_id,
                 reason: "recipient marked the message as spam"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: frank.delivery_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryOpened{
                 message_id: message_id,
                 delivery_id: frank.delivery_id
               },
               consistency: :strong
             )

    email_deliveries_by_recipient =
      message_id
      |> Messaging.list_operator_email_deliveries()
      |> Map.new(&{&1.recipient_name, {&1.status, &1.reason}})

    assert email_deliveries_by_recipient == %{
             "Alice" => {"sent", nil},
             "Bob" => {"delivered", nil},
             "Carol" => {"delayed", "recipient server is temporarily unavailable"},
             "Dana" => {"bounced", "mailbox does not exist"},
             "Erin" => {"spam complaint", "recipient marked the message as spam"},
             "Frank" => {"opened", nil}
           }
  end

  test "Memba staff email delivery clears prior delay reason when delivery recovers" do
    %{message_id: message_id, recipients: [_alice, bob]} =
      send_message_with_recipients(["Alice", "Bob"])

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelayed{
                 message_id: message_id,
                 delivery_id: bob.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: bob.delivery_id
               },
               consistency: :strong
             )

    assert %MembaStaffEmailDeliveryProjection{
             status: "delivered",
             reason: nil
           } = Messaging.get_memba_staff_email_delivery(message_id, bob.person_id)
  end

  test "Memba staff email delivery overview query lists deliveries across messages newest event first" do
    %{message_id: first_message_id, recipients: [alice]} =
      send_message_with_recipients(["Alice"], subject: "Spring snowpack update")

    %{message_id: second_message_id, recipients: [bob]} =
      send_message_with_recipients(["Bob"], subject: "Trail work party")

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryDelayed{
                 message_id: first_message_id,
                 delivery_id: alice.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReportEmailDeliveryBounced{
                 message_id: second_message_id,
                 delivery_id: bob.delivery_id,
                 reason: "mailbox does not exist"
               },
               consistency: :strong
             )

    older_event_at = ~U[2026-05-29 10:00:00.000000Z]
    newer_event_at = ~U[2026-05-29 11:00:00.000000Z]

    set_delivery_event_at(alice.delivery_id, older_event_at)
    set_delivery_event_at(bob.delivery_id, newer_event_at)

    assert [
             %MembaStaffEmailDeliveryProjection{
               delivery_id: bob_delivery_id,
               message_id: ^second_message_id,
               message_subject: "Trail work party",
               recipient_name: "Bob",
               recipient_address: "bob@example.test",
               channel: "email",
               status: "bounced",
               reason: "mailbox does not exist",
               event_at: ^newer_event_at
             },
             %MembaStaffEmailDeliveryProjection{
               delivery_id: alice_delivery_id,
               message_id: ^first_message_id,
               message_subject: "Spring snowpack update",
               recipient_name: "Alice",
               recipient_address: "alice@example.test",
               channel: "email",
               status: "delayed",
               reason: "recipient server is temporarily unavailable",
               event_at: ^older_event_at
             }
           ] = Messaging.list_operator_deliveries()

    assert bob_delivery_id == bob.delivery_id
    assert alice_delivery_id == alice.delivery_id

    assert [
             %MembaStaffEmailDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_subject: "Spring snowpack update",
               event_at: ^older_event_at
             }
           ] = Messaging.list_operator_deliveries(message_id: first_message_id)
  end

  test "Memba staff email delivery queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_memba_staff_email_delivery(Ecto.UUID.generate()))
    assert is_nil(Messaging.get_memba_staff_email_delivery(nil))
    assert is_nil(Messaging.get_memba_staff_email_delivery("not-a-uuid"))

    assert is_nil(
             Messaging.get_memba_staff_email_delivery(Ecto.UUID.generate(), Ecto.UUID.generate())
           )

    assert is_nil(Messaging.get_memba_staff_email_delivery(nil, Ecto.UUID.generate()))
    assert is_nil(Messaging.get_memba_staff_email_delivery(Ecto.UUID.generate(), "not-a-uuid"))

    assert Messaging.list_operator_email_deliveries(Ecto.UUID.generate()) == []
    assert Messaging.list_operator_email_deliveries(nil) == []
    assert Messaging.list_operator_email_deliveries("not-a-uuid") == []

    assert Messaging.list_operator_deliveries(message_id: Ecto.UUID.generate()) == []
    assert Messaging.list_operator_deliveries(message_id: nil) == []
    assert Messaging.list_operator_deliveries(message_id: "not-a-uuid") == []
    assert Messaging.list_operator_deliveries(nil) == []
  end

  defp send_message_with_recipients(names, opts \\ []) do
    subject = Keyword.get(opts, :subject, "Trip planning night")

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
                 subject: subject,
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    %{message_id: message_id, recipients: recipients}
  end

  defp set_delivery_event_at(delivery_id, event_at) do
    MembaStaffEmailDeliveryProjection
    |> where([deliverability], deliverability.delivery_id == ^delivery_id)
    |> Repo.update_all(set: [updated_at: event_at])
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
