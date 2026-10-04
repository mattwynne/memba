Packet `task-010-0b851f0-package-build-gate-1` is `ready_for_review`. Task 010 remains unchecked for independent acceptance.

Changes:

- [bin/dev](/workspace/memba/bin/dev:455) now resolves Mix beside the active Elixir executable, fetches standalone package dependencies during setup, and runs package tests before web precommit with exact failure propagation.
- [Dockerfile](/workspace/memba/Dockerfile:23) copies package/web manifests before dependency resolution, package production sources before compilation, and the release from `/app/web`.
- [.dockerignore](/workspace/memba/.dockerignore:16) excludes generated package build, dependency, coverage, documentation, and tarball artifacts.
- [test_dev_checkout_boundary.sh](/workspace/memba/.fabro/workflows/scripts/test_dev_checkout_boundary.sh:1) proves package and web checks execute from the current checkout without leaking foreign devenv context.
- [test_dev_quality_gate_exit_status.sh](/workspace/memba/.fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh:1) proves package failures retain their status and prevent later web commands.
- [continuous-delivery.yml](/workspace/memba/.github/workflows/continuous-delivery.yml:40) caches standalone package dependencies/builds with `packages/live_query/mix.lock` in the cache key.
- [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1) records the result and evidence.

Focused validation passed:

- Standalone package: `15 tests, 0 failures`.
- Package formatting: exit `0`.
- Both shell regression harnesses: exit `0`.
- Production release: exit `0`; found `web/_build/prod/rel/memba/lib/live_query-0.1.0/ebin/live_query.app`.
- `bash -n bin/dev` and `git diff --check`: exit `0`.
- JSON result artifact validation: exit `0`.

Docker, Podman, Buildah, and nerdctl are unavailable in this sandbox, so no container image build is claimed. The local production release and Docker source-copy ordering provide the available release proof. Per packet instructions, the unscoped full `dev check` was left to the deterministic workflow node.