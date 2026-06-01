defmodule MembaWeb.MemberMessageLive.Show do
  @moduledoc """
  LiveView entry point for the member-facing message detail page.

  The router can reference this module as `MemberMessageLive.Show` from the
  existing `scope "/", MembaWeb` block, avoiding a duplicated `MembaWeb`
  namespace prefix when the member message route is moved from the controller.
  """
  use MembaWeb, :live_view

  alias MembaWeb.MemberMessageDetail

  @impl Phoenix.LiveView
  def mount(%{"club_id" => _club_id, "message_id" => _message_id} = params, _session, socket) do
    socket = ensure_identity_assigns(socket)

    case MemberMessageDetail.load(params, socket.assigns.current_identity_clubs) do
      {:ok, detail_assigns} ->
        {:ok,
         socket
         |> assign(:route_params, params)
         |> assign(detail_assigns)
         |> assign(:expanded_receipt_groups, MapSet.new())}

      {:error, :forbidden} ->
        forbidden!(socket)

      {:error, :not_found} ->
        not_found!(socket)
    end
  end

  def mount(params, _session, socket) when is_map(params) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, params)}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_receipt_group", %{"status" => status}, socket) do
    expanded_receipt_groups = toggle_receipt_group(socket, status)

    {:noreply, assign(socket, :expanded_receipt_groups, expanded_receipt_groups)}
  end

  @impl Phoenix.LiveView
  def render(%{message: _message} = assigns) do
    MembaWeb.PageHTML.message(assigns)
  end

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

  defp toggle_receipt_group(socket, status) do
    expanded_receipt_groups =
      socket.assigns
      |> Map.get(:expanded_receipt_groups, MapSet.new())
      |> MapSet.new()

    if MapSet.member?(expanded_receipt_groups, status) do
      MapSet.delete(expanded_receipt_groups, status)
    else
      MapSet.put(expanded_receipt_groups, status)
    end
  end

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)

  defp not_found!(socket) do
    case socket.private[:connect_info] do
      %Plug.Conn{} = conn ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: MembaWeb.Router

      _connect_info ->
        raise "message detail not found"
    end
  end
end
