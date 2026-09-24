defmodule Memba.ReleaseAdminInvariantRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :memba,
    adapter: Ecto.Adapters.Postgres
end
