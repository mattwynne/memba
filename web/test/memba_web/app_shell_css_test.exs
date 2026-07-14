defmodule MembaWeb.AppShellCssTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @design_system_css Path.expand("../../../styles.css", __DIR__)
  @design_system_import "@import \"../../../styles.css\";"

  test "app stylesheet imports the shared design-system stylesheet" do
    assert File.read!(@app_css) =~ @design_system_import,
           "app.css should import the design-system stylesheet once, rather than " <>
             "hand-duplicating its classes — that duplication is what let the club-home " <>
             "section tabs drift out of sync with the design in the first place " <>
             "(see .design-sync/NOTES.md, 2026-07-14)."
  end

  test "design-system stylesheet defines the shared member app shell and section-tab classes" do
    css = File.read!(@design_system_css)

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
          ".app-foot__mark",
          ".section-tabs",
          ".section-tabs__list",
          ".section-tabs__action",
          ".section-tab",
          ".section-panel"
        ] do
      assert css =~ selector
    end
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
end
