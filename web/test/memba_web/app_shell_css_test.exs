defmodule MembaWeb.AppShellCssTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)

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
end
