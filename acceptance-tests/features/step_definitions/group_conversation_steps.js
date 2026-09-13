const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  emailFor,
  ensureState,
  kootenayClubName,
  openMemberClubHome,
  waitForLiveViewConnected
} = require("../support/member_message");
const { withMemberHarness } = require("../support/member_harness");
const {
  ensureMembershipAdministrator,
  ensureOrdinaryMember
} = require("../support/membership_administration");
const serverCommands = require("../support/server_commands");

Given(
  /^(.+) are members of the Kootenay Mountaineering Club Trips committee group$/,
  async function (personNamesText) {
    ensureNamedGroupMembers(
      this,
      kootenayClubName,
      "Trips committee",
      parsePersonList(personNamesText)
    );
  }
);

When(/^(\w+) views the (.+) home$/, async function (personName, clubName) {
  this.currentGroupViewer = personName;
  await withMemberHarness(this, personName, (member) => openMemberClubHome(member, clubName));
});

When(/^(\w+) opens the (.+) home$/, async function (personName, clubName) {
  this.currentGroupViewer = personName;
  await withMemberHarness(this, personName, (member) => openMemberClubHome(member, clubName));
});

Then(/^(\w+) should see the (.+) group$/, async function (personName, groupName) {
  await withMemberHarness(this, personName, async (member) => {
    await expect(groupLink(member, groupName)).toBeVisible();
  });
});

Then(/^(\w+) should not see the (.+) group$/, async function (personName, groupName) {
  await withMemberHarness(this, personName, async (member) => {
    await expect(groupLink(member, groupName)).toHaveCount(0);
  });
});

Then(
  /^(\w+) should not be listed as a member of the (.+) group$/,
  async function (personName, groupName) {
    const viewerName = this.currentGroupViewer;
    assert.ok(viewerName, "Expected a member to have viewed the club home");

    const groupId = groupIdFor(this, kootenayClubName, groupName);
    const personId = personIdFor(this, personName);

    await withMemberHarness(this, viewerName, async (member) => {
      await openGroup(member, kootenayClubName, groupId, "members");
      await expect(
        member.page.locator(
          `[data-testid="club-member-row"][data-member-id="${personId}"]`
        )
      ).toHaveCount(0);
    });
  }
);

Given(
  /^the (.+ Club) (.+) group has the conversation "([^"]+)"$/,
  async function (clubName, groupName, subject) {
    createGroupConversation(this, clubName, groupName, subject);
  }
);

Given("the Everyone group has the conversation {string}", async function (subject) {
  createGroupConversation(this, kootenayClubName, "Everyone", subject);
});

When(/^(\w+) selects the (.+) group$/, async function (personName, groupName) {
  this.currentGroupViewer = personName;
  this.currentGroupName = groupName;

  await withMemberHarness(this, personName, async (member) => {
    await openMemberClubHome(member, kootenayClubName);
    await selectGroup(member, groupName);
  });
});

Then(/^(\w+) should see the conversation "([^"]+)"$/, async function (personName, subject) {
  await withMemberHarness(this, personName, async (member) => {
    await expect(conversationRow(member, subject)).toBeVisible();
  });
});

Then(
  /^(\w+) should not see the conversation "([^"]+)"$/,
  async function (personName, subject) {
    await withMemberHarness(this, personName, async (member) => {
      await expect(conversationRow(member, subject)).toHaveCount(0);
    });
  }
);

Then(
  /^(\w+) should see (\w+) in the member list$/,
  async function (viewerName, memberName) {
    await viewMembersAndAssertPresence(this, viewerName, memberName, true);
  }
);

Then(
  /^(\w+) should not see (\w+) in the member list$/,
  async function (viewerName, memberName) {
    await viewMembersAndAssertPresence(this, viewerName, memberName, false);
  }
);

