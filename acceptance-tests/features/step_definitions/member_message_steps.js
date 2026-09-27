const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertEveryAddressedMemberEmailDeliveryStatus,
  assertMemberMessageAddressedTo,
  assertMemberMessageNotAddressedTo,
  assertConversationShowsReply,
  assertMemberEmailDeliveryStatus,
  assertMemberSeesMessageInClub,
  clubSlugFor,
  emailFor,
  ensureClubSlugMatchesInboundAddress,
  ensureState,
  kootenayClubName,
  nelsonClubName,
  openMemberMessage,
  reportRecipientEmailStatus,
  recordMembershipProjectionCheckpoint,
  postMemberReply,
  sendInboundClubEmail,
  sendMemberMessageToKootenayMembers
} = require("../support/member_message");
const { ensureAdminGroupMembers } = require("../support/membership_administration");
const { withMemberHarness, withStaffHarness } = require("../support/member_harness");
const serverCommands = require("../support/server_commands");

Given("Kootenay Mountaineering Club is a club", async function () {
  ensureClubState(this, kootenayClubName);
});

Given("Nelson Paddling Club is a club", async function () {
  ensureClubState(this, nelsonClubName);
});

Given("Alice, Bob, Carol, and Dana are people", async function () {
  ensurePeopleState(this, ["Alice", "Bob", "Carol", "Dana"]);
});

Given("Pat is a person", async function () {
  ensurePeopleState(this, ["Pat"]);
});

Given("Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club", async function () {
  ensureMembersState(this, ["Alice", "Bob", "Carol", "Dana"], kootenayClubName);
  ensureAdminGroupMembers(this, ["Bob"], kootenayClubName);
});

Given("Pat is a member of Nelson Paddling Club", async function () {
  ensureMembersState(this, ["Pat"], nelsonClubName);
});

When(
  "{word} sends the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await ensureKootenayMember(this, senderName);
    await withMemberHarness(this, senderName, (member) =>
      sendMemberMessageToKootenayMembers(member, senderName, subject)
    );
  }
);

When(/^(\w+) emails "([^"]+)" to ([^\s]+)$/, async function (senderName, subject, toAddress) {
  await prepareInboundClubEmailRouting(this, toAddress);
  await sendInboundClubEmail(this, senderName, subject, toAddress);
});

Given(
  "{word} has sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await sendMessageToKootenayMembersDirectly(this, senderName, subject);
  }
);

When("{word} replies {string} to {string}", async function (senderName, body, subject) {
  await withMemberHarness(this, senderName, (member) => postMemberReply(member, senderName, subject, body));
});

Then(
  "{word} should see {word}'s reply in the conversation for {string}",
  async function (viewerName, senderName, subject) {
    const reply = latestReplyFor(this, subject, senderName);

    await withMemberHarness(this, viewerName, (member) =>
      assertConversationShowsReply(member, subject, senderName, reply.body)
    );
  }
);

Then(
  "{word} should see the message {string} in Kootenay Mountaineering Club",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberSeesMessageInClub(member, subject, kootenayClubName)
    );
  }
);

Then(/^(\w+) should see the message was addressed to (.+)$/, async function (
  viewerName,
  expectedNamesText
) {
  await withMemberHarness(this, viewerName, (member) =>
    assertMemberMessageAddressedTo(member, parsePersonList(expectedNamesText))
  );
});

Then("{word} should not see {word} in the addressed members", async function (viewerName, excludedName) {
  await withMemberHarness(this, viewerName, (member) =>
    assertMemberMessageNotAddressedTo(member, excludedName)
  );
});

Then(
  "{word} should see every addressed member's status as {string}",
  async function (viewerName, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertEveryAddressedMemberEmailDeliveryStatus(member, member.lastMessageSubject, expectedStatus)
    );
  }
);

When("{word} views the message {string}", async function (viewerName, subject) {
  await withMemberHarness(this, viewerName, (member) => openMemberMessage(member, subject));
});

Then(
  "{word} should see {word}'s status for {string} as {string}",
  async function (viewerName, recipientName, subject, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberEmailDeliveryStatus(member, recipientName, subject, expectedStatus)
    );
  }
);

