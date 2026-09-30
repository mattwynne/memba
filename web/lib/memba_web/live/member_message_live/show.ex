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
  alias MembaWeb.LiveQuery.Binding
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.MemberMessageDetailQuery

  @message_detail_query_id :member_message_detail

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)

    socket =
      socket
      |> ensure_identity_assigns()
      |> assign(:current_identity_email, identity_email(socket.assigns[:current_identity]))
      |> assign(:route_params, params)
      |> assign_initial_reply_state()
      |> assign(:expanded_receipt_groups, MapSet.new())

    case params do
      %{"club_id" => _club_id, "message_id" => _message_id} ->
        case Binding.bind(
               socket,
               MemberMessageDetailQuery.query(),
               message_detail_query_inputs(socket),
               MembaReadModelSource.new()
             ) do
          {:ok, socket} ->
            {:ok, synchronize_message_detail_shell(socket)}

          {:error, errors, socket} ->
            initial_binding_error!(errors, socket)
        end

      _params ->
        not_found!(socket)
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def handle_info({:read_model_changed, _change} = notification, socket) do
    case Binding.handle_notification(socket, notification) do
      {:ignored, socket} ->
        {:noreply, socket}

      {:ok, socket} ->
        {:noreply, synchronize_message_detail_shell(socket)}

      {:error, errors, socket} ->
        {:noreply, refresh_binding_error(errors, socket)}
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

  def handle_event("follow_conversation", _params, socket) do
    update_current_member_follow(socket, :follow)
  end

  def handle_event("unfollow_conversation", _params, socket) do
    update_current_member_follow(socket, :unfollow)
  end

  def handle_event("post_reply", _params, socket) do
    handle_event("post_reply", %{"reply" => %{}}, socket)
  end

  @impl Phoenix.LiveView
  def render(%{message_detail: message_detail} = assigns) when is_map(message_detail) do
    assigns
    |> assign(message_detail)
    |> MembaWeb.PageHTML.message()
  end

  def render(%{message_detail: nil} = assigns) do
    ~H"""
    <div id="member-message-detail-cleared"></div>
    """
  end

  def render(_assigns) do
    raise "MemberMessageLive.Show requires a loaded message before rendering"
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
    case Binding.rebind(
           socket,
           @message_detail_query_id,
           message_detail_query_inputs(socket)
         ) do
      {:ok, socket} ->
        synchronize_message_detail_shell(socket)

      {:error, errors, socket} ->
        refresh_binding_error(errors, socket)
    end
  end

  defp message_detail_query_inputs(socket) do
    %{
      club_id: Map.get(socket.assigns.route_params, "club_id"),
      message_id: Map.get(socket.assigns.route_params, "message_id"),
      authenticated_email: socket.assigns.current_identity_email
    }
  end

  defp synchronize_message_detail_shell(
         %{assigns: %{message_detail: %{page_title: page_title}}} = socket
       ) do
    assign(socket, :page_title, page_title)
  end

  defp synchronize_message_detail_shell(socket), do: socket

  defp initial_binding_error!(
         [{@message_detail_query_id, :forbidden} | _errors],
         socket
       ),
       do: forbidden!(socket)

  defp initial_binding_error!(
         [{@message_detail_query_id, :not_found} | _errors],
         socket
       ),
       do: not_found!(socket)

  defp initial_binding_error!(errors, _socket) do
    raise "member message detail live query failed: #{inspect(errors)}"
  end

  defp refresh_binding_error(errors, socket) do
    if Enum.any?(errors, fn
         {@message_detail_query_id, reason} when reason in [:forbidden, :not_found] -> true
         _other -> false
       end) do
      socket
      |> assign(:page_title, nil)
      |> push_navigate(to: access_lost_path(socket.assigns.route_params))
    else
      raise "member message detail live query refresh failed: #{inspect(errors)}"
    end
  end

  defp update_current_member_follow(socket, action) do
    case current_member_follow_attrs(socket) do
      {:ok, attrs} ->
        dispatch_current_member_follow(socket, action, attrs)

      {:error, :forbidden} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Only current club members can follow conversations in Memba."
         )}
    end
  end

  defp dispatch_current_member_follow(socket, action, attrs) do
    case run_current_member_follow_action(action, attrs) do
      :ok ->
        {:noreply, refresh_message_detail(socket)}

      {:ok, _result} ->
        {:noreply, refresh_message_detail(socket)}

      {:error, reason} ->
        log_follow_failure(socket, action, reason)

        {:noreply,
         put_flash(
           socket,
           :error,
           "Your conversation notification setting was not changed. Please try again."
         )}
    end
  end

  defp current_member_follow_attrs(socket) do
    with %{
           message_detail: %{
             selected_club: %{club_id: club_id},
             conversation_audience: %{conversation_id: conversation_id},
             current_member: %{id: member_id}
           }
         } <- socket.assigns do
      {:ok,
       %{
         club_id: club_id,
         conversation_id: conversation_id,
         member_id: member_id
       }}
    else
      _missing_follow_context -> {:error, :forbidden}
    end
  end

  defp run_current_member_follow_action(:follow, attrs) do
    Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)
  end

  defp run_current_member_follow_action(:unfollow, attrs) do
    Messaging.unfollow_conversation_as_current_member(attrs, consistency: :strong)
  end

  defp assign_initial_reply_state(socket) do
    socket
    |> assign(:reply_state, :composing)
    |> assign(:reply_body_error, nil)
    |> assign(:reply_error, nil)
    |> assign(:reply_form, reply_form())
  end

  defp post_current_member_reply(socket, reply_params) do
    with %{
           message_detail: %{
             conversation_audience: %{conversation_id: conversation_id},
             current_member: %{id: sender_id}
           }
         } <-
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
    detail = socket.assigns.message_detail

    Logger.error("Member message reply failed",
      club_id: detail.selected_club.club_id,
      conversation_id: detail.conversation_audience.conversation_id,
      sender_id: current_member_id(detail.current_member),
      reason: inspect(reason)
    )
  end

  defp log_follow_failure(socket, action, reason) do
    detail = socket.assigns.message_detail

    Logger.error("Member conversation follow setting failed",
      action: action,
      club_id: detail.selected_club.club_id,
      conversation_id: detail.conversation_audience.conversation_id,
      member_id: current_member_id(detail.current_member),
      reason: inspect(reason)
    )
  end

  defp current_member_id(nil), do: nil
  defp current_member_id(current_member), do: current_member.id

  defp access_lost_path(%{"group_id" => group_id})
       when is_binary(group_id) and group_id != "",
       do: ~p"/groups/#{group_id}"

  defp access_lost_path(_route_params), do: ~p"/conversations"

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp identity_email(%{email: email}), do: email
  defp identity_email(_identity), do: nil

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
