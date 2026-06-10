defmodule MembaWeb.Plugs.CanonicalHostRedirectTest do
  use MembaWeb.ConnCase, async: true

  test "redirects the Fly hostname to the canonical domain and preserves path and query", %{
    conn: conn
  } do
    conn =
      conn
      |> Map.put(:host, "memba.fly.dev")
      |> get("/admin/clubs?sort=name")

    assert response(conn, 301) == ""
    assert get_resp_header(conn, "location") == ["https://memba.io/admin/clubs?sort=name"]
  end

  test "redirects staff admin pages from club subdomains to the root domain and preserves path and query",
       %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "lean.lvh.me")
      |> get("/admin/clubs?sort=name")

    assert response(conn, 301) == ""
    assert get_resp_header(conn, "location") == ["http://lvh.me:4002/admin/clubs?sort=name"]
  end

  test "redirects non-club club_id URLs to the club subdomain and removes the club_id query",
       %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    conn =
      conn
      |> Map.put(:host, "localhost")
      |> get("/messages/new?club_id=#{club.club_id}&draft=1")

    assert response(conn, 302) == ""
    assert get_resp_header(conn, "location") == ["http://kmc.lvh.me:4002/messages/new?draft=1"]
  end

  test "leaves root-domain URLs with unknown club_id for route handling", %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "lvh.me")
      |> get("/messages/new?club_id=unknown")

    assert redirected_to(conn) == ~p"/auth"
  end

  test "does not redirect member pages from club subdomains", %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "lean.lvh.me")
      |> get("/")

    assert conn.status == 404
    assert get_resp_header(conn, "location") == []
  end

  test "does not redirect the canonical hostname", %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "memba.io")
      |> get("/")

    assert conn.status == 200
    assert get_resp_header(conn, "location") == []
  end
end
