const assert = require("node:assert/strict");
const { createHash, randomBytes } = require("node:crypto");

const token = process.env.ACCEPTANCE_STAFF_MCP_TOKEN || randomBytes(32).toString("hex");
const credentials = JSON.stringify({
  "pat@memba.io": createHash("sha256").update(token).digest("hex")
});

async function rpc(world, method, params = {}) {
  const response = await fetch(new URL("/mcp", world.baseUrl), {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      accept: "application/json, text/event-stream",
      "content-type": "application/json",
      "mcp-protocol-version": "2025-11-25"
    },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params })
  });
  assert.equal(response.status, 200, `Staff MCP ${method} returned HTTP ${response.status}`);
  const body = await response.json();
  assert.ok(body.result, `Staff MCP ${method} failed: ${body.error?.message}`);
  return body.result;
}

async function callStaffTool(world, name, args = {}) {
  const result = await rpc(world, "tools/call", { name, arguments: args });

  if (result.isError) {
    throw new Error(result.content[0].text);
  }

  return result.structuredContent;
}

async function listStaffTools(world) {
  return (await rpc(world, "tools/list")).tools;
}

module.exports = { callStaffTool, credentials, listStaffTools };
