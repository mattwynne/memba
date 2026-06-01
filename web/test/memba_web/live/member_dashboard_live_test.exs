defmodule MembaWeb.MemberDashboardLiveTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo
  alias MembaWeb.UserAuth

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
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-club-home[data-live-view='member-dashboard'][data-club-id='#{alice.club_id}']"
           )

    assert has_element?(view, "#club-site-current-identity", "Signed in as alice@example.com")
    assert has_element?(view, "#member-message-#{message.message_id}")
    assert has_element?(view, "#club-member-#{alice.person_id}")
    assert has_element?(view, "#club-member-#{bob.person_id}")
  end

  test "logged-out club home still renders the public club marketing experience", %{conn: conn} do
    club = create_club(name: "Alpine Club")

    conn = get(conn, ~p"/?club_id=#{club.club_id}")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query("#club-marketing-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-club-home[data-live-view='member-dashboard']")
           |> Enum.any?()
  end

  test "signed-in identities outside the selected club are still forbidden", %{conn: conn} do
    alice = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/?club_id=#{alice.club_id}")

    assert response(conn, 403) == "Forbidden"
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
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

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

    %{
      club_id: club_id,
      person_id: person_id
    }
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
