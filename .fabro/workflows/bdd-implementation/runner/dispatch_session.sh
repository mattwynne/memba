#!/usr/bin/env bash
set -euo pipefail
job=$(realpath "$1")
unit="memba-session-$(printf '%s' "$job" | sha256sum | cut -c1-16)"
remaining=$(python3 - "$job" <<'PY'
import json,sys,time
from pathlib import Path
s=json.loads((Path(sys.argv[1])/'state.json').read_text())
assert s['status']=='running', s['status']
print(max(1,int(s['deadline']-time.time())))
PY
)
read -r memory tasks filesize < <(python3 - "$job" <<'PY'
import json,sys
from pathlib import Path
c=json.loads((Path(sys.argv[1])/'contract.json').read_text())
m,t=c.get('memory_mb',1024),c.get('tasks_max',128)
assert isinstance(m,int) and 128 <= m <= 6144
assert isinstance(t,int) and 32 <= t <= 512
f=c.get('file_size_mb',16)
assert isinstance(f,int) and 16 <= f <= 128
print(m,t,f)
PY
)
: >> "$job/service.log"
chmod 600 "$job/service.log"
sudo -n systemd-run --unit="$unit" --uid="$(id -un)" \
  --property="Environment=HOME=$HOME" --property="Environment=PATH=$PATH" \
  --property=KillMode=control-group --property=TimeoutStopSec=5 \
  --property=Restart=on-failure --property=RestartSec=2 \
  --property="RuntimeMaxSec=$remaining" --property="MemoryMax=${memory}M" \
  --property="TasksMax=$tasks" --property=UMask=0077 --property="LimitFSIZE=${filesize}M" --property=LimitCORE=0 \
  --property="StandardOutput=append:$job/service.log" --property="StandardError=append:$job/service.log" \
  /usr/bin/python3 "$job/session_candidate.py" run "$job"
printf '%s\n' "$unit.service"
