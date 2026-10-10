Code.require_file("draft.ex", __DIR__)
Code.require_file("fake_record.ex", __DIR__)
ExUnit.start()

defmodule ConflictSpike.DraftTest do
  use ExUnit.Case, async: true
  alias ConflictSpike.{Draft, FakeRecord}

  @original %{"name" => "Alice Smith", "phone" => "111"}

  test "untouched follows latest; dirty draft and baseline stay, reversion resumes following" do
    latest = %{@original | "name" => "Alice Jones"}
    assert Draft.observe(Draft.new(@original), latest).draft == latest
    dirty = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown"})
    observed = Draft.observe(dirty, latest)
    assert observed.draft == dirty.draft
    assert observed.baseline == @original
    assert observed.warning == %{}
    assert Draft.edit(observed, %{"name" => "Alice Smith"}).draft == latest
  end

  test "name only: no notification, stale save, explicit confirmation, repeat race" do
    state = Draft.new(%{"name" => "Alice Smith"}) |> Draft.edit(%{"name" => "Alice Brown"})
    current = %{"name" => "Alice Jones"}
    attempt = Draft.attempt(state)
    assert {:stale, ^current} = FakeRecord.save(current, attempt, :allowed)
    warned = Draft.rejected(state, attempt, current)
    assert warned.warning == current
    assert {:stale, ^current} = FakeRecord.save(current, Draft.attempt(warned), :allowed)

    assert {:ok, %{"name" => "Alice Brown"}} =
             FakeRecord.save(current, Draft.attempt(warned, :confirm), :allowed)

    newer = %{"name" => "Robin Jones"}
    observed = Draft.observe(warned, newer)
    assert observed.warning == current
    confirm = Draft.attempt(observed, :confirm)
    assert {:stale, ^newer} = FakeRecord.save(newer, confirm, :allowed)
    again = Draft.rejected(observed, confirm, newer)
    assert again.warning == newer
    assert again.draft == state.draft

    assert {:ok, %{"name" => "Alice Brown"}} =
             FakeRecord.save(newer, Draft.attempt(again, :confirm), :allowed)
  end

  test "hypothetical two-field edit preserves fields actor did not edit" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown", "phone" => "111"})
    current = %{@original | "phone" => "222"} |> Map.put("private", "untouched")
    assert Draft.attempt(state).changes == %{"name" => "Alice Brown"}
    assert {:ok, saved} = FakeRecord.save(current, Draft.attempt(state), :allowed)
    assert saved == %{"name" => "Alice Brown", "phone" => "222", "private" => "untouched"}
  end

  test "two dirty fields: one then both conflict; confirmation covers all shown values" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown", "phone" => "333"})
    current = %{@original | "name" => "Alice Jones"}
    warned = Draft.rejected(state, Draft.attempt(state), current)
    assert warned.warning == %{"name" => "Alice Jones"}
    confirm = Draft.attempt(warned, :confirm)
    newer = %{current | "phone" => "222"}
    assert {:stale, ^newer} = FakeRecord.save(newer, confirm, :allowed)
    again = Draft.rejected(warned, confirm, newer)
    assert again.warning == newer
    assert {:ok, saved} = FakeRecord.save(newer, Draft.attempt(again, :confirm), :allowed)
    assert saved == state.draft
  end

  test "repeat race back to baseline still warns with that newly encountered value" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown"})
    warned = Draft.rejected(state, Draft.attempt(state), %{@original | "name" => "Alice Jones"})
    confirm = Draft.attempt(warned, :confirm)
    assert {:stale, @original} = FakeRecord.save(@original, confirm, :allowed)
    again = Draft.rejected(warned, confirm, @original)
    assert again.warning == %{"name" => "Alice Smith"}
  end

  test "cancel discards whole draft and warning, adopts latest without writer call" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown", "phone" => "333"})
    current = %{@original | "name" => "Alice Jones"}
    warned = Draft.rejected(state, Draft.attempt(state), current)
    latest = %{current | "phone" => "444"}
    cancelled = Draft.cancel(warned, latest)
    assert cancelled == Draft.new(latest)
    assert Draft.attempt(cancelled).changes == %{}
  end

  test "confirmation cannot bypass domain authorization or validation; edits invalidate warning" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown", "actor_id" => "fake"})
    current = %{@original | "name" => "Alice Jones"}
    warned = Draft.rejected(state, Draft.attempt(state), current)

    assert {:error, :forbidden} =
             FakeRecord.save(current, Draft.attempt(warned, :confirm), :denied)

    edited = Draft.edit(warned, %{"name" => " "})
    assert edited.warning == %{}
    refute Map.has_key?(edited.draft, "actor_id")

    assert {:error, :invalid} =
             FakeRecord.save(current, Draft.attempt(edited, :confirm), :allowed)
  end

  test "preflight is not protection: intervening write must be rejected at writer" do
    state = Draft.new(@original) |> Draft.edit(%{"name" => "Alice Brown"})
    attempt = Draft.attempt(state)
    assert {:ok, _} = FakeRecord.save(@original, attempt, :allowed)
    intervening = %{@original | "name" => "Alice Jones"}
    assert {:stale, ^intervening} = FakeRecord.save(intervening, attempt, :allowed)
  end
end
