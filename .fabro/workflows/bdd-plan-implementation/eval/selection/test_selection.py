import importlib.util
import inspect
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('selection_eval', Path(__file__).with_name('eval.py'))
selection = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selection)


class CommitSelectionTest(unittest.TestCase):
    def test_launch_selects_the_memba_environment_catalog_entry(self):
        self.assertIn('"--environment", "memba-dev"', inspect.getsource(selection.run))

    def test_objective_choices_without_judging_explanation(self):
        case = json.loads((selection.HERE / 'case.json').read_text())
        for scenario in case['acceptable_first']:
            reply = {key: case[key] for key in ['plan', 'feature']}
            reply.update(scenario=scenario, reason='Establish the missing successful path.')
            self.assertTrue(selection.assess(json.dumps(reply), case)['passed'])
        reply['scenario'] = 'Alice cannot replace their name with whitespace'
        self.assertFalse(selection.assess(json.dumps(reply), case)['passed'])
        reply['scenario'] = case['acceptable_first'][0]
        reply['plan'] = 'another/plan.md'
        self.assertFalse(selection.assess(json.dumps(reply), case)['passed'])
        self.assertFalse(selection.assess('{"error":"No active plan"}', case)['passed'])
        self.assertFalse(selection.assess('not JSON', case)['passed'])

    def test_only_commit_is_supplied_and_sessions_are_independent(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'batch'
            case = selection.prepare(out, 20)
            config = (out / 'workflow.toml').read_text()
            self.assertIn(f'commit = "{case["commit"]}"', config)
            self.assertIn('graph = "workflow.fabro"', config)
            self.assertNotIn('plan = ', config)
            graph = (out / 'workflow.fabro').read_text()
            for i in range(1, 21):
                self.assertIn(f'thread_id="trial_{i}"', graph)
            self.assertEqual(graph.count('shape=box'), 20)
            self.assertNotIn('import=', graph)
            self.assertNotIn('script=', graph)
            prompt = (out / 'prompt.md').read_text()
            for secret in [case['plan'], case['feature'], *case['acceptable_first']]:
                self.assertNotIn(secret, prompt)
            with self.assertRaises(FileExistsError):
                selection.prepare(out, 20)

    def test_report_keeps_wrong_missing_and_failed_native_stages(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'batch'
            case = selection.prepare(out, 4)
            answer = {key: case[key] for key in ['plan', 'feature']}
            answer.update(scenario=case['acceptable_first'][0], reason='Missing rename path.')
            for i, scenario in [(1, case['acceptable_first'][0]), (2, 'wrong scenario'), (3, case['acceptable_first'][1])]:
                stage = out / f'dump/stages/00{i}-trial_{i}@1'
                stage.mkdir(parents=True)
                (stage / 'response.md').write_text(json.dumps({**answer, 'scenario': scenario}))
            events = [{'event': 'stage.completed', 'node_id': f'trial_{i}',
                       'properties': {'status': 'succeeded' if i < 3 else 'failed'}} for i in range(1, 4)]
            (out / 'events.jsonl').write_text('\n'.join(map(json.dumps, events)))
            result = selection.report(out)
            self.assertEqual((result['passed'], result['observed'], result['no_response']), (1, 3, 1))


if __name__ == '__main__':
    unittest.main()
