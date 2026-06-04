const tls = require("node:tls");

async function sendEmail({ attachment, body, from, password, subject, to, user }) {
  const client = await SmtpClient.connect();

  try {
    await client.authenticate({ password, user });
    await client.command(`MAIL FROM:<${from}>`, /^250/);
    await client.command(`RCPT TO:<${to}>`, /^250/);
    await client.command("DATA", /^354/);
    await client.writeData(mimeMessage({ attachment, body, from, subject, to }));
    await client.expect(/^250/);
    await client.command("QUIT", /^221/).catch(() => {});
  } finally {
    client.close();
  }
}

class SmtpClient {
  static async connect() {
    const socket = await new Promise((resolve, reject) => {
      const socket = tls.connect({ host: "smtp.fastmail.com", port: 465, servername: "smtp.fastmail.com" }, () =>
        resolve(socket)
      );
      socket.once("error", reject);
    });
    const client = new SmtpClient(socket);
    await client.expect(/^220/);
    return client;
  }

  constructor(socket) {
    this.socket = socket;
    this.buffer = "";
    this.waiters = [];
    socket.on("data", (chunk) => this.onData(chunk));
  }

  async authenticate({ password, user }) {
    await this.command("EHLO memba-smoke-tests", /^250[ -]/m);
    await this.command(`AUTH PLAIN ${Buffer.from(`\0${user}\0${password}`).toString("base64")}`, /^235/);
  }

  onData(chunk) {
    this.buffer += chunk.toString("utf8");
    this.flushWaiters();
  }

  flushWaiters() {
    for (const waiter of [...this.waiters]) {
      const response = completeResponse(this.buffer);
      if (!response) {
        continue;
      }
      this.buffer = this.buffer.slice(response.length);
      this.waiters = this.waiters.filter((item) => item !== waiter);
      waiter.resolve(response);
    }
  }

  expect(pattern) {
    return new Promise((resolve, reject) => {
      const waiter = {
        resolve: (response) => {
          if (!pattern.test(response)) {
            reject(new Error(`Unexpected SMTP response. Expected ${pattern}, got:\n${response}`));
          } else {
            resolve(response);
          }
        }
      };
      this.waiters.push(waiter);
      this.flushWaiters();
    });
  }

  async command(line, pattern) {
    this.socket.write(`${line}\r\n`);
    return this.expect(pattern);
  }

  async writeData(message) {
    this.socket.write(`${dotStuff(message)}\r\n.\r\n`);
  }

  close() {
    this.socket.destroy();
  }
}

function completeResponse(buffer) {
  const lines = buffer.split(/\r?\n/);
  if (lines.length < 2) {
    return null;
  }

  let consumed = "";
  for (const line of lines) {
    if (line === "") {
      consumed += "\r\n";
      continue;
    }
    consumed += `${line}\r\n`;
    if (/^\d{3} /.test(line)) {
      return consumed;
    }
  }
  return null;
}

function dotStuff(message) {
  return message.replace(/^\./gm, "..");
}

function mimeMessage({ attachment, body, from, subject, to }) {
  const now = new Date().toUTCString();
  const messageId = `<${Date.now()}.${Math.random().toString(16).slice(2)}@memba-smoke-tests>`;

  if (!attachment) {
    return [
      `From: ${from}`,
      `To: ${to}`,
      `Subject: ${subject}`,
      `Date: ${now}`,
      `Message-ID: ${messageId}`,
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=utf-8",
      "Content-Transfer-Encoding: quoted-printable",
      "",
      quotedPrintable(body)
    ].join("\r\n");
  }

  const boundary = `memba-smoke-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return [
    `From: ${from}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    `Date: ${now}`,
    `Message-ID: ${messageId}`,
    "MIME-Version: 1.0",
    `Content-Type: multipart/mixed; boundary="${boundary}"`,
    "",
    `--${boundary}`,
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: quoted-printable",
    "",
    quotedPrintable(body),
    `--${boundary}`,
    `Content-Type: ${attachment.contentType || "application/octet-stream"}`,
    `Content-Disposition: attachment; filename="${attachment.filename}"`,
    "Content-Transfer-Encoding: base64",
    "",
    Buffer.from(attachment.content).toString("base64").replace(/.{1,76}/g, "$&\r\n").trim(),
    `--${boundary}--`,
    ""
  ].join("\r\n");
}

function quotedPrintable(text) {
  return String(text || "")
    .replace(/=/g, "=3D")
    .replace(/[^\S\r\n]+$/gm, (spaces) => spaces.replace(/ /g, "=20").replace(/\t/g, "=09"));
}

module.exports = { sendEmail };
