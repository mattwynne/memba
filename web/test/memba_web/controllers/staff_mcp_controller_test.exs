defmodule MembaWeb.StaffMCPControllerTest do
  use MembaWeb.FeatureCase, async: false

  import Plug.Conn

  alias Memba.Onboarding
  alias MembaWeb.IdentityAuth
  alias MembaWeb.StaffMCP.Auth

  @token "staff-token-for-the-mcp-controller-test"

  setup do
    previous = Application.get_env(:memba, Auth, [])
    digest = :crypto.hash(:sha256, @token)
    Application.put_env(:memba, Auth, [{"pat@memba.io", digest}])
    on_exit(fn -> Application.put_env(:memba, Auth, previous) end)
  end

  test "requires a bearer credential for every request even with a staff browser session", %{
    conn: conn
  } do
    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
      |> rpc("tools/list", %{})

    assert response(conn, 401) == ""
    assert [~s(Bearer realm="Memba Staff")] = get_resp_header(conn, "www-authenticate")
  end

  test "requires a valid origin when provided and serves authenticated requests as JSON", %{
    conn: conn
  } do
    denied =
      conn
      |> authorized()
      |> put_req_header("origin", "https://different.example")
      |> rpc("tools/list", %{})

    assert response(denied, 403) == ""

    result =
      conn
      |> authorized()
      |> rpc("initialize", %{"protocolVersion" => "2025-11-25"})
      |> json_response(200)

    assert %{
             "id" => 1,
             "result" => %{"protocolVersion" => "2025-11-25", "capabilities" => %{"tools" => %{}}}
           } = result

    assert conn |> authorized() |> get("/mcp") |> response(405) == ""
  end

  test "rejects invalid tokens and club-site requests", %{conn: conn} do
    assert conn
           |> put_req_header("authorization", "Bearer " <> String.duplicate("x", 40))
           |> rpc("tools/list", %{})
           |> response(401) == ""

    assert conn
           |> Map.put(:host, "kmc.lvh.me")
           |> authorized()
           |> rpc("tools/list", %{})
           |> response(404) == ""
  end

  test "discovers tools and validates arguments before dispatch", %{conn: conn} do
    result = conn |> authorized() |> rpc("tools/list", %{}) |> json_response(200)

    assert %{"result" => %{"tools" => tools}} = result

    assert Enum.any?(
             tools,
             &match?(%{"name" => "create_club", "inputSchema" => %{"required" => ["name"]}}, &1)
           )

    assert %{"error" => %{"code" => -32602}} =
             conn
             |> authorized()
             |> rpc("tools/call", %{"name" => "create_club", "arguments" => %{"name" => 1}})
             |> json_response(200)
  end

  test "uses existing club commands and returns projected results", %{conn: conn} do
    assert %{"club_id" => club_id} = tool(conn, "create_club", %{"name" => "Summit Paddlers"})

    assert %{"club" => %{"club_id" => ^club_id, "slug" => "summit-paddlers"}, "items" => []} =
             tool(conn, "get_club", %{"club_id" => club_id})

    assert %{"items" => [%{"club_id" => ^club_id}], "next_offset" => nil} =
             tool(conn, "list_clubs", %{"limit" => 1})
  end

  test "creates and edits a person using the existing email verification rules", %{conn: conn} do
    assert %{"person_id" => person_id} =
             tool(conn, "create_person", %{
               "name" => "Jordan",
               "email_addresses" => [%{"email" => "jordan@example.com", "is_primary" => true}]
             })

    assert %{"person_id" => ^person_id} =
             tool(conn, "replace_person_email_addresses", %{
               "person_id" => person_id,
               "email_addresses" => [
                 %{"email" => "jordan@example.com", "is_primary" => true},
                 %{"email" => "jordan@alternate.example", "is_primary" => false}
               ]
             })

    assert %{
             "email_addresses" => [
               %{
                 "email" => "jordan@example.com",
                 "is_primary" => true,
                 "verified_at" => "1970-01-01T00:00:00.000000Z"
               },
               %{
                 "email" => "jordan@alternate.example",
                 "is_primary" => false,
                 "verified_at" => nil
               }
             ]
           } = tool(conn, "get_person", %{"person_id" => person_id})
  end

  test "records the credential owner when triaging a request", %{conn: conn} do
    {:ok, request} =
      Onboarding.create_request(
        %{
          requester_name: "Val Applicant",
          requested_club_name: "Paddlers",
          note: "Request access"
        },
        verified_identity_email: "val@example.com"
      )

    assert %{"status" => "rejected", "triaged_by_staff_email" => "pat@memba.io"} =
             tool(conn, "reject_onboarding_request", %{
               "request_id" => request.request_id,
               "internal_rejection_notes" => "Duplicate request"
             })

    assert %{"status" => "rejected"} =
             tool(conn, "get_onboarding_request", %{"request_id" => request.request_id})
  end

  defp authorized(conn), do: put_req_header(conn, "authorization", "Bearer " <> @token)

  defp rpc(conn, method, params) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json, text/event-stream")
    |> post("/mcp", Jason.encode!(%{jsonrpc: "2.0", id: 1, method: method, params: params}))
  end

  defp tool(conn, name, args) do
    assert %{"result" => %{"structuredContent" => result}} =
             conn
             |> authorized()
             |> rpc("tools/call", %{"name" => name, "arguments" => args})
             |> json_response(200)

    result
  end
end
