defmodule MembaWeb.ForbiddenError do
  @moduledoc """
  Exception used when LiveView mount-time authorization must preserve a 403 response.
  """

  defexception message: "Forbidden", plug_status: 403
end
