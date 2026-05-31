defmodule MembaWeb.Plugs.CanonicalHostRedirectTest do
  use MembaWeb.ConnCase, async: true

  alias MembaWeb.UserAuth

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

  test "does not redirect the canonical hostname", %{conn: conn} do
    conn =
      conn
      |> Map.put(:host, "memba.io")
      |> init_test_session(%{UserAuth.identity_session_key() => "pat@memba.io"})
      |> get("/admin/clubs")

    assert html_response(conn, 200) =~ "Clubs"
    assert get_resp_header(conn, "location") == []
  end
end
