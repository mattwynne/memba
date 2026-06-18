defmodule Memba.Messaging.MemberEmailDeliveryProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Projectors.MemberEmailDelivery, as: MemberEmailDeliveryProjector
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
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
             %MemberEmailDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^alice_person_id,
               recipient_name: "Alice",
               status: "sent"
             },
             %MemberEmailDeliveryProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               recipient_id: ^bob_person_id,
               recipient_name: "Bob",
               status: "sent"
             }
           ] = Messaging.list_member_email_deliverys(message_id)

    assert %MemberEmailDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent"
           } = Messaging.get_member_email_delivery(bob_delivery_id)

    assert %MemberEmailDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             recipient_id: ^bob_person_id,
             status: "sent"
           } = Messaging.get_member_email_delivery(message_id, bob_person_id)
  end

  test "member email delivery projection applies the ADR 0006 status mapping" do
    %{message_id: message_id, recipients: recipients} =
      send_message_with_recipients(["Alice", "Bob", "Carol", "Dana", "Erin"])

    [_alice, bob, carol, dana, erin] = recipients

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

    receipts_by_recipient =
      message_id
      |> Messaging.list_member_email_deliverys()
      |> Map.new(&{&1.recipient_name, &1.status})

    assert receipts_by_recipient == %{
             "Alice" => "sent",
             "Bob" => "delivered",
             "Carol" => "delivery problem",
             "Dana" => "delivery problem",
             "Erin" => "delivery problem"
           }
  end

  test "member email delivery projection ignores historic opened events" do
    %{message_id: message_id, recipients: [_alice, bob]} =
      send_message_with_recipients(["Alice", "Bob"])

    handler_name = "member-email-delivery-opened-compat-#{Ecto.UUID.generate()}"

    assert :ok =
             MemberEmailDeliveryProjector.handle(
               %EmailDeliveryOpened{
                 message_id: message_id,
                 delivery_id: bob.delivery_id
               },
               %{
                 handler_name: handler_name,
                 event_number: 10_000
               }
             )

    assert %MemberEmailDeliveryProjection{status: "sent"} =
             Messaging.get_member_email_delivery(message_id, bob.person_id)

    assert %MemberEmailDeliveryProjector.ProjectionVersion{last_seen_event_number: 10_000} =
             Repo.get_by(MemberEmailDeliveryProjector.ProjectionVersion,
               projection_name: handler_name
             )
  end

  test "member email delivery queries do not normalize unsupported opened rows" do
    %{message_id: message_id, recipients: [_alice, bob]} =
      send_message_with_recipients(["Alice", "Bob"])

    MemberEmailDeliveryProjection
    |> where([receipt], receipt.delivery_id == ^bob.delivery_id)
    |> Repo.update_all(set: [status: "opened"])

    assert %MemberEmailDeliveryProjection{status: "opened"} =
             Messaging.get_member_email_delivery(bob.delivery_id)

    assert %MemberEmailDeliveryProjection{status: "opened"} =
             Messaging.get_member_email_delivery(message_id, bob.person_id)

    assert %{"Bob" => "opened"} =
             message_id
             |> Messaging.list_member_email_deliverys()
             |> Map.new(&{&1.recipient_name, &1.status})
  end

  test "member email delivery queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_member_email_delivery(Memba.ID.generate(:delivery)))
    assert is_nil(Messaging.get_member_email_delivery(nil))
    assert is_nil(Messaging.get_member_email_delivery("not-a-uuid"))

    assert is_nil(
             Messaging.get_member_email_delivery(
               Memba.ID.generate(:message),
               Memba.ID.generate(:person)
             )
           )

    assert is_nil(Messaging.get_member_email_delivery(nil, Memba.ID.generate(:person)))
    assert is_nil(Messaging.get_member_email_delivery(Memba.ID.generate(:message), "not-a-uuid"))

    assert Messaging.list_member_email_deliverys(Memba.ID.generate(:message)) == []
    assert Messaging.list_member_email_deliverys(nil) == []
    assert Messaging.list_member_email_deliverys("not-a-uuid") == []
  end

  defp send_message_with_recipients(names) do
    [sender | _rest] =
      recipients =
      Enum.map(names, fn name ->
        %Recipient{
          delivery_id: Memba.ID.generate(:delivery),
          person_id: Memba.ID.generate(:person),
          name: name,
          email: email_for(name)
        }
      end)

    message_id = Memba.ID.generate(:message)

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Memba.ID.generate(:club),
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
