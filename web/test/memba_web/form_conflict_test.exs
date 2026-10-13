defmodule MembaWeb.FormConflictTest do
  use ExUnit.Case, async: true
  alias MembaWeb.FormConflict

  test "untouched fields follow latest while dirty fields keep their baseline and raw draft" do
    state = FormConflict.new(%{name: "Alice", description: "Saved"})
    state = FormConflict.edit(state, %{name: "Robin", description: "Saved"})
    state = FormConflict.observe(state, %{name: "Jones", description: "New description"})
    assert state.baseline == %{name: "Alice", description: "New description"}
    assert state.draft == %{name: "Robin", description: "New description"}
    assert state.latest == %{name: "Jones", description: "New description"}
  end

  test "reverting to normalized baseline follows latest without rebasing dirty text" do
    normalize = fn value -> value |> String.split() |> Enum.join(" ") end
    state = FormConflict.new(%{name: "Alice Smith"}) |> FormConflict.edit(%{name: "Robin"})
    state = FormConflict.observe(state, %{name: "Alice Jones"}, normalize)
    assert state.baseline.name == "Alice Smith"
    state = FormConflict.edit(state, %{name: " Alice   Smith "})
    state = FormConflict.observe(state, state.latest, normalize)
    assert state.draft.name == "Alice Jones"
    assert state.baseline.name == "Alice Jones"
  end

  test "a rejected untouched field stays the displayed draft while unrelated untouched fields follow" do
    state =
      FormConflict.new(%{name: "Alice Smith", description: "Saved"})
      |> FormConflict.rejected(%{name: "Alice Jones"})
      |> FormConflict.observe(%{name: "Alice Green", description: "New description"})

    assert state.draft == %{name: "Alice Smith", description: "New description"}
    assert state.baseline == %{name: "Alice Smith", description: "New description"}
    assert state.confirmation == %{name: "Alice Jones"}
    assert state.latest == %{name: "Alice Green", description: "New description"}
  end

  test "each rejected attempt can be announced again even when the displayed value is unchanged" do
    state = FormConflict.new(%{name: "Alice"}) |> FormConflict.edit(%{name: "Robin"})
    first = FormConflict.rejected(state, %{name: "Jones"})
    second = FormConflict.rejected(first, %{name: "Jones"})
    assert second.warning_serial > first.warning_serial
    assert second.confirmation == first.confirmation
  end

  test "observing a newer value cannot change consent, but editing raw draft invalidates it" do
    state =
      FormConflict.new(%{name: "Alice"})
      |> FormConflict.edit(%{name: "Robin"})
      |> FormConflict.rejected(%{name: "Jones"})

    state = FormConflict.observe(state, %{name: "Green"})
    assert state.confirmation == %{name: "Jones"}
    assert FormConflict.edit(state, %{name: "Robin"}).confirmation == %{name: "Jones"}
    assert FormConflict.edit(state, %{name: " Robin "}).confirmation == nil
  end
end