When(
  /^(\w+) sends the message "([^"]+)" to the (.+) group in the web app$/,
  async function (senderName, subject, groupName) {
    ensureState(this);
    const club = clubFor(this, kootenayClubName);
    const groupId = groupIdFor(this, kootenayClubName, groupName);
    const body = `${subject} details.`;

    await withMemberHarness(this, senderName, async (member) => {
      await openMemberClubHome(member, kootenayClubName);
      await selectGroup(member, groupName);

      member.localDeliveryFactsBeforeSend = serverCommands.listLocalDeliveryFacts();

      await member.page.locator("#member-section-action-new-message").click();
      const compose = member.page.locator("#member-message-compose");
      await expect(compose).toHaveAttribute("data-audience-group-id", groupId);
      await expect(compose).toHaveAttribute("data-compose-state", "composing");
      await waitForLiveViewConnected(member);

      await member.page.getByLabel("Subject").fill(subject);
      await member.page.getByLabel("Message").fill(body);
      await member.page.getByRole("button", { name: "Send message" }).click();

      await expect(compose).toHaveAttribute("data-compose-state", "sent");
      const messageId = await compose.getAttribute("data-sent-message-id");
      assert.ok(messageId, `Expected ${JSON.stringify(subject)} to expose its message id`);

      member.messages[subject] = {
        body,
        clubId: club.clubId,
        clubSlug: club.slug,
        messageId,
        senderName,
        subject
      };
      member.lastMessageSubject = subject;
    });
  }
);

Then(
  /^(.+) should be able to read the (.+) conversation "([^"]+)"$/,
  async function (personNamesText, groupName, subject) {
    const message = messageFor(this, subject);
    const groupId = groupIdFor(this, kootenayClubName, groupName);

    for (const personName of parsePersonList(personNamesText)) {
      await withMemberHarness(this, personName, async (member) => {
        await member.page.goto(
          clubSiteUrl(
            member.baseUrl,
            clubFor(member, kootenayClubName),
            `/messages/${message.messageId}?group_id=${groupId}`
          )
        );
        await expect(member.page.getByRole("heading", { name: subject })).toBeVisible();
      });
    }
  }
);

Then(
  /^(\w+) should not be able to read the (.+) conversation "([^"]+)"$/,
  async function (personName, groupName, subject) {
    const message = messageFor(this, subject);
    const groupId = groupIdFor(this, kootenayClubName, groupName);

    await withMemberHarness(this, personName, async (member) => {
      const response = await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          clubFor(member, kootenayClubName),
          `/messages/${message.messageId}?group_id=${groupId}`
        )
      );

      assert.equal(response.status(), 404);
      await expect(member.page.locator("body")).toContainText("Not Found");
      await expect(member.page.getByText(subject, { exact: true })).toHaveCount(0);
    });
  }
);

When(/^(\w+) tries to view the (.+) group$/, async function (personName, groupName) {
  const groupId = groupIdFor(this, kootenayClubName, groupName);

  await withMemberHarness(this, personName, async (member) => {
    await member.page.goto(
      clubSiteUrl(member.baseUrl, clubFor(member, kootenayClubName), `/groups/${groupId}`)
    );

    await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
    await expect(member.page.locator("#member-group-access-guidance")).toBeVisible();
  });
});

Given(
  /^(\w+) most recently viewed the (.+) group in (.+)$/,
  async function (personName, groupName, clubName) {
    await rememberGroupSelection(this, personName, groupName, clubName);
  }
);

Given(
  /^(\w+) most recently viewed (.+) in (.+)$/,
  async function (personName, groupName, clubName) {
    await rememberGroupSelection(this, personName, groupName, clubName);
  }
);

Given(
  /^(\w+) has not previously selected a group in (.+)$/,
  async function (personName, clubName) {
    const club = clubFor(this, clubName);

    await withMemberHarness(this, personName, async (member) => {
      await member.page.evaluate(
        ({ clubId }) => window.localStorage.removeItem(`memba:lastGroup:${clubId}`),
        { clubId: club.clubId }
      );

      assert.equal(
        await member.page.evaluate(
          ({ clubId }) => window.localStorage.getItem(`memba:lastGroup:${clubId}`),
          { clubId: club.clubId }
        ),
        null
      );
    });
  }
);

