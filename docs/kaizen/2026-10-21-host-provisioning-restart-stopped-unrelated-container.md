# Problem: Host provisioning restarted Docker and stopped an unrelated Fabro run container

Date: 2026-10-21

## Context

The stock Fabro `0.389.0-nightly.0` server upgrade used the normal `hub.local`
provisioning playbook to update the Fabro host. The upgrade preserved Fabro run
history and did not use `fabro rm`, but one historical run container was still
running when host package and runtime configuration changes began.

## Expected standard

Before host provisioning that can restart a shared runtime, capture a full
inventory of containers and other affected services, identify anything still
running, and compare that inventory with the playbook's restart impact. If an
unrelated workload can be interrupted, obtain the normal approval or coordinate
with its owner before proceeding. A broad maintenance authorization does not
make an explicit preserve-running-resources constraint disappear.

## What happened

The first provisioning run started an APT dist-upgrade at `18:15:30Z`. It
upgraded Docker from `29.5.2` to `29.9.2` and containerd from `1.7.28` to
`2.4.2`. Systemd restarted containerd at `18:15:58Z` and stopped Docker at
`18:16:06Z`.

Docker's shutdown stopped container
`dabccf1f81869c9623520159b5204b80fc85ed1917dd91640f23bfdd9f104a7a`,
the managed container for Fabro run `01M422K1QSVNZT7QYZVEWK4GSC`. Systemd and
containerd recorded that exact scope and shim being deactivated during the
daemon shutdown. Docker records its finish time as
`2026-10-21T18:16:06.592518723Z`, exit code `143`, with `OOMKilled=false`.
Its restart policy was `no`, so it remained stopped.

The retained playbook explicitly stops Docker and containerd before configuring
runtime storage and restarts both afterward. The restart was therefore
foreseeable. It was necessary for the chosen provisioning route, but interrupting
the unrelated container without first coordinating it was avoidable.

No full pre-provisioning container and service inventory was retained. A
post-provisioning inventory shows the affected container newly exited and all
other listed historical Fabro run containers already exited, but it cannot
prove that no other unrelated host resource was affected. The container was not
subsequently restarted, executed in, or removed.

## Impact

- An unrelated historical run container was stopped despite the upgrade's
  preservation constraint.
- The missing pre-change inventory made the full blast radius impossible to
  prove afterward.
- Review time was required to reconstruct the cause from APT history, the
  system journal, Docker metadata, the playbook, and the post-change inventory.

## What allowed it to happen

- The operational preflight checked access, versions, jobs, disk, and backup
  readiness, but did not freeze a complete container and service inventory.
- The running historical container was not reconciled with the playbook's
  unconditional Docker/containerd stop and restart tasks.
- The standard provisioning route was treated as routine even though its
  host-wide daemon restart had a wider impact than the Fabro service upgrade.

## Countermeasure

For future Fabro host maintenance:

1. Save a timestamped, full pre-deploy inventory of all containers, their run
   labels, state, restart policy, and owning purpose, plus the host services the
   playbook will restart.
2. Inspect the proposed playbook/package transaction for daemon restarts and
   state the resulting impact before execution.
3. If any unrelated workload is running, pause for normal approval or coordinate
   with its owner; otherwise choose a narrower supported change path that does
   not interrupt it.
4. Save the equivalent post-deploy inventory and compare it with the pre-deploy
   snapshot before declaring maintenance complete.

These are operational controls, not permission to restart the preserved
container from this incident.

## Validation and status

The incident chronology and immediate cause have been validated from the
container metadata, APT transaction, system journal, retained playbook, and
post-deploy inventory. No preventive automation, playbook guard, or standard
pre/post inventory procedure has yet been implemented or exercised.

This note is **Open**. Close it only after the inventory and restart-impact
preflight is part of the normal maintenance procedure and has been demonstrated
on a later host change without interrupting an uncoordinated workload.

## Separate quality-run observation

The same upgrade's first managed quality attempt failed with an
EventStore/Postgres connection-pool queue timeout; an identical fresh attempt
then passed. That establishes the observed failure mechanism and the later
passing attempt, not that the first failure was a transient flake. Its underlying
cause remains uninvestigated and is separate from this host-maintenance issue.
