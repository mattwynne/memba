defmodule MembaWeb.Admin.ClubsLive.ShowTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership
  alias Memba.Membership.Projections.Club, as: ClubProjection

  test "edit form displays and saves a club name and slug", %{conn: conn} do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    assert has_element?(view, "#edit-club-form[aria-label='Edit club']")
    assert input_value(initial_html, "#edit-club-name-input") == "Kootenay Mountaineering Club"
    assert input_value(initial_html, "#edit-club-slug-input") == "kmc"

    view
    |> form("#edit-club-form", club: %{name: "KMC Alpine Club", slug: "kmc-alpine"})
    |> render_submit()

    assert has_element?(view, "#club-show", "KMC Alpine Club")

    updated_html = render(view)
    assert input_value(updated_html, "#edit-club-name-input") == "KMC Alpine Club"
    assert input_value(updated_html, "#edit-club-slug-input") == "kmc-alpine"

    assert %ClubProjection{name: "KMC Alpine Club", slug: "kmc-alpine"} =
             Membership.get_club(club_id)

    assert %ClubProjection{club_id: ^club_id} = Membership.get_club_by_slug("kmc-alpine")
    assert is_nil(Membership.get_club_by_slug("kmc"))
  end

  test "invalid edit submissions leave the form editable without changing the projection", %{
    conn: conn
  } do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC Alpine Club", slug: "KMC Club!"})
    |> render_submit()

    invalid_html = render(view)
    assert input_value(invalid_html, "#edit-club-name-input") == "KMC Alpine Club"
    assert input_value(invalid_html, "#edit-club-slug-input") == "KMC Club!"

    assert %ClubProjection{name: "Kootenay Mountaineering Club", slug: "kmc"} =
             Membership.get_club(club_id)
  end

  test "slug validation feedback updates live while editing", %{conn: conn} do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc club!"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='invalid']")
    assert has_element?(view, "#update-club-button[disabled]")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc-alpine"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='available']")
    refute has_element?(view, "#update-club-button[disabled]")
  end

  test "slug availability feedback updates live while editing", %{conn: conn} do
    club_id = Ecto.UUID.generate()
    other_club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_club(
               %{club_id: other_club_id, name: "Alpine Club", slug: "alpine"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "alpine"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='taken']")
    assert has_element?(view, "#update-club-button[disabled]")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='available']")
    refute has_element?(view, "#update-club-button[disabled]")
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
