defmodule MembaWeb.DevTestSupportController do
  @moduledoc false

  use MembaWeb, :controller

  import Ecto.Query

  alias Memba.Accounts
  alias Memba.Accounts.SignInToken
  alias Memba.Repo

  @messaging_email_delivery_providers %{
    "fake" => Memba.Messaging.EmailDeliveryProviders.Fake,
    "local" => Memba.Messaging.EmailDeliveryProviders.Local,
    "unavailable" => Memba.Messaging.EmailDeliveryProviders.Unavailable
  }

  def expire_auth_link(conn, %{"email" => email}) do
    normalized_email = Accounts.normalize_email(email)
    expired_at = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)

    SignInToken
    |> where([token], token.email == ^normalized_email)
    |> order_by([token], desc: token.inserted_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      %SignInToken{} = token ->
        token
        |> Ecto.Changeset.change(expires_at: expired_at)
        |> Repo.update!()

      nil ->
        :ok
    end

    send_resp(conn, :no_content, "")
  end

  def configure_messaging_email_delivery_provider(conn, %{"provider" => provider_name}) do
    with {:ok, provider} <- Map.fetch(@messaging_email_delivery_providers, provider_name),
         true <- Code.ensure_loaded?(provider) do
      Application.put_env(:memba, :messaging_email_delivery_provider, provider)

      send_resp(conn, :no_content, "")
    else
      _unknown_or_unavailable ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "unknown messaging email delivery provider"})
    end
  end
end
