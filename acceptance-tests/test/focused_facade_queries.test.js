const assert = require("node:assert/strict");
const test = require("node:test");
const serverCommands = require("../features/support/server_commands");
const creation = require("../features/support/custom_group_creation");
const { assertBoardMembership } = require("../features/support/custom_group_access_request");
const messaging = require("../features/support/member_message");
const { kootenayClubName } = creation;

test("group member observation keeps the focused query and names result", (t) => {
  const calls = [];
  t.mock.method(serverCommands, "runCommand", (source, payload) => {
    calls.push({ source, payload });
    return calls.length === 1 ? { groupId: "group-1" } : { names: ["Alice"] };
  });

  creation.assertOnlyGroupMember(
    { clubs: { [kootenayClubName]: { clubId: "club-1" } } },
    "Board",
    "Alice"
  );

  assert.deepEqual(calls[0].payload, { clubId: "club-1", groupName: "Board" });
  assert.deepEqual(calls[1].payload, { groupId: "group-1" });
  assert.match(calls[1].source, /Memba\.Membership\.ClubGroupQueries\.list_active_members_of_group\(\)/);
  assert.match(calls[1].source, /Enum\.map\(& &1\.name\)/);
  assert.match(calls[1].source, /Enum\.sort\(\)/);
});

test("Board membership observation remains authoritative, for both outcomes", (t) => {
  let activeMember = false;
  t.mock.method(serverCommands, "runCommand", (source, payload) => {
    assert.match(source, /Memba\.Membership\.AuthoritativeMembershipQueries\.active_member_of_group_authoritatively\?\(/);
    assert.deepEqual(payload, { clubId: "club-1", groupId: "group-1", personId: "person-1" });
    return { activeMember };
  });
  const world = {
    clubs: { [kootenayClubName]: { clubId: "club-1" } },
    groups: { [`${kootenayClubName}:Board`]: "group-1" },
    people: { Eve: { personId: "person-1" } }
  };

  assertBoardMembership(world, "Eve", false);
  activeMember = true;
  assertBoardMembership(world, "Eve", true);
});

test("inbound recovery keeps query delegates and the recorded message shape", async (t) => {
  t.mock.method(serverCommands, "runCommand", (source, payload) => {
    assert.deepEqual(payload, { providerMessageId: "email-1" });
    assert.match(source, /Memba\.Messaging\.MessageSourceQueries\.get_inbound_email_source\("resend", provider_message_id\)/);
    assert.match(source, /nil -> nil/);
    assert.match(source, /Memba\.Messaging\.MessageQueries\.get_message\(message_id\)/);
    return {
      source: { status: "accepted", messageId: "message-1" },
      message: {
        body: "Agenda details", clubId: "club-1", conversationId: "conversation-1",
        messageId: "message-1", replyToMessageId: null, senderId: "person-1", subject: "Agenda"
      }
    };
  });
  const world = {
    clubs: { [kootenayClubName]: { clubId: "club-1", slug: "kmc" } },
    inboundEmails: { Agenda: { providerMessageId: "email-1", senderName: "Alice" } }
  };

  const message = await messaging.recordAcceptedInboundRootMessage(world, "Agenda");
  assert.deepEqual(message, {
    body: "Agenda details", clubId: "club-1", clubSlug: "kmc",
    messageId: "message-1", senderName: "Alice", subject: "Agenda"
  });
  assert.equal(world.messages.Agenda, message);
});

test("unused removal and system-group snapshot entry points are no longer exported", () => {
  assert.equal(Object.hasOwn(messaging, "removeMemberFromClub"), false);
  assert.equal(Object.hasOwn(creation, "tryCreateCustomGroupInBrowser"), false);
  assert.equal(Object.hasOwn(creation, "assertSystemGroupsUnchanged"), false);
});
