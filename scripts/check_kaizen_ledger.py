#!/usr/bin/env python3
"""Verify that the kaizen ledger links every top-level note exactly once."""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
KAIZEN = ROOT / "docs" / "kaizen"
LEDGER = KAIZEN / "README.md"
LINK = re.compile(r"\[[^]]+\]\(([^)]+\.md)\)")


def main() -> int:
    actual = {path.name for path in KAIZEN.glob("*.md") if path.name != LEDGER.name}
    linked_targets = LINK.findall(LEDGER.read_text())
    linked_names = [Path(target).name for target in linked_targets]
    counts = Counter(linked_names)

    errors: list[str] = []
    for target in linked_targets:
        if Path(target).is_absolute() or Path(target).parent != Path("."):
            errors.append(f"ledger link must be a direct relative filename: {target}")
        elif not (KAIZEN / target).is_file():
            errors.append(f"ledger link target does not exist: {target}")

    missing = sorted(actual - counts.keys())
    unexpected = sorted(counts.keys() - actual)
    duplicates = sorted(name for name, count in counts.items() if count != 1)
    if missing:
        errors.append("notes missing from ledger: " + ", ".join(missing))
    if unexpected:
        errors.append("ledger links without top-level notes: " + ", ".join(unexpected))
    if duplicates:
        errors.append("notes not linked exactly once: " + ", ".join(duplicates))

    if errors:
        print("Kaizen ledger check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Kaizen ledger check passed: {len(actual)} notes linked exactly once")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
