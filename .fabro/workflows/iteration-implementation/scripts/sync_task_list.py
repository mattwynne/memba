#!/usr/bin/env python3
"""Create or preserve an iteration implementation todo list.

The approved plan is the source of scope. The todo file is execution state; once
it exists, this helper preserves it. On first creation, split substantive
Implementation Plan sub-bullets into separate one-node-sized tasks rather than
flattening a broad numbered plan item into one oversized todo.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

BROAD_UNBULLETED_CHARS = 240
MAX_TASK_CHARS = 360


@dataclass
class PlanItem:
    title: str
    bullets: list[str] = field(default_factory=list)


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def implementation_plan_lines(plan_text: str, plan_path: Path) -> list[str]:
    lines = plan_text.splitlines()
    in_section = False
    section: list[str] = []

    for line in lines:
        if line.strip() == "## Implementation Plan":
            in_section = True
            continue

        if in_section and line.startswith("## "):
            break

        if in_section:
            section.append(line)

    if not in_section:
        raise SystemExit(f"No ## Implementation Plan section found in {plan_path}")

    return section


def parse_plan_items(lines: list[str], plan_path: Path) -> list[PlanItem]:
    items: list[PlanItem] = []
    current: PlanItem | None = None
    current_bullet_index: int | None = None

    numbered = re.compile(r"^([0-9]+)\.\s+(.*)$")
    bullet = re.compile(r"^\s+-\s+(.*)$")

    for raw_line in lines:
        line = raw_line.rstrip()
        if not line.strip():
            continue

        numbered_match = numbered.match(line)
        if numbered_match:
            current = PlanItem(title=normalize(numbered_match.group(2)))
            items.append(current)
            current_bullet_index = None
            continue

        bullet_match = bullet.match(line)
        if bullet_match and current is not None:
            current.bullets.append(normalize(bullet_match.group(1)))
            current_bullet_index = len(current.bullets) - 1
            continue

        # Continuation line for a wrapped bullet or wrapped numbered item.
        if current is not None and raw_line.startswith((" ", "\t")):
            continuation = normalize(line)
            if not continuation:
                continue
            if current_bullet_index is not None:
                current.bullets[current_bullet_index] = normalize(
                    f"{current.bullets[current_bullet_index]} {continuation}"
                )
            else:
                current.title = normalize(f"{current.title} {continuation}")
            continue

        # Ignore explanatory prose inside the section rather than inventing a task.

    if not items:
        raise SystemExit(f"No numbered tasks found under ## Implementation Plan in {plan_path}")

    return items


def split_broad_unbulleted_title(title: str) -> list[str]:
    """Split an overlong unbulleted plan item on sentence boundaries when safe."""
    title = normalize(title)
    if len(title) <= BROAD_UNBULLETED_CHARS:
        return [title]

    # Prefer explicit sentence boundaries in prose-style plan items. Keep the
    # punctuation with each sentence so task text remains readable.
    sentences = [normalize(part) for part in re.split(r"(?<=[.!?])\s+", title) if part.strip()]
    if len(sentences) > 1 and all(len(sentence) <= MAX_TASK_CHARS for sentence in sentences):
        return sentences

    return [title]


def task_texts(items: list[PlanItem]) -> list[str]:
    tasks: list[str] = []

    for item in items:
        title = normalize(item.title)
        title_prefix = title.rstrip(":")

        if item.bullets:
            for bullet in item.bullets:
                bullet_text = normalize(bullet)
                if title_prefix:
                    tasks.append(normalize(f"{title_prefix}: {bullet_text}"))
                else:
                    tasks.append(bullet_text)
        else:
            tasks.extend(split_broad_unbulleted_title(title))

    return tasks


def is_implementation_task(task: str) -> bool:
    """Return false for prerequisite checks and negative scope constraints."""
    non_implementation_patterns = (
        r"^no changes? to\b",
        r"^do not\b",
        r"^verify\b.*\bbefore (?:starting|implementing)\b",
    )
    return not any(re.search(pattern, task, re.IGNORECASE) for pattern in non_implementation_patterns)


def implementation_tasks_only(tasks: list[str]) -> list[str]:
    """Drop explicit non-implementation constraints from the execution todo list."""
    return [task for task in tasks if is_implementation_task(task)]


def validate_granularity(tasks: list[str]) -> None:
    problems: list[str] = []

    for index, task in enumerate(tasks, start=1):
        if task.endswith(":"):
            problems.append(
                f"task {index:03d} ends with ':' and appears to hide child work: {task}"
            )
        if len(task) > MAX_TASK_CHARS:
            problems.append(
                f"task {index:03d} is {len(task)} chars; split it into smaller plan sub-bullets: {task}"
            )

    if problems:
        message = [
            "Generated todo list is too coarse for one-task-at-a-time implementation.",
            "Split the Implementation Plan into smaller sub-bullets or refine the plan before delivery.",
            "Problems:",
        ]
        message.extend(f"- {problem}" for problem in problems)
        raise SystemExit("\n".join(message))


def render_todo(tasks: list[str]) -> str:
    lines = ["# Implementation TODO", ""]
    for index, task in enumerate(tasks, start=1):
        lines.append(f"- [ ] {index:03d} {task}")
    return "\n".join(lines) + "\n"


def sync_task_list(plan_path: Path, todo_path: Path) -> None:
    if todo_path.exists():
        print(f"Using existing {todo_path}; preserving existing check-offs, splits, and ordering.")
        return

    plan_text = plan_path.read_text()
    section = implementation_plan_lines(plan_text, plan_path)
    items = parse_plan_items(section, plan_path)
    tasks = implementation_tasks_only(task_texts(items))
    validate_granularity(tasks)

    todo_path.parent.mkdir(parents=True, exist_ok=True)
    todo_path.write_text(render_todo(tasks))
    print(f"Created {todo_path} from {plan_path}")


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Usage: sync_task_list.py PLAN_PATH TODO_PATH", file=sys.stderr)
        return 2

    plan_path = Path(argv[1])
    todo_path = Path(argv[2])

    if not plan_path.is_file():
        print(f"Plan not found: {plan_path}", file=sys.stderr)
        return 1

    sync_task_list(plan_path, todo_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
