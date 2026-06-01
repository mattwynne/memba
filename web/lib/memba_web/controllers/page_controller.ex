defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias Memba.Messaging

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
      when not is_nil(identity) do
    render_club_home(conn, club_id)
  end

  def home(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil ->
        not_found(conn)

      _club ->
        Phoenix.LiveView.Controller.live_render(conn, MembaWeb.ClubMarketingLive,
          session: %{"club_id" => club_id}
        )
    end
  end

  def home(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "My clubs"
      else
        "Membership made calm"
      end

    conn
    |> assign(:page_title, page_title)
    |> render(:home)
  end

  def send_message(%{assigns: %{current_identity: identity}} = conn, %{
        "club_id" => club_id,
        "message" => message_params
      })
      when not is_nil(identity) do
    selected_club = selected_club(conn, club_id)
    sender_id = Map.get(message_params, "sender_id")

    cond do
      is_nil(selected_club) ->
        not_found(conn)

      not Membership.active_member_of_club?(club_id, sender_id) ->
        conn
        |> put_flash(:error, "Choose an active member as the sender.")
        |> render_club_home(club_id, message_params)

      true ->
        attrs =
          message_params
          |> Map.take(["sender_id", "subject", "body"])
          |> Map.merge(%{
            "message_id" => Ecto.UUID.generate(),
            "club_id" => club_id
          })

        case Messaging.send_club_message(attrs, consistency: :strong) do
          :ok ->
            conn
            |> put_flash(:info, "Message sent")
            |> redirect(to: ~p"/?#{[club_id: club_id]}")

          {:ok, _result} ->
            conn
            |> put_flash(:info, "Message sent")
            |> redirect(to: ~p"/?#{[club_id: club_id]}")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Could not send message: #{format_reason(reason)}")
            |> render_club_home(club_id, message_params)
        end
    end
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def terms(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end

  defp render_club_home(
         conn,
         club_id,
         message_params \\ %{"sender_id" => "", "subject" => "", "body" => ""}
       ) do
    case selected_club(conn, club_id) do
      nil ->
        not_found(conn)

      selected_club ->
        members = Membership.list_active_members_of_club(club_id)
        messages = Messaging.list_messages_for_club(club_id)

        conn
        |> assign(:page_title, selected_club.name)
        |> assign(:selected_club, selected_club)
        |> assign(:members, members)
        |> assign(:member_options, Enum.map(members, &{&1.name, &1.id}))
        |> assign(:messages, messages)
        |> assign(:message_form, Phoenix.Component.to_form(message_params, as: :message))
        |> render(:club)
    end
  end

  defp selected_club(conn, club_id) do
    Enum.find(conn.assigns.current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end

  defp format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")
end
