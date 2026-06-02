defmodule Memba.Messaging.StatusReportApiTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  test "public status reporting APIs dispatch delivery status commands" do
    message_id = Ecto.UUID.generate()
    recipients = recipients(["Alice", "Bob", "Carol", "Dana", "Erin"])
    [alice, bob, carol, dana, erin] = recipients

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Ecto.UUID.generate(),
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_delivered(
               %{"message_id" => message_id, "delivery_id" => bob.delivery_id},
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_delayed(
               %{
                 message_id: message_id,
                 delivery_id: carol.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_bounced(
               %{
                 message_id: message_id,
                 delivery_id: dana.delivery_id,
                 reason: "mailbox does not exist"
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_delivered(
               %{message_id: message_id, delivery_id: erin.delivery_id},
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_opened(
               %{message_id: message_id, delivery_id: erin.delivery_id},
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_spam_complaint(
               %{
                 message_id: message_id,
                 delivery_id: alice.delivery_id,
                 reason: "recipient marked the message as spam"
               },
               consistency: :strong
             )

    assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"

    assert Messaging.get_member_email_delivery(message_id, carol.person_id).status ==
             "delivery problem"

    assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).status == "delayed"

    assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).reason ==
             "recipient server is temporarily unavailable"

    assert Messaging.get_member_email_delivery(message_id, dana.person_id).status ==
             "delivery problem"

    assert Messaging.get_memba_staff_email_delivery(message_id, dana.person_id).status == "bounced"
    assert Messaging.get_memba_staff_email_delivery(message_id, erin.person_id).status == "opened"

    assert Messaging.get_memba_staff_email_delivery(message_id, alice.person_id).status ==
             "spam complaint"
  end

  test "public status reporting APIs surface aggregate validation errors" do
    assert {:error, :message_not_sent} =
             Messaging.report_email_delivery_delivered(%{
               message_id: Ecto.UUID.generate(),
               delivery_id: Ecto.UUID.generate()
             })
  end

  defp recipients(names) do
    Enum.map(names, fn name ->
      %Recipient{
        delivery_id: Ecto.UUID.generate(),
        person_id: Ecto.UUID.generate(),
        name: name,
        email: email_for(name)
      }
    end)
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
