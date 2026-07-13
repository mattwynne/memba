defmodule MembaWeb.AppShellCssTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @design_system_css Path.expand("../../../styles.css", __DIR__)
  @member_app_shell_marker "/* ============================================================\n   Member app shell components."
  @club_home_section_tabs_marker "/* ============================================================\n   Club-home section tabs."

  test "app stylesheet defines the shared member app shell classes" do
    css = File.read!(@app_css)

    for selector <- [
          ".app-frame",
          ".app-card",
          ".app-bar",
          ".app-bar__brand",
          ".app-bar__club",
          ".app-bar__id",
          ".app-bar__me",
          ".app-bar__avatar",
          ".app-bar__who",
          ".app-menu",
          ".app-menu--id",
          ".app-menu__status",
          ".app-menu__item",
          ".app-menu__divider",
          ".app-menu__signout",
          ".app-foot",
          ".app-foot__mark"
        ] do
      assert css =~ selector
    end
  end

  test "Phoenix app-shell CSS stays in sync with the design-system mirror source" do
    assert member_app_shell_css(File.read!(@app_css)) ==
             member_app_shell_css(File.read!(@design_system_css))
  end

  test "design-system app-shell CSS defines every token it consumes" do
    css = File.read!(@design_system_css)

    defined_tokens =
      ~r/--[\w-]+(?=\s*:)/
      |> Regex.scan(css)
      |> List.flatten()
      |> MapSet.new()

    consumed_tokens =
      ~r/var\((--[\w-]+)/
      |> Regex.scan(css, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    assert MapSet.subset?(consumed_tokens, defined_tokens),
           "Missing design-system token definitions: #{inspect(MapSet.difference(consumed_tokens, defined_tokens))}"
  end

  defp member_app_shell_css(css) do
    [_before, member_app_shell_css] = String.split(css, @member_app_shell_marker, parts: 2)

    (@member_app_shell_marker <> member_app_shell_css)
    |> strip_club_home_section_tabs()
    |> strip_club_home_section_tab_media_rules()
  end

  defp strip_club_home_section_tabs(css) do
    case String.split(css, @club_home_section_tabs_marker, parts: 2) do
      [before, rest] ->
        [_section_tabs_css, after_section_tabs_css] =
          String.split(rest, "@media (max-width: 640px)", parts: 2)

        before <> "@media (max-width: 640px)" <> after_section_tabs_css

      [_css_without_section_tabs] ->
        css
    end
  end

  defp strip_club_home_section_tab_media_rules(css) do
    css
    |> String.replace(
      ~r/\n\s*\.section-tabs \{\n\s*align-items: stretch;\n\s*flex-direction: column;\n\s*\}\n/,
      "\n"
    )
    |> String.replace(
      ~r/\n\s*\.section-tabs__action,\n\s*\.section-tabs__action \.btn \{\n\s*width: 100%;\n\s*\}\n/,
      "\n"
    )
  end
end
