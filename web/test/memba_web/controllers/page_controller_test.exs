defmodule MembaWeb.PageControllerTest do
  use MembaWeb.ConnCase

  import Swoosh.TestAssertions

  alias Memba.Accounts
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Onboarding.Request
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "A simpler way to keep your group members informed."
    assert response =~ "Kootenay Mountaineering Club"
    assert response =~ "Request access for your group"
    assert response =~ "See what members can do"
    refute response =~ "❤️"
    refute response =~ "rehearsal-room door"
    refute response =~ "One price, paid yearly."

    assert html |> LazyHTML.query("a[href='/get-started']") |> Enum.any?()
  end

  test "GET / presents sign-in links instead of Memba staff entry points", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query("nav[aria-label='Main navigation'] a[href='/auth']")
           |> Enum.empty?()

    assert html |> LazyHTML.query("header a[href='/auth']") |> Enum.any?()
    assert html |> LazyHTML.query("main a[href='/auth']") |> Enum.empty?()
    assert html |> LazyHTML.query("main a[href='/get-started']") |> Enum.any?()
    assert response =~ "Sign in"
    refute response =~ "Internal Memba staff"
    refute response =~ "Open internal Memba staff"
    refute response =~ ~s(href="/admin/clubs")
    refute response =~ ~s(href="/clubs")
  end

  test "GET / shows Your clubs with club subdomain links for signed-in members", %{conn: conn} do
    first_club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    second_club = create_active_member(email: "ALICE@example.com", club_name: "Bridge Club")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Your clubs"
    assert response =~ "You’re a member of 2 clubs"
    assert response =~ "Alpine Club"
    assert response =~ "Bridge Club"
    refute response =~ "A simpler way to keep your group members informed."

    for club <- [first_club, second_club] do
      assert html
             |> LazyHTML.query("a[data-testid='my-club-link'][href='#{ClubSite.url(club)}']")
             |> Enum.any?()

      refute html
             |> LazyHTML.query("a[data-testid='my-club-link']")
             |> LazyHTML.text()
             |> String.contains?(club.club_id)

      refute response =~ "club_id=#{club.club_id}"
    end

    refute html |> LazyHTML.query("a#admin-home-link") |> Enum.any?()

    assert html
           |> LazyHTML.query("form#home-sign-out-form[action='/auth'][method='post']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("form#home-sign-out-form input[name='_method'][value='delete']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("button#home-sign-out-button[type='submit']")
           |> Enum.any?()
  end

  test "GET / with a club_id shows a public public club page to logged-out visitors", %{
    conn: conn
  } do
    club = create_club(name: "Alpine Club")

    conn = get(conn, ~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Welcome to Alpine Club"

    assert response =~
             "Sign in with the email address Alpine Club has for you to read member messages"

    assert response =~ "Email me a sign-in link"

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    assert html |> LazyHTML.query("a#public-club-page-sign-in-link[href='/auth']") |> Enum.any?()
    refute response =~ "Send a club message"
    refute response =~ "Signed in as"
  end

  test "GET / with a club_id shows the public club page to signed-in staff who are not members",
       %{
         conn: conn
       } do
    club = create_club(name: "Alpine Club")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
      |> get(~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Welcome to Alpine Club"

    assert response =~
             "Sign in with the email address Alpine Club has for you to read member messages"

    assert response =~ "Email me a sign-in link"

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    refute response =~ "Send club message"
    refute response =~ "Signed in as pat@memba.io"
  end

  test "GET / on a public club subdomain shows that club public page", %{conn: conn} do
    club = create_club(name: "Kootenay Mountaineering Club", slug: "kmc")

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Welcome to Kootenay Mountaineering Club"

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()
  end

  test "GET / on an unknown public club subdomain returns not found", %{conn: conn} do
    _club = create_club(name: "Kootenay Mountaineering Club", slug: "kmc")

    conn =
      conn
      |> Map.put(:host, "unknown.lvh.me")
      |> get(~p"/")

    response = html_response(conn, 404)

    refute response =~ "Kootenay Mountaineering Club"
  end

  test "GET / on the smoke-test club subdomain returns not found for public visitors", %{
    conn: conn
  } do
    _club = create_club(name: "Smoke Test Club", slug: "test")

    conn =
      conn
      |> Map.put(:host, "test.lvh.me")
      |> get(~p"/")

    response = html_response(conn, 404)

    refute response =~ "Welcome to Smoke Test Club"
    refute response =~ "Email me a sign-in link"
  end

  test "GET / with the smoke-test club_id returns not found for public visitors", %{conn: conn} do
    club = create_club(name: "Smoke Test Club", slug: "test")

    conn = get(conn, ~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 404)

    refute response =~ "Welcome to Smoke Test Club"
  end

  test "GET / on the smoke-test club subdomain still shows the member dashboard to active members",
       %{conn: conn} do
    club = create_club(name: "Smoke Test Club", slug: "test")

    tester =
      create_active_member(
        email: "test@memba.io",
        name: "Smoke Tester",
        club_name: club.name,
        club_id: club.club_id
      )

    _message =
      create_message(club_id: club.club_id, sender_id: tester.person_id, subject: "Smoke test")

    conn =
      conn
      |> Map.put(:host, "test.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "test@memba.io"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Hello, Smoke."
    refute response =~ "Welcome to Smoke Test Club"

    assert html
           |> LazyHTML.query("#member-club-home[data-club-id='#{club.club_id}']")
           |> Enum.any?()
  end

  test "GET / with a member club_id opens a useful member club page", %{conn: conn} do
    club =
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
        club_id: club.club_id
      )

    message =
      create_message(club_id: club.club_id, sender_id: bob.person_id, subject: "Trip night")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Alpine Club"

    assert response =~
             "Read recent club messages, send a note to all current members, and see who is on the member list."

    assert response =~ "Send club message"
    assert response =~ "Recent club messages"
    assert response =~ "Current members"
    assert response =~ "2 current members"

    assert html
           |> LazyHTML.text()
           |> String.contains?(
             "Memba sends club-wide messages to everyone with a current membership."
           )

    assert html |> LazyHTML.query("#club-site-layout[data-surface='club-site']") |> Enum.any?()

    assert html
           |> LazyHTML.query("#club-site-current-identity")
           |> LazyHTML.text() =~ "Signed in as alice@example.com"

    assert html
           |> LazyHTML.query("form#club-site-sign-out-form[action='/auth'][method='post']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#club-site-layout header")
           |> LazyHTML.text()
           |> then(&(not String.contains?(&1, "Powered by Memba")))

    assert html
           |> LazyHTML.query("#club-site-layout footer")
           |> LazyHTML.text() =~ "Powered by Memba"

    assert html
           |> LazyHTML.query("#member-club-home[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "section#member-dashboard-cta a#member-send-message-link[href='/messages/new?club_id=#{club.club_id}']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#active-members-card[data-active-member-count='2']")
           |> Enum.any?()

    refute html |> LazyHTML.query("form#member-message-form") |> Enum.any?()
    refute html |> LazyHTML.query("select#member-message-sender-select") |> Enum.any?()
    refute html |> LazyHTML.query("input#member-message-subject-input") |> Enum.any?()
    refute html |> LazyHTML.query("textarea#member-message-body-input") |> Enum.any?()

    assert html
           |> LazyHTML.query("[data-testid='club-member-row'][data-member-name='Alice Adams']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("[data-testid='club-member-row'][data-member-name='Bob Builder']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "a[data-testid='club-message-link'][href='/messages/#{message.message_id}?club_id=#{club.club_id}']"
           )
           |> Enum.any?()

    refute response =~ "Your clubs"
  end

  test "GET / on a club subdomain shows the member dashboard to active club members", %{
    conn: conn
  } do
    club = create_club(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: club.name,
        club_id: club.club_id
      )

    message =
      create_message(club_id: club.club_id, sender_id: alice.person_id, subject: "Trip night")

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Hello, Alice."
    refute response =~ "Welcome to Kootenay Mountaineering Club"

    assert html
           |> LazyHTML.query("#member-club-home[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#member-send-message-link[href='/messages/new']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "a[data-testid='club-message-link'][href='/messages/#{message.message_id}']"
           )
           |> Enum.any?()
  end

  test "GET / on a club subdomain shows the public page to signed-in non-members", %{conn: conn} do
    club = create_club(name: "Kootenay Mountaineering Club", slug: "kmc")

    _other_club =
      create_active_member(email: "pat@example.com", club_name: "Nelson Paddling Club")

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Welcome to Kootenay Mountaineering Club"

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    refute response =~ "Send club message"
  end

  test "GET /messages/new on a club subdomain selects the host club", %{conn: conn} do
    club = create_club(name: "Kootenay Mountaineering Club", slug: "kmc")

    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: club.name,
        club_id: club.club_id
      )

    _bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: club.name,
        club_id: club.club_id
      )

    _pat = create_active_member(email: "pat@example.com", club_name: "Nelson Paddling Club")

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/new")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Kootenay Mountaineering Club"

    assert html
           |> LazyHTML.query(
             "#member-message-compose[data-club-id='#{club.club_id}'][data-active-member-count='2']"
           )
           |> Enum.any?()

    assert html |> LazyHTML.query("#member-compose-club-home-link[href='/']") |> Enum.any?()
    refute response =~ "club_id="
  end

  test "GET /messages/:message_id on a club subdomain shows the host-selected club message", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club"
      )

    club = Repo.get!(Club, alice.club_id) |> Ecto.Changeset.change(slug: "kmc") |> Repo.update!()

    message =
      create_message(
        club_id: club.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/#{message.message_id}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Trip planning night"
    assert response =~ "Bring your maps."

    assert html
           |> LazyHTML.query(
             "#member-message-detail[data-club-id='#{club.club_id}'][data-message-id='#{message.message_id}']"
           )
           |> Enum.any?()

    assert html |> LazyHTML.query("#back-to-club-home-link[href='/']") |> Enum.any?()
    refute response =~ "club_id="
  end

  test "GET /messages/:message_id on a club subdomain redirects signed-out visitors and preserves the full URL",
       %{conn: conn} do
    alice =
      create_active_member(email: "alice@example.com", club_name: "Kootenay Mountaineering Club")

    club = Repo.get!(Club, alice.club_id) |> Ecto.Changeset.change(slug: "kmc") |> Repo.update!()

    message =
      create_message(club_id: club.club_id, sender_id: alice.person_id, subject: "Members only")

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> get(~p"/messages/#{message.message_id}")

    assert redirected_to(conn) == ~p"/auth"

    assert get_session(conn, IdentityAuth.return_to_session_key()) ==
             "http://kmc.lvh.me/messages/#{message.message_id}"
  end

  test "auth callback returns active members to private club subdomain URLs", %{conn: conn} do
    alice =
      create_active_member(email: "alice@example.com", club_name: "Kootenay Mountaineering Club")

    club = Repo.get!(Club, alice.club_id) |> Ecto.Changeset.change(slug: "kmc") |> Repo.update!()

    message =
      create_message(club_id: club.club_id, sender_id: alice.person_id, subject: "Members only")

    return_to = "http://kmc.lvh.me/messages/#{message.message_id}"
    assert {:ok, %{token: token}} = Accounts.request_sign_in_link("alice@example.com")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.return_to_session_key() => return_to})
      |> get(~p"/auth/sign-in/#{token}")

    assert redirected_to(conn) == return_to
  end

  test "GET /messages/:message_id on a club subdomain forbids signed-in non-members", %{
    conn: conn
  } do
    alice =
      create_active_member(email: "alice@example.com", club_name: "Kootenay Mountaineering Club")

    club = Repo.get!(Club, alice.club_id) |> Ecto.Changeset.change(slug: "kmc") |> Repo.update!()

    _other_club =
      create_active_member(email: "pat@example.com", club_name: "Nelson Paddling Club")

    message =
      create_message(
        club_id: club.club_id,
        sender_id: alice.person_id,
        subject: "Members only",
        body: "Private club message"
      )

    conn =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/messages/#{message.message_id}")

    assert response(conn, 403) == "Forbidden"
    refute conn.resp_body =~ "Members only"
    refute conn.resp_body =~ "Private club message"
  end

  test "GET /messages/new on an unknown club subdomain returns not found", %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "unknown.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/new")

    assert html_response(conn, 404)
  end

  test "GET /messages/:message_id shows member message detail to active club members", %{
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
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    alice_receipt =
      create_member_email_delivery(
        message_id: message.message_id,
        recipient_id: alice.person_id,
        recipient_name: "Alice Adams",
        status: "sent"
      )

    bob_receipt =
      create_member_email_delivery(
        message_id: message.message_id,
        recipient_id: bob.person_id,
        recipient_name: "Bob Builder",
        status: "delivered"
      )

    create_memba_staff_email_delivery(
      delivery_id: bob_receipt.delivery_id,
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      recipient_address: "bob-private@example.invalid",
      status: "bounced",
      reason: "mailbox does not exist"
    )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Trip planning night"
    assert response =~ "Bring your maps."
    assert response =~ "From"
    assert response =~ "Alice Adams"

    assert html
           |> LazyHTML.query(
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("a#back-to-club-home-link[href='/?club_id=#{alice.club_id}']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#member-receipts-summary[data-receipt-count='2']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "[data-testid='member-receipt-group'][data-receipt-status='sent'] [data-testid='receipt-group-count']"
           )
           |> LazyHTML.text() =~ "1"

    assert html
           |> LazyHTML.query(
             "[data-testid='member-receipt-group'][data-receipt-status='delivered'] [data-testid='receipt-group-count']"
           )
           |> LazyHTML.text() =~ "1"

    assert html
           |> LazyHTML.query("#member-receipt-group-toggle-sent[aria-expanded='false']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#member-receipt-group-toggle-delivered[aria-expanded='false']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("[data-testid='member-receipt']")
           |> Enum.any?()

    assert html |> LazyHTML.query(".hero-clock") |> Enum.any?()
    assert html |> LazyHTML.query(".hero-check-circle") |> Enum.any?()

    refute response =~ alice_receipt.delivery_id
    refute response =~ bob_receipt.delivery_id
    refute response =~ "bob-private@example.invalid"
    refute response =~ "mailbox does not exist"
    refute response =~ "bounced"
  end

  test "GET /messages/:message_id redirects unauthenticated visitors and preserves return path",
       %{
         conn: conn
       } do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    message =
      create_message(club_id: club.club_id, sender_id: club.person_id, subject: "Members only")

    return_path = ~p"/messages/#{message.message_id}?#{[club_id: club.club_id]}"

    conn = get(conn, return_path)

    assert redirected_to(conn) == ~p"/auth"
    assert get_session(conn, IdentityAuth.return_to_session_key()) == return_path
  end

  test "GET /messages/:message_id forbids signed-in users outside the requested club", %{
    conn: conn
  } do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    _other_club = create_active_member(email: "pat@example.com", club_name: "Paddling Club")

    message =
      create_message(
        club_id: club.club_id,
        sender_id: club.person_id,
        subject: "Members only",
        body: "Private club message"
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/messages/#{message.message_id}?#{[club_id: club.club_id]}")

    assert response(conn, 403) == "Forbidden"
    refute conn.resp_body =~ "Members only"
    refute conn.resp_body =~ "Private club message"
  end

  test "GET /messages/:message_id returns not found when message belongs to a different club", %{
    conn: conn
  } do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club = create_club(name: "Paddling Club")

    message =
      create_message(
        club_id: other_club.club_id,
        sender_id: club.person_id,
        subject: "Wrong club",
        body: "This should stay hidden"
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/#{message.message_id}?#{[club_id: club.club_id]}")

    response = html_response(conn, 404)

    refute response =~ "Wrong club"
    refute response =~ "This should stay hidden"
  end

  test "GET / shows a Memba staff link for signed-in Memba staff", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "Pat@Memba.IO"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Your clubs"

    assert html
           |> LazyHTML.query("a#admin-home-link[href='/admin/clubs']")
           |> Enum.any?()
  end

  test "GET / shows both clubs and Memba staff access for signed-in staff members", %{conn: conn} do
    club = create_active_member(email: "pat@memba.io", club_name: "Staff Tennis Club")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Your clubs"
    assert response =~ "Staff Tennis Club"

    assert html
           |> LazyHTML.query("a[data-testid='my-club-link'][href='#{ClubSite.url(club)}']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("a#admin-home-link[href='/admin/clubs']")
           |> Enum.any?()
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "Simple software for volunteer-run groups."
  end

  test "GET /get-started shows a signed-out request form with public navigation", %{conn: conn} do
    conn = get(conn, ~p"/get-started")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Ask us to set up Memba for your group."
    assert response =~ "Want to use Memba with your club or group?"
    assert response =~ "Memba staff will review your request"

    assert html
           |> LazyHTML.query("header nav[aria-label='Public navigation'] a[href='/']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "form#get-started-request-form[action='/get-started'][method='post']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("input#get-started-requester-name[name='request[requester_name]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("input#get-started-requester-email[name='request[requester_email]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("input#get-started-club-name[name='request[requested_club_name]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("textarea#get-started-note[name='request[note]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("button#get-started-request-submit[type='submit']")
           |> Enum.any?()

    refute html |> LazyHTML.query("a[href^='mailto:hello@memba.io']") |> Enum.any?()
  end

  test "GET /get-started shows signed-in requester identity as read-only details", %{conn: conn} do
    person =
      insert_membership_person!(
        name: "Alice Applicant",
        email: "alice@example.com"
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/get-started")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query(
             "[data-testid='get-started-signed-in-requester'][data-person-id='#{person.person_id}']"
           )
           |> LazyHTML.text()
           |> String.contains?("Alice Applicant")

    assert response =~ "alice@example.com"
    assert response =~ "You’re signed in, so we’ll use these details for your request."
    assert response =~ "What would you like Memba to help with?"

    refute html
           |> LazyHTML.query("input#get-started-requester-name[name='request[requester_name]']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("input#get-started-requester-email[name='request[requester_email]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("input#get-started-club-name[name='request[requested_club_name]']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("textarea#get-started-note[name='request[note]']")
           |> Enum.any?()
  end

  test "POST /get-started rejects missing signed-out request fields", %{conn: conn} do
    conn =
      post(conn, ~p"/get-started",
        request: %{
          requester_name: "",
          requester_email: "",
          requested_club_name: "",
          note: ""
        }
      )

    response = html_response(conn, 422)

    assert response =~ "Want to use Memba with your club or group?"
    assert response =~ "can&#39;t be blank"
    assert Repo.aggregate(Request, :count) == 0
    assert_no_email_sent()
  end

  test "POST /get-started rejects invalid signed-out requester email", %{conn: conn} do
    conn =
      post(conn, ~p"/get-started",
        request: %{
          requester_name: "Robin Requester",
          requester_email: "not an email address",
          requested_club_name: "West Coast Paddlers",
          note: "We want a safer way to message members."
        }
      )

    response = html_response(conn, 422)

    assert response =~ "is invalid"
    assert Repo.aggregate(Request, :count) == 0
    assert_no_email_sent()
  end

  test "POST /get-started stores a signed-out request and acknowledges staff review", %{
    conn: conn
  } do
    club_count = Repo.aggregate(Club, :count)
    membership_count = Repo.aggregate(Membership, :count)

    conn =
      post(conn, ~p"/get-started",
        request: %{
          requester_name: " Robin Requester ",
          requester_email: " Robin@Example.COM ",
          requested_club_name: " West Coast Paddlers ",
          note: " We want a safer way to message members. "
        }
      )

    assert redirected_to(conn) == ~p"/get-started?submitted=true"

    assert [%Request{} = request] = Repo.all(Request)
    assert request.requester_name == "Robin Requester"
    assert request.requester_email == "Robin@Example.COM"
    assert request.normalized_requester_email == "robin@example.com"
    assert request.requested_club_name == "West Coast Paddlers"
    assert request.note == "We want a safer way to message members."
    assert request.status == "active"
    assert is_nil(request.requester_person_id)

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.from == {"Memba", "messages@mail.memba.io"}
    assert email.to == [{"", "hello@memba.io"}]
    assert email.reply_to == {"Robin Requester", "Robin@Example.COM"}
    assert email.subject == "New Memba request: West Coast Paddlers"
    assert email.text_body =~ "Request ID: #{request.request_id}"
    assert email.text_body =~ "Club: West Coast Paddlers"
    assert email.text_body =~ "Robin Requester"
    assert email.text_body =~ "Robin@Example.COM"
    assert email.text_body =~ "We want a safer way to message members."
    assert email.provider_options == %{message_stream: "outbound-onboarding"}

    assert Repo.aggregate(Club, :count) == club_count
    assert Repo.aggregate(Membership, :count) == membership_count

    response =
      conn
      |> recycle()
      |> get(~p"/get-started?submitted=true")
      |> html_response(200)

    assert response =~ "Thanks — we’ll read your request."
    assert response =~ "We’ll email you if Memba looks like a good fit for your group."
  end

  test "POST /get-started stores signed-in identity details from the current person", %{
    conn: conn
  } do
    club_count = Repo.aggregate(Club, :count)
    membership_count = Repo.aggregate(Membership, :count)

    person =
      insert_membership_person!(
        name: "Alice Applicant",
        email: "alice@example.com"
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> post(~p"/get-started",
        request: %{
          requester_name: "Forged Name",
          requester_email: "forged@example.net",
          requested_club_name: " West Coast Paddlers ",
          note: " We want a safer way to message members. "
        }
      )

    assert redirected_to(conn) == ~p"/get-started?submitted=true"

    assert [%Request{} = request] = Repo.all(Request)
    assert request.requester_name == "Alice Applicant"
    assert request.requester_email == "alice@example.com"
    assert request.normalized_requester_email == "alice@example.com"
    assert request.requester_person_id == person.person_id
    assert request.requested_club_name == "West Coast Paddlers"
    assert request.note == "We want a safer way to message members."
    assert request.status == "active"

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.to == [{"", "hello@memba.io"}]
    assert email.reply_to == {"Alice Applicant", "alice@example.com"}
    assert email.subject == "New Memba request: West Coast Paddlers"
    assert email.text_body =~ "Alice Applicant"
    assert email.text_body =~ "alice@example.com"
    refute email.text_body =~ "Forged Name"
    refute email.text_body =~ "forged@example.net"

    assert Repo.aggregate(Club, :count) == club_count
    assert Repo.aggregate(Membership, :count) == membership_count
  end

  test "GET /terms", %{conn: conn} do
    conn = get(conn, ~p"/terms")
    assert html_response(conn, 200) =~ "Terms of Service"
  end

  test "GET /privacy", %{conn: conn} do
    conn = get(conn, ~p"/privacy")
    assert html_response(conn, 200) =~ "Privacy Policy"
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: club_name
        )

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

  defp create_message(attrs) do
    Repo.insert!(%Message{
      message_id: Memba.ID.generate(:message),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Memba.ID.generate(:delivery),
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
      channel: Keyword.get(attrs, :channel, "email"),
      status: Keyword.fetch!(attrs, :status),
      reason: Keyword.fetch!(attrs, :reason)
    })
  end
end
