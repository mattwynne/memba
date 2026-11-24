const assert = require("node:assert/strict");
const test = require("node:test");
const serverCommands = require("../features/support/server_commands");
const { assertMemberRemovalBlocked, removeMemberAsStaff } = require("../features/support/membership_administration");

test("staff member removal sends the membership ID to MCP and reports the operation result", async (t) => {
  t.mock.method(serverCommands, "runCommand", () => ({
    activeMember: true,
    clubId: "club-1",
    clubSlug: "west-coast-paddlers",
    email: "robin@example.com",
    membershipAdministrator: true,
    membershipId: "membership-1",
    personId: "person-1",
    personName: "Robin"
  }));

  const fetch = t.mock.method(globalThis, "fetch", async (url, request) => {
    assert.equal(url.pathname, "/mcp");
    assert.deepEqual(JSON.parse(request.body).params, {
      name: "remove_club_member",
      arguments: { membership_id: "membership-1" }
    });
    return Response.json({ result: { isError: true, content: [{ text: "last_membership_administrator" }] } });
  });

  const world = { baseUrl: "http://lvh.me:4000", clubs: {}, memberships: {}, people: {} };
  await removeMemberAsStaff(world, "Robin", "West Coast Paddlers");

  assert.equal(fetch.mock.callCount(), 1);
  await assertMemberRemovalBlocked(world, "last_membership_administrator");
});
