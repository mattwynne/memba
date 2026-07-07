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

  test "app css includes the conversation detail head and follow toggle rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".detail-head {"
    assert css =~ ".detail-head__main {"
    assert css =~ ".follow-toggle {"
    assert css =~ ".follow-toggle input {"
    assert css =~ ".follow-toggle__text {"
    assert css =~ ".follow-toggle__text strong {"
    assert css =~ ".follow-toggle__text span {"

    assert css =~ "align-items: flex-start;"
    assert css =~ "border-radius: 999px;"
    assert css =~ "cursor: pointer;"
    assert css =~ "white-space: nowrap;"
  end

  test "app css includes the delivery details summary, group, recipient, and status tint rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".delivery-title {"
    assert css =~ ".delivery-meta {"
    assert css =~ ".delivery-summary {"
    assert css =~ ".delivery-summary__head {"
    assert css =~ ".delivery-summary__title {"
    assert css =~ ".delivery-summary__count {"
    assert css =~ ".delivery-bar {"
    assert css =~ ".delivery-bar > span {"
    assert css =~ ".delivery-legend {"
    assert css =~ ".delivery-legend__item {"
    assert css =~ ".delivery-legend__sw {"
    assert css =~ ".delivery-group {"
    assert css =~ ".delivery-group__btn {"
    assert css =~ ".delivery-group__ic {"
    assert css =~ ".delivery-group__rows {"
    assert css =~ ".recipient {"
    assert css =~ ".recipient__id {"
    assert css =~ ".recipient__av {"
    assert css =~ ".recipient__reason {"
    assert css =~ ".deliv-ok {"
    assert css =~ ".deliv-snd {"
    assert css =~ ".deliv-bad {"
    assert css =~ ".deliv-tint-ok {"
    assert css =~ ".deliv-tint-snd {"
    assert css =~ ".deliv-tint-bad {"
  end
end
