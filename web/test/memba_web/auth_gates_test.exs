defmodule MembaWeb.AuthGatesTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  describe "Memba staff routes" do
    test "redirect unauthenticated browsers to sign in and preserve the return path" do
      conn =
        build_conn(:get, "/admin/clubs?filter=recent")
        |> get("/admin/clubs?filter=recent")

      assert redirected_to(conn) == ~p"/auth"

      assert get_session(conn, IdentityAuth.return_to_session_key()) ==
               "/admin/clubs?filter=recent"
    end

    test "forbid signed-in non-staff browsers", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/admin/clubs")

      assert response(conn, 403) == "Forbidden"
    end

    test "allow signed-in Memba staff browsers", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/admin/clubs")

      assert html_response(conn, 200) =~ ~s(id="clubs-index")
    end
  end

  describe "club_id member routes" do
    test "allow unauthenticated browsers to see the public public club page" do
      club = create_club(name: "Alpine Club")

      conn =
        build_conn(:get, "/?club_id=#{club.club_id}")
        |> get("/?club_id=#{club.club_id}")

      response = html_response(conn, 200)

      assert response =~ "Welcome to Alpine Club"
      assert response =~ "Sign in to continue"
      assert response =~ "Powered by"
      assert get_session(conn, IdentityAuth.return_to_session_key()) == nil
    end

    test "allow signed-in staff to see a club page without active membership", %{conn: conn} do
      club = create_club(name: "Alpine Club")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      response = html_response(conn, 200)

      assert response =~ "Welcome to Alpine Club"
      assert response =~ "Sign in to continue"
    end

    test "forbid signed-in browsers without active membership in the requested club", %{
      conn: conn
    } do
      club = create_active_member(email: "alice@example.com")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "other@example.com"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      assert response(conn, 403) == "Forbidden"
    end

    test "forbid signed-in browsers with only inactive membership in the requested club", %{
      conn: conn
    } do
      club = create_active_member(email: "alice@example.com", active: false)

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      assert response(conn, 403) == "Forbidden"
    end

    test "allow signed-in active members of the requested club", %{conn: conn} do
      club = create_active_member(email: "alice@example.com")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      response = html_response(conn, 200)

      assert response =~ "What the club's been saying, and who's around right now."
      assert response =~ club.name
    end
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    club =
      insert_membership_club!(
        club_id: club_id,
        name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
      )

    Repo.insert!(%Person{
      person_id: person_id,
      name: "Test Member",
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: Keyword.get(attrs, :active, true)
    })

    club
  end
end
