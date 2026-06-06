defmodule MembaWeb.Admin.RequestsLive.IndexTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  test "staff requests index uses the operations page treatment", %{conn: conn} do
    {:ok, _view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    html = LazyHTML.from_fragment(initial_html)

    assert_selector_exists(html, "#admin-requests-index[data-admin-page='requests']")
    assert_selector_exists(html, "#admin-requests-route-ready")
    refute initial_html =~ "Browser acceptance harness"
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end
end
