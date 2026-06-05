defmodule MembaWeb.AdminOperationsIndexLiveTest do
  use MembaWeb.FeatureCase, async: false

  test "global staff operations indexes require staff sign-in" do
    for path <- ["/admin/people", "/admin/messages"] do
      conn =
        build_conn(:get, path)
        |> get(path)

      assert redirected_to(conn) == ~p"/auth"
      assert Plug.Conn.get_session(conn, MembaWeb.IdentityAuth.return_to_session_key()) == path
    end
  end

  test "Memba staff can open the read-only global People index", %{conn: conn} do
    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/people")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "People"
    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#admin-people-index")
    assert_selector_exists(html, "#admin-people-read-only-notice")
    assert_selector_exists(html, "#admin-people-table[aria-label='People records']")
    refute_selector_exists(html, "#new-person-form")
  end

  test "Memba staff can open the read-only global Messages index", %{conn: conn} do
    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/messages")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "Messages"
    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#admin-messages-index")
    assert_selector_exists(html, "#admin-messages-read-only-notice")
    assert_selector_exists(html, "#admin-messages-table[aria-label='Messages']")
    refute_selector_exists(html, "#new-message-form")
    refute_selector_exists(html, "[data-admin-message-action='resend']")
    refute_selector_exists(html, "[data-admin-message-action='delete']")
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp refute_selector_exists(html, selector) do
    refute html |> LazyHTML.query(selector) |> Enum.any?(), "Did not expect selector #{selector}"
  end
end
