const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  assertOnlyGroupMember,
  ensureClubWithSlug,
  ensureCustomGroup,
  ensureOrdinaryClubMembers,
  kootenayClubName
} = require("./custom_group_creation");
const { withMemberHarness } = require("./member_harness");
const {
  assertMemberDoesNotSeeAdminMessage,
  clubSiteUrl,
  testMailboxEmails,
  waitForLiveViewConnected,
  waitForMailboxEmails
} = require("./member_message");
const serverCommands = require("./server_commands");

const boardName = "Board";
const requestSubject = "Access request: Board";

function ensureKootenayClub(world) {
  ensureClubWithSlug(world, kootenayClubName, "kmc");
}

function ensureEveIsOrdinaryMember(world) {
  ensureOrdinaryClubMembers(world, ["Eve"]);
}

function ensureAliceIsOnlyBoardMember(world) {
  ensureCustomGroup(world, kootenayClubName, boardName, "board", ["Alice"]);
  assertOnlyGroupMember(world, boardName, "Alice");
}

async function openBoardAs(world, personName) {
  const groupId = boardId(world);

  await withMemberHarness(world, personName, async (member) => {
    await member.page.goto(clubSiteUrl(member.baseUrl, club(world)));
    await waitForLiveViewConnected(member);

    const boardLink = member.page.locator(
      `[data-testid="member-group-link"][data-group-id="${groupId}"]`
    );

    await expect(boardLink).toBeVisible();
    await boardLink.click();
    await waitForLiveViewConnected(member);
    await expect(member.page.locator("#member-group-name")).toHaveText(boardName);
  });
}

async function assertRequestAccessWithoutComposer(world, personName) {
  await withMemberHarness(world, personName, async (member) => {
    await expect(member.page.locator("#member-group-request-access")).toHaveText(
      "Request access"
    );
    await expect(member.page.locator("#member-message-compose")).toHaveCount(0);
    await expect(member.page.locator("#member-section-action-new-message")).toHaveCount(0);
  });
}

async function requestBoardAccess(world, personName) {
  world.accessRequestMailboxBaselineIds = (await testMailboxEmails(world)).map(
    mailboxIdentity
  );

  await withMemberHarness(world, personName, async (member) => {
    const requestButton = member.page.locator("#member-group-request-access");

    await expect(requestButton).toBeVisible();
    await requestButton.click();
    await expect(member.page.locator("#member-group-request-status")).toContainText(
      "Your request has been sent."
    );
    await expect(requestButton).toHaveCount(0);
  });

  rememberAccessRequestMessage(world, personName);
}

async function assertRequestStatus(world, personName, expectedText) {
  await withMemberHarness(world, personName, async (member) => {
    await expect(member.page.locator("#member-group-request-status")).toContainText(
      expectedText
    );
  });
}

function assertBoardMembership(world, personName, expected) {
  const activeMember = serverCommands.runCommand(
    `
%{
  activeMember:
    Memba.Membership.active_member_of_group_authoritatively?(
      Map.fetch!(payload, "clubId"),
      Map.fetch!(payload, "groupId"),
      Map.fetch!(payload, "personId")
    )
}
`,
    {
      clubId: club(world).clubId,
      groupId: boardId(world),
      personId: person(world, personName).personId
    }
  ).activeMember;

  assert.equal(
    activeMember,
    expected,
    `Expected ${personName} ${expected ? "to belong" : "not to belong"} to ${boardName}`
  );
}

async function openRequestEmailAction(world, personName, actionLabel) {
  assert.ok(
    Array.isArray(world.accessRequestMailboxBaselineIds),
    "Expected the request-email baseline to be captured before submission"
  );

  serverCommands.dispatchPendingEmailDeliveries();

  const emails = await waitForMailboxEmails(
    world,
    world.accessRequestMailboxBaselineIds.length + 1,
    `${personName}'s ${requestSubject} email`
  );
  const freshEmails = emailsAfterBaseline(
    world.accessRequestMailboxBaselineIds,
    emails
  );
  const recipient = person(world, personName);
  const expectedSubject = `[${club(world).slug}] ${requestSubject}`;
  const email = freshEmails.find(
    (candidate) =>
      candidate.subject === expectedSubject &&
      mailboxRecipient(candidate).includes(recipient.email) &&
      mailboxText(candidate).includes("Eve would like to join Board.") &&
      htmlActionUrl(candidate, actionLabel)
  );

  assert.ok(
    email,
    `Expected a fresh ${JSON.stringify(expectedSubject)} email to ${recipient.email} ` +
      `with the ${JSON.stringify(actionLabel)} action`
  );

  const actionUrl = htmlActionUrl(email, actionLabel);
  assertExpectedClubUrl(
    world,
    actionUrl,
    `/groups/${boardId(world)}/members/add/${person(world, "Eve").personId}`
  );

  world.accessRequestEmail = email;
  world.accessRequestActionUrl = actionUrl;

  await withMemberHarness(world, personName, async (member) => {
    await member.page.goto(actionUrl);
    await waitForLiveViewConnected(member);
  });
}

