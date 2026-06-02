defmodule MembaWeb.IdentityAuthTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  describe "fetch_current_identity/2" do
    test "assigns no current identity when the session has no signed-in email", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> IdentityAuth.fetch_current_identity([])

      assert conn.assigns.current_identity == nil
      assert conn.assigns.current_identity_email == nil
      assert conn.assigns.current_identity_staff? == false
      assert conn.assigns.current_identity_clubs == []
    end

    test "normalizes the signed-in session email and assigns staff status", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => " Pat@Memba.IO "})
        |> IdentityAuth.fetch_current_identity([])

      assert conn.assigns.current_identity.email == "pat@memba.io"
      assert conn.assigns.current_identity.staff? == true
      assert conn.assigns.current_identity.active_clubs == []
      assert conn.assigns.current_identity_email == "pat@memba.io"
      assert conn.assigns.current_identity_staff? == true
      assert conn.assigns.current_identity_clubs == []
    end

    test "assigns active clubs for a signed-in member email", %{conn: conn} do
      club = create_active_member(email: "Alice@Example.COM", club_name: "Kootenay")

      conn =
        conn
        |> init_test_session(%{"current_identity_email" => " alice@example.com "})
        |> IdentityAuth.fetch_current_identity([])

      assert conn.assigns.current_identity.email == "alice@example.com"
      assert conn.assigns.current_identity.staff? == false

      assert [%Club{club_id: club_id, name: "Kootenay"}] =
               conn.assigns.current_identity.active_clubs

      assert club_id == club.club_id
      assert conn.assigns.current_identity_clubs == conn.assigns.current_identity.active_clubs
    end
  end

  describe "session helpers" do
    test "log_in_identity/2 renews the session and stores the normalized email", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"identity_return_to" => "/admin/clubs"})
        |> IdentityAuth.log_in_identity(" Pat@Memba.IO ")

      assert get_session(conn, "current_identity_email") == "pat@memba.io"
      assert get_session(conn, "identity_return_to") == nil
    end

    test "log_out_identity/1 clears the signed-in identity session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => "pat@memba.io"})
        |> IdentityAuth.log_out_identity()

      assert get_session(conn, "current_identity_email") == nil
    end
  end

  describe "require_authenticated_identity/2" do
    test "continues when a current identity is assigned", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => "pat@memba.io"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_authenticated_identity([])

      refute conn.halted
    end

    test "redirects unauthenticated requests to auth and stores a safe return path" do
      conn =
        build_conn(:get, "/admin/clubs?club_id=club-123")
        |> init_test_session(%{})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_authenticated_identity([])

      assert redirected_to(conn) == "/auth"
      assert get_session(conn, "identity_return_to") == "/admin/clubs?club_id=club-123"
      assert conn.halted
    end
  end

  describe "require_staff_identity/2" do
    test "continues for signed-in Memba staff", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => "pat@memba.io"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_staff_identity([])

      refute conn.halted
    end

    test "forbids signed-in non-staff identities", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => "alice@example.com"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_staff_identity([])

      assert response(conn, 403) == "Forbidden"
      assert conn.halted
    end

    test "redirects unauthenticated requests to auth" do
      conn =
        build_conn(:get, "/admin/clubs")
        |> init_test_session(%{})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_staff_identity([])

      assert redirected_to(conn) == "/auth"
      assert get_session(conn, "identity_return_to") == "/admin/clubs"
      assert conn.halted
    end
  end

  describe "require_active_club_member/2" do
    test "continues for signed-in active members of the requested club", %{conn: conn} do
      club = create_active_member(email: "alice@example.com")

      conn =
        %{conn | query_params: %{"club_id" => club.club_id}}
        |> init_test_session(%{"current_identity_email" => "alice@example.com"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_active_club_member([])

      refute conn.halted
    end

    test "forbids signed-in identities that are not active members of the requested club", %{
      conn: conn
    } do
      club = create_active_member(email: "alice@example.com")

      conn =
        %{conn | query_params: %{"club_id" => club.club_id}}
        |> init_test_session(%{"current_identity_email" => "other@example.com"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_active_club_member([])

      assert response(conn, 403) == "Forbidden"
      assert conn.halted
    end

    test "forbids signed-in identities when club_id is missing", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"current_identity_email" => "alice@example.com"})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_active_club_member([])

      assert response(conn, 403) == "Forbidden"
      assert conn.halted
    end

    test "redirects unauthenticated requests to auth and preserves the club_id return path" do
      club_id = Ecto.UUID.generate()

      conn =
        build_conn(:get, "/member-area?club_id=#{club_id}")
        |> init_test_session(%{})
        |> IdentityAuth.fetch_current_identity([])
        |> IdentityAuth.require_active_club_member([])

      assert redirected_to(conn) == "/auth"
      assert get_session(conn, "identity_return_to") == "/member-area?club_id=#{club_id}"
      assert conn.halted
    end
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
      active: true
    })

    club
  end
end
