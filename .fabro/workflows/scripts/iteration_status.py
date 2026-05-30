#!/usr/bin/env python3
"""Maintain iteration lifecycle metadata for Fabro workflows."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

INDEX_PATH = Path("docs/iterations/README.md")
ACTIVE_STATUSES = {
    "implementing",
    "ready-for-review",
    "in-review",
    "reviewing",
    "finalizing",
}


@dataclass(frozen=True)
class IterationRow:
    number: str
    status: str
    title: str
    plan_path: Path
    line_index: int


def iteration_dir_from_plan(plan_path: Path) -> Path:
    if plan_path.name != "plan.md":
        raise SystemExit(f"plan_path must end with /plan.md: {plan_path}")
    return plan_path.parent


def iteration_number_from_plan(plan_path: Path) -> str:
    slug = iteration_dir_from_plan(plan_path).name
    return slug.split("-", 1)[0]


def parse_index(index_path: Path = INDEX_PATH) -> tuple[str, list[IterationRow]]:
    if not index_path.exists():
        raise SystemExit(f"Iteration index not found: {index_path}")

    text = index_path.read_text()
    rows: list[IterationRow] = []
    for i, line in enumerate(text.splitlines()):
        if not line.startswith("|") or "[plan](" not in line:
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 5 or cells[0] == "---" or cells[0] == "#":
            continue
        match = re.search(r"\[plan\]\(([^)]+)\)", cells[4])
        if not match:
            continue
        rows.append(
            IterationRow(
                number=cells[0],
                status=cells[2],
                title=cells[3],
                plan_path=Path("docs/iterations") / match.group(1),
                line_index=i,
            )
        )
    return text, rows


def active_rows(rows: list[IterationRow], exclude_number: str | None = None) -> list[IterationRow]:
    return [
        row
        for row in rows
        if row.status.strip().lower() in ACTIVE_STATUSES and row.number != exclude_number
    ]


def replace_plan_status(plan_path: Path, status: str) -> None:
    if not plan_path.exists():
        raise SystemExit(f"Plan not found: {plan_path}")
    text = plan_path.read_text()
    if re.search(r"^Status:\s*.*$", text, flags=re.MULTILINE):
        text = re.sub(
            r"^Status:\s*.*$",
            f"Status: {status}",
            text,
            count=1,
            flags=re.MULTILINE,
        )
    else:
        text = text.replace("\n## Goal\n", f"\nStatus: {status}\n\n## Goal\n", 1)
    plan_path.write_text(text)


def replace_index_status(plan_path: Path, status: str, index_path: Path = INDEX_PATH) -> None:
    text, rows = parse_index(index_path)
    iteration_number = iteration_number_from_plan(plan_path)
    lines = text.splitlines()
    for row in rows:
        if row.number == iteration_number:
            cells = [cell.strip() for cell in lines[row.line_index].strip().strip("|").split("|")]
            cells[2] = status
            lines[row.line_index] = "| " + " | ".join(cells) + " |"
            index_path.write_text("\n".join(lines) + ("\n" if text.endswith("\n") else ""))
            return
    raise SystemExit(f"Could not find iteration {iteration_number} row in {index_path}")


def cmd_check_clear(args: argparse.Namespace) -> int:
    plan_path = Path(args.plan_path)
    _, rows = parse_index()
    exclude = iteration_number_from_plan(plan_path) if args.allow_same_iteration else None
    active = active_rows(rows, exclude_number=exclude)
    if active:
        print("Implementation WIP limit is occupied by active iteration(s):", file=sys.stderr)
        for row in active:
            print(
                f"- {row.number} {row.title} ({row.status}) {row.plan_path}",
                file=sys.stderr,
            )
        print(
            "Plan validation may run in parallel, but starting another implementation is blocked until the active iteration is merged or otherwise resolved.",
            file=sys.stderr,
        )
        return 1
    print("Implementation WIP slot is clear.")
    return 0


def cmd_mark(args: argparse.Namespace) -> int:
    plan_path = Path(args.plan_path)
    if args.check_clear_first:
        _, rows = parse_index()
        active = active_rows(rows, exclude_number=iteration_number_from_plan(plan_path))
        if active:
            return cmd_check_clear(
                argparse.Namespace(
                    plan_path=args.plan_path,
                    allow_same_iteration=True,
                )
            )
    replace_plan_status(plan_path, args.status)
    replace_index_status(plan_path, args.status)
    print(f"Marked {plan_path} as {args.status} in plan and iteration index.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(required=True)

    check = sub.add_parser("check-clear", help="fail if another iteration occupies the implementation WIP slot")
    check.add_argument("plan_path")
    check.add_argument("--allow-same-iteration", action="store_true")
    check.set_defaults(func=cmd_check_clear)

    mark = sub.add_parser("mark", help="mark an iteration plan and index row with a lifecycle status")
    mark.add_argument("plan_path")
    mark.add_argument("status")
    mark.add_argument("--check-clear-first", action="store_true")
    mark.set_defaults(func=cmd_mark)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
