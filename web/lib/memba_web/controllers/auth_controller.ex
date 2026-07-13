defmodule MembaWeb.AuthController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Accounts
  alias Memba.Membership
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @invalid_link_notice "That sign-in link is no longer valid. Please ask for a new sign-in link."

  def callback(conn, %{"token" => token} = params) do
    return_to =
      Map.get(params, "return_to") || get_session(conn, IdentityAuth.return_to_session_key())

    case Accounts.consume_sign_in_token(token) do
      {:ok, %{email: email}} ->
        conn
        |> verify_pending_person_email_address_for_sign_in(email)
        |> IdentityAuth.log_in_identity(email)
        |> maybe_store_staff_onboarding_return_to(email, return_to)
        |> put_flash(:info, "Signed in.")
        |> redirect_after_sign_in(path_after_sign_in(email, return_to))

      {:error, :consumed} ->
        if signed_in?(conn) do
          redirect(conn, to: ~p"/")
        else
          reject_sign_in_link(conn, :consumed)
        end

      {:error, reason} ->
        reject_sign_in_link(conn, reason)
    end
  end

  def delete(conn, _params) do
    conn
    |> IdentityAuth.log_out_identity()
    |> put_flash(:info, "Signed out.")
    |> redirect(to: ~p"/")
  end

  defp reject_sign_in_link(conn, reason) do
    Logger.warning("Rejected auth sign-in link callback: #{inspect(reason)}")

    conn
    |> put_flash(:error, @invalid_link_notice)
    |> redirect(to: ~p"/auth")
  end

  defp signed_in?(conn), do: not is_nil(Map.get(conn.assigns, :current_identity))

  defp verify_pending_person_email_address_for_sign_in(conn, email) do
    case Membership.verify_pending_person_email_address_for_sign_in(email, consistency: :strong) do
      :ok ->
        conn

      {:error, reason} ->
        Logger.warning(
          "Could not verify pending person email address from sign-in link: #{inspect(reason)}"
        )

        conn
    end
  end

  defp safe_return_to(return_to) when is_binary(return_to) do
    cond do
      String.starts_with?(return_to, "//") -> nil
      String.starts_with?(return_to, "/") -> return_to
      ClubSite.safe_club_url?(return_to) -> return_to
      true -> nil
    end
  end

  defp safe_return_to(_return_to), do: nil

  defp path_after_sign_in(email, return_to) do
    cond do
      needs_staff_onboarding?(email) -> ~p"/auth/onboard"
      Accounts.staff_email?(email) -> safe_return_to(return_to) || ~p"/admin/clubs"
      true -> safe_return_to(return_to) || ~p"/"
    end
  end

  defp redirect_after_sign_in(conn, "http" <> _rest = url), do: redirect(conn, external: url)
  defp redirect_after_sign_in(conn, path), do: redirect(conn, to: path)

  defp needs_staff_onboarding?(email) do
    Accounts.staff_email?(email) and not staff_person?(email)
  end

  defp staff_person?(email), do: not is_nil(Membership.get_person_by_email(email))

  defp maybe_store_staff_onboarding_return_to(conn, email, return_to) do
    if needs_staff_onboarding?(email) do
      put_session(
        conn,
        IdentityAuth.staff_onboarding_return_to_session_key(),
        safe_return_to(return_to) || ~p"/admin/clubs"
      )
    else
      conn
    end
  end
end
