# Project guidelines

- Use `dev check` when you are done with code, config, dependency, migration, acceptance-test, or app-behaviour changes, and fix any pending issues. The default quality gate runs both Mix precommit/ExUnit and browser acceptance.
- Use `dev check --quick` only for faster local loops when you intentionally want to skip browser acceptance; run full `dev check` before handing off app changes.
- Do not run `dev check` for docs-only, planning-only, prose-only, or kaizen-note edits unless Matt explicitly asks for it or the edit changes executable examples/scripts.
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps.
