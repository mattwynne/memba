defmodule MembaWeb.AuthGatesTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.ClubSite
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

    test "redirect first-time signed-in Memba staff browsers to onboarding", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/admin/clubs")

      assert redirected_to(conn) == ~p"/auth/onboard"

      assert get_session(conn, IdentityAuth.staff_onboarding_return_to_session_key()) ==
               ~p"/admin/clubs"
    end

    test "allow onboarded signed-in Memba staff browsers", %{conn: conn} do
      insert_membership_person!(name: "Pat Staff", email: "pat@memba.io")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/admin/clubs")

      assert html_response(conn, 200) =~ ~s(id="clubs-index")
    end
  end

  describe "Memba staff request routes" do
    test "redirect unauthenticated browsers to sign in and preserve the return path" do
      conn =
        build_conn(:get, "/admin/requests?filter=active")
        |> get("/admin/requests?filter=active")

      assert redirected_to(conn) == ~p"/auth"

      assert get_session(conn, IdentityAuth.return_to_session_key()) ==
               "/admin/requests?filter=active"
    end

    test "forbid signed-in non-staff browsers", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/admin/requests")

      assert response(conn, 403) == "Forbidden"
    end

    test "redirect first-time signed-in Memba staff browsers to onboarding", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/admin/requests")

      assert redirected_to(conn) == ~p"/auth/onboard"

      assert get_session(conn, IdentityAuth.staff_onboarding_return_to_session_key()) ==
               ~p"/admin/requests"
    end

    test "allow onboarded signed-in Memba staff browsers", %{conn: conn} do
      insert_membership_person!(name: "Pat Staff", email: "pat@memba.io")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/admin/requests")

      assert html_response(conn, 200) =~ ~s(id="admin-requests-index")
    end
  end

  describe "club home routes" do
    test "redirect unauthenticated club_id home requests to the club subdomain" do
      club = create_club(name: "Alpine Club")

      conn =
        build_conn(:get, "/?club_id=#{club.club_id}")
        |> get("/?club_id=#{club.club_id}")

      assert redirected_to(conn, 302) == ClubSite.url(club)
    end

    test "redirect signed-in staff club_id home requests to the club subdomain", %{conn: conn} do
      club = create_club(name: "Alpine Club")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      assert redirected_to(conn, 302) == ClubSite.url(club)
    end

    test "show signed-in browsers without active membership the public club subdomain page", %{
      conn: conn
    } do
      club = create_active_member(email: "alice@example.com")

      conn =
        conn
        |> club_host(club)
        |> init_test_session(%{IdentityAuth.identity_session_key() => "other@example.com"})
        |> get(~p"/")

      assert html_response(conn, 200) =~ "Welcome to Kootenay Mountaineering Club"
    end

    test "show signed-in browsers with only inactive membership the public club subdomain page",
         %{
           conn: conn
         } do
      club = create_active_member(email: "alice@example.com", active: false)

      conn =
        conn
        |> club_host(club)
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/")

      assert html_response(conn, 200) =~ "Welcome to Kootenay Mountaineering Club"
    end

    test "redirect signed-in active member club_id home requests to the club subdomain", %{
      conn: conn
    } do
      club = create_active_member(email: "alice@example.com")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> get(~p"/?#{[club_id: club.club_id]}")

      assert redirected_to(conn, 302) == ClubSite.url(club)
    end
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp club_host(conn, club) do
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_active_member(attrs) do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    club =
      insert_membership_club!(
        club_id: club_id,
        name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
      )

    person =
      insert_membership_person!(
        person_id: person_id,
        name: "Test Member",
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: Keyword.get(attrs, :active, true)
    })

    club
  end
end
