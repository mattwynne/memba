const assert = require("node:assert/strict");
const test = require("node:test");

const { parseCommandResult } = require("../features/support/server_commands");

function frame(value) {
  const encoded = Buffer.from(JSON.stringify(value), "utf8").toString("base64");

  return `__MEMBA_ACCEPTANCE_RESULT_START__${encoded}__MEMBA_ACCEPTANCE_RESULT_END__`;
}

test("server command results ignore logger output sharing RPC stdout", () => {
  const output = [
    "16:31:54.550 [warning] email_delivery_provider_error",
    frame([{ deliveryId: "del-1", status: "failed" }]),
    "16:31:54.551 [debug] asynchronous log after the result"
  ].join("\n");

  assert.deepEqual(parseCommandResult(output), [{ deliveryId: "del-1", status: "failed" }]);
});

test("server command results require an explicit frame", () => {
  assert.throws(
    () => parseCommandResult('{"status":"sent"}'),
    /Acceptance server command returned an unframed result/
  );
});
