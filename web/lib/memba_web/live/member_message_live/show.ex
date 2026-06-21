defmodule MembaWeb.MemberMessageLive.Show do
  @moduledoc """
  LiveView entry point for the member-facing message detail page.

  The router can reference this module as `MemberMessageLive.Show` from the
  existing `scope "/", MembaWeb` block, avoiding a duplicated `MembaWeb`
  namespace prefix when the member message route is moved from the controller.
  """
  use MembaWeb, :live_view

  require Logger

  alias Memba.Messaging
  alias Memba.ReadModelChanges
  alias MembaWeb.MemberMessageDetail

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    case params do
      %{"club_id" => _club_id, "message_id" => _message_id} ->
        case MemberMessageDetail.load(
               params,
               socket.assigns.current_identity_clubs,
               socket.assigns.current_identity
             ) do
          {:ok, detail_assigns} ->
            if connected?(socket) do
              Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
            end

            {:ok,
             socket
             |> assign(:route_params, params)
             |> assign(detail_assigns)
             |> assign_initial_reply_state()
             |> assign(:expanded_receipt_groups, MapSet.new())}

          {:error, :forbidden} ->
            forbidden!(socket)

          {:error, :not_found} ->
            not_found!(socket)
        end

      _params ->
        {:ok, assign(socket, :route_params, params)}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed,
         %{projector: Memba.Messaging.Projectors.MemberEmailDelivery, source_event: event}},
        %{assigns: %{message: message}} = socket
      ) do
    if Map.get(event, :message_id) == message.message_id do
      {:noreply, refresh_message_detail(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {:read_model_changed,
         %{projector: Memba.Messaging.Projectors.Message, source_event: event}},
        %{assigns: %{message: message}} = socket
      ) do
    if Map.get(event, :conversation_id) == message.conversation_id do
      {:noreply, refresh_message_detail(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("toggle_receipt_group", %{"status" => status}, socket) do
    expanded_receipt_groups = toggle_receipt_group(socket, status)

    {:noreply, assign(socket, :expanded_receipt_groups, expanded_receipt_groups)}
  end

  def handle_event("post_reply", %{"reply" => reply_params}, socket) do
    if blank_reply_body?(reply_params) do
      {:noreply,
       socket
       |> assign(:reply_state, :composing)
       |> assign(:reply_body_error, "Reply body can’t be blank.")
       |> assign(:reply_error, nil)
       |> assign(:reply_form, reply_form(reply_params))}
    else
      case post_current_member_reply(socket, reply_params) do
        {:ok, _reply_message_id} ->
          {:noreply,
           socket
           |> refresh_message_detail()
           |> assign(:reply_state, :posted)
           |> assign(:reply_body_error, nil)
           |> assign(:reply_error, nil)
           |> assign(:reply_form, reply_form())}

        {:error, reason} ->
          log_reply_failure(socket, reason)

          {:noreply,
           socket
           |> assign(:reply_state, :failed)
           |> assign(:reply_body_error, nil)
           |> assign(:reply_error, reason)
           |> assign(:reply_form, reply_form(reply_params))}
      end
    end
  end

  def handle_event("post_reply", _params, socket) do
    handle_event("post_reply", %{"reply" => %{}}, socket)
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
        <section class="overflow-hidden rounded-3xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-primary">
            Club message
          </p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-base-content">
            Member message detail
          </h1>
          <p class="mt-4 max-w-2xl leading-7 text-ink-2">
            This LiveView surface is ready for the existing member message route to load and
            render the selected club message.
          </p>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp put_session_club_id(params, session) do
    case {Map.get(params, "club_id"), Map.get(session, "club_id")} do
      {nil, club_id} when is_binary(club_id) -> Map.put(params, "club_id", club_id)
      _club_id_present_or_missing -> params
    end
  end

  defp put_club_id_source(params, session) do
    case Map.get(session, "club_id_source") do
      "host" -> Map.put(params, "club_id_source", "host")
      _source -> params
    end
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

  defp refresh_message_detail(socket) do
    case MemberMessageDetail.load(
           socket.assigns.route_params,
           socket.assigns.current_identity_clubs,
           socket.assigns.current_identity
         ) do
      {:ok, detail_assigns} ->
        assign(socket, detail_assigns)

      {:error, :forbidden} ->
        forbidden!(socket)

      {:error, :not_found} ->
        not_found!(socket)
    end
  end

  defp assign_initial_reply_state(socket) do
    socket
    |> assign(:reply_state, :composing)
    |> assign(:reply_body_error, nil)
    |> assign(:reply_error, nil)
    |> assign(:reply_form, reply_form())
  end

  defp post_current_member_reply(socket, reply_params) do
    with %{message: %{conversation_id: conversation_id}, current_member: %{id: sender_id}} <-
           socket.assigns do
      reply_message_id = Memba.ID.generate(:message)

      attrs = %{
        "message_id" => reply_message_id,
        "conversation_id" => conversation_id,
        "sender_id" => sender_id,
        "body" => Map.get(reply_params, "body", "")
      }

      case Messaging.post_message_reply(attrs, consistency: :strong) do
        :ok -> {:ok, reply_message_id}
        {:ok, _result} -> {:ok, reply_message_id}
        {:error, reason} -> {:error, reason}
      end
    else
      _missing_reply_context -> {:error, :forbidden}
    end
  end

  defp blank_reply_body?(reply_params) do
    reply_params
    |> Map.get("body", "")
    |> to_string()
    |> String.trim()
    |> Kernel.==("")
  end

  defp reply_form do
    reply_form(%{"body" => ""})
  end

  defp reply_form(reply_params) do
    reply_params
    |> Map.take(["body"])
    |> Map.put_new("body", "")
    |> to_form(as: :reply)
  end

  defp log_reply_failure(socket, reason) do
    Logger.error("Member message reply failed",
      club_id: socket.assigns.selected_club.club_id,
      conversation_id: socket.assigns.message.conversation_id,
      sender_id: current_member_id(socket.assigns.current_member),
      reason: inspect(reason)
    )
  end

  defp current_member_id(nil), do: nil
  defp current_member_id(current_member), do: current_member.id

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