async function assertTargetedBoardAdd(world, actorName, targetName) {
  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-name")).toHaveText(boardName);
    await expect(member.page.locator("#targeted-group-member-heading")).toHaveText(
      `Add to ${boardName}`
    );
    await expect(
      member.page.locator(`#targeted-group-member-person-${person(world, targetName).personId}`)
    ).toContainText(targetName);
    await expect(member.page.locator("#targeted-group-member-add")).toHaveText(
      `Add ${targetName} to ${boardName}`
    );
  });
}

async function confirmTargetedBoardAdd(world, actorName, targetName) {
  world.groupWelcomeMailboxBaselineIds = (await testMailboxEmails(world)).map(
    mailboxIdentity
  );

  await withMemberHarness(world, actorName, async (member) => {
    await member.page.locator("#targeted-group-member-add").click();
    await expect(member.page.locator("#targeted-group-member-success")).toContainText(
      `${targetName} is now a member of ${boardName}.`
    );
    await expect(
      member.page.locator(`#club-member-${person(world, targetName).personId}`)
    ).toBeVisible();
    await expect(member.page.locator("#targeted-group-member-add")).toHaveCount(0);
  });

  assertBoardMembership(world, targetName, true);
}

async function captureWelcomeEmail(world, personName) {
  assert.ok(
    Array.isArray(world.groupWelcomeMailboxBaselineIds),
    "Expected the welcome-email baseline to be captured before explicit Add"
  );

  const emails = await waitForMailboxEmails(
    world,
    world.groupWelcomeMailboxBaselineIds.length + 1,
    `${personName}'s ${boardName} welcome email`
  );
  const freshEmails = emailsAfterBaseline(
    world.groupWelcomeMailboxBaselineIds,
    emails
  );
  const recipient = person(world, personName);
  const expectedSubject = `[${club(world).slug}] You've been added to ${boardName}`;
  const expectedPath = `/groups/${boardId(world)}`;
  const email = freshEmails.find(
    (candidate) =>
      candidate.subject === expectedSubject &&
      mailboxRecipient(candidate).includes(recipient.email) &&
      emailUrlForPath(candidate, expectedPath)
  );

  assert.ok(
    email,
    `Expected a fresh ${JSON.stringify(expectedSubject)} email to ${recipient.email} ` +
      `with a ${boardName} link`
  );

  const welcomeUrl = emailUrlForPath(email, expectedPath);
  assertExpectedClubUrl(world, welcomeUrl, expectedPath);

  world.groupWelcomeEmail = email;
  world.groupWelcomeUrl = welcomeUrl;
}

async function openWelcomeLink(world, personName) {
  assert.ok(world.groupWelcomeUrl, `Expected ${personName}'s captured welcome link`);

  await withMemberHarness(world, personName, async (member) => {
    await member.page.goto(world.groupWelcomeUrl);
    await waitForLiveViewConnected(member);
    await expect(member.page.locator("#member-group-name")).toHaveText(boardName);
  });
}

async function assertBoardConversationAccess(world, personName) {
  await withMemberHarness(world, personName, async (member) => {
    await expect(member.page.locator("#member-section-tabs")).toBeVisible();
    await expect(member.page.locator("#member-section-panel-conversations")).toBeVisible();
    await expect(member.page.locator("#member-group-request-access")).toHaveCount(0);
  });
}

async function assertNoAdminRequestConversationAccess(world, personName) {
  await withMemberHarness(world, personName, async (member) => {
    await assertMemberDoesNotSeeAdminMessage(member, requestSubject);
    const message = member.messages[requestSubject];
    const response = await member.page.goto(
      clubSiteUrl(
        member.baseUrl,
        club(world),
        `/messages/${encodeURIComponent(message.messageId)}`
      )
    );

    assert.ok(
      response && [403, 404].includes(response.status()),
      `Expected ${personName}'s direct Admin request URL to be forbidden or not found`
    );
    await expect(member.page.getByRole("heading", { name: requestSubject })).toHaveCount(0);
    await expect(member.page.locator("#member-message-reply-form")).toHaveCount(0);
  });
}

