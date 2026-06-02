defmodule MembaWeb.Admin.ClubsLive.IndexTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  test "create form suggests a generated slug and allows staff override", %{conn: conn} do
    {:ok, view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs")

    assert input_value(initial_html, "#club-name-input") == ""
    assert input_value(initial_html, "#club-slug-input") == ""

    suggested_html =
      view
      |> form("#new-club-form", club: %{name: "Kootenay Mountaineering Club", slug: ""})
      |> render_change()

    assert input_value(suggested_html, "#club-slug-input") ==
             "kootenay-mountaineering-club"

    override_html =
      view
      |> form("#new-club-form", club: %{name: "Kootenay Mountaineering Club", slug: "kmc"})
      |> render_change()

    assert input_value(override_html, "#club-slug-input") == "kmc"

    view
    |> form("#new-club-form", club: %{name: "Kootenay Mountaineering Club", slug: "kmc"})
    |> render_submit()

    assert has_element?(
             view,
             "#clubs [data-testid='club-row'][data-club-name='Kootenay Mountaineering Club']"
           )
  end

  defp input_value(html, selector) do
    values =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute("value")

    assert [value] = values
    value
  end
end
