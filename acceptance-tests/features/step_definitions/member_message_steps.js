const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertAdminConversationShowsReply,
  assertAdminMessageDeliveredToMembers,
  assertAdminMessageNotDeliveredToMember,
  assertEveryAddressedMemberEmailDeliveryStatus,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertEachAddressedMemberReceivedEmailSubject,
  assertInboundRejectionEmail,
  assertInboundRejectionEmailSupportGuidance,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertMemberMessageAddressedTo,
  assertMemberMessageBody,
  assertMemberMessageNotAddressedTo,
  assertConversationFollowingState,
  assertConversationDoesNotShowReply,
  assertClubHomeConversationCount,
  assertClubHomeConversationLatestReplyFrom,
  assertClubHomeConversationNoParticipantAvatars,
  assertClubHomeConversationOrder,
  assertClubHomeConversationParticipantAvatarStack,
  assertClubHomeConversationPreview,
  assertClubHomeConversationReplyCount,
  assertClubHomeConversationsPanelDoesNotShowPreferEmailCard,
  assertClubHomeDoesNotShowHeading,
  assertConversationEntriesWithSenderTimestampAndBody,
  assertConversationEntryKindBadgesAbsent,
  assertConversationDuplicateFromLineAbsent,
  assertConversationReplyOrder,
  assertConversationShowsReply,
  assertMemberEmailDeliveryStatus,
  assertMemberCannotReplyToMessage,
  assertMemberDoesNotSeeAdminMessage,
  assertMemberSeesMessageInClub,
  assertMemberWasToldMessageBodyCannotBeBlank,
  assertMemberWasToldMessageWasNotSent,
  assertMemberWasToldToContactSupport,
  assertMessageDetailBackLink,
  assertNoAddressedMemberReceivedEmail,
  assertNoAdminMessageCreated,
  assertNoMemberMessageCreated,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  assertReplyComposerHelperSentenceAbsent,
  assertReplyComposerIdentifiesMember,
  assertReplyComposerNote,
  assertReplyEmailDeliveredToMembers,
  assertReplyEmailNotDeliveredToMembers,
  assertReplyEmailNotDeliveredToAuthor,
  assertStopFollowLinkNotValid,
  clubSlugFor,
  emailFor,
  ensureClubSlugMatchesInboundAddress,
  ensureState,
  followConversation,
  followStopFollowLinkFromReplyEmail,
  followTamperedStopFollowLink,
  kootenayClubName,
  makeClubMessageSendingUnavailable,
  nelsonClubName,
  openMemberMessage,
  openMemberClubHome,
  reportRecipientEmailStatus,
  removeMemberFromClub,
  recordMembershipProjectionCheckpoint,
  recordAcceptedInboundRootMessage,
  postMemberReply,
  sendInboundClubEmail,
  sendInboundClubEmailReply,
  sendInboundClubEmailWithReplyHeaders,
  sendMemberMessageToKootenayMembers,
  trySendBlankMemberMessageToKootenayMembers,
  trySendMemberMessageToKootenayMembers,
  unfollowConversation
} = require("../support/member_message");
const {
  memberBrowserAction,
  signInMember,
  withMemberHarness,
  withStaffHarness
} = require("../support/member_harness");
const serverCommands = require("../support/server_commands");

Given("Kootenay Mountaineering Club is a club", async function () {
  ensureClubState(this, kootenayClubName);
});

Given("Nelson Paddling Club is a club", async function () {
  ensureClubState(this, nelsonClubName);
});

Given("Alice, Bob, and Carol are people", async function () {
  ensurePeopleState(this, ["Alice", "Bob", "Carol"]);
});

Given("Alice, Bob, Carol, and Dana are people", async function () {
  ensurePeopleState(this, ["Alice", "Bob", "Carol", "Dana"]);
});

Given("Pat is a person", async function () {
  ensurePeopleState(this, ["Pat"]);
});

Given("Alice, Bob, and Carol are members of Kootenay Mountaineering Club", async function () {
  ensureMembersState(this, ["Alice", "Bob", "Carol"], kootenayClubName);
});

Given("Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club", async function () {
  ensureMembersState(this, ["Alice", "Bob", "Carol", "Dana"], kootenayClubName);
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

Given(/^(\w+) emailed "([^"]+)" to ([^\s]+)$/, async function (senderName, subject, toAddress) {
  await prepareInboundClubEmailRouting(this, toAddress);
  await sendInboundClubEmail(this, senderName, subject, toAddress);
  await recordAcceptedInboundRootMessage(this, subject);
});

