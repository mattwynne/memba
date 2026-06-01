defmodule MembaWeb.PageControllerTest do
  use MembaWeb.ConnCase

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo
  alias MembaWeb.UserAuth

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Keep every member in the loop."
    assert response =~ "Red Donkey Technology Corp"
    assert response =~ "https://donkey.red"
  end

  test "GET / presents sign-in links instead of staff admin entry points", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query("nav[aria-label='Main navigation'] a[href='/auth']")
           |> Enum.any?()

    assert html |> LazyHTML.query("header > a[href='/auth']") |> Enum.any?()
    assert html |> LazyHTML.query("main a[href='/auth']") |> Enum.any?()
    assert response =~ "Sign In"
    refute response =~ "Internal staff admin"
    refute response =~ "Open internal staff admin"
    refute response =~ ~s(href="/admin/clubs")
    refute response =~ ~s(href="/clubs")
  end

  test "GET / shows My clubs with query-string club links for signed-in members", %{conn: conn} do
    first_club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    second_club = create_active_member(email: "ALICE@example.com", club_name: "Bridge Club")

    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "My clubs"
    assert response =~ "Alpine Club"
    assert response =~ "Bridge Club"
    refute response =~ "Keep every member in the loop."

    for club <- [first_club, second_club] do
      assert html
             |> LazyHTML.query("a[data-testid='my-club-link'][href='/?club_id=#{club.club_id}']")
             |> Enum.any?()
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

  test "GET / with a club_id shows a public club marketing page to logged-out visitors", %{
    conn: conn
  } do
    club = create_club(name: "Alpine Club")

    conn = get(conn, ~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Welcome to Alpine Club"
    assert response =~ "Members can sign in to see club updates"

    assert html
           |> LazyHTML.query("#club-marketing-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    assert html |> LazyHTML.query("a#club-marketing-sign-in-link[href='/auth']") |> Enum.any?()
    refute response =~ "Send a club message"
    refute response =~ "Signed in as"
  end

  test "GET / with a member club_id opens a useful member club page", %{conn: conn} do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    bob =
      create_active_member(
        email: "bob@example.com",
        club_name: "Alpine Club",
        club_id: club.club_id
      )

    message =
      create_message(club_id: club.club_id, sender_id: bob.person_id, subject: "Trip night")

    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/?#{[club_id: club.club_id]}")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "Alpine Club"
    assert response =~ "Welcome to your club space."
    assert response =~ "Send a club message"
    assert response =~ "Members"
    assert response =~ "Sent messages"
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
             "form#member-message-form[action='/?club_id=#{club.club_id}'][method='post']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("[data-testid='club-member-row'][data-member-name='Test Member']")
           |> Enum.any?()

    assert html
           |> LazyHTML.query(
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}']"
           )
           |> Enum.any?()

    refute response =~ "My clubs"
  end

  test "GET / shows an Admin link for signed-in Memba staff", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "Pat@Memba.IO"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "My clubs"

    assert html
           |> LazyHTML.query("a#admin-home-link[href='/admin/clubs']")
           |> Enum.any?()
  end

  test "GET / shows both clubs and Admin for signed-in staff members", %{conn: conn} do
    club = create_active_member(email: "pat@memba.io", club_name: "Staff Tennis Club")

    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "pat@memba.io"})
      |> get(~p"/")

    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert response =~ "My clubs"
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

  test "GET /terms", %{conn: conn} do
    conn = get(conn, ~p"/terms")
    assert html_response(conn, 200) =~ "Terms of Service"
  end

  test "GET /privacy", %{conn: conn} do
    conn = get(conn, ~p"/privacy")
    assert html_response(conn, 200) =~ "Privacy Policy"
  end

  defp create_club(attrs) do
    Repo.insert!(%Club{
      club_id: Ecto.UUID.generate(),
      name: Keyword.fetch!(attrs, :name)
    })
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        Repo.insert!(%Club{
          club_id: club_id,
          name: club_name
        })

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
end
