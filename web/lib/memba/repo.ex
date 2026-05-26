defmodule Memba.Repo do
  use Ecto.Repo,
    otp_app: :memba,
    adapter: Ecto.Adapters.Postgres
end
