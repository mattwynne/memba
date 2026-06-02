defmodule MembaWeb.LayoutsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.Layouts

  test "public app layout keeps Memba-branded chrome for public pages" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Layouts.app flash={@flash}>
        <section id="public-layout-slot">Public page content</section>
      </Layouts.app>
      """)

    assert_selector(html, "a[aria-label='Memba home'][href='/']")
    assert_selector(html, "#public-layout-slot")
    refute_selector(html, "#admin-layout")
    refute_selector(html, "#club-site-layout")
  end

  test "admin layout provides utilitarian staff chrome and admin navigation" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Layouts.admin flash={@flash}>
        <main id="admin-layout-slot">Admin page content</main>
      </Layouts.admin>
      """)

    assert_selector(html, "#admin-layout[data-surface='admin']")
    assert_selector(html, "a[aria-label='Memba staff home'][href='/admin/clubs']")
    assert_selector(html, "nav[aria-label='Memba staff navigation'] a[href='/admin/clubs']")
    assert_selector(html, "nav[aria-label='Memba staff navigation'] a[href='/admin/deliveries']")
    assert_selector(html, "form#admin-sign-out-form[action='/auth'][method='post']")
    assert_selector(html, "input[name='_method'][value='delete']")
    assert_selector(html, "button#admin-sign-out-button[type='submit']")
    assert_selector(html, "#admin-layout-slot")
    refute_selector(html, "#club-site-layout")
  end

  test "club-site layout seam exposes neutral slate CSS custom properties without routes" do
    assigns = %{
      flash: %{},
      current_identity: %{email: "alice@example.com"},
      theme: %{"background" => "#f1f5f9", accent: "#0f766e"}
    }

    html =
      rendered_to_string(~H"""
      <Layouts.club_site
        flash={@flash}
        club_name="Riverside Tennis Club"
        current_identity={@current_identity}
        theme={@theme}
      >
        <section id="club-site-layout-slot">Future club member page content</section>
      </Layouts.club_site>
      """)

    assert_selector(html, "#club-site-layout[data-surface='club-site']")
    assert_selector(html, "#club-site-layout-slot")
    assert_text(html, "#club-site-layout header", "Riverside Tennis Club")
    assert_text(html, "#club-site-layout header", "Signed in as alice@example.com")
    refute_text(html, "#club-site-layout header", "Powered by Memba")
    assert_text(html, "#club-site-footer", "Powered by Memba")
    assert_selector(html, "form#club-site-sign-out-form[action='/auth'][method='post']")
    assert_selector(html, "form#club-site-sign-out-form input[name='_method'][value='delete']")
    assert_selector(html, "button#club-site-sign-out-button[type='submit']")

    style = only_attribute(html, "#club-site-layout", "style")
    assert style =~ "--club-site-bg: #f1f5f9;"
    assert style =~ "--club-site-paper: #ffffff;"
    assert style =~ "--club-site-ink: #0f172a;"
    assert style =~ "--club-site-muted: #64748b;"
    assert style =~ "--club-site-accent: #0f766e;"
    assert style =~ "--club-site-line: #e2e8f0;"
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered layout to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered layout not to include selector #{inspect(selector)}"
  end

  defp assert_text(html, selector, expected_text) do
    text = selected_text(html, selector)

    assert text =~ expected_text
  end

  defp refute_text(html, selector, text) do
    refute selected_text(html, selector) =~ text
  end

  defp selected_text(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
  end

  defp only_attribute(html, selector, attribute) do
    attributes =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute(attribute)

    assert [value] = attributes
    value
  end
end
