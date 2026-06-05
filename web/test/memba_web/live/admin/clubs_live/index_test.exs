defmodule MembaWeb.Admin.ClubsLive.IndexTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership
  alias Memba.Membership.Projections.Club, as: ClubProjection

  test "staff clubs index uses the operations page treatment", %{conn: conn} do
    {:ok, _view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs")

    html = LazyHTML.from_fragment(initial_html)

    assert initial_html =~ "Memba staff operations"
    assert_selector_exists(html, "#clubs-index[data-admin-page='clubs']")
    assert_selector_exists(html, "#clubs-index-new-club-action[href='#new-club-form']")
    assert_selector_exists(html, "#clubs-summary-total")
    assert_selector_exists(html, "#clubs-create-card #new-club-form[aria-label='Create a club']")
    assert_selector_exists(html, "#clubs-directory-card")
    assert_selector_exists(html, "#clubs-table")
    assert_selector_exists(html, "#clubs[aria-label='Clubs']")
    refute initial_html =~ "Browser acceptance harness"
  end

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

  test "duplicate slug create submissions show a server error and keep the form editable", %{
    conn: conn
  } do
    existing_club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: existing_club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs")

    view
    |> form("#new-club-form", club: %{name: "KMC Duplicate Club", slug: "kmc"})
    |> render_submit()

    duplicate_html = render(view)

    assert has_element?(view, "#flash-error", "Could not create club: :slug taken")
    assert input_value(duplicate_html, "#club-name-input") == "KMC Duplicate Club"
    assert input_value(duplicate_html, "#club-slug-input") == "kmc"

    assert %ClubProjection{club_id: ^existing_club_id, slug: "kmc"} =
             Membership.get_club_by_slug("kmc")

    assert [^existing_club_id] =
             Membership.list_clubs()
             |> Enum.filter(&(&1.slug == "kmc"))
             |> Enum.map(& &1.club_id)
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

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end
end
