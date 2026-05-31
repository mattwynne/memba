defmodule MembaWeb.PageControllerTest do
  use MembaWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Keep every member in the loop."
    assert response =~ "Red Donkey Technology Corp"
    assert response =~ "https://donkey.red"
  end

  test "GET / presents operational links as staff admin entry points", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html |> LazyHTML.query("nav[aria-label='Main navigation'] a[href='/admin/clubs']") |> Enum.any?()
    assert html |> LazyHTML.query("main a[href='/admin/clubs']") |> Enum.any?()
    assert html |> LazyHTML.query("a[href='/admin/clubs']") |> Enum.any?()
    assert response =~ "Internal staff admin"
    assert response =~ "Open internal staff admin"
    refute response =~ ~s(href="/clubs")
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "Membership software for clubs that run on trust."
  end

  test "GET /terms", %{conn: conn} do
    conn = get(conn, ~p"/terms")
    assert html_response(conn, 200) =~ "Terms of Service"
  end

  test "GET /privacy", %{conn: conn} do
    conn = get(conn, ~p"/privacy")
    assert html_response(conn, 200) =~ "Privacy Policy"
  end
end
