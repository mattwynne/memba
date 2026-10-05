defmodule Memba.Messaging.PostmarkLookupTest do
  use ExUnit.Case, async: false
  alias Memba.Messaging.EmailDeliveryProviders.PostmarkLookup
  alias Memba.Messaging.EmailDeliveryProviders.Postmark

  setup do
    original_mailer = Application.get_env(:memba, Memba.Mailer)
    original_provider = Application.get_env(:memba, Postmark)
    Application.put_env(:memba, Memba.Mailer, api_key: "test-only")
    Application.put_env(:memba, Postmark, from: "example@example.test")

    on_exit(fn ->
      restore(Memba.Mailer, original_mailer)
      restore(Postmark, original_provider)
      Application.delete_env(:memba, :postmark_lookup_req_options)
    end)
  end

  test "matches metadata in search and confirms recipient in detail without network access" do
    test_pid = self()

    Application.put_env(:memba, :postmark_lookup_req_options,
      plug: fn conn ->
        send(
          test_pid,
          {:lookup, conn.request_path, conn.query_string,
           Plug.Conn.get_req_header(conn, "x-postmark-server-token")}
        )

        body =
          case conn.request_path do
            "/messages/outbound" ->
              %{
                "TotalCount" => 1,
                "Messages" => [
                  %{"MessageID" => "pm_123", "Metadata" => %{"memba_delivery_id" => "del_123"}}
                ]
              }

            "/messages/outbound/pm_123/details" ->
              %{
                "Metadata" => %{"memba_delivery_id" => "del_123"},
                "MessageID" => "pm_123",
                "To" => [
                  %{"Email" => "ada@example.test", "Name" => "Ada"},
                  %{"Email" => "other@example.test", "Name" => nil}
                ]
              }
          end

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(body))
      end
    )

    assert {:ok, %{message_ids: ["pm_123"], duplicate_count: 0, complete?: true}} =
             Postmark.find_handoff("del_123", "ada@example.test", DateTime.utc_now())

    assert_receive {:lookup, "/messages/outbound", query, ["test-only"]}
    assert query =~ "metadata_memba_delivery_id=del_123"
    assert_receive {:lookup, "/messages/outbound/pm_123/details", _, ["test-only"]}
  end

  test "substring recipient is not falsely confirmed" do
    Application.put_env(:memba, :postmark_lookup_req_options,
      plug: fn conn ->
        body =
          case conn.request_path do
            "/messages/outbound" ->
              %{
                "TotalCount" => 1,
                "Messages" => [
                  %{"MessageID" => "pm_123", "Metadata" => %{"memba_delivery_id" => "del_123"}}
                ]
              }

            "/messages/outbound/pm_123/details" ->
              %{
                "Metadata" => %{"memba_delivery_id" => "del_123"},
                "To" => [%{"Email" => "nada@example.test", "Name" => nil}]
              }
          end

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(body))
      end
    )

    assert {:error, :postmark_recipient_mismatch} =
             PostmarkLookup.find("del_123", "ada@example.test", DateTime.utc_now())
  end

  test "verifies all candidates across pages and reports only confirmed duplicate sends" do
    test_pid = self()

    Application.put_env(:memba, :postmark_lookup_req_options,
      plug: fn conn ->
        send(test_pid, {:lookup, conn.request_path, conn.query_string})

        body =
          case {conn.request_path, Plug.Conn.Query.decode(conn.query_string)["offset"]} do
            {"/messages/outbound", "0"} ->
              %{
                "TotalCount" => 501,
                "Messages" => [
                  %{"MessageID" => "pm_1", "Metadata" => %{"memba_delivery_id" => "del_123"}},
                  %{"MessageID" => "pm_wrong", "Metadata" => %{"memba_delivery_id" => "del_123"}}
                ]
              }

            {"/messages/outbound", "500"} ->
              %{
                "TotalCount" => 501,
                "Messages" => [
                  %{"MessageID" => "pm_2", "Metadata" => %{"memba_delivery_id" => "del_123"}}
                ]
              }

            {"/messages/outbound/pm_wrong/details", _} ->
              %{
                "Metadata" => %{"memba_delivery_id" => "other_delivery"},
                "To" => [%{"Email" => "ada@example.test", "Name" => nil}]
              }

            {"/messages/outbound/" <> _id, _} ->
              %{
                "Metadata" => %{"memba_delivery_id" => "del_123"},
                "To" => [%{"Email" => "ada@example.test", "Name" => nil}]
              }
          end

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(body))
      end
    )

    assert {:ok, %{message_ids: ["pm_1", "pm_2"], duplicate_count: 1, complete?: true}} =
             Postmark.find_handoff("del_123", "ada@example.test", DateTime.utc_now())

    assert_receive {:lookup, "/messages/outbound", query1}
    assert Plug.Conn.Query.decode(query1)["offset"] == "0"
    assert_receive {:lookup, "/messages/outbound/pm_1/details", _}
    assert_receive {:lookup, "/messages/outbound/pm_wrong/details", _}
    assert_receive {:lookup, "/messages/outbound", query2}
    assert Plug.Conn.Query.decode(query2)["offset"] == "500"
    assert_receive {:lookup, "/messages/outbound/pm_2/details", _}
  end

  test "confirmed acceptance survives a later candidate detail error without claiming a complete duplicate count" do
    Application.put_env(:memba, :postmark_lookup_req_options,
      plug: fn conn ->
        case conn.request_path do
          "/messages/outbound" ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.resp(
              200,
              Jason.encode!(%{
                "TotalCount" => 2,
                "Messages" =>
                  Enum.map(["pm_1", "pm_2"], fn id ->
                    %{"MessageID" => id, "Metadata" => %{"memba_delivery_id" => "del_123"}}
                  end)
              })
            )

          "/messages/outbound/pm_1/details" ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.resp(
              200,
              Jason.encode!(%{
                "Metadata" => %{"memba_delivery_id" => "del_123"},
                "To" => [%{"Email" => "ada@example.test", "Name" => nil}]
              })
            )

          "/messages/outbound/pm_2/details" ->
            Plug.Conn.resp(conn, 503, "unavailable")
        end
      end
    )

    assert {:ok, %{message_ids: ["pm_1"], duplicate_count: 0, complete?: false}} =
             Postmark.find_handoff("del_123", "ada@example.test", DateTime.utc_now())
  end

  test "empty search is inconclusive, not a provider failure" do
    Application.put_env(:memba, :postmark_lookup_req_options,
      plug: fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"TotalCount" => 0, "Messages" => []}))
      end
    )

    assert :not_found = PostmarkLookup.find("del_123", "ada@example.test", DateTime.utc_now())
  end

  defp restore(key, nil), do: Application.delete_env(:memba, key)
  defp restore(key, value), do: Application.put_env(:memba, key, value)
end
