defmodule MembaWeb.FormConflictComponents do
  @moduledoc "Shared amber warning for conditional existing-record edits."
  use MembaWeb, :html

  attr :id, :string, required: true
  attr :state, :any, required: true
  slot :actions

  def warning(assigns) do
    ~H"""
    <div
      :if={@state && @state.confirmation}
      id={@id}
      role="alert"
      aria-atomic="true"
      tabindex="-1"
      phx-mounted={JS.focus()}
      phx-hook=".ConflictWarning"
      data-focus-event="focus_form_conflict"
      data-warning-value={Jason.encode!([@state.warning_serial, @state.confirmation])}
      class="mt-4 flex min-w-0 gap-3 rounded-lg border border-amber-300 bg-amber-50 p-4 text-amber-950"
    >
      <.icon name="hero-exclamation-triangle" class="size-5 shrink-0" />
      <div class="min-w-0 flex-1">
        <p :for={{_field, value} <- @state.confirmation} class="break-words font-semibold">
          Changed elsewhere to “{value}”.
        </p>
        <p class="mt-1 text-sm">Saving your edit will replace that value.</p>
        <div :if={@actions != []} class="mt-3 flex flex-wrap gap-2">{render_slot(@actions)}</div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ConflictWarning">
      export default {
        mounted() {
          this.warningValue = this.el.dataset.warningValue
          this.handleEvent(this.el.dataset.focusEvent, ({id}) => {
            if (id === this.el.id) requestAnimationFrame(() => this.el.focus())
          })
        },
        updated() {
          if (this.warningValue !== this.el.dataset.warningValue) {
            this.warningValue = this.el.dataset.warningValue
            requestAnimationFrame(() => this.el.focus())
          }
        }
      }
    </script>
    """
  end
end
