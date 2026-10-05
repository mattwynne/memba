defmodule Memba.Messaging.CommandDispatch do
  @moduledoc """
  The Messaging application boundary to Commanded. Use-case modules prepare
  commands; this module alone submits them to the command router.
  """

  alias Memba.Messaging.App

  def dispatch(command, opts \\ []) when is_list(opts) do
    case App.dispatch(command, opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> {:ok, ok}
      {:error, _reason} = error -> error
    end
  end
end
