defmodule MembaWeb.Support.ResendReceivedEmailClient do
  @moduledoc false

  def get_received_email("email_fetched_content") do
    {:ok,
     %{
       "text" => "Bring route ideas from fetched content.",
       "html" => "<p>Bring route ideas from fetched content.</p>",
       "headers" => %{"message-id" => "<email_123@example.com>"},
       "attachments" => []
     }}
  end

  def get_received_email("email_no_body") do
    {:ok,
     %{
       "text" => nil,
       "html" => nil,
       "headers" => %{"message-id" => "<email_no_body@example.com>"},
       "attachments" => []
     }}
  end

  def get_received_email("api_error") do
    {:error, {:resend_received_email_api_error, 404, %{"message" => "not found"}}}
  end
end
