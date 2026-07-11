defmodule MembaWeb.MemberDashboardLiveTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Role
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.MemberDashboardPresentation
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "routed club home renders signed-in active members through the dashboard LiveView", %{
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
      create_message(club_id: alice.club_id, sender_id: bob.person_id, subject: "Trip night")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#member-club-home[data-live-view='member-dashboard'][data-club-id='#{alice.club_id}']"
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

    assert has_element?(view, "#member-message-#{message.message_id}")
    assert has_element?(view, "#club-member-#{alice.person_id}")
    assert has_element?(view, "#club-member-#{bob.person_id}")
  end

  test "routed dashboard member sections render only the compact member app footer" do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    for path <- [~p"/conversations", ~p"/members"] do
      response =
        build_conn()
        |> signed_in_club_host("alice@example.com", alice)
        |> get(path)
        |> html_response(200)

      document = LazyHTML.from_fragment(response)

      assert document
             |> LazyHTML.query("#club-site-footer.app-foot")
             |> Enum.any?()

      assert document
             |> LazyHTML.query("footer")
             |> Enum.count() == 1

      refute response =~ "Red Donkey Technology Corp"
      refute response =~ "Footer navigation"
    end
  end

  test "dashboard renders the section tab spine with conversations selected by default", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(view, "#member-section-tabs.section-tabs")
    assert has_element?(view, "#member-section-tabs-list[role='tablist']")

    assert has_element?(
             view,
             "#member-section-tab-conversations.section-tab.is-active" <>
               "[data-tab='conversations'][role='tab'][aria-selected='true']" <>
               "[aria-controls='member-section-panel-conversations']",
             "Conversations"
           )

    assert has_element?(
             view,
             "#member-section-tab-members.section-tab" <>
               "[data-tab='members'][role='tab'][aria-selected='false']" <>
               "[aria-controls='member-section-panel-members']",
             "Members"
           )

    assert has_element?(
             view,
             "#member-section-panel-conversations.section-panel[data-panel='conversations']" <>
               "[role='tabpanel'][aria-labelledby='member-section-tab-conversations']"
           )

    refute has_element?(view, "#member-section-panel-conversations[hidden]")

    assert has_element?(
             view,
             "#member-section-panel-members.section-panel[data-panel='members']" <>
               "[role='tabpanel'][aria-labelledby='member-section-tab-members'][hidden]"
           )

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-new-message.btn.btn-primary.btn-sm" <>
               "[data-section-action='conversations'][href='/messages/new']",
             "New message"
           )

    refute has_element?(view, "#member-section-action-new-message[hidden]")
    refute has_element?(view, "#member-section-action-new-message[data-section-action='members']")
    refute has_element?(view, "#member-dashboard-cta")
    refute has_element?(view, "#member-send-message-link")
  end

  test "dashboard section tabs are LiveView patch links with push-state URLs" do
    html = dashboard_html(%{current_member_can_manage_members?: true})

    assert html_has_selector?(
             html,
             "#member-section-tab-conversations[href='/conversations'][data-phx-link='patch']" <>
               "[data-phx-link-state='push']"
           )

    assert html_has_selector?(
             html,
             "#member-section-tab-members[href='/members'][data-phx-link='patch']" <>
               "[data-phx-link-state='push']"
           )

    refute html_has_selector?(html, "#member-section-tab-conversations[phx-click]")
    refute html_has_selector?(html, "#member-section-tab-members[phx-click]")
  end

  test "club template renders named member rows with current marker and a single members action" do
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)

    members = [
      %{id: alice_id, name: "Alice Adams", initials: "AA"},
      %{id: bob_id, name: "Bob Builder", initials: "BB"}
    ]

    html =
      dashboard_html(%{
        active_section: "members",
        current_member: %{id: alice_id, name: "Alice Adams"},
        current_member_can_manage_members?: true,
        members: members,
        active_member_count: 2
      })

    refute html_has_selector?(html, "#member-section-panel-members[hidden]")

    assert html_has_selector?(
             html,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute html_has_selector?(html, "#club-members h2", "Current members")
    refute html_has_selector?(html, "#club-members #member-invite-member-link")
    assert invite_member_action_count(html) == 1

    assert html_has_selector?(
             html,
             "#active-members-list.member-list[data-active-member-count='2']" <>
               "[data-active-members-state='active-members']"
           )

    refute html_has_selector?(html, "#active-members-list [data-member-name]")

    assert_rendered_member_row(html, alice_id,
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )

    assert_rendered_member_row(html, bob_id,
      name: "Bob Builder",
      initials: "BB",
      current?: false
    )

    refute html_has_selector?(html, "#active-members-empty-state")
    refute html_has_selector?(html, "#active-members-avatar-stack")

    first_member_html =
      dashboard_html(%{
        active_section: "members",
        current_member: %{id: alice_id, name: "Alice Adams"},
        current_member_can_manage_members?: true,
        members: [hd(members)],
        active_member_count: 1
      })

    assert html_has_selector?(
             first_member_html,
             "#active-members-list.member-list[data-active-member-count='1']" <>
               "[data-active-members-state='first-member'] #active-members-empty-state",
             "You’re the first member listed"
           )

    assert html_has_selector?(
             first_member_html,
             "#active-members-empty-state",
             "As members are added, you’ll see them here."
           )

    refute html_has_selector?(first_member_html, "#active-members-list [data-member-name]")

    assert_rendered_member_row(first_member_html, alice_id,
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )

    ordinary_member_html =
      dashboard_html(%{
        active_section: "members",
        current_member: %{id: alice_id, name: "Alice Adams"},
        current_member_can_manage_members?: false,
        members: [hd(members)],
        active_member_count: 1
      })

    refute html_has_selector?(ordinary_member_html, "#member-section-action-invite-member")
    refute html_has_selector?(ordinary_member_html, "#club-members #member-invite-member-link")

    assert html_has_selector?(
             ordinary_member_html,
             "#active-members-empty-state",
             "You’re the first member listed"
           )
  end

  test "dashboard patching to members selects the members URL state", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    grant_manage_members!(alice)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    view
    |> element("#member-section-tab-members")
    |> render_click()

    assert_patch(view, ~p"/members")

    assert has_element?(
             view,
             "#member-section-tab-members.section-tab.is-active" <>
               "[aria-selected='true'][aria-controls='member-section-panel-members']"
           )

    assert has_element?(
             view,
             "#member-section-tab-conversations.section-tab" <>
               "[aria-selected='false'][aria-controls='member-section-panel-conversations']"
           )

    assert has_element?(view, "#member-section-panel-conversations[hidden]")
    refute has_element?(view, "#member-section-panel-members[hidden]")

    assert has_element?(
             view,
             "#member-section-action-invite-member" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute has_element?(view, "#member-section-action-new-message")
  end

  test "dashboard renders conversations in the default visible section panel", %{
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
        subject: "Trip planning night",
        body:
          "Route update — the forestry service closed the approach road after last week's storm, so the original plan is off."
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#member-section-panel-conversations.section-panel[data-panel='conversations']"
           )

    refute has_element?(view, "#member-section-panel-conversations[hidden]")
    assert has_element?(view, "#member-section-panel-members[hidden]")

    refute has_element?(
             view,
             "#member-section-panel-conversations #club-messages h2",
             "Recent club messages"
           )

    assert has_element?(
             view,
             "#member-section-panel-conversations #club-messages #member-message-list " <>
               "#member-message-#{message.message_id}[data-testid='club-message-row'][data-message-subject='Trip planning night']"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} " <>
               "[data-testid='message-body-preview'].conversation__preview",
             "Route update — the forestry service closed the approach road after last week's storm, so the original plan is off."
           )

    refute has_element?(view, "#member-section-panel-conversations #member-message-list-empty")
  end

  test "dashboard renders the empty conversation state inside the default panel", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#member-section-panel-conversations.section-panel[data-panel='conversations'] " <>
               "#member-message-list-empty",
             "No club messages yet"
           )
  end

  test "dashboard conversation rows use design-system classes and render participant avatar stacks" do
    message_id = Memba.ID.generate(:message)
    originator_id = Memba.ID.generate(:person)
    carol_id = Memba.ID.generate(:person)
    dana_id = Memba.ID.generate(:person)
    elliot_id = Memba.ID.generate(:person)

    html =
      dashboard_html(%{
        message_rows: [
          %{
            message_id: message_id,
            originator_id: originator_id,
            originator_name: "Bob Builder",
            originator_initials: "BB",
            subject: "Weekend conditions",
            body: "Trail is clear to the lake, with snow above the pass.",
            sent_at_label: "Jun 03, 2026",
            reply_count: 5,
            latest_replier_id: elliot_id,
            latest_replier_name: "Elliot Explorer",
            reply_activity_label: "5 replies · latest from Elliot Explorer",
            participants: [
              %{id: carol_id, name: "Carol Canoe", initials: "CC"},
              %{id: dana_id, name: "Dana Downhill", initials: "DD"},
              %{id: elliot_id, name: "Elliot Explorer", initials: "EE"}
            ],
            additional_participant_count: 2
          }
        ]
      })

    row_selector = "#member-message-#{message_id}[data-testid='club-message-row']"
    link_selector = "#{row_selector} [data-testid='club-message-link'].conversation"

    assert html_has_selector?(html, "#member-message-list.conversation-list")
    assert html_has_selector?(html, "#{link_selector}[href='/messages/#{message_id}']")

    assert html_has_selector?(
             html,
             "#{link_selector} [data-testid='message-originator-initials']" <>
               ".conversation__avatar.avatar.avatar-placeholder",
             "BB"
           )

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__body .conversation__head .conversation__subject",
             "Weekend conditions"
           )

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__date[data-testid='message-sent-at']",
             "Jun 03, 2026"
           )

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__preview[data-testid='message-body-preview']",
             "Trail is clear to the lake"
           )

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__participants " <>
               ".avatar-stack[data-testid='message-participant-avatar-stack'] " <>
               "[data-testid='message-participant-avatar'][data-participant-id='#{carol_id}']" <>
               "[data-participant-name='Carol Canoe'].avatar.avatar-placeholder",
             "CC"
           )

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__participants " <>
               ".avatar-stack [data-testid='message-participant-overflow'].is-more",
             "+2"
           )

    assert participant_avatar_names(html, message_id) == [
             "Carol Canoe",
             "Dana Downhill",
             "Elliot Explorer"
           ]

    assert html_has_selector?(
             html,
             "#{link_selector} .conversation__replies[data-testid='message-reply-activity']" <>
               "[data-reply-count='5'][data-latest-replier-id='#{elliot_id}']" <>
               "[data-latest-replier-name='Elliot Explorer']",
             "5 replies · latest from Elliot Explorer"
           )
  end

  test "dashboard renders member content inside the hidden members section panel", %{
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

    grant_manage_members!(alice)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#member-section-panel-members.section-panel[data-panel='members'][hidden]"
           )

    refute has_element?(view, "#member-section-panel-members #club-members h2", "Current members")

    refute has_element?(
             view,
             "#member-section-panel-members #club-members #member-invite-member-link"
           )

    assert has_element?(
             view,
             "#member-section-panel-members " <>
               "#active-members-list.member-list[data-active-member-count='2'][data-active-members-state='active-members']"
           )

    refute has_element?(view, "#member-section-panel-members #active-members-card")

    assert_live_member_row(view, alice.person_id,
      scope: "#member-section-panel-members #active-members-list",
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )

    assert_live_member_row(view, bob.person_id,
      scope: "#member-section-panel-members #active-members-list",
      name: "Bob Builder",
      initials: "BB",
      current?: false
    )
  end

  test "dashboard renders member role badges and omits removed members", %{conn: conn} do
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
      create_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_name: "Alpine Club",
        club_id: alice.club_id,
        active: false
      )

    chair_role = create_role(club_id: alice.club_id, role_key: "chair", name: "Chair")
    secretary_role = create_role(club_id: alice.club_id, role_key: "secretary", name: "Secretary")
    treasurer_role = create_role(club_id: alice.club_id, role_key: "treasurer", name: "Treasurer")

    assign_role(bob, treasurer_role)
    assign_role(bob, chair_role)
    assign_role(carol, secretary_role)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/members")

    bob_role_selector =
      "#club-member-#{bob.person_id} .member-row__role.badge.badge-primary.badge-soft"

    assert has_element?(view, bob_role_selector, "Chair")
    assert has_element?(view, bob_role_selector, "Treasurer")
    assert role_badge_labels(render(view), bob.person_id) == ["Chair", "Treasurer"]

    refute has_element?(view, "#club-member-#{alice.person_id} .member-row__role")
    refute has_element?(view, "#club-member-#{carol.person_id}")
    refute has_element?(view, ".member-row__role", "Secretary")
  end

  test "dashboard renders the members tab invite action only for members who can manage members",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, admin_view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members")

    assert has_element?(
             admin_view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute has_element?(admin_view, "#club-members #member-invite-member-link")
    assert invite_member_action_count(render(admin_view)) == 1

    refute has_element?(
             admin_view,
             "#member-section-action-invite-member[data-section-action='conversations']"
           )

    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    {:ok, member_view, _html} =
      build_conn()
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    refute has_element?(
             member_view,
             "#member-section-tabs .section-tabs__action #member-section-action-invite-member"
           )
  end

  test "dashboard renders polished CTA, conversation rows, reply activity, and named member rows",
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

    sent_at = ~U[2026-05-30 12:00:00.000000Z]

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Trip night",
        inserted_at: sent_at
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "delivered"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "sent"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    refute has_element?(view, "#member-dashboard-hero")

    refute has_element?(view, "#member-dashboard-cta")
    refute has_element?(view, "#member-send-message-link")

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-new-message.btn.btn-primary.btn-sm[data-section-action='conversations'][href='/messages/new']",
             "New message"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='club-message-link'][href='/messages/#{message.message_id}']"
           )

    refute has_element?(view, "#member-message-list-empty")

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-originator-initials'].avatar.avatar-placeholder",
             "BB"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-started-by'][data-originator-id='#{bob.person_id}'][data-originator-name='Bob Builder']",
             "Started by Bob Builder"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-sent-at']",
             Calendar.strftime(sent_at, "%b %d, %Y")
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-reply-activity'][data-reply-count='0']",
             "No replies yet"
           )

    refute has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-participant-avatar-stack']"
           )

    refute has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-receipt-glance']"
           )

    refute has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-receipt-segment']"
           )

    assert has_element?(view, "#active-members-list.member-list[data-active-member-count='2']")
    assert has_element?(view, "#active-members-list[data-active-members-state='active-members']")
    refute has_element?(view, "#active-members-empty-state", "You’re the first member listed")

    assert_live_member_row(view, alice.person_id,
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )
  end

  test "dashboard renders larger member lists as named member rows without overflow",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    members =
      for index <- 2..8 do
        create_active_member(
          email: "member#{index}@example.com",
          name: "Member #{index}",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )
      end

    last_member = List.last(members)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(view, "#active-members-list.member-list[data-active-member-count='8']")

    assert_live_member_row(view, last_member.person_id,
      name: "Member 8",
      current?: false
    )

    refute has_element?(view, "#active-members-avatar-stack")
    refute has_element?(view, "#active-members-overflow-avatar")
    refute has_element?(view, "#active-members-empty-state")
  end

  test "dashboard exposes the members tab invite action to Membership Admins",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members")

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute has_element?(view, "#club-members #member-invite-member-link")
    assert invite_member_action_count(render(view)) == 1
  end

  test "club subdomain dashboard exposes the members tab invite action to Membership Admins without a club_id query",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "robin@example.com"})
      |> live(~p"/members")

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute has_element?(view, "#club-members #member-invite-member-link")
    refute has_element?(view, "#member-section-action-invite-member[href*='club_id=']")
    assert invite_member_action_count(render(view)) == 1
  end

  test "dashboard keeps the member invite action hidden from ordinary members", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    refute has_element?(view, "#club-members #member-invite-member-link")
  end

  test "dashboard preserves the members empty state and invite actions for first-member admins",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members")

    refute has_element?(view, "#member-section-panel-members[hidden]")

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
               "[data-section-action='members'][href='/members/invitations/new']",
             "Invite member"
           )

    refute has_element?(view, "#member-section-panel-members #club-members h2", "Current members")

    refute has_element?(
             view,
             "#member-section-panel-members #club-members #member-invite-member-link"
           )

    assert invite_member_action_count(render(view)) == 1

    assert has_element?(
             view,
             "#member-section-panel-members " <>
               "#active-members-list.member-list[data-active-member-count='1']" <>
               "[data-active-members-state='first-member'] #active-members-empty-state",
             "You’re the first member listed"
           )

    assert has_element?(
             view,
             "#member-section-panel-members #active-members-list " <>
               "#club-member-#{robin.person_id}.member-row[data-testid='club-member-row'] " <>
               ".member-row__name",
             "Robin Rivers"
           )
  end

  test "club subdomain dashboard keeps the member invite action hidden from ordinary members",
       %{conn: conn} do
    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/conversations")

    refute has_element?(view, "#club-members #member-invite-member-link")
    refute has_element?(view, "#club-members a[href='/members/invitations/new']")
    refute has_element?(view, "#club-members a[href*='/members/invitations/new']")
  end

  test "dashboard conversation row shows reply activity and omits delivery glance",
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

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    dana =
      create_active_member(
        email: "dana@example.com",
        name: "Dana Downhill",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Weekend conditions"
      )

    reply =
      create_message(
        club_id: alice.club_id,
        sender_id: carol.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Weekend conditions",
        body: "Trail is clear."
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "delivered"
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
      recipient_name: "Carol Canoe",
      status: "sent"
    )

    dana_delivery_id =
      create_member_email_delivery(
        message_id: message.message_id,
        recipient_id: dana.person_id,
        recipient_name: "Dana Downhill",
        status: "delivery problem"
      ).delivery_id

    create_memba_staff_email_delivery(
      delivery_id: dana_delivery_id,
      message_id: message.message_id,
      recipient_id: dana.person_id,
      recipient_name: "Dana Downhill",
      recipient_address: "dana.operator@example.net",
      channel: "postmark-webhook",
      status: "bounced",
      reason: "SMTP 550 Mailbox full from ProviderEvent::Bounce"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    message_selector = "#member-message-#{message.message_id}"

    assert has_element?(
             view,
             "#{message_selector} [data-testid='club-message-link'][href='/messages/#{message.message_id}']"
           )

    refute has_element?(
             view,
             "#{message_selector} [data-testid='club-message-link'][href='/messages/#{reply.message_id}']"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-started-by'][data-originator-id='#{bob.person_id}']",
             "Started by Bob Builder"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-reply-activity'][data-reply-count='1'][data-latest-replier-id='#{carol.person_id}'][data-latest-replier-name='Carol Canoe']",
             "1 reply · latest from Carol Canoe"
           )

    refute has_element?(view, "#member-message-#{reply.message_id}")
    refute has_element?(view, "#{message_selector} [data-testid='message-receipt-glance']")
    refute has_element?(view, "#{message_selector} [data-testid='message-receipt-segment']")

    html = render(view)

    refute html =~ dana_delivery_id
    refute html =~ "2 of 4 delivered"
    refute html =~ "dana.operator@example.net"
    refute html =~ "postmark-webhook"
    refute html =~ "bounced"
    refute html =~ "SMTP 550 Mailbox full"
    refute html =~ "ProviderEvent::Bounce"
  end

  test "dashboard omits timestamp label when a message row has no inserted_at timestamp" do
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    message_id = Memba.ID.generate(:message)

    message = %Message{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: "Projection without timestamp",
      body: "Body",
      inserted_at: nil
    }

    assert [message_row] =
             MemberDashboardPresentation.present_message_rows([message], %{
               sender_id => "Bob Builder"
             })

    html =
      dashboard_html(%{
        selected_club: %{club_id: club_id, name: "Alpine Club"},
        message_rows: [message_row]
      })

    assert html_has_selector?(
             html,
             "#member-message-#{message_id}[data-testid='club-message-row']"
           )

    refute html_has_selector?(
             html,
             "#member-message-#{message_id} [data-testid='message-sent-at']"
           )
  end

  test "dashboard preserves browser acceptance selectors for messages and members", %{conn: conn} do
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
        sender_id: bob.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#member-club-home[data-club-id='#{alice.club_id}']"
           )

    assert has_element?(
             view,
             "#member-section-action-new-message.btn.btn-primary.btn-sm[href='/messages/new']",
             "New message"
           )

    assert has_element?(
             view,
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}'][data-message-subject='Trip planning night']"
           )

    assert has_element?(
             view,
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}'] " <>
               "[data-testid='club-message-link'][href='/messages/#{message.message_id}']"
           )

    assert_live_member_row(view, alice.person_id, name: "Alice Adams", current?: true)
    assert_live_member_row(view, bob.person_id, name: "Bob Builder", current?: false)
  end

  test "dashboard reaches compose through links instead of inline compose controls", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    refute has_element?(view, "#member-dashboard-cta")
    refute has_element?(view, "#member-send-message-link")

    assert has_element?(
             view,
             "#member-section-tabs .section-tabs__action " <>
               "#member-section-action-new-message.btn.btn-primary.btn-sm[href='/messages/new']",
             "New message"
           )

    refute has_element?(view, "form#member-message-form")
    refute has_element?(view, "form#member-message-compose-form")
    refute has_element?(view, "[phx-submit='send_message']")
    refute has_element?(view, "select#member-message-sender-select")
    refute has_element?(view, "input#member-message-subject-input")
    refute has_element?(view, "textarea#member-message-body-input")
    refute has_element?(view, "button#member-message-send-button")
  end

  test "dashboard omits the inbound email card from the conversations panel", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    refute has_element?(view, "#member-section-panel-conversations #member-dashboard-inbound-email")
    refute has_element?(view, "#member-dashboard-cta #member-dashboard-inbound-email")
    refute has_element?(view, "#member-dashboard-inbound-email", "Prefer email?")
    refute has_element?(view, "#member-dashboard-inbound-email", "You can also send a club-wide message to")
    refute has_element?(view, "#member-dashboard-inbound-email-link")

    refute has_element?(
             view,
             "#member-dashboard-inbound-email[data-inbound-address='kmc@clubs.memba.io']"
           )

    refute has_element?(
             view,
             "#member-dashboard-inbound-email-link[href='mailto:kmc@clubs.memba.io']"
           )
  end

  test "dashboard renders a designed empty message state with a compose action", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(view, "#member-message-list-empty", "No club messages yet")

    assert has_element?(
             view,
             "#member-message-empty-send-link.btn.btn-soft[href='/messages/new']",
             "Send the first message"
           )
  end

  test "dashboard renders first-member active-member copy only when current member is alone",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#active-members-list.member-list[data-active-member-count='1'][data-active-members-state='first-member']"
           )

    assert has_element?(view, "#active-members-empty-state", "You’re the first member listed")

    assert has_element?(
             view,
             "#active-members-empty-state",
             "As members are added, you’ll see them here."
           )

    assert_live_member_row(view, alice.person_id,
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )

    refute has_element?(
             view,
             "#active-members-card-copy",
             "Memba sends club-wide messages to everyone with a current membership."
           )
  end

  test "dashboard renders every active member as a named row",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    members =
      for index <- 2..7 do
        create_active_member(
          email: "member#{index}@example.com",
          name: "Member #{index}",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )
      end

    last_member = List.last(members)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/conversations")

    assert has_element?(
             view,
             "#active-members-list.member-list[data-active-member-count='7'][data-active-members-state='active-members']"
           )

    assert_live_member_row(view, alice.person_id,
      name: "Alice Adams",
      initials: "AA",
      current?: true
    )

    assert_live_member_row(view, last_member.person_id,
      name: "Member 7",
      current?: false
    )

    refute has_element?(view, "#active-members-avatar-stack")
    refute has_element?(view, "#active-members-overflow-avatar")
  end

  test "logged-out club home still renders the public club page", %{conn: conn} do
    club = create_club(name: "Alpine Club")

    conn =
      conn
      |> club_host(club)
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-club-home[data-live-view='member-dashboard']")
           |> Enum.any?()
  end

  test "signed-in identities outside the selected club see the public club page", %{conn: conn} do
    alice = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    conn =
      conn
      |> club_host(alice)
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/")

    assert html_response(conn, 200) =~ "Welcome to Alpine Club"
  end

  test "signed-in inactive members of the selected club see the public club page", %{conn: conn} do
    inactive_alice =
      create_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club",
        active: false
      )

    conn =
      conn
      |> club_host(inactive_alice)
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/")

    assert html_response(conn, 200) =~ "Welcome to Alpine Club"
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    attrs
    |> Keyword.put(:active, true)
    |> create_member()
  end

  defp create_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

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

    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%Membership{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: Keyword.get(attrs, :active, true)
    })

    %{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person.person_id
    }
  end

  defp grant_manage_members!(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp create_role(attrs) do
    Repo.insert!(%Role{
      role_id: Memba.ID.generate(:role),
      club_id: Keyword.fetch!(attrs, :club_id),
      role_key: Keyword.fetch!(attrs, :role_key),
      name: Keyword.fetch!(attrs, :name)
    })
  end

  defp assign_role(member, role) do
    Repo.insert!(%RoleAssignment{
      club_id: role.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      role_id: role.role_id,
      active: true
    })
  end

  defp club_attrs(attrs, club_id, club_name) do
    base = [
      club_id: club_id,
      name: club_name
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end

  defp create_message(attrs) do
    inserted_at = Keyword.get_lazy(attrs, :inserted_at, &DateTime.utc_now/0)
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%Message{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body"),
      inserted_at: inserted_at,
      updated_at: inserted_at
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

  defp create_memba_staff_email_delivery(attrs) do
    Repo.insert!(%MembaStaffEmailDelivery{
      delivery_id: Keyword.fetch!(attrs, :delivery_id),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      recipient_address: Keyword.fetch!(attrs, :recipient_address),
      channel: Keyword.fetch!(attrs, :channel),
      status: Keyword.fetch!(attrs, :status),
      reason: Keyword.fetch!(attrs, :reason)
    })
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

  defp dashboard_html(assigns) do
    %{
      flash: %{},
      current_identity: %{email: "alice@example.com"},
      selected_club: %{club_id: Memba.ID.generate(:club), name: "Alpine Club"},
      current_member: %{name: "Alice Adams"},
      current_member_can_manage_members?: false,
      active_section: "conversations",
      club_id_source: "host",
      members: [],
      active_member_count: 0,
      message_rows: []
    }
    |> Map.merge(assigns)
    |> MembaWeb.PageHTML.club()
    |> rendered_to_string()
  end

  defp assert_rendered_member_row(html, member_id, opts) do
    name = Keyword.fetch!(opts, :name)
    selector = member_row_selector(member_id)

    assert html_has_selector?(html, "#{selector} .member-row__name", name)
    refute html_has_selector?(html, "#{selector}[data-member-name]")

    case Keyword.fetch(opts, :initials) do
      {:ok, initials} ->
        assert html_has_selector?(html, "#{selector} .member-row__avatar", initials)

      :error ->
        :ok
    end

    case Keyword.fetch(opts, :current?) do
      {:ok, current?} -> assert_rendered_current_member_state(html, selector, current?)
      :error -> :ok
    end
  end

  defp assert_rendered_current_member_state(html, selector, current?) do
    assert html_has_selector?(html, "#{selector}[data-current-member='#{to_string(current?)}']")

    if current? do
      assert html_has_selector?(
               html,
               "#{selector} .member-row__meta [data-testid='club-member-current-indicator']",
               "You"
             )
    else
      assert html_has_selector?(html, "#{selector} .member-row__meta")

      refute html_has_selector?(
               html,
               "#{selector} .member-row__meta [data-testid='club-member-current-indicator']"
             )
    end
  end

  defp assert_live_member_row(view, member_id, opts) do
    name = Keyword.fetch!(opts, :name)
    selector = scoped_member_row_selector(Keyword.get(opts, :scope), member_id)

    assert has_element?(view, "#{selector} .member-row__name", name)
    refute has_element?(view, "#{selector}[data-member-name]")

    case Keyword.fetch(opts, :initials) do
      {:ok, initials} -> assert has_element?(view, "#{selector} .member-row__avatar", initials)
      :error -> :ok
    end

    case Keyword.fetch(opts, :current?) do
      {:ok, current?} -> assert_live_current_member_state(view, selector, current?)
      :error -> :ok
    end
  end

  defp assert_live_current_member_state(view, selector, current?) do
    assert has_element?(view, "#{selector}[data-current-member='#{to_string(current?)}']")

    if current? do
      assert has_element?(
               view,
               "#{selector} .member-row__meta [data-testid='club-member-current-indicator']",
               "You"
             )
    else
      assert has_element?(view, "#{selector} .member-row__meta")

      refute has_element?(
               view,
               "#{selector} .member-row__meta [data-testid='club-member-current-indicator']"
             )
    end
  end

  defp scoped_member_row_selector(nil, member_id), do: member_row_selector(member_id)

  defp scoped_member_row_selector(scope, member_id) do
    "#{scope} #{member_row_selector(member_id)}"
  end

  defp role_badge_labels(html, member_id) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#{member_row_selector(member_id)} .member-row__role")
    |> Enum.map(fn role_badge -> role_badge |> LazyHTML.text() |> String.trim() end)
  end

  defp invite_member_action_count(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("a[href='/members/invitations/new']")
    |> Enum.count(fn action ->
      action
      |> LazyHTML.text()
      |> String.contains?("Invite member")
    end)
  end

  defp member_row_selector(member_id) do
    "#club-member-#{member_id}.member-row[data-testid='club-member-row']" <>
      "[data-member-id='#{member_id}']"
  end

  defp participant_avatar_names(html, message_id) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#member-message-#{message_id} [data-testid='message-participant-avatar']")
    |> LazyHTML.attribute("data-participant-name")
  end

  defp html_has_selector?(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> Enum.any?()
  end

  defp html_has_selector?(html, selector, text) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
    |> String.contains?(text)
  end
end
