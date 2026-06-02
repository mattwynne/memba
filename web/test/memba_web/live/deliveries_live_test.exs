defmodule MembaWeb.DeliveriesLiveTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  test "operators can review deliveries from multiple messages with problem reasons", %{
    conn: conn
  } do
    %{
      subject: first_subject,
      recipients: [first_recipient]
    } =
      send_projected_message(
        subject: "Spring snowpack update",
        recipients: ["Alice"]
      )

    %{
      subject: second_subject,
      recipients: [second_recipient]
    } =
      send_projected_message(
        subject: "Trail work party",
        recipients: ["Bob"]
      )

    first_reason = "recipient server is temporarily unavailable"
    second_reason = "mailbox does not exist"

    assert :ok =
             Messaging.report_email_delivery_delayed(
               %{
                 message_id: first_recipient.message_id,
                 delivery_id: first_recipient.delivery_id,
                 reason: first_reason
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.report_email_delivery_bounced(
               %{
                 message_id: second_recipient.message_id,
                 delivery_id: second_recipient.delivery_id,
                 reason: second_reason
               },
               consistency: :strong
             )

    conn
    |> sign_in_staff()
    |> visit("/admin/deliveries")
    |> assert_path("/admin/deliveries")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has("nav[aria-label='Memba staff navigation'] a[href='/admin/deliveries']")
    |> assert_has("#deliveries-overview")
    |> assert_has("#deliveries-table[aria-label='Email deliveries']")
    |> assert_has("[data-test-id^='delivery-row-']", count: 2)
    |> assert_delivery_row(first_recipient.delivery_id, [
      first_subject,
      first_recipient.name,
      first_recipient.email,
      "email",
      "delayed",
      first_reason
    ])
    |> assert_delivery_row(second_recipient.delivery_id, [
      second_subject,
      second_recipient.name,
      second_recipient.email,
      "email",
      "bounced",
      second_reason
    ])
  end

  defp send_projected_message(opts) do
    subject = Keyword.fetch!(opts, :subject)
    recipient_names = Keyword.fetch!(opts, :recipients)

    [sender | _rest] =
      recipients =
      Enum.map(recipient_names, fn name ->
        %Recipient{
          delivery_id: Ecto.UUID.generate(),
          person_id: Ecto.UUID.generate(),
          name: name,
          email: email_for(name)
        }
      end)

    message_id = Ecto.UUID.generate()

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Ecto.UUID.generate(),
                 sender_id: sender.person_id,
                 subject: subject,
                 body: "Please read this club update.",
                 recipients: recipients
               },
               consistency: :strong
             )

    recipients =
      Enum.map(recipients, fn recipient ->
        %{
          message_id: message_id,
          delivery_id: recipient.delivery_id,
          name: recipient.name,
          email: recipient.email
        }
      end)

    %{message_id: message_id, subject: subject, recipients: recipients}
  end

  defp assert_delivery_row(session, delivery_id, expected_texts) do
    row_selector = "[data-test-id='delivery-row-#{delivery_id}']"

    session
    |> assert_has("#{row_selector} [data-test-id='delivery-event-at']")
    |> assert_has("#{row_selector} [data-test-id='delivery-status']")
    |> then(fn session ->
      Enum.reduce(expected_texts, session, fn expected_text, session ->
        assert_has(session, row_selector, expected_text)
      end)
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
