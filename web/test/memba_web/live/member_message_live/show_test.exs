defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo
  alias MembaWeb.UserAuth

  test "renders a member message detail LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberMessageLive.Show)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")
    assert has_element?(view, "#member-message-detail[data-live-view='member-message-detail']")
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
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(view, "a#back-to-club-home-link[href='/?club_id=#{alice.club_id}']")
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
