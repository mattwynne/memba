defmodule MembaWeb.PersonEmailAddressVerificationController do
  use MembaWeb, :controller

  @doc """
  Render the email-address verification callback page.

  Token consumption and final success/invalid states are implemented by the next
  iteration task; this action establishes the public callback route and
  standalone confirmation-page shell.
  """
  def callback(conn, %{"token" => token}) when is_binary(token) do
    conn
    |> assign(:hide_public_footer, true)
    |> assign(:page_title, "Email verification")
    |> assign(:status, :checking)
    |> render(:callback)
  end
end
