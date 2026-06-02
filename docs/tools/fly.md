# Fly.io production operations

Memba production runs on Fly.io, but local development agents must not deploy it directly.

## Deployment policy

- Do not run `fly deploy` from a local workstation or agent session.
- Do not use `fly deploy --skip-release-command` from local as a workaround.
- Commit the change and let CI/CD perform the production deploy.
- Local sessions may use Fly for read-only inspection and diagnostics, such as:
  - `fly status --app memba`
  - `fly releases --app memba`
  - `fly logs --app memba --no-tail`
  - `fly ssh console --app memba -C '<read-only command>'`
- Mutating Fly operations, including secrets, machines, deploys, scaling, and release commands, need explicit Matt approval and should normally be done through CI/CD or a documented runbook.

## Why

Deploying from an uncommitted local working tree can put code in production that is not reproducible from git. A later CI or local deploy from committed code may silently revert that change and make production behaviour confusing to debug.

The standard production path is:

1. Make the code/config/docs change locally.
2. Run the appropriate checks, normally `./bin/dev check` for app changes.
3. Commit the change.
4. Let CI/CD deploy from git.
5. Use Fly read-only diagnostics to verify production if needed.
