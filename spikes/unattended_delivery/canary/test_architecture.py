"""A technical obligation, not an invented customer scenario."""
import ast
from pathlib import Path
import unittest


class IndependenceTest(unittest.TestCase):
    def test_stock_has_no_runtime_dependencies(self):
        tree = ast.parse(Path('stock.py').read_text())
        self.assertFalse(any(isinstance(node, (ast.Import, ast.ImportFrom)) for node in ast.walk(tree)))