Then(/^(\w+) should see the (.+) group selected$/, async function (personName, groupName) {
  const groupId = groupIdFor(this, kootenayClubName, groupName);

  await withMemberHarness(this, personName, async (member) => {
    await expect(
      member.page.locator(
        `#member-club-home[data-selected-group-id="${groupId}"] ` +
          `[data-testid="member-group-link"][data-group-id="${groupId}"][aria-current="true"]`
      )
    ).toBeVisible();
    await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
  });
});

Given(/^(\w+) is not a club admin$/, function (personName) {
  ensureOrdinaryMember(this, personName, kootenayClubName);
});

Given(/^(\w+) is a club admin$/, function (personName) {
  ensureMembershipAdministrator(this, personName, kootenayClubName);
});

Given(
  /^(.+) are members of the Kootenay Mountaineering Club Board group$/,
  function (personNamesText) {
    ensureNamedGroupMembers(
      this,
      kootenayClubName,
      "Board",
      parsePersonList(personNamesText)
    );
  }
);

Given(
  /^(.+) are the only members of the Kootenay Mountaineering Club Board group$/,
  function (personNamesText) {
    const personNames = parsePersonList(personNamesText);
    ensureNamedGroupMembers(this, kootenayClubName, "Board", personNames);

    assert.deepEqual(activeGroupMemberNames(this, "Board"), personNames);
  }
);

Given(
  /^(\w+) is the only member of the Kootenay Mountaineering Club Board group$/,
  function (personName) {
    ensureNamedGroupMembers(this, kootenayClubName, "Board", [personName]);

    assert.deepEqual(activeGroupMemberNames(this, "Board"), [personName]);
  }
);

Given(
  /^(\w+) is a member of the Kootenay Mountaineering Club Board group$/,
  function (personName) {
    ensureNamedGroupMembers(this, kootenayClubName, "Board", [personName]);
  }
);

Given(/^Board has the conversation "([^"]+)"$/, function (subject) {
  createGroupConversation(this, kootenayClubName, "Board", subject);
});

When(/^(\w+) opens Board$/, async function (personName) {
  this.currentGroupViewer = personName;

  await withMemberHarness(this, personName, (member) =>
    openGroup(member, kootenayClubName, groupIdFor(this, kootenayClubName, "Board"))
  );
});

When(/^(\w+) views Board's members$/, async function (personName) {
  this.currentGroupViewer = personName;

  await withMemberHarness(this, personName, (member) =>
    openGroup(
      member,
      kootenayClubName,
      groupIdFor(this, kootenayClubName, "Board"),
      "members"
    )
  );
});

Then(
  /^(\w+) should be told that she does not belong to Admin$/,
  async function (personName) {
    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-group-access-title")).toHaveText(
        "Admin is a private group"
      );
      await expect(member.page.locator("#member-group-access-guidance")).toContainText(
        "but not of Admin"
      );
    });
  }
);

Then(/^(\w+) should see the club Admin email address$/, async function (personName) {
  const adminEmail = clubAdminEmailAddress(this, kootenayClubName);

  await withMemberHarness(this, personName, async (member) => {
    await expect(member.page.locator("#member-group-admin-email")).toHaveText(adminEmail);
    await expect(member.page.locator("#member-group-admin-email")).toHaveAttribute(
      "href",
      `mailto:${adminEmail}`
    );
  });
});

Then(
  /^(\w+) should see neither (.+) conversations nor its membership list$/,
  async function (personName, groupName) {
    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
      await expect(member.page.locator("#member-section-tabs")).toHaveCount(0);
      await expect(member.page.locator("[data-testid='club-message-row']")).toHaveCount(0);
      await expect(member.page.locator("[data-testid='club-member-row']")).toHaveCount(0);
    });
  }
);

Then(
  /^(\w+) should see Board's name and the club Admin email address$/,
  async function (personName) {
    const adminEmail = clubAdminEmailAddress(this, kootenayClubName);

    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-group-name")).toHaveText("Board");
      await expect(member.page.locator("#member-group-admin-email")).toHaveText(adminEmail);
    });
  }
);

