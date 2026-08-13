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

  test "POST /dev/test-support/reset restores the local messaging provider", %{conn: conn} do
    Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

    conn = post(conn, ~p"/dev/test-support/reset")

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Local
  end

  test "POST /dev/test-support/sign-in stores the signed-in identity in the browser session",
       %{conn: conn} do
    conn = post(conn, ~p"/dev/test-support/sign-in", %{"email" => "Alice@Example.Test"})

    assert response(conn, 204) == ""
    assert get_session(conn, MembaWeb.IdentityAuth.identity_session_key()) == "alice@example.test"
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

  describe "GET /dev/test-support/stop-follow-url" do
    test "returns a path with a token scoped to the seeded Drew follow", %{conn: conn} do
      conn = get(conn, "/dev/test-support/stop-follow-url")

      assert %{"path" => path} = json_response(conn, 200)
      assert "/messages/conversations/stop-following/" <> token = path

      assert {:ok, scope} = Memba.Messaging.ConversationStopFollowToken.verify(token)
      assert scope.club_id == "clb_11111111-1111-1111-1111-111111111111"
      assert scope.conversation_id == "msg_30000000-0000-0000-0000-000000000001"
      assert scope.member_id == "per_dddddddd-dddd-dddd-dddd-dddddddddddd"
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
