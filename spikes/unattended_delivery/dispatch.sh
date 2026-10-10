#!/usr/bin/env bash
# Start or observe ONE admitted job. Never changes credentials or existing jobs.
set -euo pipefail
job=$(realpath "$1")
runner="$job/controller.py"
unit="memba-candidate-$(printf '%s' "$job" | sha256sum | cut -c1-16)"
remaining=$(python3 - "$job" <<'PY'
import json, sys, time
from pathlib import Path
s = json.loads((Path(sys.argv[1]) / 'state.json').read_text())
if s['status'] != 'running':
    raise SystemExit('Job is terminal: ' + s['status'])
print(max(1, int(s['deadline'] - time.time())))
PY
)
# Precreate as the dispatching user: systemd's append target otherwise becomes
# root-owned 0600 under UMask=0077, hiding evidence from the job owner.
: >> "$job/service.log"
chmod 600 "$job/service.log"
# systemd owns the full cgroup, including escaped subprocess groups. Restart
# accounting is also persisted by the controller. Killing the controller invokes
# cgroup cleanup BEFORE Restart=on-failure launches a replacement.
sudo -n systemd-run --unit="$unit" --description="Isolated non-production candidate" \
  --uid="$(id -un)" --property="Environment=HOME=$HOME" \
  --property="Environment=PATH=$PATH" \
  --property=KillMode=control-group --property=TimeoutStopSec=5 \
  --property=Restart=on-failure --property=RestartSec=2 \
  --property="RuntimeMaxSec=$remaining" --property=MemoryMax=1G \
  --property=TasksMax=128 --property=UMask=0077 --property=LimitFSIZE=16M \
  --property=LimitCORE=0 \
  --property=StandardOutput="append:$job/service.log" \
  --property=StandardError="append:$job/service.log" \
  /usr/bin/python3 "$runner" run "$job"
printf '%s\n' "$unit.service"
