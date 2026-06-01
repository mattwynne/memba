defmodule MembaWeb.AdminDiagnosticsLiveTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  test "admin message detail keeps diagnostic sections and raw receipt values", %{conn: conn} do
    %{message_id: message_id, recipients: [alice, bob]} =
      send_projected_message_with_recipients(["Alice", "Bob"])

    reason = "recipient server is temporarily unavailable"

    assert :ok =
             Messaging.report_delivery_delayed(
               %{message_id: message_id, delivery_id: bob.delivery_id, reason: reason},
               consistency: :strong
             )

    response =
      conn
      |> sign_in_staff()
      |> get("/admin/messages/#{message_id}")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "Trip planning night"
    assert response =~ "Bring route ideas."
    assert response =~ alice.email
    assert response =~ bob.email
    assert response =~ alice.delivery_id
    assert response =~ bob.delivery_id

    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#message-show")
    assert_selector_exists(html, "#addressed-recipients[aria-label='Addressed recipients']")
    assert_selector_exists(html, "#delivery-records[aria-label='Delivery records']")
    assert_selector_exists(html, "#member-receipts[aria-label='Member receipt statuses']")

    assert_selector_exists(
      html,
      "#addressed-recipients [data-testid='addressed-recipient'][data-delivery-id='#{bob.delivery_id}'][data-recipient-name='Bob']"
    )

    assert_selector_exists(
      html,
      "#delivery-records [data-testid='delivery-record'][data-delivery-id='#{bob.delivery_id}'][data-recipient-name='Bob']"
    )

    assert_selector_exists(
      html,
      "#delivery-status-#{bob.delivery_id}[data-delivery-status='sent']"
    )

    assert_exact_text(html, "#delivery-status-#{bob.delivery_id}", "sent")

    assert_selector_exists(
      html,
      "#member-receipts [data-testid='member-receipt'][data-delivery-id='#{bob.delivery_id}'][data-recipient-name='Bob']"
    )

    assert_selector_exists(
      html,
      "#receipt-status-#{bob.delivery_id}[data-receipt-status='delivery problem']"
    )

    assert_exact_text(html, "#receipt-status-#{bob.delivery_id}", "delivery problem")
    refute response =~ reason
    refute response =~ "Delivery problem"
  end

  test "admin deliveries overview keeps detailed operator statuses and provider reasons", %{
    conn: conn
  } do
    %{message_id: message_id, recipients: [recipient]} =
      send_projected_message_with_recipients(["Carol"], subject: "Trail work party")

    reason = "recipient marked the message as spam"

    assert :ok =
             Messaging.report_delivery_spam_complaint(
               %{message_id: message_id, delivery_id: recipient.delivery_id, reason: reason},
               consistency: :strong
             )

    response =
      conn
      |> sign_in_staff()
      |> get("/admin/deliveries")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)
    row_selector = "[data-test-id='delivery-row-#{recipient.delivery_id}']"

    assert response =~ "Deliveries"
    assert response =~ "Trail work party"
    assert response =~ recipient.name
    assert response =~ recipient.email
    assert response =~ recipient.delivery_id
    assert response =~ reason

    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#deliveries-overview")
    assert_selector_exists(html, "#deliveries-table[aria-label='Delivery records']")

    assert_selector_exists(
      html,
      "#{row_selector}[data-message-id='#{message_id}'][data-delivery-status='spam complaint']"
    )

    assert_exact_text(html, "#{row_selector} [data-test-id='delivery-status']", "spam complaint")
    assert_exact_text(html, "#{row_selector} [data-test-id='delivery-reason']", reason)
    refute response =~ "Delivery problem"
  end

  defp send_projected_message_with_recipients(names, opts \\ []) do
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
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Ecto.UUID.generate(),
                 sender_id: sender.person_id,
                 subject: Keyword.get(opts, :subject, "Trip planning night"),
                 body: Keyword.get(opts, :body, "Bring route ideas."),
                 recipients: recipients
               },
               consistency: :strong
             )

    %{message_id: message_id, recipients: recipients}
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp assert_exact_text(html, selector, expected_text) do
    actual_text =
      html
      |> LazyHTML.query(selector)
      |> LazyHTML.text()
      |> String.trim()

    assert actual_text == expected_text
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
