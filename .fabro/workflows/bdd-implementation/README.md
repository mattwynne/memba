# One bounded implementation run

```sh
bin/dev fabro implement docs/iterations/068-member-name-editing/plan.md
```

This is a separate, non-production implementation path. It does not call the old
`fabro deliver`, change main, push, mark an iteration merged, or deploy.

## What happens

1. Fabro claims the checkout and admits its exact committed ready/validated plan.
   `execution.json` beside the plan declares approved editable/unit/support files
   and technical obligations. Actual Gherkin pickles are discovered by iteration
   tag; only their scenario-level `@todo` tags are removed. Unit selectors are
   generated from the approved unit files. Photos and other iterations stay future.
2. One authenticated Sol 6.1 builder reads files on demand. Genuine current unit
   feedback authorizes relevant repair; the same unit and acceptance are rerun.
   The scoped formatter operates on approved existing Elixir/HEEx files only.
3. The controller runs every exact example and independent technical obligation,
   then ordinary `bin/dev check` against the committed candidate with read-only
   Git metadata. A separate read-only Sol reviewer examines the whole contract,
   source and raw evidence. Rejections return to the same builder.
4. Fabro verifies the current receipts, raw log hashes, independent verdict and
   ordinary full gate before retaining a local `fabro-candidates/<run-key>` ref.
   Checkpoints descend from the original source; they are not orphan roots.

## Recovery and accounting

One immutable run key identifies one job, source, contract, candidate history,
original deadline and spent allowance. Preparation and monitoring are idempotent.
Systemd owns the contained worker; repeated Fabro monitor stages do not create
replacement workers. Controller restarts retain pending writes and sessions.
Typed transient provider failures receive bounded cooldowns; request/time slices
resume the same session, not a fresh allowance. An interrupted review resumes
only that reviewer and exact candidate. A journal snapshot before inference also
preserves the first request without inventing an assistant response.

New admission limits: **6 hours total, 12 model visits, 800 operations, 4 process
restarts and 6 provider recoveries**. Each visit is at most 75 minutes/160 model
requests. Checks are at most 10 minutes, ordinary full gate at most 20 minutes;
worker limits are 6 GiB/512 tasks/128 MiB per file. All failed attempts remain.
Tokens are accounted, not a cumulative execution stop. OpenAI charges are unknown;
Pi catalog estimates are not charges and there is no supported hard dollar cap.

Run-start ownership prevents overlapping implementations in one checkout.
Sandbox cleanup stops only the verified owned worker, including cancellation;
it does not delete jobs or rewrite historical candidate/accounting evidence.

## Trusted host and actual actor

The Fabro environment is **local**, which is not itself a sandbox. It executes
only these trusted command stages. Application/test code runs in the existing
private Nix/bwrap runtime with separate PostgreSQL/Phoenix/browser lifecycles,
read-only source/dependencies and no host database, sockets, credentials or
external network. Warm dependencies come from this source checkout, never an
accepted product patch. A cold checkout runs its existing setup/full-check path
before admission. Devenv discovers the public tool environment automatically.

Actual inference is `openai-codex/gpt-6.1-sol`, high thinking, through the pinned Pi
SDK, with only inspect/edit/observe and the scoped formatter; review is inspect-only.
No native tools, discovery, provider fallback or opaque automatic retries.

Fabro 0.316 requires an eligible model catalog even for command-only graphs.
The proof server registers `stateful-sol/gpt-6.1-sol` as a metadata-only routing
entry at a deliberately non-listening loopback endpoint. Native Fabro inference
therefore fails closed. This is **not** the inference adapter, substitute model,
connectivity probe, or evidence of successful model execution. The contained
worker's actual native response identities/session/usage records are authoritative.
Do not add native agent/prompt hooks to this graph. Server bootstrap secrets stay
outside Git. The proof server configuration is retained with the run evidence.

Evidence lives under `~/.local/state/memba/fabro-implementation/<run-key>/` and
`.fabro/tmp/bdd/<run-key>/report.json`. Saved, tested, independently accepted,
published and deployed are distinct states. Finishing this exemplar is one run's
proof, not a claim that future delivery or production recovery is established.