When(
  /^(\w+) emails "([^"]+)" to ([^\s]+) from "([^"]+)"$/,
  async function (senderName, subject, toAddress, fromAddress) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmail(this, senderName, subject, toAddress, { fromAddress });
  }
);

When(
  /^(\w+) emails "([^"]+)" to ([^\s]+) with an attachment$/,
  async function (senderName, subject, toAddress) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmail(this, senderName, subject, toAddress, {
      attachments: [
        {
          filename: "route.gpx",
          content_type: "application/gpx+xml",
          size: 1234
        }
      ]
    });
  }
);

When(
  /^(\w+) emails "([^"]+)" to ([^\s]+) with only an HTML body$/,
  async function (senderName, subject, toAddress) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmail(this, senderName, subject, toAddress, { htmlOnly: true });
  }
);

When(
  /^(\w+) emails "([^"]+)" to ([^\s]+) with the body:$/,
  async function (senderName, subject, toAddress, body) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmail(this, senderName, subject, toAddress, { textBody: body });
  }
);

Given("club message sending is unavailable", async function () {
  await makeClubMessageSendingUnavailable(this);
});

When(
  "{word} tries to send a message to Kootenay Mountaineering Club members with subject {string} and no body",
  async function (senderName, subject) {
    await signInMember(this, senderName);
    await memberBrowserAction(this, `blank member message send for ${senderName}`, () =>
      trySendBlankMemberMessageToKootenayMembers(this, senderName, subject)
    );
  }
);

When(
  "{word} tries to send the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await signInMember(this, senderName);
    await memberBrowserAction(this, `failed member message send for ${senderName}`, () =>
      trySendMemberMessageToKootenayMembers(this, senderName, subject)
    );
  }
);

Given(
  "{word} has sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await sendMessageToKootenayMembersDirectly(this, senderName, subject);
  }
);

Given(
  "{word} sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await sendMessageToKootenayMembersDirectly(this, senderName, subject);
  }
);

Given(
  "{word} sent the message {string} to Nelson Paddling Club members",
  async function (senderName, subject) {
    await sendMessageToClubMembersDirectly(this, senderName, subject, nelsonClubName);
  }
);

When("{word} replies {string} to {string}", async function (senderName, body, subject) {
  await withMemberHarness(this, senderName, (member) => postMemberReply(member, senderName, subject, body));
});

When("{word} replies by email to {string} with:", async function (senderName, subject, body) {
  await sendInboundClubEmailReply(this, senderName, subject, body, {
    requireReply: Boolean(this.memberships && this.memberships[`${kootenayClubName}:${senderName}`])
  });
});

When(
  /^(\w+) replies by email to "([^"]+)" through ([^\s]+)$/,
  async function (senderName, subject, toAddress) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmailReply(this, senderName, subject, `${subject} details.`, { toAddress });
  }
);

When(
  /^(\w+) emails "([^"]+)" to ([^\s]+) with reply headers from "([^"]+)"$/,
  async function (senderName, subject, toAddress, referencedSubject) {
    await prepareInboundClubEmailRouting(this, toAddress);
    await sendInboundClubEmailWithReplyHeaders(this, senderName, subject, toAddress, referencedSubject);
  }
);

Given("{word} follows the conversation for {string}", async function (memberName, subject) {
  await withMemberHarness(this, memberName, (member) => followConversation(member, memberName, subject));
});

When("{word} stops following the conversation for {string}", async function (memberName, subject) {
  await withMemberHarness(this, memberName, (member) => unfollowConversation(member, memberName, subject));
});

Given("{word} is no longer a member of Kootenay Mountaineering Club", async function (memberName) {
  removeMemberFromClub(this, memberName, kootenayClubName);
});

Then(
  "the conversation for {string} should show {word}'s reply {string}",
  async function (subject, senderName, body) {
    await withMemberHarness(this, "Alice", (member) =>
      assertConversationShowsReply(member, subject, senderName, body)
    );
  }
);

Then("the conversation for {string} should show Bob's reply", async function (subject) {
  const reply = latestReplyFor(this, subject, "Bob");

  await withMemberHarness(this, "Alice", (member) =>
    assertConversationShowsReply(member, subject, "Bob", reply.body)
  );
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
  "the conversation for {string} should show {string} before {string}",
  async function (subject, earlierBody, laterBody) {
    await withMemberHarness(this, "Alice", (member) =>
      assertConversationReplyOrder(member, subject, earlierBody, laterBody)
    );
  }
);

Then(
  "{word}'s club home should show the {string} conversation preview {string}",
  async function (viewerName, subject, expectedPreview) {
    await withMemberHarness(this, viewerName, (member) =>
      assertClubHomeConversationPreview(member, viewerName, subject, expectedPreview)
    );
  }
);

Then(
  "{word}'s club home should not show the {string} heading",
  async function (viewerName, heading) {
    await withMemberHarness(this, viewerName, (member) =>
      assertClubHomeDoesNotShowHeading(member, viewerName, heading)
    );
  }
);

Then(
  "{word}'s club home Conversations panel should not show the Prefer email card",
  async function (viewerName) {
    await withMemberHarness(this, viewerName, (member) =>
      assertClubHomeConversationsPanelDoesNotShowPreferEmailCard(member, viewerName)
    );
  }
);

Then(
  "{word}'s club home should list one conversation for {string}",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertClubHomeConversationCount(member, viewerName, subject, 1)
    );
  }
);

