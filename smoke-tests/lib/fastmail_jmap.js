const assert = require("node:assert/strict");

const JMAP_SESSION_URL = "https://api.fastmail.com/jmap/session";

class FastmailJmapClient {
  constructor({ token }) {
    assert.ok(token, "Expected a Fastmail JMAP API token");
    this.token = token;
    this.session = null;
    this.apiUrl = null;
    this.accountId = null;
  }

  async connect() {
    const response = await fetch(JMAP_SESSION_URL, {
      headers: { Authorization: `Bearer ${this.token}` }
    });

    if (!response.ok) {
      throw new Error(`Fastmail JMAP session failed: HTTP ${response.status} ${await response.text()}`);
    }

    this.session = await response.json();
    this.apiUrl = this.session.apiUrl;
    this.accountId = this.session.primaryAccounts && this.session.primaryAccounts["urn:ietf:params:jmap:mail"];

    if (!this.apiUrl || !this.accountId) {
      throw new Error("Fastmail JMAP session did not include a mail apiUrl/accountId");
    }

    return this;
  }

  async apiCall(methodCalls) {
    if (!this.session) {
      await this.connect();
    }

    const response = await fetch(this.apiUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
        methodCalls
      })
    });

    if (!response.ok) {
      throw new Error(`Fastmail JMAP call failed: HTTP ${response.status} ${await response.text()}`);
    }

    return response.json();
  }

  async recentEmails({ after, limit = 30, text } = {}) {
    const filter = {};
    if (after) {
      filter.after = after instanceof Date ? after.toISOString() : after;
    }
    if (text) {
      filter.text = text;
    }

    const result = await this.apiCall([
      [
        "Email/query",
        {
          accountId: this.accountId,
          filter,
          limit,
          sort: [{ property: "receivedAt", isAscending: false }]
        },
        "q"
      ],
      [
        "Email/get",
        {
          accountId: this.accountId,
          "#ids": { resultOf: "q", name: "Email/query", path: "/ids" },
          properties: ["id", "blobId", "threadId", "mailboxIds", "keywords", "subject", "from", "to", "cc", "bcc", "receivedAt", "sentAt", "preview", "textBody", "htmlBody", "bodyValues"],
          fetchTextBodyValues: true,
          fetchHTMLBodyValues: true,
          maxBodyValueBytes: 200000
        },
        "g"
      ]
    ]);

    const get = result.methodResponses.find(([name, _args, id]) => name === "Email/get" && id === "g");
    if (!get) {
      throw new Error(`Fastmail JMAP Email/get response missing: ${JSON.stringify(result)}`);
    }

    return get[1].list.map(normalizeEmail);
  }

  async waitForEmail(predicate, { after, description, intervalMs = 5000, timeoutMs = 120000, text } = {}) {
    const deadline = Date.now() + timeoutMs;
    let lastEmails = [];

    while (Date.now() <= deadline) {
      lastEmails = await this.recentEmails({ after, text });
      const found = lastEmails.find(predicate);
      if (found) {
        return found;
      }
      await this.waitForEmailEvent({ timeoutMs: Math.min(intervalMs, Math.max(0, deadline - Date.now())) });
    }

    throw new Error(
      `Timed out waiting for ${description || "email"}. Last emails: ${JSON.stringify(lastEmails.map(summary))}`
    );
  }

  async waitForEmailEvent({ timeoutMs = 5000 } = {}) {
    if (!this.session || !this.session.eventSourceUrl || timeoutMs <= 0) {
      await new Promise((resolve) => setTimeout(resolve, timeoutMs));
      return;
    }

    try {
      await waitForJmapEvent({
        eventSourceUrl: this.session.eventSourceUrl,
        token: this.token,
        timeoutMs
      });
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, timeoutMs));
    }
  }
}

async function waitForJmapEvent({ eventSourceUrl, token, timeoutMs }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const url = eventSourceUrl
      .replace("{types}", encodeURIComponent("Email"))
      .replace("{closeafter}", encodeURIComponent("StateChange"))
      .replace("{ping}", "300");

    const response = await fetch(url, {
      headers: { Accept: "text/event-stream", Authorization: `Bearer ${token}` },
      signal: controller.signal
    });

    if (!response.ok || !response.body) {
      throw new Error(`Fastmail JMAP event source failed: HTTP ${response.status}`);
    }

    for await (const chunk of response.body) {
      const text = Buffer.from(chunk).toString("utf8");
      if (/^data:/m.test(text) && /Email|StateChange/i.test(text)) {
        controller.abort();
        return;
      }
    }
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeEmail(email) {
  const bodyValues = email.bodyValues || {};
  const text = bodyParts(email.textBody, bodyValues).join("\n");
  const html = bodyParts(email.htmlBody, bodyValues).join("\n");

  return {
    ...email,
    fromEmails: addresses(email.from),
    toEmails: addresses(email.to),
    text,
    html
  };
}

function bodyParts(parts, bodyValues) {
  return (parts || [])
    .map((part) => bodyValues[part.partId] && bodyValues[part.partId].value)
    .filter((value) => typeof value === "string" && value.length > 0);
}

function addresses(items) {
  return (items || []).map((item) => String(item.email || "").toLowerCase()).filter(Boolean);
}

function summary(email) {
  return {
    subject: email.subject,
    from: email.fromEmails,
    to: email.toEmails,
    receivedAt: email.receivedAt,
    preview: email.preview
  };
}

module.exports = { FastmailJmapClient };
