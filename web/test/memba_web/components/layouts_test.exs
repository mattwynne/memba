defmodule MembaWeb.LayoutsTest do
  use MembaWeb.ConnCase, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.Layouts
  alias MembaWeb.ClubSite

  @sha "abcdef0123456789abcdef0123456789abcdef01"

  setup do
    original_env = System.get_env("MEMBA_GIT_SHA")
    original_footer_config = Application.get_env(:memba, :show_git_commit_in_footer)

    System.delete_env("MEMBA_GIT_SHA")

    on_exit(fn ->
      restore_system_env("MEMBA_GIT_SHA", original_env)
      Application.put_env(:memba, :show_git_commit_in_footer, original_footer_config)
    end)
  end

  test "public app layout keeps Memba-branded chrome for public pages" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Layouts.app flash={@flash}>
        <section id="public-layout-slot">Public page content</section>
      </Layouts.app>
      """)

    assert_selector(html, "a[aria-label='Memba home'][href='/']")
    assert_text(html, "nav[aria-label='Main navigation']", "Features")
    assert_text(html, "nav[aria-label='Main navigation']", "Pricing")
    assert_selector(html, "nav[aria-label='Main navigation'] a[href='/about']")
    assert_selector(html, "header a[href='/auth']")
    assert_selector(html, "header a[href='/get-started']")
    refute_text(html, "nav[aria-label='Main navigation']", "Home")
    assert_selector(html, "#public-layout-slot")
    refute_selector(html, "#admin-layout")
    refute_selector(html, "#club-site-layout")
  end

  test "admin layout provides the staff operations shell and iteration nav" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Layouts.admin flash={@flash}>
        <main id="admin-layout-slot">Admin page content</main>
      </Layouts.admin>
      """)

    assert_selector(html, "#admin-layout[data-surface='admin']")
    assert_selector(html, "#admin-sidebar")
    assert_selector(html, "#admin-content")
    assert_selector(html, "a[aria-label='Memba staff home'][href='/admin/clubs']")
    assert_selector(html, "#admin-navigation-group")

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-clubs[data-admin-nav-item='clubs'][href='/admin/clubs']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-people[data-admin-nav-item='people'][href='/admin/people']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-requests[data-admin-nav-item='requests'][href='/admin/requests']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-requests[data-phx-link='redirect'][data-phx-link-state='push']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-people[data-phx-link='redirect'][data-phx-link-state='push']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-messages[data-admin-nav-item='messages'][href='/admin/messages']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-messages[data-phx-link='redirect'][data-phx-link-state='push']"
    )

    assert_selector(
      html,
      "nav[aria-label='Memba staff navigation'] a#admin-nav-deliveries[data-admin-nav-item='deliveries'][href='/admin/deliveries']"
    )

    assert_selector_count(html, "nav[aria-label='Memba staff navigation'] a", 5)
    assert_text(html, "nav[aria-label='Memba staff navigation']", "Clubs")
    assert_text(html, "nav[aria-label='Memba staff navigation']", "Requests")
    assert_text(html, "nav[aria-label='Memba staff navigation']", "People")
    assert_text(html, "nav[aria-label='Memba staff navigation']", "Messages")
    assert_text(html, "nav[aria-label='Memba staff navigation']", "Deliveries")
    refute_text(html, "nav[aria-label='Memba staff navigation']", "Incoming")
    refute_text(html, "nav[aria-label='Memba staff navigation']", "Roles")
    assert_selector(html, "#admin-staff-identity-block")
    assert_selector(html, "form#admin-sign-out-form[action='/auth'][method='post']")
    assert_selector(html, "input[name='_method'][value='delete']")
    assert_selector(html, "button#admin-sign-out-button[type='submit']")
    assert_selector(html, "#admin-layout-slot")
    refute_selector(html, "#club-site-layout")
  end

  test "club-site layout uses canonical Memba theme without white-label custom properties" do
    assigns = %{
      flash: %{},
      current_identity: %{email: "alice@example.com"}
    }

    html =
      rendered_to_string(~H"""
      <Layouts.club_site
        flash={@flash}
        club_name="Riverside Tennis Club"
        current_identity={@current_identity}
      >
        <section id="club-site-layout-slot">Future club member page content</section>
      </Layouts.club_site>
      """)

    assert_selector(html, "#club-site-layout.app-frame[data-surface='club-site']")
    assert_selector(html, "#club-site-layout > .app-card")
    assert_selector(html, "#club-site-layout > .app-card > main > #club-site-layout-slot")
    assert_text(html, "#club-site-layout .app-card > header", "Riverside Tennis Club")
    assert_selector(html, "#club-site-layout > .app-card > header > .app-bar")

    assert_text(
      html,
      "#club-site-layout header .app-bar__brand .app-bar__club",
      "Riverside Tennis Club"
    )

    refute_selector(html, "#club-site-layout header .app-bar__club[href]")
    refute_selector(html, "#club-site-layout header a[href='/']")
    assert_selector(html, "#club-site-layout header .app-bar .dropdown.dropdown-end.app-bar__id")

    assert_selector(
      html,
      "#club-site-layout header details.app-bar__id > summary#club-site-identity-menu-button.app-bar__me[aria-controls='club-site-identity-menu'][aria-label='Member identity menu']"
    )

    assert_text(html, "#club-site-layout header .app-bar__avatar", "A")
    assert_text(html, "#club-site-layout header .app-bar__who", "alice")
    refute_text(html, "#club-site-layout header .app-bar__who", "alice@example.com")
    refute_text(html, "#club-site-layout header", "Powered by Memba")
    assert_selector(html, "#club-site-footer.app-foot")
    assert_text(html, "#club-site-footer", "Powered by Memba")

    assert_selector(
      html,
      "#club-site-footer a#club-site-footer-memba-home-link[href='#{ClubSite.root_url()}'][aria-label='Visit Memba home']"
    )

    assert_selector(
      html,
      "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id[role='menu']"
    )

    assert_selector(
      html,
      "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id form#club-site-sign-out-form[action='/auth'][method='post']"
    )

    assert_selector(
      html,
      "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id form#club-site-sign-out-form input[name='_method'][value='delete']"
    )

    assert [csrf_token] =
             attributes(
               html,
               "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id form#club-site-sign-out-form input[name='_csrf_token'][type='hidden']",
               "value"
             )

    assert String.trim(csrf_token) != ""

    assert_selector(
      html,
      "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id button#club-site-sign-out-button.app-menu__signout[type='submit'][role='menuitem']"
    )

    assert_text(html, "#club-site-sign-out-button", "Sign out")

    refute_text(html, "#club-site-footer", "Commit")

    assert only_attribute(html, "#club-site-layout", "class") == "app-frame"
    refute html =~ "--club-site-"
    assert [] = attributes(html, "#club-site-layout", "style")
  end

  test "club-site layout renders flash messages" do
    assigns = %{flash: %{"info" => "Club settings saved"}}

    html =
      rendered_to_string(~H"""
      <Layouts.club_site flash={@flash} club_name="Riverside Tennis Club">
        <section id="club-site-layout-slot-with-flash">Club member page content</section>
      </Layouts.club_site>
      """)

    assert_selector(html, "#club-site-layout-slot-with-flash")
    assert_selector(html, "#flash-group[aria-live='polite']")
    assert_selector(html, "#flash-info[role='alert']")
    assert_text(html, "#flash-info", "Club settings saved")
  end

  test "club-site layout gates the member identity dropdown when signed out" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Layouts.club_site flash={@flash} club_name="Riverside Tennis Club">
        <section id="public-club-site-layout-slot">Public club page content</section>
      </Layouts.club_site>
      """)

    assert_selector(html, "#club-site-layout header .app-bar")

    assert_text(
      html,
      "#club-site-layout header .app-bar__brand .app-bar__club",
      "Riverside Tennis Club"
    )

    refute_selector(html, "#club-site-layout header .app-bar .app-bar__id")
    refute_selector(html, "#club-site-layout header #club-site-identity-menu-button")
    refute_selector(html, "#club-site-layout header .app-bar__avatar")
    refute_selector(html, "#club-site-layout header .app-bar__who")
    refute_selector(html, "#club-site-layout header .app-menu")
    refute_selector(html, "#club-site-layout header #club-site-sign-out-form")
    refute_text(html, "#club-site-layout header", "Signed in as")
    assert_selector(html, "#public-club-site-layout-slot")
  end

  test "club-site layout accepts optional member names and derives name-like initials" do
    assigns = %{
      flash: %{},
      current_identity: %{email: "élodie.durand@example.com"},
      member_name: "Élodie Durand"
    }

    html =
      rendered_to_string(~H"""
      <Layouts.club_site
        flash={@flash}
        club_name="Riverside Tennis Club"
        current_identity={@current_identity}
        member_name={@member_name}
      >
        <section id="club-site-layout-slot-with-member-name">Club member page content</section>
      </Layouts.club_site>
      """)

    assert_selector(html, "#club-site-layout header .app-bar .app-bar__id")
    assert_text(html, "#club-site-layout header .app-bar__avatar", "ÉD")
    assert_text(html, "#club-site-layout header .app-bar__who", "Élodie Durand")
    refute_text(html, "#club-site-layout header .app-bar__who", "élodie.durand")
    assert_selector(html, "#club-site-layout-slot-with-member-name")
  end

  test "club-site layout falls back to email local-part identity when member name is missing" do
    assigns = %{
      flash: %{},
      current_identity: %{email: "alice.smith@example.com"},
      nil_member_name: nil,
      blank_member_name: "  "
    }

    nil_name_html =
      rendered_to_string(~H"""
      <Layouts.club_site
        flash={@flash}
        club_name="Riverside Tennis Club"
        current_identity={@current_identity}
        member_name={@nil_member_name}
      >
        <section id="club-site-layout-slot-with-nil-member-name">Club member page content</section>
      </Layouts.club_site>
      """)

    blank_name_html =
      rendered_to_string(~H"""
      <Layouts.club_site
        flash={@flash}
        club_name="Riverside Tennis Club"
        current_identity={@current_identity}
        member_name={@blank_member_name}
      >
        <section id="club-site-layout-slot-with-blank-member-name">Club member page content</section>
      </Layouts.club_site>
      """)

    for html <- [nil_name_html, blank_name_html] do
      assert_selector(html, "#club-site-identity-menu-button")
      assert_text(html, "#club-site-layout header .app-bar__avatar", "AS")
      assert_text(html, "#club-site-layout header .app-bar__who", "alice.smith")
      assert_selector(html, "#club-site-sign-out-button")
    end
  end

  test "root layout suppresses the public footer when member app chrome is active", %{conn: conn} do
    conn = Plug.Conn.assign(conn, :hide_public_footer, true)

    html =
      rendered_to_string(
        Layouts.root(%{
          conn: conn,
          inner_content:
            Phoenix.HTML.raw(
              ~s(<footer id="club-site-footer" class="app-foot">Powered by <a href="/">Memba</a></footer>)
            )
        })
      )

    assert_selector(html, "#club-site-footer.app-foot")
    assert_text(html, "#club-site-footer", "Powered by Memba")
    assert_selector_count(html, "footer", 1)
    refute html =~ "Red Donkey Technology Corp"
    refute html =~ "Footer navigation"
  end

  test "root layout keeps the public footer for public pages by default", %{conn: conn} do
    html = rendered_to_string(Layouts.root(%{conn: conn, inner_content: "Public page content"}))

    assert_text(html, "footer", "Red Donkey Technology Corp")
    assert_selector(html, "footer nav[aria-label='Footer navigation'] a[href='/about']")
    assert_selector(html, "footer nav[aria-label='Footer navigation'] a[href='/terms']")
    assert_selector(html, "footer nav[aria-label='Footer navigation'] a[href='/privacy']")

    assert_selector(
      html,
      "footer nav[aria-label='Footer navigation'] a[href='mailto:hello@memba.io']"
    )
  end

  test "root footer shows linked git commit when enabled" do
    System.put_env("MEMBA_GIT_SHA", @sha)
    Application.put_env(:memba, :show_git_commit_in_footer, true)

    html = rendered_to_string(Layouts.root(%{inner_content: "Page content"}))

    assert_text(html, "footer", "Commit")

    assert_selector(
      html,
      "footer a[href='https://github.com/mattwynne/memba/commit/#{@sha}']"
    )

    assert_text(html, "footer a", "abcdef0")
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered layout to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered layout not to include selector #{inspect(selector)}"
  end

  defp assert_selector_count(html, selector, expected_count) do
    actual_count =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> Enum.count()

    assert actual_count == expected_count,
           "Expected #{inspect(selector)} to match #{expected_count} elements, got #{actual_count}"
  end

  defp assert_text(html, selector, expected_text) do
    text = html |> selected_text(selector) |> normalize_whitespace()

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

  defp normalize_whitespace(text) when is_binary(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp only_attribute(html, selector, attribute) do
    attributes = attributes(html, selector, attribute)
    assert [value] = attributes
    value
  end

  defp attributes(html, selector, attribute) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(attribute)
  end

  defp restore_system_env(key, nil), do: System.delete_env(key)
  defp restore_system_env(key, value), do: System.put_env(key, value)
end
