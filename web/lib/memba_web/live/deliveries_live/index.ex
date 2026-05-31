defmodule MembaWeb.DeliveriesLive.Index do
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main id="deliveries-route" class="mx-auto max-w-6xl space-y-6 p-6">
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">
            Operator overview
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-zinc-900">Deliveries</h1>
          <p class="text-zinc-600">
            Delivery records will appear here as the overview table is implemented.
          </p>
        </section>
      </main>
    </Layouts.app>
    """
  end
end
