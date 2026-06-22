const assert = require("node:assert/strict");
const { describe, it } = require("node:test");

const { smokeConfig } = require("../lib/config");

describe("smokeConfig", () => {
  it("uses the production smoke club subdomain address by default", () => {
    withSmokeEnv({}, () => {
      assert.equal(smokeConfig().inboundAddress, "everyone@test.clubs.memba.io");
    });
  });

  it("builds the smoke club address from the configured slug and inbound namespace", () => {
    withSmokeEnv(
      {
        MEMBA_SMOKE_CLUB_SLUG: "kmc",
        MEMBA_SMOKE_INBOUND_DOMAIN: "clubs.example.test"
      },
      () => {
        assert.equal(smokeConfig().inboundAddress, "everyone@kmc.clubs.example.test");
      }
    );
  });
});

function withSmokeEnv(overrides, run) {
  const defaultSensitiveKeys = ["MEMBA_SMOKE_CLUB_SLUG", "MEMBA_SMOKE_INBOUND_DOMAIN"];
  const env = {
    MEMBA_SMOKE_FASTMAIL_PASSWORD: "fastmail-password",
    MEMBA_SMOKE_STAFF_EMAIL: "staff@memba.test",
    MEMBA_SMOKE_UNKNOWN_EMAIL: "unknown@memba.test",
    ...overrides
  };
  const original = {};
  const keys = [...new Set([...Object.keys(env), ...defaultSensitiveKeys])];

  for (const key of keys) {
    original[key] = process.env[key];
    if (Object.prototype.hasOwnProperty.call(env, key)) {
      process.env[key] = env[key];
    } else {
      delete process.env[key];
    }
  }

  try {
    run();
  } finally {
    for (const key of keys) {
      if (original[key] === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = original[key];
      }
    }
  }
}
