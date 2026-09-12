# Manual browser validation

Date: 2026-09-12

The connection states were exercised in Chromium against a locally running
Phoenix test server and compared with `reconnect-indicator-prototype.html`.
Checks ran at desktop (`1280 × 800`) and narrow mobile (`360 × 640`) viewport
sizes. The mobile run also emulated `prefers-reduced-motion: reduce`.

## Simulations

- A client transport interruption recovered after 675 ms. A mutation observer
  recorded no visible client or server status before or after recovery.
- A prolonged client transport interruption displayed only
  `Connection paused — reconnecting…`. Restoring the transport automatically
  hid the status.
- A server error was simulated through LiveView's channel error path while the
  socket remained connected and channel rejoin was paused. It displayed only
  `Memba is temporarily unavailable — retrying…`. Resuming channel rejoin
  automatically hid the status.

Both visible states retained the current page, did not receive focus, contained
no button, and had `pointer-events: none`. Each status was fixed, horizontally
centred, and 18 px above the viewport bottom. The mobile statuses remained
within the required 16 px side margins.

With reduced motion enabled, the spinner's computed animation was `none` and
the status transition duration was `0s`.

## Prototype comparison

The production and prototype client pills shared the exact copy, fixed
bottom-centre placement, pointer transparency, 13 px type, sage border, ink
text, paper background, fully rounded shape, and compact dimensions:

| Viewport | Production | Prototype |
| --- | --- | --- |
| Desktop | 253 × 37.6 px | 270 × 35.6 px |
| Mobile | 180 × 53.2 px | 180 × 51.2 px |

## Defect found and corrected

The first prolonged-client simulation displayed both statuses. The
`remove_attribute("hidden")` operations were acting on their source elements
rather than inheriting the preceding `show` selectors. The operations now
carry the same state-specific selectors explicitly, with component-test
coverage for the serialized commands. The full browser matrix passed after
that correction.

## Command

```console
ACCEPTANCE_LOG_PROGRESS=0 devenv shell -- node .fabro/tmp/manual_reconnect_check.cjs
```

The temporary harness started and stopped the isolated acceptance lifecycle,
built the browser assets, ran all simulations and assertions, and captured
desktop/mobile production and prototype screenshots under a temporary
directory. It exited successfully with `"result": "passed"`.
