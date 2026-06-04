const assert = require("node:assert/strict");
const tls = require("node:tls");

class FastmailImapClient {
  constructor({ host = "imap.fastmail.com", port = 993, user, password }) {
    assert.ok(user, "Expected an IMAP user");
    assert.ok(password, "Expected an IMAP password");
    this.host = host;
    this.port = port;
    this.user = user;
    this.password = password;
    this.client = null;
  }

  async connect() {
    this.client = await ImapClient.connect({ host: this.host, port: this.port });
    await this.client.expectUntaggedOk();
    await this.client.command("LOGIN", [this.user, this.password]);
    await this.client.command("SELECT", ["INBOX"]);
    return this;
  }

  async recentEmails({ after, limit = 30, text } = {}) {
    if (!this.client) {
      await this.connect();
    }

    const searchResponse = await this.client.command("UID SEARCH", ["ALL"]);
    const uids = parseSearchUids(searchResponse).slice(-1 * limit);
    if (uids.length === 0) {
      return [];
    }

    const fetchResponse = await this.client.rawCommand(
      `UID FETCH ${uidSet(uids)} (UID INTERNALDATE BODY.PEEK[])`
    );

    return parseFetchedMessages(fetchResponse)
      .map(normalizeMessage)
      .filter((email) => !after || new Date(email.receivedAt) >= new Date(after))
      .filter((email) => !text || searchableText(email).toLowerCase().includes(String(text).toLowerCase()))
      .sort((left, right) => {
        const dateComparison = new Date(right.receivedAt) - new Date(left.receivedAt);
        return dateComparison || Number(right.id || 0) - Number(left.id || 0);
      });
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
      await new Promise((resolve) => setTimeout(resolve, intervalMs));
    }

    throw new Error(
      `Timed out waiting for ${description || "email"}. Last emails: ${JSON.stringify(lastEmails.map(summary))}`
    );
  }

  close() {
    if (this.client) {
      this.client.close();
    }
  }
}

class ImapClient {
  constructor(socket) {
    this.socket = socket;
    this.buffer = "";
    this.tag = 0;
    socket.on("data", (chunk) => {
      this.buffer += chunk.toString("utf8");
    });
  }

  static connect({ host, port }) {
    return new Promise((resolve, reject) => {
      const socket = tls.connect({ host, port, servername: host }, () => resolve(new ImapClient(socket)));
      socket.once("error", reject);
    });
  }

  async expectUntaggedOk() {
    await this.readUntil((buffer) => /^\* OK/m.test(buffer));
  }

  async command(command, args = []) {
    return this.rawCommand(`${command} ${args.map(quoteAtom).join(" ")}`.trim());
  }

  async rawCommand(line) {
    const tag = `A${++this.tag}`;
    this.socket.write(`${tag} ${line}\r\n`);
    const response = await this.readUntil((buffer) => new RegExp(`(^|\\r?\\n)${tag} (OK|NO|BAD)`, "m").test(buffer));

    if (new RegExp(`(^|\\r?\\n)${tag} (NO|BAD)`, "m").test(response)) {
      throw new Error(`Unexpected IMAP response for ${line}:\n${response}`);
    }

    return response;
  }

  readUntil(done) {
    return new Promise((resolve, reject) => {
      const deadline = Date.now() + 30000;
      const poll = () => {
        if (done(this.buffer)) {
          const response = this.buffer;
          this.buffer = "";
          resolve(response);
          return;
        }

        if (Date.now() > deadline) {
          reject(new Error(`Timed out waiting for IMAP response. Buffer:\n${this.buffer}`));
          return;
        }

        setTimeout(poll, 20);
      };
      poll();
    });
  }

  close() {
    this.socket.destroy();
  }
}

function parseSearchUids(response) {
  const match = response.match(/^\* SEARCH\s*(.*)$/m);
  if (!match) {
    return [];
  }

  return match[1]
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map(Number)
    .filter((uid) => Number.isInteger(uid));
}

function uidSet(uids) {
  return uids.join(",");
}

function parseFetchedMessages(response) {
  const messages = [];
  let index = 0;

  while (index < response.length) {
    const headerMatch = response.slice(index).match(/\*\s+\d+\s+FETCH[\s\S]*?UID\s+(\d+)[\s\S]*?INTERNALDATE\s+"([^"]+)"[\s\S]*?BODY\[\]\s+\{(\d+)\}\r?\n/i);
    if (!headerMatch) {
      break;
    }

    const headerStart = index + headerMatch.index;
    const bodyStart = headerStart + headerMatch[0].length;
    const size = Number(headerMatch[3]);
    const raw = response.slice(bodyStart, bodyStart + size);
    messages.push({ uid: headerMatch[1], internalDate: headerMatch[2], raw });
    index = bodyStart + size;
  }

  return messages;
}

function normalizeMessage(message) {
  const parsed = parseMessage(message.raw);
  const receivedAt = parsed.headers.date ? new Date(parsed.headers.date).toISOString() : imapDate(message.internalDate);

  return {
    id: message.uid,
    subject: decodeHeader(parsed.headers.subject || ""),
    fromEmails: emailAddresses(parsed.headers.from),
    toEmails: emailAddresses(parsed.headers.to),
    ccEmails: emailAddresses(parsed.headers.cc),
    bccEmails: emailAddresses(parsed.headers.bcc),
    receivedAt,
    preview: parsed.body.slice(0, 200),
    text: parsed.body,
    html: ""
  };
}

function parseMessage(raw) {
  const [headerText, ...bodyParts] = raw.split(/\r?\n\r?\n/);
  return { headers: parseHeaders(headerText), body: decodeBody(headerText, bodyParts.join("\n\n")) };
}

function parseHeaders(headerText) {
  const unfolded = String(headerText || "").replace(/\r?\n[\t ]+/g, " ");
  const headers = {};

  for (const line of unfolded.split(/\r?\n/)) {
    const separator = line.indexOf(":");
    if (separator <= 0) {
      continue;
    }
    headers[line.slice(0, separator).toLowerCase()] = line.slice(separator + 1).trim();
  }

  return headers;
}

function decodeBody(headerText, body) {
  const headers = parseHeaders(headerText);
  const transferEncoding = String(headers["content-transfer-encoding"] || "").toLowerCase();

  if (transferEncoding === "base64") {
    return Buffer.from(body.replace(/\s+/g, ""), "base64").toString("utf8");
  }

  if (transferEncoding === "quoted-printable") {
    return decodeQuotedPrintable(body);
  }

  return body;
}

function decodeQuotedPrintable(value) {
  return String(value || "")
    .replace(/=\r?\n/g, "")
    .replace(/=([0-9A-F]{2})/gi, (_match, hex) => String.fromCharCode(parseInt(hex, 16)));
}

function decodeHeader(value) {
  return String(value || "").replace(/=\?UTF-8\?Q\?([^?]+)\?=/gi, (_match, encoded) =>
    decodeQuotedPrintable(encoded.replace(/_/g, " "))
  );
}

function emailAddresses(value) {
  return Array.from(String(value || "").matchAll(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi)).map((match) =>
    match[0].toLowerCase()
  );
}

function searchableText(email) {
  return [email.subject, email.preview, email.text, email.html, ...email.fromEmails, ...email.toEmails].join("\n");
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

function imapDate(value) {
  return new Date(String(value || "").replace(/^(\d+)-([A-Za-z]+)-(\d+)/, "$1 $2 $3")).toISOString();
}

function quoteAtom(value) {
  if (/^[A-Z0-9.]+$/i.test(String(value))) {
    return String(value);
  }

  return `"${String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

module.exports = { FastmailImapClient };
