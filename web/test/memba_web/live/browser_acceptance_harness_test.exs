defmodule MembaWeb.BrowserAcceptanceHarnessTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Membership
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
    |> assert_has("nav[aria-label='Memba staff navigation'] a[href='/admin/clubs']")
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
    |> assert_has(
      "#staff-club-home-link[aria-label='Open Kootenay Mountaineering Club home page']"
    )
    |> assert_has("#staff-club-home-link[href^='http://']")
    |> assert_has("#new-person-link[aria-label='New person'][href^='/admin/clubs/']")
    |> assert_has("#invite-member-link[aria-label='Invite member'][href^='/admin/clubs/']")
    |> refute_has("#new-person-form")
    |> assert_has("#people[aria-label='People']")
    |> assert_has("#memberships-invitation-notice", "Invitation required")
    |> refute_has("#add-member-form")
    |> refute_has("#member-person-select")
    |> refute_has("#add-member-button")
    |> assert_has("#members[aria-label='Members']")
    |> refute_has("#new-message-form")
    |> refute_has("#message-sender-select")
    |> refute_has("#message-subject-input")
    |> refute_has("#message-body-input")
    |> refute_has("#send-message-button")
    |> assert_has("#club-messaging-card")
    |> assert_has("#club-messages-link[aria-label='Open global Messages']")
    |> assert_has("#club-messages-link[href='/admin/messages']")
    |> refute_has("#messages")
    |> refute_has("[data-testid='message-row']")
    |> create_person("Alice")
    |> assert_has("#people [data-testid='person-row'][data-person-name='Alice']")
    |> add_member("Alice")
    |> assert_has("#members [data-testid='member-row'][data-member-name='Alice']")
    |> project_club_message("Alice", "Trip planning night", "Bring route ideas.")
    |> click_link("Open global Messages")
    |> assert_path("/admin/messages")
    |> assert_has("#admin-messages-index")
    |> assert_has(
      "#admin-messages-table-body [data-testid='admin-message-row'][data-message-subject='Trip planning night']"
    )
    |> click_link("Open diagnostics")
    |> assert_path("/admin/messages/*")
    |> assert_has("#message-show")
    |> assert_has("#back-to-club-link[aria-label='Back to club']")
    |> assert_has("#back-to-club-link[href^='/admin/clubs/']")
    |> assert_has("#addressed-recipients[aria-label='Addressed recipients']")
    |> assert_has(
      "#addressed-recipients [data-testid='addressed-recipient'][data-recipient-name='Alice']"
    )
    |> assert_has("#delivery-records[aria-label='Email deliveries']")
    |> assert_has(
      "#delivery-records [data-testid='delivery-record'][data-recipient-name='Alice']"
    )
    |> assert_has(
      "#delivery-records [data-testid='delivery-status'][data-delivery-status='pending']"
    )
    |> assert_has("#member-receipts[aria-label='Member email delivery statuses']")
    |> assert_has("#member-receipts [data-testid='member-receipt'][data-recipient-name='Alice']")
    |> assert_has("#member-receipts [data-testid='receipt-status'][data-receipt-status='sent']")
  end

  test "staff can open a club home page from the staff club page", %{conn: conn} do
    conn
    |> sign_in_staff()
    |> visit("/admin/clubs")
    |> create_club("Kootenay Mountaineering Club")
    |> click_link("Kootenay Mountaineering Club")
    |> assert_path("/admin/clubs/*")
    |> click_link("Open club home page")
    |> assert_has("#public-club-page-page", "Welcome to Kootenay Mountaineering Club")
    |> assert_has("#public-club-page-sign-in-link[href='/auth']")
    |> refute_has("#member-club-home")
  end

  test "developers can use browser routes to inspect an existing club message to active members",
       %{
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
    |> project_club_message("Alice", "Trip planning night", "Bring route ideas.")
    |> click_link("Open global Messages")
    |> assert_path("/admin/messages")
    |> assert_has(
      "#admin-messages-table-body [data-testid='admin-message-row'][data-message-subject='Trip planning night']"
    )
    |> click_link("Open diagnostics")
    |> assert_path("/admin/messages/*")
    |> assert_has("#message-show", "Trip planning night")
    |> assert_addressed_recipient("Alice")
    |> assert_addressed_recipient("Bob")
    |> assert_addressed_recipient("Carol")
    |> refute_has("#addressed-recipients [data-testid='addressed-recipient']", "Pat")
    |> assert_has("#delivery-records [data-testid='delivery-record']", count: 3)
    |> assert_has("#member-receipts [data-testid='member-receipt']", count: 3)
    |> assert_member_email_delivery("Alice", "sent")
    |> assert_member_email_delivery("Bob", "sent")
    |> assert_member_email_delivery("Carol", "sent")
  end

  test "member email delivery statuses refresh after delivery status reports are invoked", %{
    conn: conn
  } do
    %{message_id: message_id, recipients: recipients} =
      send_projected_message_with_recipients(["Alice", "Bob", "Carol", "Dana", "Erin", "Frank"])

    delivery_ids_by_name = Map.new(recipients, &{&1.name, &1.delivery_id})

    session =
      conn
      |> sign_in_staff()
      |> visit("/admin/messages/#{message_id}")
      |> assert_path("/admin/messages/*")
      |> assert_has("#message-show", "Trip planning night")
      |> assert_member_email_delivery("Alice", "sent")

    assert :ok =
             report_email_delivery_delivered(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Bob"]
             })

    assert :ok =
             report_email_delivery_delayed(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Carol"],
               reason: "recipient server is temporarily unavailable"
             })

    assert :ok =
             report_email_delivery_bounced(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Dana"],
               reason: "mailbox does not exist"
             })

    assert :ok =
             report_email_delivery_spam_complaint(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Erin"],
               reason: "recipient marked the message as spam"
             })

    assert :ok =
             report_email_delivery_delivered(%{
               message_id: message_id,
               delivery_id: delivery_ids_by_name["Frank"]
             })

    assert_eventually(fn ->
      session
      |> assert_member_email_delivery("Alice", "sent")
      |> assert_member_email_delivery("Bob", "delivered")
      |> assert_member_email_delivery("Carol", "delivery problem")
      |> assert_member_email_delivery("Dana", "delivery problem")
      |> assert_member_email_delivery("Erin", "delivery problem")
      |> assert_member_email_delivery("Frank", "delivered")
    end)
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
    current_path = PhoenixTest.Driver.current_path(session)
    email = email_for(name)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: Memba.ID.generate(:person),
                 name: name,
                 email: email,
                 email_addresses: [%{email: email, is_primary: true}]
               },
               consistency: :strong
             )

    session
    |> visit(current_path)
    |> assert_has("#people [data-testid='person-row']", name)
  end

  defp add_member(session, name) do
    current_path = PhoenixTest.Driver.current_path(session)
    club_id = current_path |> String.split("/", trim: true) |> List.last()
    person = Membership.get_person_by_email(email_for(name))

    assert person

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    session
    |> visit(current_path)
    |> assert_has("#members [data-testid='member-row']", name)
  end

  defp project_club_message(session, sender_name, subject, body) do
    current_path = PhoenixTest.Driver.current_path(session)
    club_id = current_path |> String.split("/", trim: true) |> List.last()

    sender =
      club_id
      |> Membership.list_active_members_of_club()
      |> Enum.find(&(&1.name == sender_name))

    assert sender

    result =
      Messaging.send_club_message(
        %{
          message_id: Memba.ID.generate(:message),
          club_id: club_id,
          sender_id: sender.id,
          subject: subject,
          body: body
        },
        consistency: :strong
      )

    assert result == :ok or match?({:ok, _result}, result)

    session
    |> visit(current_path)
    |> assert_has("#club-messages-link[href='/admin/messages']")
    |> refute_has("#messages [data-testid='message-row']", subject)
  end

  defp assert_addressed_recipient(session, name) do
    assert_has(session, "#addressed-recipients [data-recipient-name='#{name}']", name)
  end

  defp assert_member_email_delivery(session, name, status) do
    assert_has(session, "#member-receipts [data-recipient-name='#{name}']", status)
  end

  defp report_email_delivery_delivered(attrs) do
    apply(Messaging, :report_email_delivery_delivered, [attrs, [consistency: :strong]])
  end

  defp report_email_delivery_delayed(attrs) do
    apply(Messaging, :report_email_delivery_delayed, [attrs, [consistency: :strong]])
  end

  defp report_email_delivery_bounced(attrs) do
    apply(Messaging, :report_email_delivery_bounced, [attrs, [consistency: :strong]])
  end

  defp report_email_delivery_spam_complaint(attrs) do
    apply(Messaging, :report_email_delivery_spam_complaint, [attrs, [consistency: :strong]])
  end

  defp send_projected_message_with_recipients(names) do
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