When(
  "{word}'s email for {string} is reported as delivered",
  async function (recipientName, subject) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delivered"));
  }
);

When(
  "{word}'s email for {string} is reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "bounced", { reason }));
  }
);

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}

function latestReplyFor(world, subject, senderName) {
  ensureState(world);

  const reply = Object.values(world.replies || {})
    .filter((candidate) => candidate.subject === subject && candidate.senderName === senderName)
    .at(-1);

  if (!reply) {
    throw new Error(`Expected ${senderName} to have replied to ${JSON.stringify(subject)}`);
  }

  return reply;
}

function ensureClubState(world, clubName, { slug = clubSlugFor(clubName) } = {}) {
  ensureState(world);

  if (world.clubs[clubName]) {
    return world.clubs[clubName];
  }

  const result = serverCommands.ensureClub({ clubName, clubSlug: slug });
  const club = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
  world.clubs[clubName] = club;
  return club;
}

function ensurePeopleState(world, personNames) {
  ensureState(world);

  const unknownPeople = personNames.filter((personName) => !world.people[personName]);

  if (unknownPeople.length > 0) {
    const results = serverCommands.ensurePeople(
      unknownPeople.map((personName) => ({ personName, email: emailFor(personName) }))
    );

    for (const result of results) {
      world.people[result.personName] = personStateFromCommand(result);
    }
  }

  return personNames.map((personName) => world.people[personName]);
}

function ensureMembersState(world, personNames, clubName) {
  ensureState(world);

  const unknownMemberships = personNames.filter(
    (personName) => !world.memberships[`${clubName}:${personName}`]
  );

  if (unknownMemberships.length > 0) {
    const results = serverCommands.ensureMembers(
      unknownMemberships.map((personName) => ({
        clubName,
        clubSlug: clubSlugFor(clubName),
        personName,
        email: emailFor(personName)
      }))
    );

    for (const result of results) {
      world.clubs[clubName] = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
      world.people[result.personName] = personStateFromCommand(result);
      world.memberships[`${clubName}:${result.personName}`] = {
        clubId: result.clubId,
        membershipId: result.membershipId,
        personId: result.personId
      };
      recordMembershipProjectionCheckpoint(world, result);
    }
  }

  return personNames.map((personName) => world.memberships[`${clubName}:${personName}`]);
}

async function sendMessageToKootenayMembersDirectly(world, senderName, subject) {
  await sendMessageToClubMembersDirectly(world, senderName, subject, kootenayClubName);
}

async function sendMessageToClubMembersDirectly(world, senderName, subject, clubName) {
  ensureState(world);
  ensureMembersState(world, [senderName], clubName);

  const club = world.clubs[clubName];
  const sender = world.people[senderName];
  const body = `${subject} details.`;

  const result = serverCommands.sendClubMessage({
    clubId: club.clubId,
    senderId: sender.personId,
    senderName,
    subject,
    body
  });

  world.messages[subject] = {
    body: result.body,
    clubId: result.clubId,
    clubSlug: club.slug,
    messageId: result.messageId,
    senderName: result.senderName,
    subject: result.subject
  };
  world.lastMessageSubject = subject;
}

function personStateFromCommand(result) {
  return {
    alternateEmails: [],
    email: result.email,
    emailAddresses: [{ email: result.email, isPrimary: true }],
    name: result.personName,
    personId: result.personId,
    primaryEmail: result.email
  };
}

async function ensureKootenayMember(world, personName) {
  if (
    world.clubs &&
    world.clubs[kootenayClubName] &&
    world.people &&
    world.people[personName] &&
    world.memberships &&
    world.memberships[`${kootenayClubName}:${personName}`]
  ) {
    return;
  }

  ensureMembersState(world, [personName], kootenayClubName);
}

async function prepareInboundClubEmailRouting(world, toAddress) {
  if (String(toAddress || "").toLowerCase().includes("@unknown.")) {
    return;
  }

  await withStaffHarness(world, (staff) => ensureClubSlugMatchesInboundAddress(staff, kootenayClubName, toAddress));
}
