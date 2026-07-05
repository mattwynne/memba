defmodule MembaWeb.AppCssTest do
  use ExUnit.Case, async: true

  @app_css_path Path.expand("../../assets/css/app.css", __DIR__)

  test "app css includes the club-home section tab and panel rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".section-tabs {"
    assert css =~ ".section-tabs__list {"
    assert css =~ ".section-tab {"
    assert css =~ ".section-tab.is-active {"
    assert css =~ ".section-tabs__action {"
    assert css =~ ".section-panel {"
    assert css =~ ".section-panel[hidden] {"

    assert css =~ "justify-content: space-between;"
    assert css =~ "border: 1px solid var(--color-line);"
    assert css =~ "background: var(--color-sage-600);"
    assert css =~ "display: none;"
  end
end
