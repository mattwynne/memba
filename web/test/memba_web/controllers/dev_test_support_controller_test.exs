defmodule MembaWeb.DevTestSupportControllerTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
    end)

    :ok
  end

  test "POST /dev/test-support/messaging-delivery-provider switches provider for acceptance support",
       %{conn: conn} do
    conn =
      post(conn, ~p"/dev/test-support/messaging-delivery-provider", %{
        "provider" => "unavailable"
      })

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Unavailable

    conn =
      build_conn()
      |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
      |> post(~p"/dev/test-support/messaging-delivery-provider", %{"provider" => "local"})

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Local
  end

  test "POST /dev/test-support/messaging-delivery-provider rejects unknown provider names",
       %{conn: conn} do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    conn =
      post(conn, ~p"/dev/test-support/messaging-delivery-provider", %{
        "provider" => "postmark"
      })

    assert json_response(conn, 404) == %{"error" => "unknown messaging email delivery provider"}
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == original_provider
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