Then("the {string} conversation should show {int} replies", async function (subject, replyCount) {
  await withMemberHarness(this, "Alice", (member) =>
    assertClubHomeConversationReplyCount(member, subject, replyCount)
  );
});

Then(
  "the {string} conversation should show the latest reply is from {word}",
  async function (subject, replierName) {
    await withMemberHarness(this, "Alice", (member) =>
      assertClubHomeConversationLatestReplyFrom(member, subject, replierName)
    );
  }
);

Then("the {string} conversation should show no replies yet", async function (subject) {
  await withMemberHarness(this, "Alice", (member) =>
    assertClubHomeConversationReplyCount(member, subject, 0)
  );
});

Then(
  "{word}'s club home should list {string} before {string}",
  async function (viewerName, earlierSubject, laterSubject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertClubHomeConversationOrder(member, viewerName, earlierSubject, laterSubject)
    );
  }
);

Then("the {string} conversation should show no participant avatars", async function (subject) {
  await withMemberHarness(this, "Alice", (member) =>
    assertClubHomeConversationNoParticipantAvatars(member, subject)
  );
});

Then(
  /^the "([^"]+)" conversation participant avatar-stack should show (.+?)(?:, plus (\d+) more)?$/,
  async function (subject, participantNamesText, overflowCount) {
    await withMemberHarness(this, "Alice", (member) =>
      assertClubHomeConversationParticipantAvatarStack(
        member,
        subject,
        parsePersonList(participantNamesText),
        overflowCount ? Number(overflowCount) : 0
      )
    );
  }
);

Then(
  "{word} should not see conversation entry kind badges for {string}",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertConversationEntryKindBadgesAbsent(member, subject)
    );
  }
);

Then(
  "{word} should not see a separate {string} line under the title for {string}",
  async function (viewerName, fromLine, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertConversationDuplicateFromLineAbsent(member, subject, fromLine)
    );
  }
);

Then(
  /^the conversation for "([^"]+)" should not show (\w+)'s reply "([^"]+)"$/,
  async function (subject, senderName, body) {
    await assertConversationDoesNotShowReply(this, subject, senderName, body);
  }
);

Then(
  /^(.+) should(?: each)? receive (\w+)'s reply by email from (.+) via Memba$/,
  async function (recipientNamesText, senderName, clubName) {
    await withMemberHarness(this, "Alice", (member) =>
      assertReplyEmailDeliveredToMembers(member, senderName, parsePersonList(recipientNamesText), clubName)
    );
  }
);

Then(/^(.+) should not receive (\w+)'s reply by email$/, async function (recipientNamesText, senderName) {
  await withMemberHarness(this, "Alice", (member) =>
    assertReplyEmailNotDeliveredToMembers(member, senderName, parsePersonList(recipientNamesText))
  );
});

Then(
  /^(.+) should not receive (\w+)'s reply by email from (.+) via Memba$/,
  async function (recipientNamesText, senderName, _clubName) {
    await assertReplyEmailNotDeliveredToMembers(
      this,
      senderName,
      parsePersonList(recipientNamesText)
    );
  }
);

