const assert = require("node:assert/strict");
const { When, Then } = require("@cucumber/cucumber");
const { callStaffTool, listStaffTools } = require("../support/staff_mcp");
const { kootenayClubName } = require("../support/member_message");

When("Pat lists the staff MCP tools", async function () {
  this.staffTools = await listStaffTools(this);
});

Then("Pat can list clubs, people, messages, and deliveries", function () {
  const names = this.staffTools.map((tool) => tool.name);
  for (const name of ["list_clubs", "list_people", "list_messages", "list_deliveries"]) {
    assert.ok(names.includes(name), `Expected ${name} in the staff tools`);
  }
});

Then("Pat cannot send club messages as a member", function () {
  assert.ok(!this.staffTools.some((tool) => /send.*message/.test(tool.name)));
});

When("Pat finds {string} in the staff MCP message list", async function (subject) {
  const { items } = await callStaffTool(this, "list_messages");
  const message = items.find((item) => item.subject === subject);
  assert.ok(message, `Expected ${subject} in the staff MCP message list`);
  assert.equal(message.club_name, kootenayClubName);
  this.staffMessageId = message.message_id;
});

Then("the staff MCP server shows its delivery diagnostics", async function () {
  const diagnostics = await callStaffTool(this, "get_message", { message_id: this.staffMessageId });
  assert.equal(diagnostics.message.message_id, this.staffMessageId);
  assert.ok(diagnostics.dispatch.items.some((item) => item.recipient_name === "Bob"));
  assert.ok(diagnostics.receipts.items.some((item) => item.recipient_name === "Bob"));
});
