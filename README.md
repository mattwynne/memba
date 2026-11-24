# Memba

This repository is a monorepo:

* `web/` contains the Phoenix application.
* `acceptance-tests/` contains the Node, Cucumber.js, and Playwright acceptance tests.

Product language is captured in [`docs/problem-domain-terms.md`](docs/problem-domain-terms.md).

## Development environment

Use the development helper from the repository root:

* Run `./bin/mix setup` to install and set up the Phoenix app.
* Run `./bin/dev up` to start Postgres and the Phoenix endpoint.
* Run `./bin/dev acceptance` to run the acceptance tests against `http://localhost:4000`.
* Run `./bin/dev down` to stop development services after interrupting the app.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Email delivery

Local development and automated tests use fake/test email delivery by default.
To opt an environment into real member-message email through Postmark, see
[`docs/postmark-email.md`](docs/postmark-email.md).

## Staff MCP server

Connect an internal MCP client to `https://memba.io/mcp` using Streamable HTTP
and an `Authorization: Bearer` header. The server supports MCP revisions
`2025-11-25`, `2025-06-18`, and `2025-03-26`, tool discovery,
club and membership administration, onboarding, and message delivery diagnostics.
Each list response has `items` and a `next_offset` to pass as `offset` for the next page.
A `null` offset marks the last page.

From the repository root, with Node.js and an authenticated `flyctl`, run:

```sh
bin/staff-mcp-token pat@memba.io
```

The command generates a token, adds its digest to the existing
`MEMBA_STAFF_MCP_CREDENTIALS` mapping, and applies the secret on Fly. Fly restarts
the app's Machines. Copy the token printed at the end into your MCP client and
save it in your password manager. The command uses the `memba` Fly app by
default. Set `MEMBA_FLY_APP` for a different app.

Run `bin/staff-mcp-token --rotate pat@memba.io` to replace an existing token.
Run one credential update per app at a time. The command connects to a running
Machine to read an existing mapping and checks Fly's secret metadata again
before writing.

Staff request notifications include the ID to pass to
`get_onboarding_request`. Approval and rejection record the credential owner's
email address.