Then(/^(\w+) should not become a member of (.+)$/, function (personName, groupName) {
  groupName = groupName.replace(/^the /, "").replace(/ group$/, "");
  assert.equal(activeGroupMemberNames(this, groupName).includes(personName), false);
});

Then(
  /^(\w+) should see (.+) as Board's members$/,
  async function (personName, memberNamesText) {
    await withMemberHarness(this, personName, async (member) => {
      for (const memberName of parsePersonList(memberNamesText)) {
        const memberId = personIdFor(this, memberName);
        await expect(
          member.page.locator(
            `[data-testid="club-member-row"][data-member-id="${memberId}"]`
          )
        ).toBeVisible();
      }
    });
  }
);

Then(/^(\w+) should not belong to Board$/, function (personName) {
  assert.equal(activeGroupMemberNames(this, "Board").includes(personName), false);
});

Then(/^(\w+) should not have access to Board conversations$/, function (personName) {
  assert.equal(memberParticipatesInGroup(this, personName, "Board"), false);
});

Then(
  /^(\w+) should have Board's Members section available$/,
  async function (personName) {
    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-section-tab-members")).toBeVisible();
      await expect(member.page.locator("#member-section-tab-members")).toHaveAttribute(
        "aria-selected",
        "true"
      );
      await expect(member.page.locator("#member-section-panel-members")).toBeVisible();
    });
  }
);

Then(
  /^Board's Conversations section and New message action should be absent$/,
  async function () {
    const viewerName = this.currentGroupViewer;
    assert.ok(viewerName, "Expected a member to have opened Board");

    await withMemberHarness(this, viewerName, async (member) => {
      await expect(member.page.locator("#member-section-tab-conversations")).toHaveCount(0);
      await expect(member.page.locator("#member-section-panel-conversations")).toHaveCount(0);
      await expect(member.page.locator("#member-section-action-new-message")).toHaveCount(0);
    });
  }
);

When(/^(\w+) directly tries to (.+)$/, async function (personName, action) {
  const message = messageFor(this, "September agenda");
  const boardId = groupIdFor(this, kootenayClubName, "Board");
  const before = directActionSnapshot(this, personName, message, boardId);
  let responseStatus;
  let responseBody;

  await withMemberHarness(this, personName, async (member) => {
    const path = action.startsWith("start ")
      ? `/messages/new?group_id=${encodeURIComponent(boardId)}`
      : `/messages/${encodeURIComponent(message.messageId)}?group_id=${encodeURIComponent(boardId)}`;
    const response = await member.page.goto(
      clubSiteUrl(member.baseUrl, clubFor(member, kootenayClubName), path)
    );

    responseStatus = response.status();
    responseBody = await member.page.locator("body").innerText();
  });

  this.directBoardAction = {
    action,
    before,
    boardId,
    message,
    personName,
    responseBody,
    responseStatus
  };
});

Then("the attempt should be refused", function () {
  assert.equal(this.directBoardAction.responseStatus, 404);
});

Then(
  /^no Board conversation content should be disclosed to (\w+)$/,
  function (personName) {
    assert.equal(this.directBoardAction.personName, personName);
    assert.doesNotMatch(this.directBoardAction.responseBody, /September agenda/);
    assert.equal(memberCanReadMessage(this, personName, "September agenda"), false);
  }
);

Then("no message, reply, or follow should be created by the attempt", function () {
  const { before, boardId, message, personName } = this.directBoardAction;
  assert.deepEqual(directActionSnapshot(this, personName, message, boardId), before);
});

Given(
  "Pat belongs to Nelson Paddling Club but not Kootenay Mountaineering Club",
  function () {
    ensureState(this);

    const member = serverCommands.ensureMember({
      clubName: "Nelson Paddling Club",
      clubSlug: "nelson-paddling-club",
      personName: "Pat",
      email: emailFor("Pat")
    });

    this.clubs["Nelson Paddling Club"] = {
      clubId: member.clubId,
      name: member.clubName,
      slug: member.clubSlug
    };
    this.people.Pat = {
      email: member.email,
      name: member.personName,
      personId: member.personId
    };
    this.memberships["Nelson Paddling Club:Pat"] = {
      clubId: member.clubId,
      membershipId: member.membershipId,
      personId: member.personId
    };

    assert.equal(activeClubMember(this, "Pat", kootenayClubName), false);
  }
);

