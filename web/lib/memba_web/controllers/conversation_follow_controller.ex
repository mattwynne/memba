defmodule MembaWeb.ConversationFollowController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Membership
  alias Memba.Messaging
  alias MembaWeb.ClubSite

  def stop_following(conn, %{"token" => token}) do
    case Messaging.stop_following_conversation_from_email_token(token, consistency: :strong) do
      {:ok, scope} ->
        render_stop_following_success(conn, scope)

      {:error, reason} ->
        Logger.warning("Rejected conversation stop-follow link: #{inspect(reason)}")
        render_stop_following_failure(conn)
    end
  end

  defp render_stop_following_success(conn, scope) do
    conn
    |> assign(:page_title, "Stopped following")
    |> assign(:status, :success)
    |> assign(:conversation_url, conversation_url(scope))
    |> render(:stop_following)
  end

  defp render_stop_following_failure(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> assign(:page_title, "Stop-follow link not valid")
    |> assign(:status, :failure)
    |> assign(:conversation_url, nil)
    |> render(:stop_following)
  end

  defp conversation_url(%{club_id: club_id, conversation_id: conversation_id}) do
    case Membership.get_club(club_id) do
      nil -> nil
      club -> ClubSite.url(club, "/messages/#{conversation_id}")
    end
  end
end
