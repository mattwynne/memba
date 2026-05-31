defmodule MembaWeb.AuthController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias MembaWeb.UserAuth

  @neutral_notice "If we know that email, we sent a sign-in link."
  @invalid_link_notice "That sign-in link is invalid or has expired."

  def new(conn, _params) do
    render_sign_in(conn)
  end

  def create(conn, params) do
    params
    |> email_param()
    |> request_and_deliver_magic_link(conn)

    conn
    |> put_flash(:info, @neutral_notice)
    |> redirect(to: ~p"/auth")
  end

  def callback(conn, %{"token" => token}) do
    return_to = get_session(conn, UserAuth.return_to_session_key())

    case Accounts.consume_magic_token(token) do
      {:ok, %{email: email}} ->
        conn
        |> UserAuth.log_in_identity(email)
        |> put_flash(:info, "Signed in.")
        |> redirect(to: safe_return_to(return_to) || default_after_sign_in_path(email))

      {:error, reason} ->
        Logger.warning("Rejected auth magic link callback: #{inspect(reason)}")

        conn
        |> put_flash(:error, @invalid_link_notice)
        |> redirect(to: ~p"/auth")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_identity()
    |> put_flash(:info, "Signed out.")
    |> redirect(to: ~p"/")
  end

  defp render_sign_in(conn) do
    conn
    |> assign(:page_title, "Sign in")
    |> assign(:form, Phoenix.Component.to_form(%{"email" => ""}, as: :auth))
    |> render(:new)
  end

  defp email_param(%{"auth" => %{"email" => email}}), do: email
  defp email_param(_params), do: nil

  defp request_and_deliver_magic_link(email, conn) do
    case Accounts.request_magic_link(email) do
      {:ok, %{email: recipient_email, token: token}} ->
        deliver_magic_link(recipient_email, token, conn)

      {:ok, nil} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not create auth magic link: #{inspect(reason)}")
    end
  end

  defp deliver_magic_link(recipient_email, token, conn) do
    callback_url = url(conn, ~p"/auth/magic/#{token}")

    case AuthEmail.deliver_magic_link(recipient_email, callback_url) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not deliver auth magic link email: #{inspect(reason)}")
    end
  end

  defp safe_return_to(return_to) when is_binary(return_to) do
    cond do
      String.starts_with?(return_to, "//") -> nil
      String.starts_with?(return_to, "/") -> return_to
      true -> nil
    end
  end

  defp safe_return_to(_return_to), do: nil

  defp default_after_sign_in_path(email) do
    if Accounts.staff_email?(email) do
      ~p"/admin/clubs"
    else
      ~p"/"
    end
  end
end
