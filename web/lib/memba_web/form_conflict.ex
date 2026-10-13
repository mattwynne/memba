defmodule MembaWeb.FormConflict do
  @moduledoc """
  Small server-owned state for flat existing-record edit forms.
  Values are raw drafts; field-specific validation and persistence stay outside.
  """
  # Announcement counter only; never a persistence or concurrency revision.
  defstruct [:baseline, :draft, :latest, :confirmation, warning_serial: 0]

  def new(values) when is_map(values) do
    %__MODULE__{baseline: values, draft: values, latest: values}
  end

  def observe(%__MODULE__{} = state, latest, normalize \\ &Function.identity/1)
      when is_map(latest) do
    Enum.reduce(latest, %{state | latest: latest}, fn {field, value}, state ->
      confirming_field? = is_map(state.confirmation) and Map.has_key?(state.confirmation, field)

      if not confirming_field? and
           normalize.(Map.fetch!(state.draft, field)) ==
             normalize.(Map.fetch!(state.baseline, field)) do
        %{
          state
          | baseline: Map.put(state.baseline, field, value),
            draft: Map.put(state.draft, field, value)
        }
      else
        state
      end
    end)
  end

  def rejected(%__MODULE__{} = state, latest) when is_map(latest) do
    %{state | latest: latest, confirmation: latest, warning_serial: state.warning_serial + 1}
  end

  def edit(%__MODULE__{} = state, draft) when is_map(draft) do
    %{
      state
      | draft: draft,
        confirmation: if(draft == state.draft, do: state.confirmation, else: nil)
    }
  end
end
