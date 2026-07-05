defmodule MembaWeb.AppShellCssTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @design_system_css Path.expand("../../../styles.css", __DIR__)
  @member_app_shell_marker "/* ============================================================\n   Member app shell components."

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
          ".app-menu__signout",
          ".app-foot",
          ".app-foot__mark"
        ] do
      assert css =~ selector
    end
  end

  test "Phoenix app-shell CSS stays in sync with the design-system mirror source" do
    assert member_app_shell_css(File.read!(@app_css)) == File.read!(@design_system_css)
  end

  defp member_app_shell_css(css) do
    [_before, member_app_shell_css] = String.split(css, @member_app_shell_marker, parts: 2)
    @member_app_shell_marker <> member_app_shell_css
  end
end