function rememberAccessRequestMessage(world, requesterName) {
  const result = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
requester_id = Map.fetch!(payload, "requesterId")
subject = Map.fetch!(payload, "subject")
admin_group_id = Memba.Membership.SystemGroups.admin_group_id(club_id)

messages =
  admin_group_id
  |> Memba.Messaging.list_conversations_for_group()
  |> Enum.map(&Memba.Messaging.get_message(&1.message_id))
  |> Enum.filter(&(&1.sender_id == requester_id and &1.subject == subject))

case messages do
  [message] ->
    %{
      body: message.body,
      clubId: message.club_id,
      messageId: message.message_id,
      senderId: message.sender_id,
      subject: message.subject
    }

  matches ->
    raise "Expected one access request message, found #{length(matches)}"
end
`,
    {
      clubId: club(world).clubId,
      requesterId: person(world, requesterName).personId,
      subject: requestSubject
    }
  );

  assert.ok(
    result.body.includes("Eve would like to join Board."),
    "Expected the browser request to create the fixed access-request message"
  );

  world.messages[requestSubject] = {
    ...result,
    clubSlug: club(world).slug
  };
  world.lastMessageSubject = requestSubject;
}

function htmlActionUrl(email, label) {
  const escapedLabel = escapeRegularExpression(label);
  const match = mailboxHtml(email).match(
    new RegExp(
      `<a\\b[^>]*href="([^"]+)"[^>]*>\\s*${escapedLabel}\\s*</a>`,
      "i"
    )
  );

  return match && decodeHtmlAttribute(match[1]);
}

function emailUrlForPath(email, expectedPath) {
  const candidates = mailboxText(email).match(/https?:\/\/[^\s<>]+/gu) || [];

  return candidates
    .map((candidate) => candidate.replace(/[),.;]+$/u, ""))
    .find((candidate) => {
      try {
        return new URL(candidate).pathname === expectedPath;
      } catch (_error) {
        return false;
      }
    });
}

function assertExpectedClubUrl(world, candidate, expectedPath) {
  const actual = new URL(candidate);
  const expectedOrigin = new URL(clubSiteUrl(world.baseUrl, club(world))).origin;

  assert.equal(actual.origin, expectedOrigin, "Expected the emitted club-hosted URL");
  assert.equal(actual.pathname, expectedPath, "Expected the emitted action path");
  assert.equal(actual.search, "", "Expected no query authority in the emitted URL");
  assert.equal(actual.hash, "", "Expected no fragment authority in the emitted URL");
}

function emailsAfterBaseline(baselineIds, emails) {
  const baseline = new Set(baselineIds);
  return emails.filter((email) => !baseline.has(mailboxIdentity(email)));
}

function mailboxIdentity(email) {
  return email.id || (email.headers && email.headers["Message-ID"]) || JSON.stringify(email);
}

function mailboxRecipient(email) {
  return JSON.stringify((email && email.to) || "");
}

function mailboxText(email) {
  return String((email && (email.text_body || email.textBody || email.text)) || "");
}

function mailboxHtml(email) {
  return String((email && (email.html_body || email.htmlBody || email.html)) || "");
}

function decodeHtmlAttribute(value) {
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function escapeRegularExpression(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function club(world) {
  const value = world.clubs && world.clubs[kootenayClubName];
  assert.ok(value, `Expected ${kootenayClubName}`);
  return value;
}

function boardId(world) {
  const value = world.groups && world.groups[`${kootenayClubName}:${boardName}`];
  assert.ok(value, `Expected ${boardName}`);
  return value;
}

function person(world, personName) {
  const value = world.people && world.people[personName];
  assert.ok(value, `Expected ${personName}`);
  return value;
}

module.exports = {
  assertBoardConversationAccess,
  assertBoardMembership,
  assertNoAdminRequestConversationAccess,
  assertRequestAccessWithoutComposer,
  assertRequestStatus,
  assertTargetedBoardAdd,
  captureWelcomeEmail,
  confirmTargetedBoardAdd,
  ensureAliceIsOnlyBoardMember,
  ensureEveIsOrdinaryMember,
  ensureKootenayClub,
  openBoardAs,
  openRequestEmailAction,
  openWelcomeLink,
  requestBoardAccess
};
