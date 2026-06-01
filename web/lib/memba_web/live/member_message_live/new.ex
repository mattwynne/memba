defmodule MembaWeb.MemberMessageLive.New do
  @moduledoc """
  LiveView entry point for the member-facing club message compose flow.

  The router references this module as `MemberMessageLive.New` from the
  `scope "/", MembaWeb` block, matching the existing member message LiveView
  namespace without duplicating the `MembaWeb` prefix.
  """
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(params, _session, socket) when is_map(params) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, params)}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site flash={@flash} current_identity={@current_identity}>
      <div
        id="member-message-compose"
        data-live-view="member-message-compose"
        data-club-id={Map.get(@route_params, "club_id")}
        class="space-y-8"
      >
        <section class="overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            New message
          </p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Send a club message
          </h1>
          <p class="mt-4 max-w-2xl leading-7 text-[var(--club-site-muted)]">
            This LiveView surface is ready for the focused member compose flow.
          </p>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end
end
