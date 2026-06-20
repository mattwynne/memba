defmodule Memba.Messaging.EmailDeliveryDispatcher do
  @moduledoc """
  OTP process responsible for asynchronous email delivery dispatch.

  Later iteration tasks add read-model-change subscription, claiming, provider
  delivery, and retry behaviour. This process is intentionally minimal here so
  the application has a named supervised dispatch boundary before that behaviour
  is attached.
  """

  use GenServer

  @name __MODULE__

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @name)

    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end
end
