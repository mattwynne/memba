"""Scripted actors and idempotent fake deployment endpoint; no real models or services."""
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import shlex
import subprocess
import sys
import time

phase, directory = sys.argv[1:]
root = Path(directory)
repo = root / "candidate"
candidate = os.environ["DELIVERY_CANDIDATE"]
operation = os.environ["DELIVERY_OPERATION"]
mode_file = root / f"fixture-{phase}"
mode = mode_file.read_text().strip() if mode_file.exists() else "normal"
once = root / f"fixture-{phase}-consumed"
first = not once.exists()
once.touch()

if mode == "hang-once" and first:
    time.sleep(30)

if mode == "infra-always" or (mode == "infra-once" and first):
    print("fixture infrastructure unavailable", file=sys.stderr)
    raise SystemExit(75)

if phase == "work":
    if (repo / "partial.txt").exists():
        (root / "saw-preserved-work").touch()
    if mode in ("die-after-edit-once", "die-with-git-lock-once") and first:
        (repo / "partial.txt").write_text("valuable unaccepted work\n")
        if mode == "die-with-git-lock-once":
            (repo / ".git" / "index.lock").write_text("unfinished index update")
        os.kill(os.getpid(), 9)
    if mode == "spawn-child-and-wait-once" and first:
        child = subprocess.Popen([sys.executable, "-c",
            "import pathlib,time; p=pathlib.Path(__import__('sys').argv[1]); "
            "(p/'child-started').touch(); time.sleep(2); (p/'orphan-survived').touch(); time.sleep(30)",
            str(root)])
        child.wait()
    if mode == "git-child-once" and first:
        helper = root / "git_filter.py"
        helper.write_text(
            "import pathlib,sys,time\n"
            f"marker=pathlib.Path({str(root / 'git-child-started')!r})\n"
            "if not marker.exists():\n    marker.touch()\n    time.sleep(30)\n"
            "sys.stdout.write(sys.stdin.read())\n"
        )
        (repo / ".gitattributes").write_text("value.txt filter=pause\n")
        subprocess.run(["git", "-C", str(repo), "config", "filter.pause.clean",
                        shlex.join([sys.executable, str(helper)])], check=True)
    (repo / "value.txt").write_text("new\n")
    state = json.loads((root / "state.json").read_text())
    if any(event["event"] == "repair" for event in state["events"]):
        (repo / "proof.txt").write_text("repair closes requested proof gap\n")
    if mode != "no-final-message":
        print(json.dumps({"saved": True}))
elif phase == "review":
    decision = "accept"
    if mode == "repair-once" and first:
        decision = "repair"
    if mode == "decision-needed":
        decision = "decision_needed"
    if mode == "edit-candidate":
        (repo / "value.txt").write_text("reviewer changed the candidate\n")
    print(json.dumps({"candidate": "stale-sha" if mode == "stale" else candidate,
                      "decision": decision, "reason": "fixture decision"}))
elif phase == "check":
    assert (repo / "value.txt").read_text() == "new\n", "product value still wrong"
    print(json.dumps({"candidate": candidate, "selected": 0 if mode == "zero-selected" else 1}))
elif phase == "package":
    if mode == "missing-input":
        print("missing release input", file=sys.stderr)
        raise SystemExit(20)
    data = (repo / "value.txt").read_bytes()
    # Fake release payload; deliberately NOT Memba's production image.
    (root / "artifact.bin").write_bytes(data)
    if mode == "advance-main":
        tree = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD^{tree}"], text=True).strip()
        base = json.loads((root / "contract.json").read_text())["base"]
        other = subprocess.check_output(["git", "-C", str(repo), "commit-tree", tree, "-p", base, "-m", "Concurrent writer"], text=True).strip()
        subprocess.run(["git", "-C", str(repo), "push", "origin", f"{other}:refs/heads/main"], check=True, capture_output=True)
    print(json.dumps({"candidate": candidate, "artifact_sha256": hashlib.sha256(data).hexdigest()}))
elif phase in ("deploy", "verify"):
    artifact = (root / "artifact.bin").read_bytes()
    assert artifact == b"new\n", "release cannot start with incorrect content"
    with sqlite3.connect(root / "deployment.sqlite") as db:
        db.execute("create table if not exists releases (operation text primary key, candidate text, artifact text)")
        artifact_hash = hashlib.sha256(artifact).hexdigest()
        if phase == "deploy":
            db.execute("insert or ignore into releases values (?, ?, ?)", (operation, candidate, artifact_hash))
        release = db.execute("select candidate, artifact from releases where operation = ?", (operation,)).fetchone()
        assert release == (candidate, artifact_hash), "deployment identity is not verified"
    print(json.dumps({"candidate": candidate, "artifact_sha256": "wrong-digest" if mode == "wrong-digest" else artifact_hash}))
else:
    raise SystemExit(f"Unknown fixture phase {phase}")
