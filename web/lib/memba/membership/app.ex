defmodule Memba.Membership.App do
  @moduledoc """
  Commanded application for the Membership bounded context.
  """

  use Commanded.Application, otp_app: :memba

  router(Memba.Membership.Router)
end
