defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth
  alias MembaWeb.MemberMessageDetail

  test "isolated message detail without route params fails instead of rendering stale shell", %{
    conn: conn
  } do
    assert_raise RuntimeError, ~r/requires a loaded message before rendering/, fn ->
      live_isolated(conn, MembaWeb.MemberMessageLive.Show)
    end
  end

  test "routed GET keeps the member message URL shape and passes club_id to the LiveView", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .app-bar__who",
             "Alice Adams"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .app-bar__avatar",
             "AA"
           )

    assert has_element?(
             view,
             "a#back-to-club-home-link[href='/conversations']",
             "All conversations"
           )
  end

  test "message detail applies the wireframe copy and footer decisions", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    response =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> get(~p"/messages/#{message.message_id}")
      |> html_response(200)

    document = LazyHTML.from_fragment(response)

    assert document
           |> LazyHTML.query("a#back-to-club-home-link[href='/conversations']")
           |> LazyHTML.text()
           |> normalize_whitespace() == "All conversations"

    assert document
           |> LazyHTML.query(
             "#member-message-reply-composer.composer > .composer__head > " <>
               "#member-message-reply-from.composer__as[data-sender-id='#{alice.person_id}']"
           )
           |> LazyHTML.text()
           |> normalize_whitespace() == "Replying as Alice Adams"

    refute response =~ "Your reply inherits the subject and is emailed to current followers except you."

    assert document
           |> LazyHTML.query("#club-site-footer.app-foot")
           |> Enum.any?()

    assert document
           |> LazyHTML.query("footer")
           |> Enum.count() == 1

    refute response =~ "Red Donkey Technology Corp"
    refute response =~ "Footer navigation"
  end

  test "club subdomain routed mount keeps the host-selected message after LiveView connects", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(
             view,
             "a#back-to-club-home-link[href='/conversations']",
             "All conversations"
           )

    refute has_element?(view, "a#back-to-club-home-link[href*='club_id=']")
  end

  test "routed message detail places the follow control beside the subject in the detail head", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-heading-row.detail-head > .detail-head__main " <>
               "h1#member-message-subject.page-title",
             "Trip planning night"
           )

    subject_class =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#member-message-subject")
      |> LazyHTML.attribute("class")
      |> List.first()

    refute subject_class =~ "text-[38px]"
    refute subject_class =~ "leading-[1.08]"
    refute subject_class =~ "tracking-[-0.032em]"
    refute subject_class =~ "text-4xl"
    refute subject_class =~ "sm:text-5xl"

    assert has_element?(
             view,
             "#member-message-heading-row.detail-head > " <>
               "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    refute has_element?(view, "#member-message-meta")
    refute has_element?(view, "#member-message-meta", "From Alice Adams")

    assert has_element?(view, "#member-conversation-follow-toggle[type='checkbox']")
    refute has_element?(view, "#member-conversation-follow-toggle[checked]")
    refute has_element?(view, "#member-conversation-follow-button")
    refute has_element?(view, "#member-conversation-unfollow-button")
  end

  test "current member changes follow state with the compact follow toggle", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    refute Messaging.following_conversation?(message.message_id, bob.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][phx-change='follow_conversation']"
           )

    refute has_element?(view, "#member-conversation-follow-toggle[checked]")

    view
    |> element("#member-conversation-follow-toggle")
    |> render_change()

    assert Messaging.following_conversation?(message.message_id, bob.person_id)

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='true'][data-can-follow='true']",
             "Following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][checked]" <>
               "[phx-change='unfollow_conversation']"
           )

    view
    |> element("#member-conversation-follow-toggle")
    |> render_change()

    refute Messaging.following_conversation?(message.message_id, bob.person_id)

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][phx-change='follow_conversation']"
           )

    refute has_element?(view, "#member-conversation-follow-toggle[checked]")
    refute has_element?(view, "#member-conversation-follow-button")
    refute has_element?(view, "#member-conversation-unfollow-button")
  end

  test "message detail shows the current-member follow explanation instead of a toggle when following is not allowed" do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    selected_club = Memba.Membership.get_club(alice.club_id)

    assert {:ok, detail_assigns} =
             MemberMessageDetail.load(
               %{"club_id" => alice.club_id, "message_id" => message.message_id},
               [selected_club],
               %{email: "guest@example.com"}
             )

    html =
      detail_assigns
      |> render_message_detail()
      |> LazyHTML.from_fragment()

    assert html
           |> LazyHTML.query(
             "#member-message-heading-row.detail-head > " <>
               "#member-conversation-follow-control" <>
               "[data-following='false'][data-can-follow='false']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#member-conversation-follow-copy")
           |> LazyHTML.text() =~
             "Only current club members can follow this conversation in Memba."

    refute html
           |> LazyHTML.query("#member-conversation-follow-toggle")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("[phx-change='follow_conversation']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-conversation-follow-button")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-conversation-unfollow-button")
           |> Enum.any?()
  end

  test "routed message detail renders the conversation and inline reply composer", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Clark",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps.",
        inserted_at: ~U[2026-06-03 07:02:00.000000Z]
      )

    first_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I'll bring snacks.",
        inserted_at: ~U[2026-06-03 08:15:00.000000Z]
      )

    second_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: carol.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I can drive.",
        inserted_at: ~U[2026-06-03 09:30:00.000000Z]
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(view, "#member-conversation[data-message-count='3']")

    refute has_element?(view, "[data-testid='member-conversation-entry-label']")

    refute has_element?(
             view,
             "[data-testid='member-conversation-entry-label']",
             "Original message"
           )

    refute has_element?(view, "[data-testid='member-conversation-entry-label']", "Reply")

    assert has_element?(
             view,
             "#member-conversation-original " <>
               "#member-conversation-entry-#{message.message_id}" <>
               ".message.message--original" <>
               "[data-conversation-kind='original']" <>
               "[data-sender-id='#{alice.person_id}']",
              "Bring your maps."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id}.message.message--original > " <>
               ".message__avatar",
             "A"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id}.message.message--original > " <>
               ".message__body > .message__head > .message__name",
             "Alice Adams"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T07:02:00.000000Z']",
             "3 Jun, 7:02am"
           )

    assert has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{first_reply.message_id}" <>
               ".message" <>
               "[data-conversation-kind='reply']" <>
               "[data-sender-id='#{bob.person_id}']",
              "I'll bring snacks."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{first_reply.message_id}.message > " <>
               ".message__avatar",
             "B"
           )

    refute has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{first_reply.message_id}.message--original"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{first_reply.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T08:15:00.000000Z']",
             "3 Jun, 8:15am"
           )

    assert has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{second_reply.message_id}" <>
               ".message" <>
               "[data-conversation-kind='reply']" <>
               "[data-sender-id='#{carol.person_id}']",
             "I can drive."
           )

    refute has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{second_reply.message_id}.message--original"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{second_reply.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T09:30:00.000000Z']",
             "3 Jun, 9:30am"
           )

    html =
      view
      |> render()
      |> LazyHTML.from_fragment()

    conversation_child_ids =
      html
      |> LazyHTML.query("#member-conversation > *")
      |> LazyHTML.attribute("id")

    replies_index =
      Enum.find_index(conversation_child_ids, &(&1 == "member-conversation-replies"))

    composer_index =
      Enum.find_index(conversation_child_ids, &(&1 == "member-message-reply-composer"))

    assert replies_index < composer_index

    assert has_element?(
             view,
             "#member-message-reply-from[data-sender-id='#{bob.person_id}']",
             "Replying as Bob Builder"
           )

    assert has_element?(view, "#member-message-reply-composer.composer")

    assert has_element?(
             view,
             "#member-message-reply-composer.composer > .composer__head > .composer__title",
             "Reply to this conversation"
           )

    assert has_element?(
             view,
             "#member-message-reply-composer.composer > .composer__head > " <>
               "#member-message-reply-from.composer__as[data-sender-id='#{bob.person_id}']",
             "Replying as Bob Builder"
           )

    assert has_element?(
             view,
             "#member-message-reply-composer.composer " <>
               "#member-message-reply-form .composer__actions " <>
               "#member-message-reply-submit-button"
           )

    assert has_element?(view, "#member-message-reply-form[phx-submit='post_reply']")
    assert has_element?(view, "#member-message-reply-body-input")
    refute has_element?(view, "#member-message-reply-subject-input")
  end

  test "each conversation entry has a delivery details menu link for that message", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I'll bring snacks."
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    for entry_message <- [message, reply] do
      assert has_element?(
               view,
               "#member-conversation-entry-#{entry_message.message_id} " <>
                 "#member-conversation-entry-menu-#{entry_message.message_id}.message__menu"
             )

      assert has_element?(
               view,
               "#member-conversation-entry-#{entry_message.message_id} " <>
                 "#member-conversation-entry-menu-button-#{entry_message.message_id}" <>
                 ".message__kebab[aria-label='Message options']"
             )

      assert has_element?(
               view,
               "#member-conversation-entry-#{entry_message.message_id} " <>
                 "a#member-conversation-entry-delivery-link-#{entry_message.message_id}" <>
                 "[data-testid='member-conversation-entry-delivery-link']" <>
                 "[href='/messages/#{entry_message.message_id}/delivery']",
               "Delivery details"
             )
    end
  end

  test "blank reply body validation keeps the inline composer and does not post", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    view
    |> element("#member-message-reply-form")
    |> render_submit(%{"reply" => %{"body" => " \n\t "}})

    assert has_element?(view, "#member-message-detail[data-reply-state='composing']")
    assert has_element?(view, "#member-message-reply-body-error", "Reply body can’t be blank.")
    assert has_element?(view, "#member-message-reply-body-input")
    refute has_element?(view, "#member-message-reply-success")
    refute has_element?(view, "#member-message-reply-error")

    assert Enum.map(
             Memba.Messaging.list_conversation_messages(message.message_id),
             & &1.message_id
           ) == [
             message.message_id
           ]
  end

  test "routed message detail omits inline delivery summary and delivery status groups", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Clark",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "sent"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivered"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: carol.person_id,
      recipient_name: "Carol Clark",
      status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    refute has_element?(view, "#member-receipt-summary")
    refute has_element?(view, "#member-receipts-section")
    refute has_element?(view, "#member-receipts")
    refute has_element?(view, "[data-testid='member-receipt-summary-status']")
    refute has_element?(view, "[data-testid='member-receipt-summary-bar-segment']")
    refute has_element?(view, "[data-testid='member-receipt-group']")
    refute render(view) =~ ~r/sent to[\s\S]*3[\s\S]*members/
    refute render(view) =~ "Members by delivery status"
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    club = Memba.Membership.get_club(club.club_id) || club
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp render_message_detail(detail_assigns) do
    detail_assigns
    |> Map.merge(%{
      current_identity: %{email: "guest@example.com"},
      expanded_receipt_groups: MapSet.new(),
      flash: %{},
      reply_body_error: nil,
      reply_error: nil,
      reply_form: Phoenix.Component.to_form(%{}, as: :reply),
      reply_state: :composing,
      route_params: %{"club_id_source" => "host"}
    })
    |> MembaWeb.PageHTML.message()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        attrs
        |> club_attrs(club_id, club_name)
        |> insert_membership_club!()

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.get(attrs, :name, "Test Member"),
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person.person_id)
  end

  defp club_attrs(attrs, club_id, club_name) do
    base = [club_id: club_id, name: club_name]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end

  defp create_message(attrs) do
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%Message{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body"),
      inserted_at: Keyword.get(attrs, :inserted_at),
      updated_at: Keyword.get(attrs, :updated_at, Keyword.get(attrs, :inserted_at))
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      status: Keyword.fetch!(attrs, :status)
    })
  end

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
