defmodule MembaWeb.PageControllerTest do
  use MembaWeb.ConnCase

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "Volunteering shouldn’t feel like work."
    assert response =~ "Kootenay Mountaineering Club"
    assert response =~ "Built with"
    assert response =~ "in Nelson, BC."
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

  test "GET / shows Your clubs with query-string club links for signed-in members", %{conn: conn} do
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
    refute response =~ "Volunteering shouldn’t feel like work."

    for club <- [first_club, second_club] do
      assert html
             |> LazyHTML.query("a[data-testid='my-club-link'][href='/?club_id=#{club.club_id}']")
             |> Enum.any?()

      refute html
             |> LazyHTML.query("a[data-testid='my-club-link'][href='/?club_id=#{club.club_id}']")
             |> LazyHTML.text()
             |> String.contains?(club.club_id)
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
    assert response =~ "Members can sign in to see club updates"

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
    assert response =~ "Members can sign in to see club updates"

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
      |> Map.put(:host, "kmc.clubs.memba.io")
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
      |> Map.put(:host, "unknown.clubs.memba.io")
      |> get(~p"/")

    response = html_response(conn, 404)

    refute response =~ "Kootenay Mountaineering Club"
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
    assert response =~ "What the club's been saying, and who's around right now."
    assert response =~ "Send club message"
    assert response =~ "Recent club messages"
    assert response =~ "Active members"
    assert response =~ "2 active members"

    assert html
           |> LazyHTML.text()
           |> String.contains?(
             "Everyone with a current membership. They'll all receive your messages."
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
           |> LazyHTML.query("a[data-testid='my-club-link'][href='/?club_id=#{club.club_id}']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("a#admin-home-link[href='/admin/clubs']")
           |> Enum.any?()
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "Membership software for clubs that run on trust."
  end

  test "GET /get-started shows invite-only contact page with public navigation", %{conn: conn} do
    conn = get(conn, ~p"/get-started")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Memba is invite-only right now."
    assert response =~ "Want to try Memba with your club?"

    assert html
           |> LazyHTML.query("header nav[aria-label='Public navigation'] a[href='/']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query("a#contact-us-link[href^='mailto:hello@memba.io']")
           |> Enum.any?()
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
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: club_name
        )

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.get(attrs, :name, "Test Member"),
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
  end

  defp create_message(attrs) do
    Repo.insert!(%Message{
      message_id: Ecto.UUID.generate(),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Ecto.UUID.generate(),
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
