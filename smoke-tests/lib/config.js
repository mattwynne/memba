function requiredEnv(name) {
  const value = process.env[name];
  if (!value || String(value).trim() === "") {
    throw new Error(`Missing required environment variable ${name}`);
  }
  return value;
}

function requiredEnvAny(names) {
  for (const name of names) {
    const value = process.env[name];
    if (value && String(value).trim() !== "") {
      return value;
    }
  }

  throw new Error(`Missing required environment variable; set one of ${names.join(", ")}`);
}

function optionalEnv(name, fallback) {
  const value = process.env[name];
  return value && String(value).trim() !== "" ? value : fallback;
}

function smokeConfig() {
  const baseUrl = optionalEnv("MEMBA_SMOKE_BASE_URL", "https://memba.io");
  const clubName = optionalEnv("MEMBA_SMOKE_CLUB_NAME", "Smoke Test Club");
  const clubSlug = optionalEnv("MEMBA_SMOKE_CLUB_SLUG", "test");
  const inboundDomain = optionalEnv("MEMBA_SMOKE_INBOUND_DOMAIN", "clubs.memba.io");
  const clubSiteBaseDomain = optionalEnv("MEMBA_SMOKE_CLUB_SITE_BASE_DOMAIN", inboundDomain);
  const memberEmail = optionalEnv("MEMBA_SMOKE_MEMBER_EMAIL", "test@memba.io");
  const memberName = optionalEnv("MEMBA_SMOKE_MEMBER_NAME", "Smoke Tester");
  const staffEmail = requiredEnv("MEMBA_SMOKE_STAFF_EMAIL");

  const fastmailUser = optionalEnv("MEMBA_SMOKE_FASTMAIL_USER", memberEmail);
  const fastmailPassword = requiredEnvAny(["MEMBA_SMOKE_FASTMAIL_PASSWORD", "SMOKE_TEST_EMAIL_PASSWORD"]);
  const jmapToken = optionalEnv(
    "MEMBA_SMOKE_FASTMAIL_JMAP_TOKEN",
    optionalEnv("SMOKE_TEST_EMAIL_API_KEY", optionalEnv("FASTMAIL_API_KEY", null))
  );

  const unknownEmail = requiredEnv("MEMBA_SMOKE_UNKNOWN_EMAIL");

  const staffFastmailUser = optionalEnv("MEMBA_SMOKE_STAFF_FASTMAIL_USER", fastmailUser);
  const staffFastmailPassword = optionalEnv("MEMBA_SMOKE_STAFF_FASTMAIL_PASSWORD", fastmailPassword);
  const staffJmapToken = optionalEnv("MEMBA_SMOKE_STAFF_FASTMAIL_JMAP_TOKEN", jmapToken);

  const postmarkServerToken = optionalEnv(
    "MEMBA_SMOKE_POSTMARK_SERVER_TOKEN",
    optionalEnv("MEMBA_POSTMARK_SERVER_TOKEN", null)
  );
  const postmarkInboundMessageStream = optionalEnv("MEMBA_SMOKE_POSTMARK_INBOUND_MESSAGE_STREAM", null);

  return {
    baseUrl,
    clubName,
    clubSlug,
    clubSiteBaseDomain,
    inboundAddress: `everyone@${clubSlug}.${inboundDomain}`,
    member: {
      email: memberEmail,
      name: memberName,
      smtpUser: fastmailUser,
      smtpPassword: fastmailPassword,
      imapUser: fastmailUser,
      imapPassword: fastmailPassword,
      jmapToken
    },
    unknown: {
      email: unknownEmail,
      smtpUser: fastmailUser,
      smtpPassword: fastmailPassword,
      imapUser: fastmailUser,
      imapPassword: fastmailPassword,
      jmapToken
    },
    staff: {
      email: staffEmail,
      imapUser: staffFastmailUser,
      imapPassword: staffFastmailPassword,
      jmapToken: staffJmapToken
    },
    postmark: {
      serverToken: postmarkServerToken,
      inboundMessageStream: postmarkInboundMessageStream
    },
    poll: {
      intervalMs: Number(optionalEnv("MEMBA_SMOKE_POLL_INTERVAL_MS", "5000")),
      timeoutMs: Number(optionalEnv("MEMBA_SMOKE_POLL_TIMEOUT_MS", "120000"))
    },
    browser: {
      headless: process.env.HEADLESS !== "false"
    }
  };
}

module.exports = { smokeConfig };
