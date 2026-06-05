defmodule Memba.Messaging.EmailDeliveryProviders.ResendAdapterTest do
  use ExUnit.Case, async: false

  import Swoosh.Email

  alias Memba.Messaging.EmailDeliveryProviders.ResendAdapter

  setup do
    original_api_client = Application.get_env(:swoosh, :api_client)
    Application.put_env(:swoosh, :api_client, Memba.TestSupport.CapturingSwooshApiClient)

    on_exit(fn ->
      case original_api_client do
        nil -> Application.delete_env(:swoosh, :api_client)
        api_client -> Application.put_env(:swoosh, :api_client, api_client)
      end
    end)

    :ok
  end

  test "serializes custom headers as the object shape Resend expects" do
    email =
      new()
      |> from({"Memba", "messages@clubs-dev.memba.io"})
      |> to("matt@mattwynne.net")
      |> reply_to({"Memba", "support@memba.io"})
      |> subject("Re: Test 123")
      |> text_body("Your email was not posted.")
      |> header("In-Reply-To", "<original-message@mattwynne.net>")
      |> header("References", "<original-message@mattwynne.net>")
      |> put_provider_option(:tags, [
        %{name: "memba_email_kind", value: "inbound_club_rejection"}
      ])

    assert {:ok, %{id: "resend-email-id"}} = ResendAdapter.deliver(email, api_key: "resend-key")

    assert_received {:swoosh_api_client_post, _url, _headers, body, ^email}

    assert %{
             "from" => "Memba <messages@clubs-dev.memba.io>",
             "to" => ["matt@mattwynne.net"],
             "reply_to" => "Memba <support@memba.io>",
             "subject" => "Re: Test 123",
             "text" => "Your email was not posted.",
             "headers" => %{
               "In-Reply-To" => "<original-message@mattwynne.net>",
               "References" => "<original-message@mattwynne.net>"
             },
             "tags" => [
               %{"name" => "memba_email_kind", "value" => "inbound_club_rejection"}
             ]
           } = Jason.decode!(body)
  end
end
