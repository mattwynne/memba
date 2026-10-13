defmodule MembaWeb.FormConflictComponentsTest do
  use MembaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "a repeated same-value rejection changes the warning focus/announcement marker" do
    state =
      MembaWeb.FormConflict.new(%{name: "Alice"}) |> MembaWeb.FormConflict.edit(%{name: "Robin"})

    first = MembaWeb.FormConflict.rejected(state, %{name: "Jones"})
    second = MembaWeb.FormConflict.rejected(first, %{name: "Jones"})

    marker = fn state ->
      render_component(&MembaWeb.FormConflictComponents.warning/1, id: "warning", state: state)
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#warning")
      |> LazyHTML.attribute("data-warning-value")
    end

    refute marker.(first) == marker.(second)
  end

  test "a new shared warning is an announced focusable card and focuses when mounted" do
    state =
      MembaWeb.FormConflict.new(%{name: "Alice"})
      |> MembaWeb.FormConflict.edit(%{name: "Robin"})
      |> MembaWeb.FormConflict.rejected(%{name: "Jones"})

    html =
      render_component(&MembaWeb.FormConflictComponents.warning/1, id: "warning", state: state)

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(
             document,
             "#warning[role='alert'][tabindex='-1'][aria-atomic='true'][phx-mounted]"
           )
           |> Enum.count() == 1

    assert LazyHTML.filter(document, "#warning[phx-hook][data-warning-value]") |> Enum.count() ==
             1

    assert LazyHTML.query(document, "#warning[data-focus-event='focus_form_conflict']")
           |> Enum.count() == 1
  end
end
