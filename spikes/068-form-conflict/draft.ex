defmodule ConflictSpike.Draft do
  @moduledoc """
  Flat, server-owned form state; values must already have comparable types.
  No actor, record identity, authorization, validation or persistence here.
  `attempt/2` describes a conditional PATCH, never a whole-record replacement.
  """
  defstruct [:baseline, :draft, :latest, warning: %{}]

  def new(values), do: %__MODULE__{baseline: values, draft: values, latest: values}

  def changes(state) do
    Map.reject(state.draft, fn {key, value} -> value == Map.fetch!(state.baseline, key) end)
  end

  # Accept only configured fields, not identity/permissions or client baselines.
  # Any edit invalidates the displayed confirmation; reversion resumes following.
  def edit(state, params) do
    draft = Map.merge(state.draft, Map.take(params, Map.keys(state.baseline)))
    state = %{state | draft: draft, warning: %{}}
    observe(state, state.latest)
  end

  def observe(state, latest) do
    latest = Map.take(latest, Map.keys(state.baseline))

    if changes(state) == %{} do
      new(latest)
    else
      %{state | latest: latest}
    end
  end

  def cancel(state, latest), do: new(Map.take(latest, Map.keys(state.baseline)))

  def attempt(state, action \\ :save) when action in [:save, :confirm] do
    changes = changes(state)
    expected = Map.take(state.baseline, Map.keys(changes))

    expected =
      if action == :confirm and state.warning != %{} do
        Map.merge(expected, state.warning)
      else
        expected
      end

    %{changes: changes, expected: expected}
  end

  # Called only with the domain's authoritative stale result, not a live projection.
  # The rejected attempt matters: another race must not silently rebase other edits.
  def rejected(state, attempt, current) do
    warning =
      current
      |> Map.take(Map.keys(attempt.changes))
      |> Map.reject(fn {key, value} ->
        value == Map.fetch!(attempt.expected, key) and
          value == Map.fetch!(state.baseline, key)
      end)

    %{state | latest: Map.take(current, Map.keys(state.baseline)), warning: warning}
  end
end
