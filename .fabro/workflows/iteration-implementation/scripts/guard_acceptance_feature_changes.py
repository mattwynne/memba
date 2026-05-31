#!/usr/bin/env python3
"""Enforce explicit plan permission for acceptance .feature edits."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


SECTION_RE = re.compile(r"^##\s+Allowed acceptance feature changes\s*$", re.IGNORECASE)
HEADING_RE = re.compile(r"^##\s+")
BACKTICK_RE = re.compile(r"`([^`]+\.feature)`")
TAG_LINE_RE = re.compile(r"^\s*(?:@[\w.-]+(?:\s+@[\w.-]+)*)?\s*$")


def git_lines(*args: str) -> list[str]:
    result = subprocess.run(["git", *args], check=True, text=True, stdout=subprocess.PIPE)
    return [line for line in result.stdout.splitlines() if line]


def changed_feature_paths(base_sha: str) -> list[str]:
    paths: set[str] = set()
    commands = [
        ("diff", "--name-only", f"{base_sha}..HEAD"),
        ("diff", "--name-only"),
        ("diff", "--cached", "--name-only"),
    ]
    for command in commands:
        for path in git_lines(*command):
            if path.endswith(".feature"):
                paths.add(path)
    return sorted(paths)


def allowed_feature_changes(plan_path: Path) -> dict[str, str]:
    in_section = False
    allowed: dict[str, str] = {}
    for line in plan_path.read_text().splitlines():
        if SECTION_RE.match(line):
            in_section = True
            continue
        if in_section and HEADING_RE.match(line):
            break
        if not in_section:
            continue
        for feature_path in BACKTICK_RE.findall(line):
            allowed[feature_path] = line.lower()
    return allowed


def diff_changed_lines(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--no-ext-diff", "--unified=0", *args],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    changed: list[str] = []
    for line in result.stdout.splitlines():
        if not line.startswith(("+", "-")):
            continue
        if line.startswith(("+++", "---")):
            continue
        changed.append(line[1:])
    return changed


def assert_tag_only(path: str, base_sha: str) -> list[str]:
    lines: list[str] = []
    lines.extend(diff_changed_lines(f"{base_sha}..HEAD", "--", path))
    lines.extend(diff_changed_lines("--", path))
    lines.extend(diff_changed_lines("--cached", "--", path))
    return [line for line in lines if not TAG_LINE_RE.match(line)]


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: guard_acceptance_feature_changes.py <plan_path> <base_sha>", file=sys.stderr)
        return 2

    plan_path = Path(sys.argv[1])
    base_sha = sys.argv[2]
    changed = changed_feature_paths(base_sha)
    if not changed:
        print("No acceptance .feature changes detected.")
        return 0

    allowed = allowed_feature_changes(plan_path)
    errors: list[str] = []

    missing = [path for path in changed if path not in allowed]
    if missing:
        errors.append(
            "Acceptance .feature files changed without explicit plan permission under "
            "'## Allowed acceptance feature changes':\n"
            + "\n".join(f"- {path}" for path in missing)
        )

    for path in changed:
        permission = allowed.get(path, "")
        if "tag-only" in permission or "tag only" in permission:
            non_tag_lines = assert_tag_only(path, base_sha)
            if non_tag_lines:
                preview = "\n".join(f"  {line}" for line in non_tag_lines[:20])
                errors.append(
                    f"{path} is permitted as tag-only, but non-tag Gherkin lines changed:\n{preview}"
                )

    if errors:
        print("Refusing to publish implementation: locked acceptance feature policy failed.", file=sys.stderr)
        print("\n\n".join(errors), file=sys.stderr)
        print(
            "\nTo permit a feature edit, add a '## Allowed acceptance feature changes' "
            "section to the plan naming each .feature file and the allowed kind of change.",
            file=sys.stderr,
        )
        return 1

    print("Acceptance .feature changes are explicitly permitted by the plan:")
    for path in changed:
        print(f"- {path}: {allowed[path].strip()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
