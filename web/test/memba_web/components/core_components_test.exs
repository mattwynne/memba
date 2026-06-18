defmodule MembaWeb.CoreComponentsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MembaWeb.CoreComponents

  describe "avatar/1" do
    test "renders the initials text" do
      html = render_avatar(initials: "MW")

      assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "MW"
      assert_class(html, "div.avatar", "avatar")
      assert_class(html, "div.avatar", "avatar-placeholder")
    end

    test "maps each size to its width class" do
      for {size, expected_class} <- [sm: "w-7", md: "w-9", lg: "w-12"] do
        html = render_avatar(initials: "MW", size: size)

        assert_class(html, "div.avatar > div", expected_class)
      end
    end

    test "picks a deterministic sage background from the cycle" do
      first_html = render_avatar(initials: "MW")
      second_html = render_avatar(initials: "MW")

      [first_bg] = avatar_bg_classes(first_html)
      [second_bg] = avatar_bg_classes(second_html)

      assert first_bg == second_bg
      assert first_bg in ~w(bg-sage-200 bg-sage-300 bg-sage-100 bg-sage-400 bg-sage-50)
    end

    test "forwards member-page attributes while keeping shared avatar classes" do
      html =
        render_avatar(
          id: "member-avatar",
          "data-testid": "club-member-row",
          title: "Alice Adams",
          initials: "AA",
          class: "shadow-sm"
        )

      assert_selector(
        html,
        "div#member-avatar.avatar.avatar-placeholder.shadow-sm[data-testid='club-member-row'][title='Alice Adams']"
      )
    end
  end

  describe "status_badge/1" do
    test "renders each semantic tone class" do
      for {tone, expected_class} <- [
            {"success", "badge-success"},
            {"info", "badge-info"},
            {"warning", "badge-warning"},
            {"error", "badge-error"}
          ] do
        html = render_status_badge(tone: tone, label: "Ready")

        assert_class(html, "span.badge", "badge")
        assert_class(html, "span.badge", "badge-soft")
        assert_class(html, "span.badge", expected_class)
      end
    end

    test "renders neutral without a colored badge class" do
      html = render_status_badge(tone: "neutral", label: "Ready")

      assert_class(html, "span.badge", "badge")
      assert_class(html, "span.badge", "badge-soft")
      refute_class(html, "span.badge", "badge-success")
      refute_class(html, "span.badge", "badge-info")
      refute_class(html, "span.badge", "badge-warning")
      refute_class(html, "span.badge", "badge-error")
    end

    test "renders the label text" do
      html = render_status_badge(label: "Active")

      assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "Active"
    end

    test "renders the leading dot" do
      html = render_status_badge(label: "Active")

      assert_selector(html, "span.badge span.rounded-full.bg-current")
      assert_class(html, "span.badge span.rounded-full.bg-current", "size-1.5")
    end

    test "forwards member receipt status attributes while keeping tone classes" do
      html =
        render_status_badge(
          tone: "warning",
          label: "Sending",
          "data-testid": "receipt-status",
          "data-receipt-status": "sent",
          "aria-label": "Delivery status for Alice Adams: Sending"
        )

      assert_selector(
        html,
        "span.badge.badge-soft.badge-warning[data-testid='receipt-status'][data-receipt-status='sent'][aria-label='Delivery status for Alice Adams: Sending']"
      )
    end
  end

  describe "button/1" do
    test "renders each variant class" do
      for {variant, expected_class} <- [
            {"primary", "btn-primary"},
            {"secondary", "btn-soft"},
            {"ghost", "btn-ghost"},
            {"danger", "btn-error"}
          ] do
        html = render_button(variant: variant)

        assert_class(html, "button", "btn")
        assert_class(html, "button", expected_class)
      end
    end

    test "renders each size class" do
      for {size, expected_class} <- [{"sm", "btn-sm"}, {"lg", "btn-lg"}] do
        html = render_button(size: size)

        assert_class(html, "button", "btn")
        assert_class(html, "button", expected_class)
      end
    end

    test "renders no size class by default" do
      html = render_button()

      refute_class(html, "button", "btn-sm")
      refute_class(html, "button", "btn-lg")
    end

    test "keeps variant and size classes when callers add layout classes" do
      html = render_button(variant: "ghost", size: "lg", class: "w-full justify-start")

      assert_class(html, "button", "btn")
      assert_class(html, "button", "btn-ghost")
      assert_class(html, "button", "btn-lg")
      assert_class(html, "button", "w-full")
      assert_class(html, "button", "justify-start")
    end

    test "renders disabled attribute" do
      html = render_button(disabled: true)

      assert_selector(html, "button[disabled]")
    end

    test "renders a button without navigation attributes" do
      html = render_button(rest: %{type: "submit"})

      assert_selector(html, "button[type='submit']")
      refute_selector(html, "a")
    end

    test "renders a link with href" do
      html = render_button(rest: %{href: "/clubs"})

      assert_selector(html, "a[href='/clubs']")
      refute_selector(html, "button")
    end

    test "renders a link with navigate" do
      html = render_button(rest: %{navigate: "/clubs"})

      assert_selector(
        html,
        "a[href='/clubs'][data-phx-link='redirect'][data-phx-link-state='push']"
      )

      refute_selector(html, "button")
    end
  end

  defp render_status_badge(assigns) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put_new(:label, "Ready")

    render_component(&CoreComponents.status_badge/1, assigns)
  end

  defp render_avatar(assigns) do
    render_component(&CoreComponents.avatar/1, Map.new(assigns))
  end

  defp render_button(assigns \\ []) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put(:inner_block, [%{inner_block: fn _, _ -> "Save" end}])

    render_component(&CoreComponents.button/1, assigns)
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component not to include selector #{inspect(selector)}"
  end

  defp assert_class(html, selector, expected_class) do
    assert expected_class in classes(html, selector),
           "Expected #{inspect(selector)} to include class #{inspect(expected_class)}"
  end

  defp refute_class(html, selector, unexpected_class) do
    refute unexpected_class in classes(html, selector),
           "Expected #{inspect(selector)} not to include class #{inspect(unexpected_class)}"
  end

  defp classes(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute("class")
    |> List.first("")
    |> String.split()
  end

  defp avatar_bg_classes(html) do
    html
    |> classes("div.avatar > div")
    |> Enum.filter(&String.starts_with?(&1, "bg-sage-"))
  end
end
