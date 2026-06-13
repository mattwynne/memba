const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertActiveMember,
  assertCannotSignInToClub,
  assertClubDoesNotExist,
  assertClubExists,
  assertKnownReadOnlyDetails,
  assertNoDuplicatePerson,
  assertPreparingToConvertRequest,
  assertRequestLeavesInbox,
  assertRequestRecordedWithKnownDetails,
  assertRequestVisible,
  assertRequesterNotEmailedAboutRejection,
  assertReviewAcknowledgement,
  assertSignedInToClub,
  assertStaffNotified,
  assertSuggestedSlug,
  assertWelcomeEmail,
  convertRequest,
  createRequestDirectly,
  ensurePerson,
  followStaffNotificationLink,
  followWelcomeLink,
  openGetStartedPage,
  openRequestsInbox,
  rejectRequest,
  signInPerson,
  submitRequestThroughBrowser
} = require("../support/request_account");

Given("{word} is signed in", async function (personName) {
  await signInPerson(this, personName);
});

Given("{word} is a person in Memba", async function (personName) {
  await ensurePerson(this, personName);
});

Given(/^(\w+) has requested Memba access for (.+)$/, async function (personName, clubName) {
  await createRequestDirectly(this, personName, clubName);
});

When(/^(\w+) requests Memba access for (.+) with a short note$/, async function (personName, clubName) {
  await submitRequestThroughBrowser(this, personName, clubName);
});

When("{word} opens the get-started page", async function (_personName) {
  await openGetStartedPage(this);
});

When("{word} opens the active requests inbox", async function (_staffName) {
  await openRequestsInbox(this);
});

When(
  /^(\w+) changes the club slug to "([^"]+)" and converts the request$/,
  async function (staffName, slug) {
    await convertRequest(this, staffName === "Pat" ? "Robin" : staffName, "West Coast Paddlers", { slug });
  }
);

When(
  /^(\w+) converts (\w+)'s (.+) request with slug "([^"]+)"$/,
  async function (_staffName, personName, clubName, slug) {
    await convertRequest(this, personName, clubName, { slug });
  }
);

When(/^(\w+) converts (\w+)'s (.+) request$/, async function (_staffName, personName, clubName) {
  await convertRequest(this, personName, clubName);
});

When(
  /^(\w+) rejects (\w+)'s (.+) request with the internal note "([^"]+)"$/,
  async function (_staffName, personName, clubName, internalNote) {
    await rejectRequest(this, personName, clubName, internalNote);
  }
);

When("{word} follows the staff notification link for {word}'s request", async function (_staffName, personName) {
  await followStaffNotificationLink(this, personName);
});

When("{word} follows the welcome sign-in link", async function (personName) {
  await followWelcomeLink(this, personName);
});

Then("{word} should see that Memba will review the request", async function (_personName) {
  await assertReviewAcknowledgement(this);
});

Then("Memba staff should be notified about {word}'s request", async function (personName) {
  await assertStaffNotified(this, personName);
});

Then(/^(.+) should not exist as a club yet$/, function (clubName) {
  assertClubDoesNotExist(clubName);
});

Then(/^(.+) should not exist as a club$/, function (clubName) {
  assertClubDoesNotExist(clubName);
});

Then(/^(\w+) should not be able to sign in to (.+?)(?: yet)?$/, async function (personName, clubName) {
  await assertCannotSignInToClub(this, personName, clubName);
});

Then("{word} should see their known name and email address as read-only request details", async function (personName) {
  await assertKnownReadOnlyDetails(this, personName);
});

Then(
  "Memba should record {word}'s request with {word}'s known name and email address",
  function (requesterName, _detailsPersonName) {
    assertRequestRecordedWithKnownDetails(this, requesterName, this.lastOnboardingRequestClubName);
  }
);

Then(/^(\w+) should see (\w+)'s (.+) request$/, async function (_staffName, requesterName, clubName) {
  await assertRequestVisible(this, requesterName, clubName);
});

Then("{word} should see the suggested club slug {string}", async function (_staffName, expectedSlug) {
  await assertSuggestedSlug(this, "West Coast Paddlers", expectedSlug);
});

Then(
  /^(\w+) should be preparing to convert (\w+)'s (.+) request$/,
  async function (_staffName, personName, clubName) {
    await assertPreparingToConvertRequest(this, personName, clubName);
  }
);

Then(/^(.+) should exist with the slug "([^"]+)"$/, function (clubName, slug) {
  assertClubExists(clubName, slug);
});

Then(/^(.+) should exist as a club$/, function (clubName) {
  assertClubExists(clubName);
});

Then(/^(\w+) should be an active member of (.+)$/, function (personName, clubName) {
  assertActiveMember(this, personName, clubName);
});

Then("{word}'s request should leave the active requests inbox", async function (personName) {
  if (!this.lastOnboardingRequestClubName) {
    throw new Error(`Expected a last onboarding request club name before checking ${personName}'s request`);
  }

  await assertRequestLeavesInbox(this, this.lastOnboardingRequestClubName);
});

Then("Memba should not create a duplicate person for {word}", function (personName) {
  assertNoDuplicatePerson(this, personName);
});

Then("{word} should not receive an email about the rejected request", async function (personName) {
  await assertRequesterNotEmailedAboutRejection(this, personName);
});

Then(/^(\w+) should receive a welcome email for (.+)$/, async function (personName, clubName) {
  await assertWelcomeEmail(this, personName, clubName);
});

Then(/^(\w+) should be signed in to (.+)$/, async function (personName, clubName) {
  await assertSignedInToClub(this, personName, clubName);
});
