defmodule MembaWeb.MemberMessageLive.Show do
  @moduledoc """
  LiveView entry point for the member-facing message detail page.

  The router can reference this module as `MemberMessageLive.Show` from the
  existing `scope "/", MembaWeb` block, avoiding a duplicated `MembaWeb`
  namespace prefix when the member message route is moved from the controller.
  """
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(params, _session, socket) when is_map(params) do
    {:ok, assign(socket, :route_params, params)}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :route_params, %{})}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site flash={@flash}>
      <div
        id="member-message-detail"
        data-live-view="member-message-detail"
        data-club-id={Map.get(@route_params, "club_id")}
        data-message-id={Map.get(@route_params, "message_id")}
        class="space-y-8"
      >
        <section class="overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            Club message
          </p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Member message detail
          </h1>
          <p class="mt-4 max-w-2xl leading-7 text-[var(--club-site-muted)]">
            This LiveView surface is ready for the existing member message route to load and
            render the selected club message.
          </p>
        </section>
      </div>
    </Layouts.club_site>
    """
  end
end
