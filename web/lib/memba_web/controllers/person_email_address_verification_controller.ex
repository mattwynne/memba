defmodule MembaWeb.PersonEmailAddressVerificationController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Membership

  def callback(conn, %{"token" => token}) when is_binary(token) do
    case verify_email_address_from_token(token) do
      {:ok, _request} ->
        render_success(conn)

      {:error, reason} ->
        Logger.warning("Rejected person email-address verification link: #{inspect(reason)}")
        render_invalid(conn)
    end
  end

  defp verify_email_address_from_token(token) do
    with {:ok, request} <- Membership.consume_person_email_address_verification_token(token),
         :ok <-
           verify_person_email_address(request) do
      {:ok, request}
    end
  end

  defp verify_person_email_address(%{person_id: person_id, email: email}) do
    case Membership.verify_person_email_address(
           %{person_id: person_id, email: email},
           consistency: :strong
         ) do
      :ok -> :ok
      {:ok, _result} -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp render_success(conn) do
    conn
    |> assign(:hide_public_footer, true)
    |> assign(:page_title, "Email verification")
    |> assign(:status, :success)
    |> assign(:icon, "hero-check")
    |> assign(:icon_tone, "border-success/30 bg-success/10 text-success")
    |> assign(:heading, "Email verified, you can close this browser.")
    |> assign(
      :message,
      "This email address is now verified for your Memba account."
    )
    |> render(:callback)
  end

  defp render_invalid(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> assign(:hide_public_footer, true)
    |> assign(:page_title, "Email verification link invalid or expired")
    |> assign(:status, :invalid)
    |> assign(:icon, "hero-envelope")
    |> assign(:icon_tone, "border-base-300 bg-base-200 text-ink-3")
    |> assign(:heading, "This verification link is invalid or expired.")
    |> assign(
      :message,
      "You can close this browser and ask for another verification email."
    )
    |> render(:callback)
  end
end
