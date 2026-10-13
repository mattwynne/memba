# Problem: Fabro dev image CI does not refresh the Fabro host

Date: 2026-06-03

## Context

We fixed a Fabro sandbox zombie-process problem by changing the Memba Fabro dev image configuration in `devenv.nix` to use `tini` as PID 1. Pushing the change triggered `.github/workflows/fabro-dev-image.yml`, which successfully built and pushed `ghcr.io/mattwynne/memba-fabro-dev:latest` in GitHub Actions run `26871553635`.

After the CI build completed, we still had to SSH into the Fabro LXC and manually refresh the image:

```sh
docker pull ghcr.io/mattwynne/memba-fabro-dev:latest
```

We then verified the pulled image on the Fabro host:

```text
Entrypoint=["/bin/tini","-g","--"]
Cmd=["/bin/bash","-lc","sleep infinity"]
```

Matt also clarified that when he is available to approve the SSH host key, direct access works with:

```sh
ssh root@192.168.1.201
ssh root@fabro.home.wynne.family
```

## Expected standard

When a pushed `devenv.nix` change causes `.github/workflows/fabro-dev-image.yml` to build and push a new Fabro dev image, the production Fabro host should end up using that new image for future run containers without an operator remembering a separate manual pull step.

At minimum, the workflow should make the remaining deployment step explicit and observable.

## What happened

The GitHub Actions workflow only builds and pushes the container image to GHCR:

```yaml
- name: Build devenv container
  run: devenv container build fabro-dev

- name: Push devenv container to GHCR
  run: devenv container copy fabro-dev
```

It does not connect to the Fabro host, pull the new image into the host Docker daemon, or verify the host-local image configuration.

Because Fabro runs Docker sandboxes from the host Docker daemon, the pushed `latest` image may not affect future runs until the host pulls it. Previous notes also flagged image-cache ambiguity around the mutable `latest` tag.

## Impact

- Image fixes can appear complete in CI while the Fabro server continues using an older cached image.
- Operators must remember a second deployment step after a green CI run.
- A missed host refresh can make later Fabro runs reproduce already-fixed sandbox failures.
- Diagnosis is confusing because `ghcr.io/mattwynne/memba-fabro-dev:latest` can mean different image IDs depending on whether we inspect GHCR or the Fabro host's local Docker cache.

## What allowed it to happen

The workflow boundary stops at publishing the image. There is no automated handoff from image publication to the Fabro host's local Docker daemon, no post-push verification on the actual host that will launch sandboxes, and no immutable image digest pinned into the Fabro workflow config.

The use of a mutable `latest` tag makes the missing host refresh easy to miss: the workflow config and the host image reference look correct even when the host still has an old local image.

## Observations

- `.github/workflows/fabro-dev-image.yml` has `packages: write` permission and successfully pushes to GHCR.
- The production Fabro host is reachable over SSH when Matt can approve the host key.
- The manual host update succeeded with `docker pull ghcr.io/mattwynne/memba-fabro-dev:latest`.
- The direct host verification step is important because the relevant correctness property was the image entrypoint used by Docker, not just that CI completed.
- Existing run containers are unaffected by pulling a new image; the refresh only protects future run containers.

## Why this matters

The Fabro dev image is delivery infrastructure. When image deployment is split between CI and an undocumented or easy-to-forget manual host pull, fixes to sandbox reliability can be silently absent from the actual delivery environment. That creates repeated incidents and wastes debugging time on problems that were already fixed in source.

## Open questions

- Does Fabro's Docker sandbox ever force-pull images, or does it always allow Docker to reuse the local cached tag?
- Should the workflow update the Fabro host over Tailscale SSH after each successful image push?
- Should Memba use immutable image tags or digests in workflow configs instead of `latest`?
- What SSH/Tailscale identity and ACL should GitHub Actions use to reach only the Fabro host safely?
- Should the post-push host refresh also stop or warn about active containers that still use an old image?

## Possible prevention ideas

