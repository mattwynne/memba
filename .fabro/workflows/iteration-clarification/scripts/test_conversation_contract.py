#!/usr/bin/env python3
"""Guard the clarification loop against an incomplete-but-valid response ending it."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
graph = (root / "workflow.fabro").read_text()

assert '<@U0C3C6Y9ZAR>' in graph  # Slack user from the actual answered interview event.
assert 'discuss -> reflect [freeform=true]' in graph
assert 'reflect -> follow_up [condition="outcome=partially_succeeded && preferred_label=ask"]' in graph
assert 'reflect -> follow_up [condition="outcome=succeeded && preferred_label=ask"]' in graph
assert 'follow_up -> reflect [freeform=true]' in graph
assert 'reflect -> summary [condition="outcome=succeeded && preferred_label=finish"]' in graph
assert 'summary -> exit [condition="outcome=succeeded"]' in graph
assert 'reflect -> failed' in graph
print("clarification conversation contract passed")