When(
  "Pat opens a link to Kootenay Mountaineering Club's Board",
  async function () {
    const boardId = groupIdFor(this, kootenayClubName, "Board");

    await withMemberHarness(this, "Pat", async (member) => {
      await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          clubFor(member, kootenayClubName),
          `/groups/${encodeURIComponent(boardId)}`
        )
      );

      this.foreignGroupResponseBody = await member.page.locator("body").innerText();
    });
  }
);

Then("no KMC group details should be disclosed to Pat", async function () {
  assert.doesNotMatch(this.foreignGroupResponseBody, /\bBoard\b/);

  await withMemberHarness(this, "Pat", async (member) => {
    await expect(member.page.locator("#member-club-home")).toHaveCount(0);
    await expect(member.page.locator("[data-testid='member-group-link']")).toHaveCount(0);
  });
});

Then(
  /^(\w+) should see Board selected with access guidance$/,
  async function (personName) {
    const boardId = groupIdFor(this, kootenayClubName, "Board");

    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-club-home")).toHaveAttribute(
        "data-selected-group-id",
        boardId
      );
      await expect(member.page.locator("#member-group-name")).toHaveText("Board");
      await expect(member.page.locator("#member-group-access-guidance")).toBeVisible();
    });
  }
);

function ensureNamedGroupMembers(world, clubName, groupName, personNames) {
  ensureState(world);
  world.groups = world.groups || {};
  world.groupMembers = world.groupMembers || {};

  const club = clubFor(world, clubName);
  const members = personNames.map((personName) => {
    const membership = world.memberships[`${clubName}:${personName}`];
    const person = world.people[personName];

    assert.ok(membership, `Expected ${personName} to be a member of ${clubName}`);
    assert.ok(person, `Expected ${personName} to be a known person`);

    return {
      membershipId: membership.membershipId,
      personId: person.personId
    };
  });

  const result = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
group_name = Map.fetch!(payload, "groupName")
group_key = Map.fetch!(payload, "groupKey")
members = Map.fetch!(payload, "members")
group_id = Memba.ID.generate(:group)

:ok =
  Memba.Membership.App.dispatch(
    %Memba.Membership.Commands.CreateGroup{
      club_id: club_id,
      group_id: group_id,
      group_key: group_key,
      email_slug: group_key,
      name: group_name
    },
    consistency: :strong
  )

Enum.each(members, fn member ->
  :ok =
    Memba.Membership.App.dispatch(
      %Memba.Membership.Commands.AddGroupMember{
        club_id: club_id,
        group_id: group_id,
        membership_id: Map.fetch!(member, "membershipId"),
        person_id: Map.fetch!(member, "personId")
      },
      consistency: :strong
    )
end)

%{groupId: group_id}
`,
    {
      clubId: club.clubId,
      groupName,
      groupKey: groupKey(groupName),
      members
    }
  );

  world.groups[groupKeyForWorld(clubName, groupName)] = result.groupId;
  world.groupMembers[groupKeyForWorld(clubName, groupName)] = personNames;
}

function createGroupConversation(world, clubName, groupName, subject) {
  ensureState(world);

  const club = clubFor(world, clubName);
  const groupId = groupIdFor(world, clubName, groupName);
  const senderName =
    (world.groupMembers && world.groupMembers[groupKeyForWorld(clubName, groupName)]?.[0]) ||
    (groupName === "Admin" ? "Bob" : "Alice");
  const sender = world.people[senderName];
  assert.ok(sender, `Expected ${senderName} to be a known person`);

  const message = serverCommands.sendClubMessage({
    audienceGroupId: groupId,
    body: `${subject} details.`,
    clubId: club.clubId,
    senderId: sender.personId,
    senderName,
    subject
  });

  world.messages[subject] = {
    body: message.body,
    clubId: message.clubId,
    clubSlug: club.slug,
    messageId: message.messageId,
    senderName,
    subject
  };
}

async function selectGroup(world, groupName) {
  const link = groupLink(world, groupName);
  await expect(link).toBeVisible();
  const groupId = await link.getAttribute("data-group-id");
  const href = await link.getAttribute("href");
  await link.click();
  await world.page.goto(new URL(href, world.page.url()).toString());
  await expect(world.page.locator("#member-group-name")).toHaveText(groupName);
  await expect(world.page.locator("#member-club-home")).toHaveAttribute(
    "data-selected-group-id",
    groupId
  );
}

async function openGroup(world, clubName, groupId, section = "conversations") {
  const suffix = section === "members" ? "/members" : "";
  await world.page.goto(
    clubSiteUrl(world.baseUrl, clubFor(world, clubName), `/groups/${groupId}${suffix}`)
  );
  await expect(world.page.locator("#member-club-home")).toHaveAttribute(
    "data-selected-group-id",
    groupId
  );
}

async function rememberGroupSelection(world, personName, groupName, clubName) {
  const club = clubFor(world, clubName);
  const groupId = groupIdFor(world, clubName, groupName);

  await withMemberHarness(world, personName, async (member) => {
    await openMemberClubHome(member, clubName);
    await selectGroup(member, groupName);

    await expect
      .poll(() =>
        member.page.evaluate(
          ({ clubId }) => window.localStorage.getItem(`memba:lastGroup:${clubId}`),
          { clubId: club.clubId }
        )
      )
      .toBe(groupId);
  });
}

async function viewMembersAndAssertPresence(
  world,
  viewerName,
  memberName,
  expectedToBePresent
) {
  const personId = personIdFor(world, memberName);

  await withMemberHarness(world, viewerName, async (member) => {
    const conversationsTab = member.page.locator("#member-section-tab-conversations");
    const membersTab = member.page.locator("#member-section-tab-members");
    const action = member.page.locator("#member-section-tabs-action");

    if ((await membersTab.getAttribute("aria-selected")) !== "true") {
      await conversationsTab.focus();
      await expect(conversationsTab).toBeFocused();

      await conversationsTab.press("ArrowRight");
      await expect(membersTab).toHaveAttribute("aria-selected", "true");
      await expect(membersTab).toBeFocused();

      await membersTab.press("ArrowLeft");
      await expect(conversationsTab).toHaveAttribute("aria-selected", "true");
      await expect(conversationsTab).toBeFocused();

      await conversationsTab.press("End");
      await expect(membersTab).toHaveAttribute("aria-selected", "true");
      await expect(membersTab).toBeFocused();

      await membersTab.press("Home");
      await expect(conversationsTab).toHaveAttribute("aria-selected", "true");
      await expect(conversationsTab).toBeFocused();

      await conversationsTab.press("ArrowRight");
      await expect(membersTab).toHaveAttribute("aria-selected", "true");
      await expect(membersTab).toBeFocused();
    }

    assert.ok(
      (await action.locator("a, button").count()) <= 1,
      "Expected at most one contextual action for the active group section"
    );
    await expect(member.page.locator("#member-section-panel-members")).toBeVisible();
    await expect(member.page.locator("#member-section-panel-conversations")).toBeHidden();

    const row = member.page.locator(
      `[data-testid="club-member-row"][data-member-id="${personId}"]`
    );

    if (expectedToBePresent) {
      await expect(row).toBeVisible();
    } else {
      await expect(row).toHaveCount(0);
    }
  });
}

function groupLink(world, groupName) {
  const groupId = groupIdFor(world, kootenayClubName, groupName);
  return world.page.locator(
    `#member-group-rail [data-testid="member-group-link"][data-group-id="${groupId}"]`
  );
}

