defmodule MembaWeb.AdminDiagnosticsLiveTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Recipient
  alias Memba.Repo

  test "Memba staff message detail keeps diagnostic sections and raw status values", %{conn: conn} do
    %{message_id: message_id, recipients: [alice, bob]} =
      send_projected_message_with_recipients(["Alice", "Bob"])

    reason = "recipient server is temporarily unavailable"

    assert :ok =
             Messaging.report_email_delivery_delayed(
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
    assert_selector_exists(html, "#message-show[data-admin-page='message-diagnostics']")
    assert_selector_exists(html, "#message-diagnostics-summary-cards")
    assert_selector_exists(html, "#message-diagnostics-note")
    assert_selector_exists(html, "#message-body-card")
    assert_selector_exists(html, "#addressed-recipients-card")
    assert_selector_exists(html, "#addressed-recipients[aria-label='Addressed recipients']")
    assert_selector_exists(html, "#delivery-records-card")
    assert_selector_exists(html, "#delivery-records[aria-label='Email deliveries']")
    assert_selector_exists(html, "#member-receipts-card")
    assert_selector_exists(html, "#member-receipts[aria-label='Member email delivery statuses']")

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
      "#delivery-status-#{bob.delivery_id}[data-delivery-status='pending']"
    )

    assert_exact_text(html, "#delivery-status-#{bob.delivery_id}", "pending")
    assert_class(html, "#delivery-status-#{bob.delivery_id}", "bg-[#f3ecd8]")
    assert_class(html, "#delivery-status-#{bob.delivery_id}", "text-[#7a5416]")

    assert_selector_exists(
      html,
      "#member-receipts [data-testid='member-receipt'][data-delivery-id='#{bob.delivery_id}'][data-recipient-name='Bob']"
    )

    assert_selector_exists(
      html,
      "#receipt-status-#{bob.delivery_id}[data-receipt-status='delivery problem']"
    )

    assert_exact_text(html, "#receipt-status-#{bob.delivery_id}", "delivery problem")
    assert_class(html, "#receipt-status-#{bob.delivery_id}", "bg-[#f6e0c9]")
    assert_class(html, "#receipt-status-#{bob.delivery_id}", "text-[#8a3d21]")
    refute response =~ reason
    refute response =~ "Delivery problem"
  end

  test "Memba staff email deliveries overview keeps detailed Memba staff statuses and provider reasons",
       %{
         conn: conn
       } do
    %{message_id: message_id, recipients: [recipient]} =
      send_projected_message_with_recipients(["Carol"], subject: "Trail work party")

    reason = "recipient marked the message as spam"

    assert :ok =
             Messaging.report_email_delivery_spam_complaint(
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
    assert_selector_exists(html, "#deliveries-table[aria-label='Email deliveries']")

    assert_selector_exists(
      html,
      "#{row_selector}[data-message-id='#{message_id}'][data-delivery-status='spam complaint']"
    )

    assert_exact_text(html, "#{row_selector} [data-test-id='delivery-status']", "spam complaint")
    assert_exact_text(html, "#{row_selector} [data-test-id='delivery-reason']", reason)
    refute response =~ "Delivery problem"
  end

  test "Memba staff diagnostics show exact async dispatch status and latest error", %{conn: conn} do
    %{message_id: message_id, recipients: [recipient]} =
      send_projected_message_with_recipients(["Dana"], subject: "Dispatch diagnostics")

    dispatch_detail = "{:postmark_delivery_error, :unavailable}"

    recipient.delivery_id
    |> failed_delivery_changeset(%{
      status: "failed",
      attempt_count: 2,
      latest_error: "postmark_delivery_error",
      latest_detail: dispatch_detail
    })
    |> Repo.update!()

    message_response =
      conn
      |> sign_in_staff()
      |> get("/admin/messages/#{message_id}")
      |> html_response(200)

    message_html = LazyHTML.from_fragment(message_response)

    assert_selector_exists(
      message_html,
      "#delivery-status-#{recipient.delivery_id}[data-delivery-status='failed']"
    )

    assert_exact_text(message_html, "#delivery-status-#{recipient.delivery_id}", "failed")
    assert_class(message_html, "#delivery-status-#{recipient.delivery_id}", "bg-[#f6e0c9]")

    assert_exact_text(
      message_html,
      "#delivery-attempt-count-#{recipient.delivery_id}",
      "Attempts: 2"
    )

    assert_exact_text(
      message_html,
      "#delivery-latest-error-#{recipient.delivery_id}",
      "Error: postmark_delivery_error"
    )

    assert_exact_text(
      message_html,
      "#delivery-latest-detail-#{recipient.delivery_id}",
      "Detail: #{dispatch_detail}"
    )

    assert_selector_exists(
      message_html,
      "#receipt-status-#{recipient.delivery_id}[data-receipt-status='sent']"
    )

    overview_response =
      conn
      |> recycle()
      |> sign_in_staff()
      |> get("/admin/deliveries")
      |> html_response(200)

    overview_html = LazyHTML.from_fragment(overview_response)
    row_selector = "[data-test-id='delivery-row-#{recipient.delivery_id}']"

    assert_selector_exists(
      overview_html,
      "#{row_selector}[data-delivery-status='sent']"
    )

    assert_exact_text(overview_html, "#{row_selector} [data-test-id='delivery-status']", "sent")

    assert_exact_text(
      overview_html,
      "#{row_selector} [data-test-id='delivery-dispatch-status']",
      "failed"
    )

    assert_exact_text(
      overview_html,
      "#{row_selector} [data-test-id='delivery-dispatch-attempts']",
      "attempts: 2"
    )

    assert_exact_text(
      overview_html,
      "#{row_selector} [data-test-id='delivery-dispatch-error']",
      "error: postmark_delivery_error"
    )

    assert_exact_text(
      overview_html,
      "#{row_selector} [data-test-id='delivery-dispatch-detail']",
      "detail: #{dispatch_detail}"
    )
  end

  defp send_projected_message_with_recipients(names, opts \\ []) do
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
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Memba.ID.generate(:club),
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

  defp assert_class(html, selector, expected_class) do
    classes =
      html
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute("class")
      |> List.first("")
      |> String.split()

    assert expected_class in classes,
           "Expected #{selector} to include class #{expected_class}; got #{inspect(classes)}"
  end

  defp failed_delivery_changeset(delivery_id, attrs) do
    EmailDeliveryProjection
    |> Repo.get!(delivery_id)
    |> Ecto.Changeset.change(attrs)
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
