defmodule MembaWeb.BrowserAcceptanceHarnessTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  test "browser routes expose stable automation selectors and accessible labels", %{
    conn: conn
  } do
    conn
    |> sign_in_staff()
    |> visit("/admin/clubs")
    |> assert_path("/admin/clubs")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has("nav[aria-label='Staff admin navigation'] a[href='/admin/clubs']")
    |> assert_has("#clubs-index")
    |> assert_has("#new-club-form[aria-label='Create a club']")
    |> assert_has("#club-name-input[aria-label='Club name']")
    |> assert_has("#create-club-button[aria-label='Create club']")
    |> assert_has("#clubs[aria-label='Clubs']")
    |> create_club("Kootenay Mountaineering Club")
    |> assert_has(
      "#clubs [data-testid='club-row'][data-club-name='Kootenay Mountaineering Club']"
    )
    |> assert_has(
      "a[data-testid='club-link'][aria-label='Open club Kootenay Mountaineering Club']"
    )
    |> assert_has("a[data-testid='club-link'][href^='/admin/clubs/']")
    |> click_link("Kootenay Mountaineering Club")
    |> assert_path("/admin/clubs/*")
    |> assert_has("#back-to-clubs-link[aria-label='Back to clubs']")
    |> assert_has("#back-to-clubs-link[href='/admin/clubs']")
    |> assert_has("#new-person-form[aria-label='Create a person']")
    |> assert_has("#person-name-input[aria-label='Person name']")
    |> assert_has("#person-email-input[aria-label='Person email']")
    |> assert_has("#create-person-button[aria-label='Create person']")
    |> assert_has("#people[aria-label='People']")
    |> assert_has("#add-member-form[aria-label='Add a member']")
    |> assert_has("#member-person-select[aria-label='Person to add as member']")
    |> assert_has("#add-member-button[aria-label='Add selected person as member']")
    |> assert_has("#members[aria-label='Members']")
    |> assert_has("#new-message-form[aria-label='Send a club message']")
    |> assert_has("#message-sender-select[aria-label='Message sender']")
    |> assert_has("#message-subject-input[aria-label='Message subject']")
    |> assert_has("#message-body-input[aria-label='Message body']")
    |> assert_has("#send-message-button[aria-label='Send club message']")
    |> assert_has("#messages[aria-label='Messages']")
    |> create_person("Alice")
    |> assert_has("#people [data-testid='person-row'][data-person-name='Alice']")
    |> add_member("Alice")
    |> assert_has("#members [data-testid='member-row'][data-member-name='Alice']")
    |> send_club_message("Alice", "Trip planning night", "Bring route ideas.")
    |> assert_has(
      "#messages [data-testid='message-row'][data-message-subject='Trip planning night']"
    )
    |> assert_has("a[data-testid='message-link'][aria-label='Open message Trip planning night']")
    |> assert_has("a[data-testid='message-link'][href^='/admin/messages/']")
    |> click_link("Trip planning night")
    |> assert_path("/admin/messages/*")
    |> assert_has("#message-show")
    |> assert_has("#back-to-club-link[aria-label='Back to club']")
    |> assert_has("#back-to-club-link[href^='/admin/clubs/']")
    |> assert_has("#addressed-recipients[aria-label='Addressed recipients']")
    |> assert_has(
      "#addressed-recipients [data-testid='addressed-recipient'][data-recipient-name='Alice']"
    )
    |> assert_has("#delivery-records[aria-label='Delivery records']")
    |> assert_has(
      "#delivery-records [data-testid='delivery-record'][data-recipient-name='Alice']"
    )
    |> assert_has(
      "#delivery-records [data-testid='delivery-status'][data-delivery-status='sent']"
    )
    |> assert_has("#member-receipts[aria-label='Member receipt statuses']")
    |> assert_has("#member-receipts [data-testid='member-receipt'][data-recipient-name='Alice']")
    |> assert_has("#member-receipts [data-testid='receipt-status'][data-receipt-status='sent']")
  end

  test "developers can use browser routes to send a club message to active members", %{
    conn: conn
  } do
    conn
    |> sign_in_staff()
    |> visit("/admin/clubs")
    |> assert_path("/admin/clubs")
    |> assert_has("#clubs-index")
    |> create_club("Kootenay Mountaineering Club")
    |> click_link("Kootenay Mountaineering Club")
    |> assert_path("/admin/clubs/*")
    |> assert_has("#club-show", "Kootenay Mountaineering Club")
    |> create_person("Alice")
    |> create_person("Bob")
    |> create_person("Carol")
    |> create_person("Pat")
    |> add_member("Alice")
    |> add_member("Bob")
    |> add_member("Carol")
    |> send_club_message("Alice", "Trip planning night", "Bring route ideas.")
    |> click_link("Trip planning night")
    |> assert_path("/admin/messages/*")
    |> assert_has("#message-show", "Trip planning night")
    |> assert_addressed_recipient("Alice")
    |> assert_addressed_recipient("Bob")
    |> assert_addressed_recipient("Carol")
    |> refute_has("#addressed-recipients [data-testid='addressed-recipient']", "Pat")
    |> assert_has("#delivery-records [data-testid='delivery-record']", count: 3)
    |> assert_has("#member-receipts [data-testid='member-receipt']", count: 3)
    |> assert_member_receipt("Alice", "sent")
    |> assert_member_receipt("Bob", "sent")
    |> assert_member_receipt("Carol", "sent")
  end

  test "member receipt statuses refresh after delivery status reports are invoked", %{
    conn: conn
  } do
    %{message_id: message_id, recipients: recipients} =
      send_projected_message_with_recipients(["Alice", "Bob", "Carol", "Dana", "Erin", "Frank"])

    delivery_ids_by_name = Map.new(recipients, &{&1.name, &1.delivery_id})

    conn
    |> sign_in_staff()
    |> visit("/admin/messages/#{message_id}")
    |> assert_path("/admin/messages/*")
    |> assert_has("#message-show", "Trip planning night")
    |> assert_member_receipt("Alice", "sent")

    assert :ok =
             report_delivery_delivered(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Bob"]
             })

    assert :ok =
             report_delivery_delayed(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Carol"],
               reason: "recipient server is temporarily unavailable"
             })

    assert :ok =
             report_delivery_bounced(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Dana"],
               reason: "mailbox does not exist"
             })

    assert :ok =
             report_delivery_spam_complaint(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Erin"],
               reason: "recipient marked the message as spam"
             })

    assert :ok =
             report_delivery_delivered(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Frank"]
             })

    assert :ok =
             report_delivery_opened(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Frank"]
             })

    conn
    |> sign_in_staff()
    |> visit("/admin/messages/#{message_id}")
    |> assert_path("/admin/messages/*")
    |> assert_member_receipt("Alice", "sent")
    |> assert_member_receipt("Bob", "delivered")
    |> assert_member_receipt("Carol", "delivery problem")
    |> assert_member_receipt("Dana", "delivery problem")
    |> assert_member_receipt("Erin", "delivery problem")
    |> assert_member_receipt("Frank", "opened")
  end

  defp create_club(session, name) do
    session
    |> within("#new-club-form", fn session ->
      session
      |> fill_in("Name", with: name)
      |> click_button("Create club")
    end)
    |> assert_has("#clubs [data-testid='club-row']", name)
  end

  defp create_person(session, name) do
    session
    |> within("#new-person-form", fn session ->
      session
      |> fill_in("Name", with: name)
      |> fill_in("Email", with: email_for(name))
      |> click_button("Create person")
    end)
    |> assert_has("#people [data-testid='person-row']", name)
  end

  defp add_member(session, name) do
    session
    |> within("#add-member-form", fn session ->
      session
      |> select("Person", option: name)
      |> click_button("Add member")
    end)
    |> assert_has("#members [data-testid='member-row']", name)
  end

  defp send_club_message(session, sender_name, subject, body) do
    session
    |> within("#new-message-form", fn session ->
      session
      |> select("Sender", option: sender_name)
      |> fill_in("Subject", with: subject)
      |> fill_in("Body", with: body)
      |> click_button("Send message")
    end)
    |> assert_has("#messages [data-testid='message-row']", subject)
  end

  defp assert_addressed_recipient(session, name) do
    assert_has(session, "#addressed-recipients [data-recipient-name='#{name}']", name)
  end

  defp assert_member_receipt(session, name, status) do
    assert_has(session, "#member-receipts [data-recipient-name='#{name}']", status)
  end

  defp report_delivery_delivered(attrs) do
    apply(Messaging, :report_delivery_delivered, [attrs, [consistency: :strong]])
  end

  defp report_delivery_delayed(attrs) do
    apply(Messaging, :report_delivery_delayed, [attrs, [consistency: :strong]])
  end

  defp report_delivery_bounced(attrs) do
    apply(Messaging, :report_delivery_bounced, [attrs, [consistency: :strong]])
  end

  defp report_delivery_spam_complaint(attrs) do
    apply(Messaging, :report_delivery_spam_complaint, [attrs, [consistency: :strong]])
  end

  defp report_delivery_opened(attrs) do
    apply(Messaging, :report_delivery_opened, [attrs, [consistency: :strong]])
  end

  defp send_projected_message_with_recipients(names) do
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
