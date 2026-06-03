function requiredEnv(name) {
  const value = process.env[name];
  if (!value || String(value).trim() === "") {
    throw new Error(`Missing required environment variable ${name}`);
  }
  return value;
}

function optionalEnv(name, fallback) {
  const value = process.env[name];
  return value && String(value).trim() !== "" ? value : fallback;
}

function smokeConfig() {
  const baseUrl = optionalEnv("MEMBA_SMOKE_BASE_URL", "https://memba.io");
  const clubName = optionalEnv("MEMBA_SMOKE_CLUB_NAME", "Test");
  const clubSlug = optionalEnv("MEMBA_SMOKE_CLUB_SLUG", "test");
  const inboundDomain = optionalEnv("MEMBA_SMOKE_INBOUND_DOMAIN", "clubs.memba.io");
  const clubSiteBaseDomain = optionalEnv("MEMBA_SMOKE_CLUB_SITE_BASE_DOMAIN", new URL(baseUrl).hostname);
  const memberEmail = optionalEnv("MEMBA_SMOKE_MEMBER_EMAIL", "test@memba.io");
  const memberName = optionalEnv("MEMBA_SMOKE_MEMBER_NAME", "Test");
  const staffEmail = requiredEnv("MEMBA_SMOKE_STAFF_EMAIL");

  const fastmailUser = optionalEnv("MEMBA_SMOKE_FASTMAIL_USER", memberEmail);
  const fastmailPassword = requiredEnv("MEMBA_SMOKE_FASTMAIL_PASSWORD");
  const jmapToken = requiredEnv("MEMBA_SMOKE_FASTMAIL_JMAP_TOKEN");

  const unknownEmail = requiredEnv("MEMBA_SMOKE_UNKNOWN_EMAIL");
  const unknownFastmailUser = optionalEnv("MEMBA_SMOKE_UNKNOWN_FASTMAIL_USER", unknownEmail);
  const unknownFastmailPassword = optionalEnv("MEMBA_SMOKE_UNKNOWN_FASTMAIL_PASSWORD", fastmailPassword);
  const unknownJmapToken = optionalEnv("MEMBA_SMOKE_UNKNOWN_FASTMAIL_JMAP_TOKEN", jmapToken);

  const staffJmapToken = optionalEnv("MEMBA_SMOKE_STAFF_FASTMAIL_JMAP_TOKEN", jmapToken);

  return {
    baseUrl,
    clubName,
    clubSlug,
    clubSiteBaseDomain,
    inboundAddress: `${clubSlug}@${inboundDomain}`,
    member: {
      email: memberEmail,
      name: memberName,
      smtpUser: fastmailUser,
      smtpPassword: fastmailPassword,
      jmapToken
    },
    unknown: {
      email: unknownEmail,
      smtpUser: unknownFastmailUser,
      smtpPassword: unknownFastmailPassword,
      jmapToken: unknownJmapToken
    },
    staff: {
      email: staffEmail,
      jmapToken: staffJmapToken
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
