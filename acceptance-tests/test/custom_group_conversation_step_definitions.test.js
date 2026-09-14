const assert = require("node:assert/strict");
const test = require("node:test");

const { loadConfiguration, runCucumber } = require("@cucumber/cucumber/api");
const {
  assertRejectedInboundReplyAttempt
} = require("../features/support/custom_group_conversations");

test("an accepted root message cannot satisfy a rejected custom-group reply attempt", () => {
  assert.throws(
    () =>
      assertRejectedInboundReplyAttempt(
        {
          conversationIdsBefore: ["original-message-id"],
          inboundResult: {
            message: {
              messageId: "accidental-root-message-id",
              replyToMessageId: null
            },
            source: {
              messageId: "accidental-root-message-id",
              rejectionReason: null,
              status: "accepted"
            }
          }
        },
        ["original-message-id", "accidental-root-message-id"]
      ),
    /rejected/
  );
});

test("a rejected custom-group reply cannot create a separate conversation", () => {
  assert.throws(
    () =>
      assertRejectedInboundReplyAttempt(
        {
          conversationIdsBefore: ["original-message-id"],
          inboundResult: {
            message: null,
            source: {
              messageId: null,
              rejectionReason: "not_current_member",
              status: "rejected"
            }
          }
        },
        ["original-message-id", "separate-message-id"]
      ),
    /conversation set/
  );
});

test("browser-backed custom-group conversation scenarios have executable step plumbing", async () => {
  let scenarioCount = 0;
  const statuses = [];
  const { runConfiguration } = await loadConfiguration({
    file: false,
    provided: {
      dryRun: true,
      format: ["message:/dev/null"],
      paths: ["features/custom_group_conversations.feature"],
      publishQuiet: true,
      require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
      tags: "@iteration-062 and not @not-ui"
    }
  });

  await runCucumber(runConfiguration, undefined, (message) => {
    if (message.testCaseStarted) {
      scenarioCount += 1;
    }

    if (message.testStepFinished) {
      statuses.push(message.testStepFinished.testStepResult.status);
    }
  });

  assert.equal(scenarioCount, 13);
  assert.deepEqual(
    [...new Set(statuses)],
    ["SKIPPED"],
    "Expected every browser-backed custom-group conversation step to have exactly one definition"
  );
});
