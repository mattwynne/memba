const { Then, When } = require("@cucumber/cucumber");
const {
  assertAddMemberPickerClosedWithTriggerFocused,
  assertAddMemberSearchFocused,
  assertOnlyMemberOffered,
  closeAddMemberPicker,
  openAddMemberPicker,
  pasteIntoAddMemberSearch,
  pressEscapeInAddMemberPicker
} = require("../support/custom_group_membership");

When(/^(\w+) opens (.+)'s add-member picker$/, async function (memberName, groupName) {
  this.addMemberPickerActor = memberName;
  await openAddMemberPicker(this, memberName, groupName);
});

Then("the add-member search should have focus", async function () {
  await assertAddMemberSearchFocused(this, this.addMemberPickerActor);
});

When(
  /^(\w+) pastes "([^"]+)" into the add-member search$/,
  async function (memberName, query) {
    this.addMemberPickerActor = memberName;
    await pasteIntoAddMemberSearch(this, memberName, query);
  }
);

Then(
  /^only (\w+) should be offered in the add-member picker$/,
  async function (memberName) {
    await assertOnlyMemberOffered(this, this.addMemberPickerActor, memberName);
  }
);

When(
  /^(\w+) presses Escape in the add-member picker$/,
  async function (memberName) {
    this.addMemberPickerActor = memberName;
    await pressEscapeInAddMemberPicker(this, memberName);
  }
);

When(/^(\w+) closes the add-member picker$/, async function (memberName) {
  this.addMemberPickerActor = memberName;
  await closeAddMemberPicker(this, memberName);
});

Then(
  "the add-member picker should close and return focus to its trigger",
  async function () {
    await assertAddMemberPickerClosedWithTriggerFocused(this, this.addMemberPickerActor);
  }
);
