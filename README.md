# Memba

This repository is a monorepo:

* `web/` contains the Phoenix application.
* `acceptance-tests/` contains the Node, Cucumber.js, and Playwright acceptance tests.

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