Then("{word} should not receive his own reply by email", async function (senderName) {
  await withMemberHarness(this, "Alice", (member) => assertReplyEmailNotDeliveredToAuthor(member, senderName));
});

Then(
  "{word} should be following the conversation for {string}",
  async function (memberName, subject) {
    await withMemberHarness(this, memberName, (member) =>
      assertConversationFollowingState(member, memberName, subject, true)
    );
  }
);

Then(
  "{word} should not be following the conversation for {string}",
  async function (memberName, subject) {
    await withMemberHarness(this, memberName, (member) =>
      assertConversationFollowingState(member, memberName, subject, false)
    );
  }
);

When(
  "{word} follows the stop-follow link from {word}'s reply email",
  async function (recipientName, senderName) {
    await followStopFollowLinkFromReplyEmail(this, recipientName, senderName);
  }
);

When(
  "{word} follows a tampered stop-follow link for {string}",
  async function (recipientName, subject) {
    await followTamperedStopFollowLink(this, recipientName, subject);
  }
);

Then("{word} should be told the stop-follow link is not valid", async function (_recipientName) {
  await assertStopFollowLinkNotValid(this);
});

Then("{word} should not be able to reply to {string}", async function (personName, subject) {
  await withMemberHarness(this, personName, (member) =>
    assertMemberCannotReplyToMessage(member, personName, subject, kootenayClubName)
  );
});

Then(
  "{word} should see the message detail back link {string} for {string}",
  async function (viewerName, expectedCopy, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMessageDetailBackLink(member, subject, expectedCopy)
    );
  }
);

Then(
  "{word} should not see the old reply composer helper sentence for {string}",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertReplyComposerHelperSentenceAbsent(
        member,
        subject,
        "Your reply inherits the subject and is emailed to current followers except you."
      )
    );
  }
);

Then(
  /^(\w+) should see the reply composer identifies (?:him|her|them) as (\w+) for "([^"]+)"$/,
  async function (viewerName, memberName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertReplyComposerIdentifiesMember(member, subject, memberName)
    );
  }
);

Then(
  "{word} should see the reply composer note {string} for {string}",
  async function (viewerName, expectedNote, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertReplyComposerNote(member, subject, expectedNote)
    );
  }
);

Then(
  "the conversation for {string} should show entries with sender, timestamp, and body:",
  async function (subject, dataTable) {
    await withMemberHarness(this, "Bob", (member) =>
      assertConversationEntriesWithSenderTimestampAndBody(member, subject, dataTable.hashes())
    );
  }
);

Then("{word} should be told the message body cannot be blank", async function (viewerName) {
  await memberBrowserAction(this, `blank-body validation notice for ${viewerName}`, () =>
    assertMemberWasToldMessageBodyCannotBeBlank(this)
  );
});

Then("{word} should be told the message was not sent", async function (viewerName) {
  await memberBrowserAction(this, `not-sent failure notice for ${viewerName}`, () =>
    assertMemberWasToldMessageWasNotSent(this)
  );
});

Then("{word} should be told to contact support", async function (viewerName) {
  await memberBrowserAction(this, `support failure notice for ${viewerName}`, () =>
    assertMemberWasToldToContactSupport(this)
  );
});

Then(
  "{word} should see the message {string} in Kootenay Mountaineering Club",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberSeesMessageInClub(member, subject, kootenayClubName)
    );
  }
);

Then(
  "no club message named {string} should be created",
  async function (subject) {
    await withMemberHarness(this, "Alice", (member) =>
      assertNoMemberMessageCreated(member, kootenayClubName, subject)
    );
  }
);

Then(
  "no Kootenay Mountaineering Club message named {string} should be created",
  async function (subject) {
    await withMemberHarness(this, "Alice", (member) =>
      assertNoMemberMessageCreated(member, kootenayClubName, subject)
    );
  }
);

Then(
  "no Kootenay Mountaineering Club Admin message named {string} should be created",
  async function (subject) {
    await assertNoAdminMessageCreated(this, kootenayClubName, subject);
  }
);

Then(
  /^(.+) should each receive the Admin message "([^"]+)" by email from (.+) via Memba$/,
  async function (recipientNamesText, subject, clubName) {
    await assertAdminMessageDeliveredToMembers(
      this,
      subject,
      parsePersonList(recipientNamesText),
      clubName
    );
  }
);

