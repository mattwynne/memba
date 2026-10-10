defmodule ConflictSpike.Warning do
  use Phoenix.Component
  import MembaWeb.CoreComponents, only: [icon: 1, button: 1]

  attr(:id, :string, required: true)
  attr(:values, :map, required: true)
  attr(:labels, :map, required: true)
  attr(:confirm, :string, default: "confirm")
  attr(:cancel, :string, default: "cancel")

  def warning(assigns) do
    ~H"""
    <div
      :if={@values != %{}}
      id={@id}
      role="alert"
      class="mt-3 flex gap-3 rounded-xl border border-warning/35 bg-warning/10 p-3 text-sm"
    >
      <.icon name="hero-exclamation-triangle" class="size-5 shrink-0 text-warning" />
      <div class="min-w-0">
        <p class="font-semibold">Changed elsewhere</p>
        <ul class="break-words">
          <li :for={{key, value} <- Enum.sort(@values)} data-field={key}>
            {Map.fetch!(@labels, key)} is now <strong>“{value}”</strong>.
          </li>
        </ul>
        <p>Saving your changes will replace the values above.</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <.button id={@id <> "-confirm"} type="button" phx-click={@confirm}>
            Save anyway
          </.button>
          <.button id={@id <> "-cancel"} type="button" variant="ghost" phx-click={@cancel}>
            Cancel my changes
          </.button>
        </div>
      </div>
    </div>
    """
  end
end
