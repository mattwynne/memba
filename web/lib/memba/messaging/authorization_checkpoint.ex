defmodule Memba.Messaging.AuthorizationCheckpoint do
  @moduledoc """
  Prepare a write using a stable event-store checkpoint rather than a lagging
  authorization projection. A later concurrent change still races the prepared
  write, as it did before this module was extracted.
  """

  alias Memba.ProjectionBarrier

  @default_timeout 5_000

  def run(authorization, opts \\ [])
      when is_function(authorization, 0) and is_list(opts) do
    deadline = System.monotonic_time(:millisecond) + timeout()
    run(authorization, Keyword.get(opts, :projections, []), deadline)
  end

  defp run(authorization, projections, deadline) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :authorization_stability_timeout}
    else
      checkpoint = ProjectionBarrier.current_checkpoint()

      with :ok <- await_projections(projections, checkpoint, deadline),
           {:ok, authorized} <- authorization.() do
        if ProjectionBarrier.current_checkpoint() == checkpoint do
          {:ok, authorized}
        else
          run(authorization, projections, deadline)
        end
      end
    end
  end

  defp await_projections([], _checkpoint, _deadline), do: :ok

  defp await_projections(projections, checkpoint, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    case ProjectionBarrier.await(projections, checkpoint: checkpoint, timeout: timeout) do
      {:ok, _result} -> :ok
      {:error, :timeout, _result} -> {:error, :authorization_stability_timeout}
    end
  end

  defp timeout do
    case Application.get_env(:memba, :authorization_stability_timeout, @default_timeout) do
      value when is_integer(value) and value >= 0 -> value
      _invalid -> @default_timeout
    end
  end
end