function conversationRow(world, subject) {
  return world.page.locator(
    `[data-testid="club-message-row"][data-message-subject="${subject}"]`
  );
}

function groupIdFor(world, clubName, groupName) {
  world.groups = world.groups || {};
  const key = groupKeyForWorld(clubName, groupName);

  if (world.groups[key]) {
    return world.groups[key];
  }

  const result = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
group_name = Map.fetch!(payload, "groupName")

group_id =
  case group_name do
    "Everyone" -> Memba.Membership.SystemGroups.everyone_group_id(club_id)
    "Admin" -> Memba.Membership.SystemGroups.admin_group_id(club_id)
  end

%{groupId: group_id}
`,
    { clubId: clubFor(world, clubName).clubId, groupName }
  );

  world.groups[key] = result.groupId;
  return result.groupId;
}

function clubFor(world, clubName) {
  ensureState(world);
  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to be a known club`);
  return club;
}

function personIdFor(world, personName) {
  ensureState(world);
  const person = world.people[personName];
  assert.ok(person, `Expected ${personName} to be a known person`);
  return person.personId;
}

function messageFor(world, subject) {
  ensureState(world);
  const message = world.messages[subject];
  assert.ok(message, `Expected ${JSON.stringify(subject)} to be a known message`);
  return message;
}

