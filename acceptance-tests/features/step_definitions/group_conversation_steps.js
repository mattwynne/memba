const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  ensureState,
  kootenayClubName,
  openMemberClubHome
} = require("../support/member_message");
const { withMemberHarness } = require("../support/member_harness");
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

      await member.page.getByLabel("Subject").fill(subject);
      await member.page.getByLabel("Message").fill(body);
      await member.page.getByRole("button", { name: "Send to all current members" }).click();

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
  let status;

  await withMemberHarness(this, personName, async (member) => {
    const response = await member.page.goto(
      clubSiteUrl(member.baseUrl, clubFor(member, kootenayClubName), `/groups/${groupId}`)
    );

    status = response.status();
    await expect(member.page.locator("body")).toContainText("Not Found");
    await expect(member.page.getByText(groupName, { exact: true })).toHaveCount(0);
  });

  this.lastGroupPageStatus = status;
});

Then("{word} should be shown that the page was not found", async function (personName) {
  assert.equal(this.lastGroupPageStatus, 404);

  await withMemberHarness(this, personName, async (member) => {
    await expect(member.page.locator("body")).toContainText("Not Found");
  });
});

Given(
  /^(\w+) most recently viewed the (.+) group in (.+)$/,
  async function (personName, groupName, clubName) {
    const club = clubFor(this, clubName);
    const groupId = groupIdFor(this, clubName, groupName);

    await withMemberHarness(this, personName, async (member) => {
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

function ensureNamedGroupMembers(world, clubName, groupName, personNames) {
  ensureState(world);
  world.groups = world.groups || {};

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
}

function createGroupConversation(world, clubName, groupName, subject) {
  ensureState(world);

  const club = clubFor(world, clubName);
  const groupId = groupIdFor(world, clubName, groupName);
  const senderName = groupName === "Admin" ? "Bob" : "Alice";
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

async function viewMembersAndAssertPresence(
  world,
  viewerName,
  memberName,
  expectedToBePresent
) {
  const personId = personIdFor(world, memberName);

  await withMemberHarness(world, viewerName, async (member) => {
    await member.page.locator("#member-section-tab-members").click();
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
  return world.page
    .locator("#member-group-rail")
    .getByRole("link", { name: groupName, exact: true });
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
