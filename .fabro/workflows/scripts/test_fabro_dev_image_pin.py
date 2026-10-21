#!/usr/bin/env python3
"""Offline pin consistency check; CI success/registry/live proof are separate gates."""
import json
import re
import tomllib
from pathlib import Path

root = Path(__file__).resolve().parents[3]
receipt = json.loads((root / ".fabro/fabro-dev-image.json").read_text())
assert re.fullmatch(r"[0-9a-f]{40}", receipt["source"])
for key in ("run_id", "run_attempt"):
    assert re.fullmatch(r"[1-9][0-9]*", receipt[key])
assert receipt["version"] == (
    f"sha-{receipt['source']}-run-{receipt['run_id']}-{receipt['run_attempt']}"
)
assert receipt["reference"] == "ghcr.io/mattwynne/memba-fabro-dev:" + receipt["version"]
assert re.fullmatch(r"sha256:[0-9a-f]{64}", receipt["digest"])
workflow_root = root / ".fabro/workflows"
configs = sorted(workflow_root.glob("*/workflow.toml"))
configs.append(workflow_root / "bdd-plan-implementation/scenario/workflow.toml")
checked = []
for path in configs:
    config = tomllib.loads(path.read_text())
    for environment in config.get("environments", {}).values():
        image = environment.get("image", {}).get("docker", "")
        if image.startswith("ghcr.io/mattwynne/memba-fabro-dev"):
            assert image == receipt["reference"], f"Stale/unpublished image pin: {path}"
            checked.append(path.parent.name)
assert "iteration-implementation" in checked and "plan-validation" in checked
print(f"Fabro published image pin contracts: OK ({len(checked)} workflow references)")
