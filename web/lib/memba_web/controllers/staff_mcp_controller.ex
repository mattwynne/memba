defmodule MembaWeb.StaffMCPController do
  use MembaWeb, :controller

  alias MembaWeb.StaffMCP.Tools

  @versions ~w(2025-11-25 2025-06-18 2025-03-26)

  plug :prevent_caching

  def rpc(conn, _params) do
    case get_req_header(conn, "mcp-protocol-version") do
      [] ->
        respond(conn, conn.body_params)

      [version] when version in @versions ->
        respond(conn, conn.body_params)

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(error(nil, -32600, "Unsupported MCP protocol version"))
    end
  end

  def no_stream(conn, _params) do
    conn
    |> put_resp_header("allow", "POST")
    |> send_resp(:method_not_allowed, "")
  end

  defp prevent_caching(conn, _opts), do: put_resp_header(conn, "cache-control", "no-store")

  defp respond(conn, %{"jsonrpc" => "2.0", "id" => id, "method" => method} = request)
       when (is_binary(id) or is_integer(id)) and is_binary(method) do
    case dispatch(method, Map.get(request, "params", %{}), conn.assigns.staff_mcp_email) do
      {:ok, result} -> json(conn, %{jsonrpc: "2.0", id: id, result: result})
      {:error, code, message} -> json(conn, error(id, code, message))
    end
  end

  defp respond(conn, %{"jsonrpc" => "2.0", "method" => "notifications/" <> _} = message)
       when not is_map_key(message, "id") do
    send_resp(conn, :accepted, "")
  end

  defp respond(conn, _message) do
    conn
    |> put_status(:bad_request)
    |> json(error(nil, -32600, "Invalid JSON-RPC request"))
  end

  defp dispatch("initialize", %{"protocolVersion" => version}, _email) when is_binary(version) do
    {:ok,
     %{
       protocolVersion: if(version in @versions, do: version, else: hd(@versions)),
       serverInfo: %{name: "memba-staff", version: "1.0.0"},
       capabilities: %{tools: %{}}
     }}
  end

  defp dispatch("ping", params, _email) when is_map(params), do: {:ok, %{}}

  defp dispatch("tools/list", params, _email) when is_map(params),
    do: {:ok, %{tools: Tools.list()}}

  defp dispatch("tools/call", %{"name" => name} = params, email) when is_binary(name) do
    case Tools.call(name, Map.get(params, "arguments", %{}), email) do
      {:ok, data} ->
        {:ok, %{structuredContent: data, content: [%{type: "text", text: Jason.encode!(data)}]}}

      {:tool_error, message} ->
        {:ok, %{isError: true, content: [%{type: "text", text: message}]}}

      {:error, message} ->
        {:error, -32602, message}
    end
  end

  defp dispatch(method, _params, _email)
       when method in ["initialize", "ping", "tools/list", "tools/call"],
       do: {:error, -32602, "Invalid parameters"}

  defp dispatch(_method, _params, _email), do: {:error, -32601, "Method not found"}

  defp error(id, code, message),
    do: %{jsonrpc: "2.0", id: id, error: %{code: code, message: message}}
end
