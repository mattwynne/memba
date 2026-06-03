const POSTMARK_API_BASE_URL = "https://api.postmarkapp.com";

class PostmarkInboundDiagnostics {
  constructor({ apiBaseUrl = POSTMARK_API_BASE_URL, messageStream, token }) {
    this.apiBaseUrl = apiBaseUrl.replace(/\/$/, "");
    this.messageStream = messageStream;
    this.token = token;
  }

  static configured(config) {
    return Boolean(config && config.postmark && config.postmark.serverToken);
  }

  async waitForInboundMessage({ after, description, from, intervalMs = 5000, recipient, subject, timeoutMs = 120000 }) {
    const deadline = Date.now() + timeoutMs;
    let lastMessages = [];

    while (Date.now() <= deadline) {
      lastMessages = await this.recentInboundMessages({ after, from, recipient, subject });
      const match = lastMessages.find((message) => message.subject === subject && includesRecipient(message, recipient));
      if (match) {
        return match;
      }
      await new Promise((resolve) => setTimeout(resolve, Math.min(intervalMs, Math.max(0, deadline - Date.now()))));
    }

    throw new Error(
      `Timed out waiting for Postmark inbound message ${description || subject}. Last inbound messages: ${JSON.stringify(lastMessages.map(summary))}`
    );
  }

  async recentInboundMessages({ after, count = 25, from, recipient, subject } = {}) {
    const url = new URL("/messages/inbound", this.apiBaseUrl);
    url.searchParams.set("count", String(count));
    url.searchParams.set("offset", "0");
    if (subject) url.searchParams.set("subject", subject);
    if (from) url.searchParams.set("fromemail", from);
    if (recipient) url.searchParams.set("recipient", recipient);
    if (after) url.searchParams.set("fromdate", toPostmarkDate(after));
    if (this.messageStream) url.searchParams.set("messagestream", this.messageStream);

    const response = await fetch(url, {
      headers: {
        Accept: "application/json",
        "X-Postmark-Server-Token": this.token
      }
    });

    if (!response.ok) {
      throw new Error(`Postmark inbound message query failed: HTTP ${response.status} ${await response.text()}`);
    }

    const body = await response.json();
    const messages = body.InboundMessages || body.Messages || [];
    return messages.map(normalizeInboundMessage);
  }
}

function normalizeInboundMessage(message) {
  return {
    id: message.ID || message.MessageID || message.MessageId || message.ID,
    subject: message.Subject || message.subject || "",
    from: (message.From || message.FromEmail || message.FromFull && message.FromFull.Email || "").toLowerCase(),
    recipients: recipients(message),
    receivedAt: message.ReceivedAt || message.Date || message.CreatedAt || null,
    status: message.Status || message.status || null,
    raw: message
  };
}

function recipients(message) {
  return [message.OriginalRecipient, message.To, message.Recipient, message.ToFull && message.ToFull.Email]
    .flatMap((value) => String(value || "").split(/[;,]/))
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
}

function includesRecipient(message, recipient) {
  return message.recipients.includes(String(recipient || "").toLowerCase());
}

function summary(message) {
  return {
    id: message.id,
    subject: message.subject,
    from: message.from,
    recipients: message.recipients,
    receivedAt: message.receivedAt,
    status: message.status
  };
}

function toPostmarkDate(value) {
  return (value instanceof Date ? value : new Date(value)).toISOString().replace(/\.\d{3}Z$/, "Z");
}

module.exports = { PostmarkInboundDiagnostics };
