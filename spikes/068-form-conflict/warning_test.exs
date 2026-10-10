Code.require_file("draft.ex", __DIR__)
Code.require_file("warning.ex", __DIR__)
Code.require_file("form.ex", __DIR__)
ExUnit.start()

defmodule ConflictSpike.WarningTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "one card lists only conflicts, uses existing amber/icon/buttons and escapes values" do
    html =
      render_component(&ConflictSpike.Warning.warning/1,
        id: "edit-conflict",
        values: %{"name" => "<script>"},
        labels: %{"name" => "Name", "phone" => "Phone"}
      )

    doc = LazyHTML.from_fragment(html)
    assert LazyHTML.filter(doc, "#edit-conflict[role=alert].bg-warning\\/10") |> Enum.count() == 1
    assert LazyHTML.query(doc, ".hero-exclamation-triangle") |> Enum.count() == 1
    assert LazyHTML.query(doc, "li[data-field=name]") |> LazyHTML.text() =~ "<script>"
    assert LazyHTML.query(doc, "script, li[data-field=phone]") |> Enum.count() == 0

    assert LazyHTML.query(doc, "#edit-conflict-confirm[type=button][phx-click=confirm]")
           |> LazyHTML.text()
           |> String.trim() == "Save anyway"

    assert LazyHTML.query(doc, "#edit-conflict-cancel[phx-click=cancel]")
           |> LazyHTML.text()
           |> String.trim() ==
             "Cancel my changes"
  end

  test "name-only and hypothetical two-field forms retain drafts and associate warning" do
    alias ConflictSpike.Draft

    for fields <- [[name: "Your name"], [name: "Your name", phone: "Phone (hypothetical)"]] do
      initial = Map.new(fields, fn {key, _} -> {Atom.to_string(key), "original"} end)
      state = Draft.new(initial) |> Draft.edit(%{"name" => "draft"})
      current = Map.put(initial, "name", "newer")
      state = Draft.rejected(state, Draft.attempt(state), current)

      doc =
        render_component(&ConflictSpike.Form.form_preview/1,
          id: "editor",
          state: state,
          fields: fields
        )
        |> LazyHTML.from_fragment()

      assert LazyHTML.query(doc, "#editor-name[value=draft][aria-describedby=editor-conflict]")
             |> Enum.count() == 1

      assert LazyHTML.query(doc, "#editor input[type=text]") |> Enum.count() == length(fields)
      assert LazyHTML.query(doc, "#editor-conflict li") |> Enum.count() == 1
      assert LazyHTML.query(doc, "#editor-save") |> Enum.count() == 0
    end
  end

  test "same component supports two conflicts and renders nothing without conflicts" do
    labels = %{"name" => "Name", "phone" => "Phone"}

    for values <- [%{}, %{"name" => "Alice Jones", "phone" => "222"}] do
      doc =
        render_component(&ConflictSpike.Warning.warning/1,
          id: "two-conflict",
          values: values,
          labels: labels
        )
        |> LazyHTML.from_fragment()

      assert LazyHTML.query(doc, "li") |> Enum.count() == map_size(values)

      assert LazyHTML.filter(doc, "#two-conflict") |> Enum.count() ==
               if(values == %{}, do: 0, else: 1)
    end
  end
end