function activeGroupMemberNames(world, groupName) {
  const groupId = groupIdFor(world, kootenayClubName, groupName);

  return serverCommands.runCommand(
    `
group_id = Map.fetch!(payload, "groupId")
%{names: Enum.map(Memba.Membership.list_active_members_of_group(group_id), & &1.name)}
`,
    { groupId }
  ).names;
}

function clubAdminEmailAddress(world, clubName) {
  const club = clubFor(world, clubName);

  return serverCommands.runCommand(
    `
slug = Map.fetch!(payload, "slug")
%{
  email:
    Memba.ClubInboundEmailAddress.address(
      slug,
      Memba.Membership.SystemGroups.admin_email_slug()
    )
}
`,
    { slug: club.slug }
  ).email;
}

function memberCanReadMessage(world, personName, subject) {
  const message = messageFor(world, subject);

  return serverCommands.runCommand(
    `
allowed =
  Memba.Messaging.member_has_conversation_access?(
    Map.fetch!(payload, "messageId"),
    Map.fetch!(payload, "clubId"),
    Map.fetch!(payload, "personId"),
    :read
  )

%{allowed: allowed}
`,
    {
      clubId: message.clubId,
      messageId: message.messageId,
      personId: personIdFor(world, personName)
    }
  ).allowed;
}

function memberParticipatesInGroup(world, personName, groupName) {
  return serverCommands.runCommand(
    `
participating =
  Map.fetch!(payload, "clubId")
  |> Memba.Membership.list_active_groups_for_member(Map.fetch!(payload, "personId"))
  |> Enum.any?(&(&1.group_id == Map.fetch!(payload, "groupId")))

%{participating: participating}
`,
    {
      clubId: clubFor(world, kootenayClubName).clubId,
      groupId: groupIdFor(world, kootenayClubName, groupName),
      personId: personIdFor(world, personName)
    }
  ).participating;
}

function directActionSnapshot(world, personName, message, boardId) {
  return serverCommands.runCommand(
    `
board_id = Map.fetch!(payload, "boardId")
conversation_id = Map.fetch!(payload, "conversationId")
person_id = Map.fetch!(payload, "personId")

%{
  boardConversationCount:
    board_id |> Memba.Messaging.list_conversations_for_group() |> Enum.count(),
  conversationMessageCount:
    conversation_id |> Memba.Messaging.list_conversation_messages() |> Enum.count(),
  following: Memba.Messaging.following_conversation?(conversation_id, person_id)
}
`,
    {
      boardId,
      conversationId: message.messageId,
      personId: personIdFor(world, personName)
    }
  );
}

function activeClubMember(world, personName, clubName) {
  return serverCommands.runCommand(
    `
active =
  Memba.Membership.active_member_of_club?(
    Map.fetch!(payload, "clubId"),
    Map.fetch!(payload, "personId")
  )

%{active: active}
`,
    {
      clubId: clubFor(world, clubName).clubId,
      personId: personIdFor(world, personName)
    }
  ).active;
}

function groupKeyForWorld(clubName, groupName) {
  return `${clubName}:${groupName}`;
}

function groupKey(groupName) {
  return groupName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}
