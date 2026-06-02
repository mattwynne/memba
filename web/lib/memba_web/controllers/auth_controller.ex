defmodule MembaWeb.AuthController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Membership
  alias MembaWeb.IdentityAuth

  @neutral_notice "Thanks. You should have an email in your inbox with a sign-in link."
  @invalid_link_notice "That sign-in link is invalid or has expired."

  def new(conn, _params) do
    render_sign_in(conn)
  end

  def sent(conn, _params) do
    conn
    |> assign(:page_title, "Check your email")
    |> assign(:notice, @neutral_notice)
    |> render(:sent)
  end

  def create(conn, params) do
    params
    |> email_param()
    |> request_and_deliver_sign_in_link(conn)

    redirect(conn, to: ~p"/auth/check-email")
  end

  def callback(conn, %{"token" => token}) do
    return_to = get_session(conn, IdentityAuth.return_to_session_key())

    case Accounts.consume_sign_in_token(token) do
      {:ok, %{email: email}} ->
        conn
        |> IdentityAuth.log_in_identity(email)
        |> maybe_store_staff_onboarding_return_to(email, return_to)
        |> put_flash(:info, "Signed in.")
        |> redirect(to: path_after_sign_in(email, return_to))

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

  def onboard(conn, _params) do
    if staff_person?(conn.assigns.current_identity_email) do
      redirect_after_staff_onboarding(conn)
    else
      render_staff_onboarding(conn)
    end
  end

  def create_onboarded_staff_person(conn, %{"staff" => %{"name" => name}}) do
    email = conn.assigns.current_identity_email

    case create_staff_person(email, name) do
      :ok ->
        conn
        |> put_flash(:info, "Welcome to Memba, #{String.trim(name)}.")
        |> redirect_after_staff_onboarding()

      {:error, reason} ->
        conn
        |> put_flash(:error, staff_onboarding_error(reason))
        |> render_staff_onboarding(%{"name" => name})
    end
  end

  def create_onboarded_staff_person(conn, _params) do
    conn
    |> put_flash(:error, "Please tell us your name.")
    |> render_staff_onboarding()
  end

  def delete(conn, _params) do
    conn
    |> IdentityAuth.log_out_identity()
    |> put_flash(:info, "Signed out.")
    |> redirect(to: ~p"/")
  end

  defp render_sign_in(conn) do
    conn
    |> assign(:page_title, "Sign in")
    |> assign(:form, Phoenix.Component.to_form(%{"email" => ""}, as: :auth))
    |> render(:new)
  end

  defp render_staff_onboarding(conn, params \\ %{"name" => ""}) do
    conn
    |> assign(:page_title, "Welcome to Memba")
    |> assign(:form, Phoenix.Component.to_form(params, as: :staff))
    |> render(:onboard)
  end

  defp email_param(%{"auth" => %{"email" => email}}), do: email
  defp email_param(_params), do: nil

  defp request_and_deliver_sign_in_link(email, conn) do
    case Accounts.request_sign_in_link(email) do
      {:ok, %{email: recipient_email, token: token}} ->
        deliver_sign_in_link(recipient_email, token, conn)

      {:ok, nil} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not create auth sign-in link: #{inspect(reason)}")
    end
  end

  defp deliver_sign_in_link(recipient_email, token, conn) do
    callback_url = url(conn, ~p"/auth/sign-in/#{token}")

    case AuthEmail.deliver_sign_in_link(recipient_email, callback_url) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not deliver auth sign-in link email: #{inspect(reason)}")
    end
  end

  defp reject_sign_in_link(conn, reason) do
    Logger.warning("Rejected auth sign-in link callback: #{inspect(reason)}")

    conn
    |> put_flash(:error, @invalid_link_notice)
    |> redirect(to: ~p"/auth")
  end

  defp signed_in?(conn), do: not is_nil(Map.get(conn.assigns, :current_identity))

  defp safe_return_to(return_to) when is_binary(return_to) do
    cond do
      String.starts_with?(return_to, "//") -> nil
      String.starts_with?(return_to, "/") -> return_to
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

  defp staff_onboarding_return_to(conn) do
    conn
    |> get_session(IdentityAuth.staff_onboarding_return_to_session_key())
    |> safe_return_to()
  end

  defp redirect_after_staff_onboarding(conn) do
    return_to = staff_onboarding_return_to(conn) || ~p"/admin/clubs"

    conn
    |> delete_session(IdentityAuth.staff_onboarding_return_to_session_key())
    |> redirect(to: return_to)
  end

  defp create_staff_person(email, name) do
    Membership.create_person(
      %{person_id: Ecto.UUID.generate(), name: name, email: email},
      consistency: :strong
    )
  end

  defp staff_onboarding_error(:invalid_name), do: "Please tell us your name."
  defp staff_onboarding_error(:email_address_taken), do: "That email address is already in use."
  defp staff_onboarding_error(reason), do: "Could not finish staff onboarding: #{inspect(reason)}"
end
