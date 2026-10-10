defmodule ConflictSpike.FakeRecord do
  @moduledoc "Test-only atomic writer. NOT a Person command or production adapter."

  # One pure transition represents the domain's serialized compare-and-write.
  # Authorization and validation remain outside the coordinator, even on confirm.
  def save(_current, _attempt, :denied), do: {:error, :forbidden}

  def save(current, attempt, :allowed) do
    cond do
      Enum.any?(attempt.changes, fn {_key, value} -> String.trim(value) == "" end) ->
        {:error, :invalid}

      Enum.any?(attempt.expected, fn {key, value} -> Map.fetch!(current, key) != value end) ->
        {:stale, current}

      true ->
        {:ok, Map.merge(current, attempt.changes)}
    end
  end
end