- Add a post-push CI step that joins Tailscale, SSHes to `fabro.home.wynne.family`, runs `docker pull`, and verifies the image entrypoint/tools on the host.
- Pin Fabro workflow image references to a unique tag or digest produced by CI, so image-cache drift is visible.
- Add a host-side verification command to `docs/reference/fabro-devenv.md` that compares the expected image digest/entrypoint with the local Docker daemon.
- Make the CI job output the image digest and the Fabro host's pulled digest when deployment succeeds.

## Resolution

Date: 2026-10-13

Root cause: publishing a replacement `latest` did not change Fabro's cached host-local tag. The image publication and workflow selection were separate, and the unchanged reference hid which build a new run would use. Matt selected never-reused version tags for Memba's own image/workflows, not a Fabro fork or host-maintenance service.

Countermeasure:

- `.github/workflows/fabro-dev-image.yml` and `.github/scripts/fabro-dev-image.sh` publish `sha-<full-SHA>-run-<run-ID>-<attempt>`. Reruns create new tags; build/copy use identical overrides; the pipeline does not promote `latest`. Failed/cancelled runs cannot supply a selected version: publication selection requires the complete CI run to succeed, including registry provenance and bare `cmp` smoke checks.
- `.fabro/fabro-dev-image.json` retains the selected successful publication receipt. All six Memba-owned workflow Docker references use its version tag. Offline helper/pin checks prevent build/copy override divergence and stale workflow references. Normal network settings and existing containers are unchanged.
- `docs/reference/fabro-devenv.md` documents the two-stage publish-then-pin process. Application HEAD is not an image selector; the successfully published receipt is.

Observed validation and rollout:

- Source `577b5c4a52d775c44c5474e999ab146cb528813d` passed ordinary remote `./bin/dev check` on `https://fabro.home.wynne.family`, run `01M4STMJV7B7ZJ5CT5V33BNXX3`: 19 package tests, 1,807 app tests, seven journeys/113 steps; responsive checks correctly skipped for config-only changes. HEAD/tree/index were byte-identical and tracked state clean. Remote real devenv 2.1.0 evaluation also confirmed all four typed version/source/build overrides.
- Image CI [38351057278, attempt 1](https://github.com/mattwynne/memba/actions/runs/38351057278) completed successfully, publishing `ghcr.io/mattwynne/memba-fabro-dev:sha-577b5c4a52d775c44c5474e999ab146cb528813d-run-38351057278-1`. Its verified **registry** digest is `sha256:94223bd78e4d595aea668ba1d2639bfc394f644e2a36da6c5ae7c0f28a767384`; receipt source/run/attempt and registry image environment matched.
- New standalone actual-host Fabro Docker run `01M4SVSN296KHA8AMNT76SWR0F` created container `9d7df6ca715a005cb9eb5c606a4ea2758e94c46a382f06261f1f8b82f9b7c371` using that tag. Before any devenv shell, its baked version/source/build matched the successful receipt, `/bin/cmp` was GNU diffutils 3.12, equal fixtures returned 0 and different fixtures returned exactly 1. Bare Git/Nix/Python and CA readability passed too. This is fresh-container proof of the selected version, not evidence from a resumed run or unchanged service health.
- The supported sandbox API exposed the requested image tag, exact container ID, ownership labels and running state. It did **not** expose a host-local image digest; the registry digest above is not claimed as a separately observed host digest.

The final workflow-pin publication is gated on an ordinary exact-candidate remote `dev check`; it does not inherit the earlier source check. Raw CI logs, publication/registry receipts, live proof, exact check records and task-owned cleanup are retained outside the managed worktree at `/home/matt/.local/state/memba/immutable-fabro-images/thr_y5cbde2k3z/`. The prediction is demonstrated for a new run: the selected version contains the previously missing tool without refreshing cached `latest`. Future image changes still require selecting a successful receipt and publishing a new pin. Existing running/resumed containers remain untouched; no claim is made about complete workflow reliability or 068 acceptance.
