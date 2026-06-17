defmodule MembaWeb.CoreComponentsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MembaWeb.CoreComponents

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

      assert_selector(html, "a[href='/clubs'][data-phx-link='redirect'][data-phx-link-state='push']")
      refute_selector(html, "button")
    end
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
end
