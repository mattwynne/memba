defmodule Memba.Messaging.App do
  @moduledoc """
  Commanded application for the Messaging bounded context.
  """

  use Commanded.Application, otp_app: :memba

  router(Memba.Messaging.Router)
end
