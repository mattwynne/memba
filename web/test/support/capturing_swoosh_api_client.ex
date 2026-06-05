defmodule Memba.TestSupport.CapturingSwooshApiClient do
  @moduledoc false

  @behaviour Swoosh.ApiClient

  @impl Swoosh.ApiClient
  def post(url, headers, body, email) do
    send(self(), {:swoosh_api_client_post, url, headers, body, email})
    {:ok, 200, [], ~s({"id":"resend-email-id"})}
  end
end
