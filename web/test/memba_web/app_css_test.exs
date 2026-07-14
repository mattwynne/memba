defmodule MembaWeb.AppCssTest do
  use ExUnit.Case, async: true

  @app_css_path Path.expand("../../assets/css/app.css", __DIR__)
  @design_system_css_path Path.expand("../../../styles.css", __DIR__)

  test "app css imports the design-system stylesheet that defines the club-home section tab and panel rules" do
    # .section-tabs*/.section-panel live only in styles.css now (app.css @imports it,
    # Tailwind inlines it at build time) — see .design-sync/NOTES.md, 2026-07-14.
    assert File.read!(@app_css_path) =~ "@import \"../../../styles.css\";"

    css = File.read!(@design_system_css_path)

    assert css =~ ".section-tabs {"
    assert css =~ ".section-tabs__list {"
    assert css =~ ".section-tab {"
    assert css =~ ".section-tab.is-active {"
    assert css =~ ".section-tabs__action {"
    assert css =~ ".section-panel {"
    assert css =~ ".section-panel[hidden] {"

    assert css =~ "justify-content: space-between;"
    assert css =~ "border-bottom: 1px solid var(--color-line);"
    assert css =~ "border-bottom-color: var(--color-sage-500);"
    assert css =~ "display: none;"
  end

  test "app css includes the club-home member list and row rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".member-list {"
    assert css =~ ".member-row {"
    assert css =~ ".member-row__avatar {"
    assert css =~ ".member-row__body {"
    assert css =~ ".member-row__name {"
    assert css =~ ".member-row__meta {"
    assert css =~ ".member-row__role {"

    assert css =~ "flex-direction: column;"
    assert css =~ "border: 1px solid var(--color-line);"
    assert css =~ "background: var(--color-paper);"
    assert css =~ "color: var(--color-ink-3);"
    assert css =~ "text-overflow: ellipsis;"
  end

  test "app css includes the club-home conversation row and avatar-stack rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".conversation-list {"
    assert css =~ ".conversation {"
    assert css =~ ".conversation__avatar {"
    assert css =~ ".conversation__body {"
    assert css =~ ".conversation__head {"
    assert css =~ ".conversation__subject {"
    assert css =~ ".conversation__date {"
    assert css =~ ".conversation__preview {"
    assert css =~ ".conversation__participants {"
    assert css =~ ".conversation__replies {"
    assert css =~ ".avatar-stack {"
    assert css =~ ".avatar-stack > span,"
    assert css =~ ".avatar-stack > .avatar {"
    assert css =~ ".avatar-stack > .is-more {"

    assert css =~ "gap: 13px;"
    assert css =~ "line-clamp: 1;"
    assert css =~ "margin-left: -6px;"
    assert css =~ "font-family: var(--font-mono);"
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

  test "app css includes the conversation message, composer, and page title rules" do
    css = File.read!(@app_css_path)

    assert css =~ ".page-title {"
    assert css =~ ".message {"
    assert css =~ ".message--original {"
    assert css =~ ".message__avatar {"
    assert css =~ ".message__body {"
    assert css =~ ".message__head {"
    assert css =~ ".message__name {"
    assert css =~ ".message__time {"
    assert css =~ ".message__text {"
    assert css =~ ".message__menu {"
    assert css =~ ".message__kebab {"
    assert css =~ ".message-menu {"
    assert css =~ ".composer {"
    assert css =~ ".composer__head {"
    assert css =~ ".composer__title {"
    assert css =~ ".composer__as {"
    assert css =~ ".composer__actions {"
    assert css =~ ".composer__note {"
    assert css =~ ".composer__error {"

    assert css =~ "grid-template-columns: 38px minmax(0, 1fr);"
    assert css =~ "background: var(--color-sage-50);"
    assert css =~ "font-size: 28px;"
    assert css =~ "resize: vertical;"
    assert css =~ "color: var(--color-error);"
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
