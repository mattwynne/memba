defmodule MembaWeb.PostmarkWebhookController do
  use MembaWeb, :controller

  def create(conn, _params) do
    conn
    |> put_status(:not_implemented)
    |> json(%{errors: %{detail: "Postmark webhook handler is not implemented yet"}})
  end
end
