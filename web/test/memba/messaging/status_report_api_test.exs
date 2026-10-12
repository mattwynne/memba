defmodule Memba.Messaging.StatusReportApiTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging.DeliveryQueries
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  test "public status reporting APIs dispatch delivery status commands" do
    message_id = Memba.ID.generate(:message)
    recipients = recipients(["Alice", "Bob", "Carol", "Dana"])
    [alice, bob, carol, dana] = recipients

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Memba.ID.generate(:club),
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.EmailDeliveryReport.delivered(%{
                       "message_id" => message_id,
                       "delivery_id" => bob.delivery_id
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.EmailDeliveryReport.delayed(%{
                       message_id: message_id,
                       delivery_id: carol.delivery_id,
                       reason: "recipient server is temporarily unavailable"
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.EmailDeliveryReport.bounced(%{
                       message_id: message_id,
                       delivery_id: dana.delivery_id,
                       reason: "mailbox does not exist"
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.EmailDeliveryReport.spam_complaint(%{
                       message_id: message_id,
                       delivery_id: alice.delivery_id,
                       reason: "recipient marked the message as spam"
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert DeliveryQueries.get_member_email_delivery(message_id, bob.person_id).status ==
             "delivered"

    assert DeliveryQueries.get_member_email_delivery(message_id, carol.person_id).status ==
             "delivery problem"

    assert DeliveryQueries.get_memba_staff_email_delivery(message_id, carol.person_id).status ==
             "delayed"

    assert DeliveryQueries.get_memba_staff_email_delivery(message_id, carol.person_id).reason ==
             "recipient server is temporarily unavailable"

    assert DeliveryQueries.get_member_email_delivery(message_id, dana.person_id).status ==
             "delivery problem"

    assert DeliveryQueries.get_memba_staff_email_delivery(message_id, dana.person_id).status ==
             "bounced"

    assert DeliveryQueries.get_memba_staff_email_delivery(message_id, alice.person_id).status ==
             "spam complaint"
  end

  test "public status reporting APIs surface aggregate validation errors" do
    assert {:error, :message_not_sent} =
             (with {:ok, command} <-
                     Memba.Messaging.EmailDeliveryReport.delivered(%{
                       message_id: Memba.ID.generate(:message),
                       delivery_id: Memba.ID.generate(:delivery)
                     }),
                   {:ok, dispatch_result} <- Memba.Messaging.CommandDispatch.dispatch(command, []) do
                dispatch_result
              end)
  end

  defp recipients(names) do
    Enum.map(names, fn name ->
      %Recipient{
        delivery_id: Memba.ID.generate(:delivery),
        person_id: Memba.ID.generate(:person),
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
