defmodule ConflictSpike.Form do
  @moduledoc "Render-only harness, not a routed LiveView. Phone is hypothetical."
  use Phoenix.Component
  import MembaWeb.CoreComponents, only: [input: 1, button: 1]
  import ConflictSpike.Warning

  attr(:id, :string, required: true)
  attr(:state, :any, required: true)
  attr(:fields, :list, required: true)

  def form_preview(assigns) do
    # Caller-owned field schema, not derived atoms from submitted keys.
    types = Map.new(assigns.fields, fn {field, _label} -> {field, :string} end)
    changeset = Ecto.Changeset.cast({%{}, types}, assigns.state.draft, Map.keys(types))

    assigns =
      assigns
      |> assign(:form, to_form(changeset, as: :draft))
      |> assign(
        :labels,
        Map.new(assigns.fields, fn {key, label} -> {Atom.to_string(key), label} end)
      )

    ~H"""
    <.form for={@form} id={@id} phx-change="edit" phx-submit="save">
      <.input
        :for={{field, label} <- @fields}
        field={@form[field]}
        id={@id <> "-" <> Atom.to_string(field)}
        type="text"
        label={label}
        aria-describedby={if Map.has_key?(@state.warning, Atom.to_string(field)), do: @id <> "-conflict"}
      />
      <.warning id={@id <> "-conflict"} values={@state.warning} labels={@labels} />
      <div :if={@state.warning == %{}} class="mt-3 flex flex-wrap gap-2">
        <.button id={@id <> "-save"} type="submit">Save</.button>
        <.button id={@id <> "-cancel"} type="button" variant="ghost" phx-click="cancel">
          Cancel my changes
        </.button>
      </div>
    </.form>
    """
  end
end
