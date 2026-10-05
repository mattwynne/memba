defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.EmailDeliveryDelayed
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
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
             "#club-site-identity-menu .app-menu__who-name",
             "Alice Adams"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .global-bar__avatar",
             "AA"
           )

    assert has_element?(
             view,
             "a#back-to-club-home-link[href='/conversations']",
             "All conversations"
           )

    refute has_element?(
             view,
             "a#back-to-club-home-link",
             "Club home"
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

    refute document
           |> LazyHTML.query("a#back-to-club-home-link")
           |> LazyHTML.text()
           |> normalize_whitespace() == "Club home"

    assert document
           |> LazyHTML.query(
             "#member-message-reply-composer.composer > .composer__head > " <>
               "#member-message-reply-from.composer__as[data-sender-id='#{alice.person_id}']"
           )
           |> LazyHTML.text()
           |> normalize_whitespace() == "Replying as Alice Adams"

    refute document
           |> LazyHTML.query("#member-message-reply-composer")
           |> LazyHTML.text()
           |> normalize_whitespace() =~
             "Your reply inherits the subject and is emailed to current followers except you."

    assert document
           |> LazyHTML.query("#club-site-footer.app-foot")
           |> Enum.any?()

    assert document
           |> LazyHTML.query("footer")
           |> Enum.count() == 1

    refute document
           |> LazyHTML.query("footer nav[aria-label='Footer navigation']")
           |> Enum.any?()

    refute document
           |> LazyHTML.query("footer a[href='/about']")
           |> Enum.any?()

    refute document
           |> LazyHTML.query("footer a[href='/terms']")
           |> Enum.any?()

    refute document
           |> LazyHTML.query("footer a[href='/privacy']")
           |> Enum.any?()

    refute document
           |> LazyHTML.query("footer a[href='mailto:hello@memba.io']")
           |> Enum.any?()

    refute response =~ "Red Donkey Technology Corp"
    refute response =~ "Footer navigation"
  end

  test "message detail preserves selected-group context in conversation and delivery links", %{
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

    group_id = Memba.ID.generate(:group)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}?#{[group_id: group_id]}")

    assert has_element?(
             view,
             "a#back-to-club-home-link[href='/groups/#{group_id}']",
             "All conversations"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-delivery-link-#{message.message_id}" <>
               "[href='/messages/#{message.message_id}/delivery?group_id=#{group_id}']",
             "Delivery details"
           )
  end

  test "an open message detail leaves the conversation after group membership is removed", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    private_group = create_group(alice.club_id, "Private Planning")
    add_group_member(private_group, alice)

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private planning details",
        body: "Bring the confidential route notes.",
        audience_group_id: private_group.group_id
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}?#{[group_id: private_group.group_id]}")

    assert has_element?(view, "#member-message-detail", "Private planning details")

    assert {:ok, _removal} =
             Memba.Membership.remove_custom_group_member(
               %{
                 club_id: alice.club_id,
                 group_id: private_group.group_id,
                 membership_id: alice.membership_id,
                 person_id: alice.person_id,
                 actor_person_id: alice.person_id,
                 removal_operation_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.GroupMembership,
      %Memba.Membership.Events.GroupMemberRemoved{
        club_id: alice.club_id,
        group_id: private_group.group_id,
        membership_id: alice.membership_id,
        person_id: alice.person_id
      }
    )

    assert_redirect(view, ~p"/groups/#{private_group.group_id}")
  end

  test "an open message detail leaves the conversation after its group access is revoked", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    private_group = create_group(alice.club_id, "Private Planning")
    add_group_member(private_group, alice)

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private planning details",
        audience_group_id: private_group.group_id
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}?#{[group_id: private_group.group_id]}")

    assert :ok =
             Messaging.revoke_conversation_access_from_group(
               %{
                 conversation_id: message.message_id,
                 club_id: alice.club_id,
                 group_id: private_group.group_id,
                 access_level: :write
               },
               consistency: :strong
             )

    notify_read_model_change(
      view,
      Memba.Messaging.Projectors.ConversationGroupAccess,
      %Memba.Messaging.Events.ConversationAccessRevokedFromGroup{
        conversation_id: message.message_id,
        club_id: alice.club_id,
        group_id: private_group.group_id,
        access_level: "write"
      }
    )

    assert_redirect(view, ~p"/groups/#{private_group.group_id}")
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
      create_authoritative_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_authoritative_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_authoritative_message(
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
               %{email: "alice@example.com"}
             )

    html =
      detail_assigns
      |> Map.put(:current_member, nil)
      |> Map.put(:can_follow_conversation, false)
      |> Map.put(:following_conversation, false)
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

  test "rendered message detail uses ported design-system classes for the title, entries, and composer",
       %{conn: conn} do
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
        body: "Bring your maps.",
        inserted_at: ~U[2026-06-03 07:02:00.000000Z]
      )

    reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I'll bring snacks.",
        inserted_at: ~U[2026-06-03 08:15:00.000000Z]
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-heading-row .detail-head__main > " <>
               "h1#member-message-subject.page-title",
             "Trip planning night"
           )

    assert has_element?(
             view,
             "#member-conversation-original > " <>
               "article#member-conversation-entry-#{message.message_id}" <>
               ".message.message--original[data-conversation-kind='original']" <>
               "[data-sender-id='#{alice.person_id}']"
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
             "#member-conversation-entry-#{message.message_id}.message.message--original " <>
               "time.message__time[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T07:02:00.000000Z']",
             "3 Jun, 7:02am"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id}.message.message--original " <>
               "p#member-message-body.message__text",
             "Bring your maps."
           )

    assert has_element?(
             view,
             "#member-conversation-replies > " <>
               "article#member-conversation-entry-#{reply.message_id}" <>
               ".message[data-conversation-kind='reply']" <>
               "[data-sender-id='#{bob.person_id}']"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message > " <>
               ".message__avatar",
             "B"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message > " <>
               ".message__body > .message__head > .message__name",
             "Bob Builder"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message " <>
               "time.message__time[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T08:15:00.000000Z']",
             "3 Jun, 8:15am"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message " <>
               "p#member-conversation-body-#{reply.message_id}.message__text",
             "I'll bring snacks."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message " <>
               "#member-conversation-entry-menu-#{reply.message_id}.context-menu " <>
               "#member-conversation-entry-menu-button-#{reply.message_id}.context-menu__button"
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{reply.message_id}.message " <>
               "#member-conversation-entry-menu-#{reply.message_id}.context-menu " <>
               ".context-menu__content"
           )

    assert has_element?(
             view,
             "#member-message-reply-composer.composer > .composer__head > h2.composer__title",
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
               "#member-message-reply-form .composer__actions > " <>
               "#member-message-reply-submit-button",
             "Post reply"
           )
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

    refute has_element?(
             view,
             "#member-message-reply-composer",
             "Your reply inherits the subject and is emailed to current followers except you."
           )

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
                 "details#member-conversation-entry-menu-#{entry_message.message_id}.context-menu"
             )

      assert has_element?(
               view,
               "#member-conversation-entry-#{entry_message.message_id} " <>
                 "summary#member-conversation-entry-menu-button-#{entry_message.message_id}" <>
                 ".context-menu__button[aria-label='Message options']" <>
                 "[aria-controls='member-conversation-entry-menu-#{entry_message.message_id}-content']"
             )

      refute has_element?(
               view,
               "#member-conversation-entry-menu-#{entry_message.message_id} [role='menu']"
             )

      refute has_element?(
               view,
               "#member-conversation-entry-menu-#{entry_message.message_id} [role='menuitem']"
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

  test "a committed reply enters an already-open conversation", %{conn: conn} do
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
        subject: "Open conversation"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(alice.email, alice)
      |> live(~p"/messages/#{message.message_id}")

    reply_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 "message_id" => reply_id,
                 "conversation_id" => message.message_id,
                 "sender_id" => bob.person_id,
                 "body" => "This arrived while the page stayed open."
               },
               consistency: :strong
             )

    assert has_element?(
             view,
             "#member-conversation[data-message-count='2'] " <>
               "#member-conversation-entry-#{reply_id}",
             "This arrived while the page stayed open."
           )
  end

  test "represented-author Person refresh is exact and replaces only the coherent result", %{
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
        subject: "Exact author refresh"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(bob.email, bob)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(view, "#member-conversation-entry-#{message.message_id}", "Alice Adams")

    alice.person_id
    |> then(&Repo.get!(Person, &1))
    |> Ecto.Changeset.change(name: "Alice Updated")
    |> Repo.update!()

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Person,
      %Memba.Membership.Events.PersonEmailAddressAdded{
        person_id: carol.person_id,
        email: carol.email,
        normalized_email: carol.email
      }
    )

    refute has_element?(
             view,
             "#member-conversation-entry-#{message.message_id}",
             "Alice Updated"
           )

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Person,
      %Memba.Membership.Events.PersonEmailAddressAdded{
        person_id: alice.person_id,
        email: alice.email,
        normalized_email: alice.email
      }
    )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id}",
             "Alice Updated"
           )

    %{socket: socket} = :sys.get_state(view.pid)
    assert is_map(socket.assigns.message_detail)
    refute Map.has_key?(socket.assigns, :message)
    refute Map.has_key?(socket.assigns, :selected_club)
    refute Map.has_key?(socket.assigns, :conversation_entries)
  end

  test "another club, conversation, message and delivery do not refresh the open result", %{
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

    other =
      create_active_member(
        email: "other@example.com",
        name: "Other Member",
        club_name: "Other Club",
        slug: "other-club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Scoped conversation"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(alice.email, alice)
      |> live(~p"/messages/#{message.message_id}")

    pending_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Scoped conversation",
        body: "Only an exact conversation invalidation should reveal me."
      )

    unrelated_message_id = Memba.ID.generate(:message)

    notify_read_model_change(
      view,
      Memba.Messaging.Projectors.Message,
      %MessageSent{
        message_id: unrelated_message_id,
        club_id: other.club_id,
        sender_id: other.person_id,
        conversation_id: unrelated_message_id,
        reply_to_message_id: nil,
        subject: "Other conversation",
        body: "Unrelated"
      }
    )

    notify_read_model_change(
      view,
      Memba.Messaging.Projectors.MemberEmailDelivery,
      %Memba.Messaging.Events.EmailDeliveryDelivered{
        message_id: unrelated_message_id,
        delivery_id: Memba.ID.generate(:delivery)
      }
    )

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Membership,
      %Memba.Membership.Events.ClubMemberAdded{
        club_id: other.club_id,
        membership_id: other.membership_id,
        person_id: other.person_id
      }
    )

    assert has_element?(view, "#member-conversation[data-message-count='1']")
    refute has_element?(view, "#member-conversation-entry-#{pending_reply.message_id}")

    notify_read_model_change(
      view,
      Memba.Messaging.Projectors.Message,
      %MessageSent{
        message_id: pending_reply.message_id,
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: pending_reply.subject,
        body: pending_reply.body
      }
    )

    assert has_element?(
             view,
             "#member-conversation[data-message-count='2'] " <>
               "#member-conversation-entry-#{pending_reply.message_id}"
           )
  end

  test "follow invalidation matches the exact current member", %{conn: conn} do
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
        subject: "Exact follow"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(alice.email, alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-conversation-follow-control[data-following='false']"
           )

    alice_follow =
      Messaging.get_conversation_follow(message.message_id, alice.person_id)
      |> Ecto.Changeset.change(following: true)
      |> Repo.update!()

    assert :ok =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: alice.club_id,
                 conversation_id: message.message_id,
                 member_id: bob.person_id
               },
               consistency: :strong
             )

    assert has_element?(
             view,
             "#member-conversation-follow-control[data-following='false']"
           )

    assert :ok =
             Memba.Messaging.Projectors.ConversationFollow.after_update(
               %ConversationFollowed{
                 follow_id: alice_follow.follow_id,
                 club_id: alice.club_id,
                 conversation_id: message.message_id,
                 member_id: alice.person_id
               },
               %{},
               %{messaging_conversation_follow: alice_follow}
             )

    assert has_element?(
             view,
             "#member-conversation-follow-control[data-following='true']"
           )
  end

  test "independent delivery commits converge in member-first and staff-first order", %{
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

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Delivery convergence"
      )

    member_first_id = Memba.ID.generate(:delivery)
    staff_first_id = Memba.ID.generate(:delivery)

    Repo.delete_all(
      from(delivery in MembaStaffEmailDelivery,
        where: delivery.message_id == ^message.message_id
      )
    )

    for {delivery_id, recipient_id, recipient_name} <- [
          {member_first_id, alice.person_id, "Alice Adams"},
          {staff_first_id, bob.person_id, "Bob Builder"}
        ] do
      create_member_email_delivery(
        delivery_id: delivery_id,
        message_id: message.message_id,
        recipient_id: recipient_id,
        recipient_name: recipient_name,
        status: "sent"
      )

      create_memba_staff_email_delivery(
        delivery_id: delivery_id,
        message_id: message.message_id,
        recipient_id: recipient_id,
        recipient_name: recipient_name,
        reason: nil
      )
    end

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(alice.email, alice)
      |> live(~p"/messages/#{message.message_id}")

    member_first_receipt =
      member_first_id
      |> Messaging.get_member_email_delivery()
      |> Ecto.Changeset.change(status: "delivery problem")
      |> Repo.update!()

    publish_delivery_change(
      Memba.Messaging.Projectors.MemberEmailDelivery,
      message.message_id,
      member_first_receipt,
      nil
    )

    assert %{status: "delivery problem", reason: nil} =
             live_receipt(view, alice.person_id)

    member_first_staff =
      member_first_id
      |> Messaging.get_memba_staff_email_delivery()
      |> Ecto.Changeset.change(status: "delayed", reason: "Mailbox temporarily unavailable")
      |> Repo.update!()

    publish_delivery_change(
      Memba.Messaging.Projectors.MembaStaffEmailDelivery,
      message.message_id,
      member_first_staff,
      member_first_staff.reason
    )

    assert %{status: "delivery problem", reason: "Mailbox temporarily unavailable"} =
             live_receipt(view, alice.person_id)

    staff_first =
      staff_first_id
      |> Messaging.get_memba_staff_email_delivery()
      |> Ecto.Changeset.change(status: "delayed", reason: "Provider retrying")
      |> Repo.update!()

    publish_delivery_change(
      Memba.Messaging.Projectors.MembaStaffEmailDelivery,
      message.message_id,
      staff_first,
      staff_first.reason
    )

    assert %{status: "sent", reason: "Provider retrying"} =
             live_receipt(view, bob.person_id)

    staff_first_receipt =
      staff_first_id
      |> Messaging.get_member_email_delivery()
      |> Ecto.Changeset.change(status: "delivery problem")
      |> Repo.update!()

    publish_delivery_change(
      Memba.Messaging.Projectors.MemberEmailDelivery,
      message.message_id,
      staff_first_receipt,
      nil
    )

    assert %{status: "delivery problem", reason: "Provider retrying"} =
             live_receipt(view, bob.person_id)

    refute has_element?(view, "#member-receipt-summary")
    refute has_element?(view, "#member-receipts-section")
  end

  test "relevant refresh preserves reply validation, route and disclosure state", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    private_group = create_group(alice.club_id, "Private Planning")
    add_group_member(private_group, alice)

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Preserve transient state",
        audience_group_id: private_group.group_id
      )

    {:ok, view, _html} =
      conn
      |> club_host(alice)
      |> init_test_session(%{
        IdentityAuth.identity_session_key() => alice.email,
        "phoenix_flash" => %{"info" => "Keep this feedback visible."}
      })
      |> live(~p"/messages/#{message.message_id}?#{[group_id: private_group.group_id]}")

    view
    |> element("#member-message-reply-form")
    |> render_submit(%{"reply" => %{"body" => "  "}})

    render_hook(view, "toggle_receipt_group", %{"status" => "delivered"})

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Person,
      %Memba.Membership.Events.PersonEmailAddressAdded{
        person_id: alice.person_id,
        email: alice.email,
        normalized_email: alice.email
      }
    )

    assert has_element?(view, "#member-message-detail[data-reply-state='composing']")
    assert has_element?(view, "#member-message-reply-body-error", "Reply body can’t be blank.")

    assert has_element?(
             view,
             "a#back-to-club-home-link[href='/groups/#{private_group.group_id}']"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-control[data-following='false']"
           )

    %{socket: socket} = :sys.get_state(view.pid)
    assert socket.assigns.reply_form.params == %{"body" => "  "}
    assert socket.assigns.reply_error == nil
    assert socket.assigns.route_params["group_id"] == private_group.group_id
    assert MapSet.member?(socket.assigns.expanded_receipt_groups, "delivered")
    assert Phoenix.Flash.get(socket.assigns.flash, :info) == "Keep this feedback visible."
  end

  test "fresh club-membership loss leaves an already-open private surface", %{conn: conn} do
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
        subject: "Membership-gated details"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(bob.email, alice)
      |> live(~p"/messages/#{message.message_id}")

    assert :ok =
             Memba.Membership.remove_member(
               %{membership_id: bob.membership_id},
               consistency: :strong
             )

    assert_redirect(view, ~p"/conversations")
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

  defp create_active_member(attrs), do: create_authoritative_active_member(attrs)

  defp create_authoritative_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)

    unless Memba.Membership.get_club(club_id) do
      assert :ok =
               Memba.Membership.create_club(
                 %{
                   club_id: club_id,
                   name: Keyword.fetch!(attrs, :club_name),
                   slug: Keyword.get(attrs, :slug, "alpine-club")
                 },
                 consistency: :strong
               )
    end

    assert :ok =
             Memba.Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.get(attrs, :name, "Test Member"),
                 email: Keyword.fetch!(attrs, :email)
               },
               consistency: :strong
             )

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Memba.Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    club_id
    |> Memba.Membership.get_club()
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
    |> Map.put(:membership_id, membership_id)
    |> Map.put(:email, Keyword.fetch!(attrs, :email))
  end

  defp create_group(club_id, name) do
    group_id = Memba.ID.generate(:group)
    actor = Repo.get_by!(Membership, club_id: club_id, active: true)

    assert :ok =
             Memba.Membership.create_custom_group(
               %{
                 group_id: group_id,
                 club_id: club_id,
                 actor_person_id: actor.person_id,
                 name: name
               },
               consistency: :strong
             )

    Repo.get!(Group, group_id)
  end

  defp add_group_member(group, member) do
    case Memba.Membership.add_custom_group_member(
           %{
             club_id: member.club_id,
             group_id: group.group_id,
             membership_id: member.membership_id,
             person_id: member.person_id,
             actor_person_id: member.person_id
           },
           consistency: :strong
         ) do
      {:ok, _admission} ->
        Repo.get_by!(GroupMembership, group_id: group.group_id, person_id: member.person_id)

      {:error, :already_active_group_member} ->
        Repo.get_by!(GroupMembership, group_id: group.group_id, person_id: member.person_id)
    end
  end

  defp notify_read_model_change(view, projector, source_event) do
    send(
      view.pid,
      {:read_model_changed,
       %{
         projector: projector,
         source_event: source_event,
         metadata: %{},
         changes: %{}
       }}
    )
  end

  defp create_message(attrs) do
    if Keyword.has_key?(attrs, :conversation_id) do
      insert_group_accessible_message!(attrs)
    else
      create_authoritative_message(attrs)
    end
  end

  defp create_authoritative_message(attrs) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message_as_current_member(
               %{
                 message_id: message_id,
                 club_id: Keyword.fetch!(attrs, :club_id),
                 sender_id: Keyword.fetch!(attrs, :sender_id),
                 audience_group_id:
                   Keyword.get_lazy(attrs, :audience_group_id, fn ->
                     SystemGroups.everyone_group_id(Keyword.fetch!(attrs, :club_id))
                   end),
                 subject: Keyword.fetch!(attrs, :subject),
                 body: Keyword.get(attrs, :body, "Message body")
               },
               consistency: :strong
             )

    :ok =
      Messaging.unfollow_conversation(
        %{
          club_id: Keyword.fetch!(attrs, :club_id),
          conversation_id: message_id,
          member_id: Keyword.fetch!(attrs, :sender_id)
        },
        consistency: :strong
      )

    Repo.delete_all(
      from(delivery in MemberEmailDelivery, where: delivery.message_id == ^message_id)
    )

    message = Messaging.get_message(message_id)

    case Keyword.fetch(attrs, :inserted_at) do
      {:ok, inserted_at} ->
        message |> Ecto.Changeset.change(inserted_at: inserted_at) |> Repo.update!()

      :error ->
        message
    end
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

  defp create_memba_staff_email_delivery(attrs) do
    Repo.insert!(%MembaStaffEmailDelivery{
      delivery_id: Keyword.fetch!(attrs, :delivery_id),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      recipient_address: "member@example.com",
      channel: "email",
      status: "sent",
      reason: Keyword.fetch!(attrs, :reason)
    })
  end

  defp publish_delivery_change(projector, message_id, delivery, reason) do
    assert :ok =
             projector.after_update(
               %EmailDeliveryDelayed{
                 message_id: message_id,
                 delivery_id: delivery.delivery_id,
                 reason: reason || "Member-facing delivery problem"
               },
               %{},
               %{delivery_change: delivery}
             )
  end

  defp live_receipt(view, recipient_id) do
    %{socket: socket} = :sys.get_state(view.pid)

    Enum.find(
      socket.assigns.message_detail.member_email_delivery_records,
      &(&1.recipient_id == recipient_id)
    )
  end

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
