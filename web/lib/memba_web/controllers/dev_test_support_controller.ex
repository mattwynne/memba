defmodule MembaWeb.DevTestSupportController do
  @moduledoc false

  use MembaWeb, :controller

  import Ecto.Query

  alias Memba.Accounts
  alias Memba.Accounts.MagicToken
  alias Memba.Repo

  def expire_auth_link(conn, %{"email" => email}) do
    normalized_email = Accounts.normalize_email(email)
    expired_at = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)

    MagicToken
    |> where([token], token.email == ^normalized_email)
    |> order_by([token], desc: token.inserted_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      %MagicToken{} = token ->
        token
        |> Ecto.Changeset.change(expires_at: expired_at)
        |> Repo.update!()

      nil ->
        :ok
    end

    send_resp(conn, :no_content, "")
  end
end
