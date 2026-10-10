import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from candidate import Blocked, digest
from memba_runtime import CACHES, argv, run, tracked_hashes


class MembaSelectionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        acceptance = self.root / 'acceptance-tests'
        (acceptance / 'features').mkdir(parents=True)
        dependencies = Path(__file__).resolve().parents[2] / 'acceptance-tests/node_modules'
        if not dependencies.exists() or not shutil.which('node'):
            self.skipTest('Run bin/dev setup first; real Gherkin parser required')
        (acceptance / 'node_modules').symlink_to(dependencies)
        self.feature = acceptance / 'features/example.feature'

    def select(self, selectors, source):
        self.feature.write_text(source)
        return subprocess.run(['node', str(Path(__file__).with_name('select_examples.cjs')),
                               str(self.root), json.dumps(selectors)], capture_output=True, text=True)

    def test_inherited_browser_tag_and_source_fingerprint(self):
        text = '@journey\nFeature: browsing\n  Scenario: follow link\n    Given a link\n'
        result = self.select([{'uri': 'features/example.feature', 'name': 'follow link'}], text)
        self.assertEqual(result.returncode, 0, result.stderr)
        selected = json.loads(result.stdout)[0]
        self.assertEqual(selected['kind'], 'browser')
        self.assertEqual(selected['id'], 'features/example.feature:3')
        self.assertEqual(selected['file_sha256'], hashlib.sha256(text.encode()).hexdigest())

    def test_rule_inherited_todo_is_not_admitted(self):
        text = 'Feature: future\n  @todo\n  Rule: next\n    Scenario: later\n      Given a thing\n'
        result = self.select([{'uri': 'features/example.feature', 'name': 'later'}], text)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Future @todo', result.stderr)

    def test_zero_or_duplicate_selections_are_not_green(self):
        text = 'Feature: example\n  Scenario: one\n    Given a thing\n'
        self.assertNotEqual(self.select([{'uri': 'features/example.feature', 'name': 'absent'}], text).returncode, 0)
        selected = {'uri': 'features/example.feature', 'name': 'one'}
        self.assertNotEqual(self.select([selected, selected], text).returncode, 0)

    def test_outline_expansion_requires_exactly_one_row(self):
        text = ('@journey\nFeature: rows\n  Scenario Outline: visit\n    Given <item>\n'
                '    Examples:\n      | item |\n      | a |\n      | b |\n')
        ambiguous = self.select([{'uri': 'features/example.feature', 'name': 'visit'}], text)
        self.assertNotEqual(ambiguous.returncode, 0)
        exact = self.select([{'uri': 'features/example.feature', 'name': 'visit', 'line': 7}], text)
        self.assertEqual(exact.returncode, 0, exact.stderr)
        self.assertEqual(json.loads(exact.stdout)[0]['id'], 'features/example.feature:7')

    def test_changed_prepared_dependency_is_blocked_before_execution(self):
        source = self.root / 'source'
        for name in CACHES:
            (source / name).mkdir(parents=True)
        dependency = source / CACHES[0] / 'dependency.ex'
        dependency.write_text('approved')
        fingerprint = digest({name: tracked_hashes(source / name,
            [str(p.relative_to(source / name)) for p in (source / name).rglob('*') if p.is_file()])
            for name in CACHES})
        (self.root / 'runtime.json').write_text(json.dumps({'cache_digest': fingerprint}))
        dependency.write_text('changed after approval')
        with self.assertRaisesRegex(Blocked, 'dependency caches changed'):
            run(self.root, 'must-not-execute', 'exit 99')

    def test_namespace_does_not_mount_host_secrets_or_network(self):
        root = self.root
        (root / 'runtime.json').write_text(json.dumps({'bwrap': '/bwrap', 'env': {}}))
        work, home = root / 'work', root / 'home'
        work.mkdir()
        home.mkdir()
        args = argv(root, work, home, 'true')
        self.assertIn('--unshare-all', args)
        self.assertEqual(args[args.index(str(work)) - 1], '--ro-bind')
        self.assertNotIn('/run', args)
        self.assertNotIn(str(Path.home()), args)
        self.assertNotIn('--share-net', args)
        self.assertIn('--encoding=UTF8', args[-1])


if __name__ == '__main__':
    unittest.main()
