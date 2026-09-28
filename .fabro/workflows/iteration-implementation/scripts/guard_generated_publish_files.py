#!/usr/bin/env python3
"""Reject generated Python bytecode in an implementation publish candidate."""

import subprocess
import sys


def changed_paths(base_sha):
    commands = [
        ["git", "diff", "--name-only", "-z", f"{base_sha}..HEAD"],
        ["git", "diff", "--name-only", "-z"],
        ["git", "diff", "--cached", "--name-only", "-z"],
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
    ]
    paths = set()
    for command in commands:
        output = subprocess.check_output(command)
        paths.update(path.decode("utf-8", "surrogateescape") for path in output.split(b"\0") if path)
    return paths


def main():
    if len(sys.argv) != 2:
        sys.exit("Usage: guard_generated_publish_files.py <implementation-base-sha>")

    unwanted = sorted(
        path
        for path in changed_paths(sys.argv[1])
        if "__pycache__" in path.split("/") or path.endswith(".pyc")
    )
    if unwanted:
        print("Refusing to publish generated Python bytecode:", file=sys.stderr)
        for path in unwanted:
            print(f"- {path}", file=sys.stderr)
        print(
            "Remove generated files from the candidate, including tracked checkpoint files, "
            "before repeating final validation.",
            file=sys.stderr,
        )
        return 1

    print("Publish candidate contains no generated Python bytecode.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