Then(
  /^(\w+) should not receive the Admin message "([^"]+)" by email$/,
  async function (recipientName, subject) {
    await assertAdminMessageNotDeliveredToMember(this, subject, recipientName);
  }
);

Then(
  /^(.+) should not see the Admin message "([^"]+)" in the (.+) web app$/,
  async function (viewerNamesText, subject, clubName) {
    await recordAcceptedInboundRootMessage(this, subject);

    for (const viewerName of parsePersonList(viewerNamesText)) {
      await withMemberHarness(this, viewerName, async (member) => {
        await openMemberClubHome(member, clubName);
        await assertMemberDoesNotSeeAdminMessage(member, subject);
      });
    }
  }
);

Then(
  /^the Admin conversation for "([^"]+)" should show (\w+)'s reply "([^"]+)"$/,
  async function (subject, senderName, body) {
    await assertAdminConversationShowsReply(this, subject, senderName, body);
  }
);

Then(
  "{word} should receive a rejection email explaining the message was not posted",
  async function (senderName) {
    await assertInboundRejectionEmail(this, senderName, "wasn't posted");
  }
);

Then(
  "{word} should receive a rejection email explaining attachments are not supported",
  async function (senderName) {
    await assertInboundRejectionEmail(this, senderName, "attachments can't be posted");
  }
);

Then(
  "{word} should receive a rejection email explaining a plain-text message body is required",
  async function (senderName) {
    await assertInboundRejectionEmail(this, senderName, "plain-text message body");
  }
);

Then("{word} should be told how to contact support", async function (senderName) {
  await assertInboundRejectionEmailSupportGuidance(this, senderName);
});

Then("the message body should be:", async function (body) {
  await withMemberHarness(this, "Alice", (member) => assertMemberMessageBody(member, body));
});

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

Then("the message should be addressed to Alice, Bob, and Carol", async function () {
  await withStaffHarness(this, (staff) => assertLastMessageAddressedTo(staff, ["Alice", "Bob", "Carol"]));
});

Then("the message should not be addressed to {word}", async function (personName) {
  await withStaffHarness(this, (staff) => assertLastMessageNotAddressedTo(staff, personName));
});

Then("each addressed member should have a separate email delivery", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberHasSeparateDeliveryRecord(staff));
});

Then("each delivery should be sent through the email provider", async function () {
  await withStaffHarness(this, (staff) => assertEachDeliverySentThroughEmailProvider(staff));
});

Then("each addressed member should receive the email in the test mailbox", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberReceivedEmailInTestMailbox(staff));
});

Then("each addressed member should receive an email from {word} via Memba", async function (senderName) {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberReceivedEmailInTestMailbox(staff, { senderName }));
});

Then("each addressed member should receive an email with the subject {string}", async function (subject) {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberReceivedEmailSubject(staff, subject));
});

Then("no addressed member should receive an email for {string}", async function (subject) {
  await withStaffHarness(this, (staff) => assertNoAddressedMemberReceivedEmail(staff, subject));
});

Then(
  "{word}'s status for {string} should be {string}",
  async function (viewerName, subject, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberEmailDeliveryStatus(member, viewerName, subject, expectedStatus)
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

Given(
  "{word}'s email for {string} has been reported as delivered",
  async function (recipientName, subject) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delivered"));
  }
);

When(
  "{word}'s email for {string} is reported as delayed because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delayed", { reason }));
  }
);

Given(
  "{word}'s email for {string} has been reported as delayed because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delayed", { reason }));
  }
);

When(
  "{word}'s email for {string} is reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "bounced", { reason }));
  }
);

Given(
  "{word}'s email for {string} has been reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "bounced", { reason }));
  }
);

When(
  "{word}'s email for {string} is reported as a spam complaint because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "spam_complaint", { reason }));
  }
);

Then(
  "Memba staff should see {word}'s delivery for {string} as {string}",
  async function (recipientName, subject, expectedStatus) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryStatus(staff, recipientName, subject, expectedStatus));
  }
);

Then(
  "Memba staff should see {word}'s delivery reason {string}",
  async function (recipientName, expectedReason) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryReason(staff, recipientName, expectedReason));
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

function ensurePersonState(world, personName) {
  ensureState(world);

  if (world.people[personName]) {
    return world.people[personName];
  }

  const result = serverCommands.ensurePerson({ personName, email: emailFor(personName) });
  const person = personStateFromCommand(result);
  world.people[personName] = person;
  return person;
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
