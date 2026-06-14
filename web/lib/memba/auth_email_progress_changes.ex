defmodule Memba.AuthEmailProgressChanges do
  @moduledoc """
  Topic helpers for committed auth-email progress notifications.

  Payloads intentionally carry only the opaque auth-email request ID. LiveViews
  reload progress from persistence after receiving a notification so PubSub does
  not disclose recipient email addresses or account-existence information.
  """

  alias Memba.ID

  @topic_prefix "auth_email_progress:"

  @type message :: {:auth_email_progress_changed, %{request_id: String.t()}}

  @doc """
  Return the narrow PubSub topic for an opaque auth-email request ID.
  """
  @spec topic(term()) :: String.t() | nil
  def topic(request_id) when is_binary(request_id) do
    with {:ok, request_id} <- ID.cast(:auth_email_request, request_id) do
      @topic_prefix <> request_id
    else
      :error -> nil
    end
  end

  def topic(_request_id), do: nil

  @doc """
  Subscribe the current process to committed progress notifications for a request.
  """
  @spec subscribe(String.t()) :: :ok | {:error, :invalid_request_id}
  def subscribe(request_id) when is_binary(request_id) do
    case topic(request_id) do
      nil -> {:error, :invalid_request_id}
      topic -> Phoenix.PubSub.subscribe(Memba.PubSub, topic)
    end
  end

  def subscribe(_request_id), do: {:error, :invalid_request_id}
end
