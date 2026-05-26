# Memba

This repository is a monorepo:

* `web/` contains the Phoenix application.
* `acceptance-tests/` contains the Node, Cucumber.js, and Playwright acceptance tests.

## Development environment

Use devenv from the repository root:

* Run `devenv shell mix setup` to install and set up the Phoenix app.
* Run `devenv shell mix phx.server` to start the Phoenix endpoint.
* Run `devenv shell acceptance-test` to run the acceptance tests against `http://localhost:4000`.

You can also work directly inside each folder:

* `cd web && mix phx.server`
* `cd acceptance-tests && npm test`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
