"""Acceptance tests use real subprocesses, Git remotes and a fake deploy target."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("delivery_controller", HERE / "controller.py")
controller = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(controller)


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="delivery-acceptance-")
        self.root = Path(self.temp.name) / "job"
        controller.create_job(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def state(self):
        return json.loads((self.root / "state.json").read_text())

    def run_job(self):
        return subprocess.run([sys.executable, str(HERE / "controller.py"), "run", str(self.root)],
                              capture_output=True, text=True, timeout=30)

    def mode(self, phase, mode):
        # Fixture controls are test-owned, outside the candidate and immutable contract.
        (self.root / f"fixture-{phase}").write_text(mode)

    def tip(self):
        return controller.git(self.root / "remote.git", "rev-parse", "refs/heads/main")

    def assert_delivered(self):
        state = self.state()
        self.assertEqual(state["status"], "delivered", state)
        self.assertEqual(self.tip(), state["candidate"])
        for phase in ("review", "check", "package", "publish", "deploy", "verify"):
            self.assertEqual(state["receipts"][phase]["candidate"], state["candidate"])
        with sqlite3.connect(self.root / "deployment.sqlite") as db:
            self.assertEqual(db.execute("select count(*) from releases").fetchone()[0], 1)
        return state

    def test_happy_path_and_duplicate_dispatch_do_not_repeat_work(self):
        self.assertEqual(self.run_job().returncode, 0)
        first = self.assert_delivered()
        self.assertEqual(self.run_job().returncode, 0)
        self.assertEqual(first, self.state())

    def test_actual_controller_death_after_each_effect_recovers(self):
        # Each subcase creates a fresh remote, not an already-delivered shortcut.
        for phase in controller.PHASES:
            with self.subTest(phase=phase):
                with tempfile.TemporaryDirectory(prefix="delivery-kill-") as directory:
                    root = Path(directory) / "job"
                    controller.create_job(root)
                    (root / "crash-after").write_text(phase)
                    result = subprocess.run([sys.executable, str(HERE / "controller.py"), "run", str(root)],
                                            capture_output=True, text=True, timeout=30)
                    state = json.loads((root / "state.json").read_text())
                    self.assertEqual(result.returncode, 0, (result.stderr, state))
                    self.assertEqual(state["status"], "delivered")
                    self.assertEqual(state["restarts"], 1)
                    with sqlite3.connect(root / "deployment.sqlite") as db:
                        self.assertEqual(db.execute("select count(*) from releases").fetchone()[0], 1)

    def test_worker_death_preserves_partial_work_without_accepting_it(self):
        self.mode("work", "die-after-edit-once")
        self.assertEqual(self.run_job().returncode, 0)
        state = self.assert_delivered()
        self.assertEqual(state["attempts"]["work"], 2)
        self.assertTrue((self.root / "saw-preserved-work").exists())
        self.assertGreaterEqual(len(state["checkpoints"]), 2)

    def test_crash_left_git_lock_is_preserved_and_recovered_after_fencing(self):
        self.mode("work", "die-with-git-lock-once")
        self.assertEqual(self.run_job().returncode, 0)
        self.assert_delivered()
        self.assertTrue((self.root / "saw-preserved-work").exists())
        backups = list((self.root / "orphaned-git-locks").glob("*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "unfinished index update")

    def test_lost_git_response_after_successful_publication_is_reconciled(self):
        original_git = controller.git
        interrupted = False

        def lose_response(repo, *args):
            nonlocal interrupted
            result = original_git(repo, *args)
            if args[:2] == ("update-ref", "refs/heads/main") and not interrupted:
                interrupted = True
                raise subprocess.TimeoutExpired("git update-ref", 15)
            return result

        with patch.object(controller, "git", side_effect=lose_response):
            self.assertEqual(controller.run_controller(self.root), 0)
        self.assertTrue(interrupted)
        self.assert_delivered()
        self.assertTrue(self.state()["receipts"]["publish"]["reconciled"])

    def test_completion_after_deadline_is_not_counted_as_delivered(self):
        original_invoke = controller.invoke
        now = [time.time()]
        deadline = controller.load(self.root / "contract.json")["deadline"]

        def finish_late(root, state, contract, phase):
            result = original_invoke(root, state, contract, phase)
            if phase == "verify":
                now[0] = deadline + 1
            return result

        with patch.object(controller, "invoke", side_effect=finish_late), patch.object(controller.time, "time", side_effect=lambda: now[0]):
            self.assertEqual(controller.run_controller(self.root), 2)
        self.assertIn("deadline", self.state()["reason"])

    def test_supervisor_deadline_fences_a_stopped_controller(self):
        contract = controller.load(self.root / "contract.json")
        contract["deadline"] = time.time() + 2
        controller.save(self.root / "contract.json", contract)
        state = self.state()
        state["contract_sha256"] = controller.digest(self.root / "contract.json")
        controller.save(self.root / "state.json", state)
        self.mode("work", "hang-once")
        with (self.root / "supervisor.log").open("w") as log:
            proc = subprocess.Popen([sys.executable, str(HERE / "controller.py"), "run", str(self.root)], stdout=log, stderr=log)
            try:
                until = time.monotonic() + 5
                while not (self.root / "fixture-work-consumed").exists():
                    self.assertLess(time.monotonic(), until)
                    time.sleep(0.01)
                os.kill(int((self.root / "controller.pid").read_text()), signal.SIGSTOP)
                self.assertEqual(proc.wait(timeout=10), 2)
                self.assertIn("deadline", self.state()["reason"])
                self.assertFalse((self.root / "runtime.json").exists())
                self.assertEqual(self.tip(), self.state()["base"])
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.wait(timeout=5)
                controller.fence(self.root)

    def test_reviewer_repair_returns_to_builder_without_human_gate(self):
        self.mode("review", "repair-once")
        self.assertEqual(self.run_job().returncode, 0)
        state = self.assert_delivered()
        self.assertEqual(state["attempts"]["work"], 2)
        self.assertEqual(state["attempts"]["review"], 2)
        self.assertEqual(state["attempts"]["check"], 1)

    def test_negative_review_cannot_publish(self):
        self.mode("review", "decision-needed")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertEqual(self.tip(), self.state()["base"])
        self.assertEqual(self.state()["status"], "blocked")
        self.assertNotIn("publish", self.state()["receipts"])

    def test_zero_selected_tests_are_not_green(self):
        self.mode("check", "zero-selected")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertEqual(self.tip(), self.state()["base"])

    def test_stale_review_is_rejected_and_redispatch_does_not_reset_budget(self):
        self.mode("review", "stale")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertEqual(self.tip(), self.state()["base"])
        prior = self.state()
        self.assertEqual(self.run_job().returncode, 2)
        self.assertEqual(prior, self.state())

    def test_reviewer_mutation_is_rejected(self):
        self.mode("review", "edit-candidate")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertIn("candidate changed", self.state()["reason"])
        self.assertEqual(self.tip(), self.state()["base"])

    def test_work_does_not_need_a_final_prose_message(self):
        self.mode("work", "no-final-message")
        self.assertEqual(self.run_job().returncode, 0)
        self.assert_delivered()

    def test_verification_of_wrong_artifact_is_not_delivery(self):
        self.mode("verify", "wrong-digest")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertNotIn("verify", self.state()["receipts"])
        self.assertIn("artifact", self.state()["reason"])

    def test_deployment_of_wrong_artifact_is_not_accepted(self):
        self.mode("deploy", "wrong-digest")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertNotIn("deploy", self.state()["receipts"])

    def test_supervisor_death_is_recovered_without_a_second_live_writer(self):
        self.mode("work", "spawn-child-and-wait-once")
        with (self.root / "supervisor.log").open("w") as log:
            proc = subprocess.Popen([sys.executable, str(HERE / "controller.py"), "run", str(self.root)],
                                    stdout=log, stderr=log)
            try:
                deadline = time.monotonic() + 10
                while not (self.root / "child-started").exists():
                    self.assertLess(time.monotonic(), deadline)
                    self.assertIsNone(proc.poll())
                    time.sleep(0.02)
                proc.kill()
                proc.wait(timeout=5)
                self.assertEqual(self.run_job().returncode, 0)
                state = self.assert_delivered()
                self.assertEqual(state["restarts"], 1)
                self.assertFalse((self.root / "orphan-survived").exists())
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.wait(timeout=5)
                controller.fence(self.root)

    def test_transient_check_failure_retries_without_reimplementation(self):
        self.mode("check", "infra-once")
        self.assertEqual(self.run_job().returncode, 0)
        state = self.assert_delivered()
        self.assertEqual(state["attempts"]["work"], 1)
        self.assertEqual(state["attempts"]["check"], 2)

    def test_check_timeout_fences_process_before_retry_without_inventing_green(self):
        self.mode("check", "hang-once")
        self.assertEqual(self.run_job().returncode, 0)
        state = self.assert_delivered()
        self.assertEqual(state["attempts"]["check"], 2)
        self.assertEqual(state["attempts"]["work"], 1)
        completions = [event for event in state["events"]
                       if event["event"] == "completed" and event["phase"] == "check"]
        self.assertEqual(len(completions), 1)
        self.assertTrue(any("timed out" in event.get("reason", "") for event in state["events"]))

    def test_failed_or_interrupted_checks_never_receive_pass_receipt(self):
        self.mode("check", "infra-always")
        self.assertEqual(self.run_job().returncode, 2)
        state = self.state()
        self.assertEqual(state["attempts"]["check"], 3)
        self.assertNotIn("check", state["receipts"])
        self.assertEqual(self.tip(), state["base"])

    def test_missing_release_input_blocks_before_publication(self):
        self.mode("package", "missing-input")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertIn("release input", self.state()["reason"])
        self.assertEqual(self.tip(), self.state()["base"])

    def test_deployment_failure_is_published_not_delivered(self):
        self.mode("deploy", "infra-always")
        self.assertEqual(self.run_job().returncode, 2)
        state = self.state()
        self.assertEqual(state["status"], "blocked")
        self.assertEqual(self.tip(), state["candidate"])
        self.assertIn("publish", state["receipts"])
        self.assertNotIn("verify", state["receipts"])
        self.assertEqual(state["attempts"]["work"], 1)

    def test_changed_main_requires_new_integration_and_check(self):
        self.mode("package", "advance-main")
        self.assertEqual(self.run_job().returncode, 2)
        self.assertIn("main moved", self.state()["reason"])
        self.assertNotEqual(self.tip(), self.state()["candidate"])

    def test_publication_checks_base_atomically_not_just_before_push(self):
        self.mode("work", "die-after-edit-once")
        self.assertEqual(self.run_job().returncode, 0)
        state = self.state()
        remote = self.root / "remote.git"
        controller.git(remote, "update-ref", "refs/heads/main", state["base"])
        # An intermediate candidate is still an ancestor: ordinary fast-forward
        # push would silently succeed despite the changed integration base.
        other = state["checkpoints"][1]
        original_git = controller.git
        injected = False

        def race(target, *args):
            nonlocal injected
            # Advance the remote after the preflight, immediately before the main write.
            writes_main = (args[0] == "push" and args[-1].endswith(":refs/heads/main")) or (
                args[:2] == ("update-ref", "refs/heads/main"))
            if writes_main and not injected:
                injected = True
                original_git(remote, "update-ref", "refs/heads/main", other, state["base"])
            return original_git(target, *args)

        with patch.object(controller, "git", side_effect=race):
            with self.assertRaises((controller.SafetyError, subprocess.CalledProcessError)):
                controller.publish(self.root, state)
        self.assertTrue(injected)
        self.assertEqual(self.tip(), other)

    def test_expired_dispatch_does_not_start_work(self):
        contract = controller.load(self.root / "contract.json")
        contract["deadline"] = time.time() - 1
        controller.save(self.root / "contract.json", contract)
        state = self.state()
        state["contract_sha256"] = controller.digest(self.root / "contract.json")
        controller.save(self.root / "state.json", state)
        self.assertEqual(self.run_job().returncode, 2)
        self.assertEqual(self.state()["attempts"], {})
        self.assertIn("deadline", self.state()["reason"])

    def test_contract_edits_fail_closed(self):
        path = self.root / "contract.json"
        contract = json.loads(path.read_text())
        contract["max_attempts"] = 1000
        path.write_text(json.dumps(contract))
        self.assertEqual(self.run_job().returncode, 2)
        self.assertIn("contract changed", self.state()["reason"])
        self.assertEqual(self.tip(), self.state()["base"])

    def test_fence_does_not_miss_child_forked_during_proc_scan(self):
        script = (
            "import os,sys,time; sys.stdin.readline(); child=os.fork(); "
            "print(os.getpid(),flush=True) if child == 0 else None; "
            "time.sleep(30) if child == 0 else os._exit(0)"
        )
        proc = subprocess.Popen([sys.executable, "-c", script], stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, text=True, start_new_session=True,
                                env={"PATH": os.defpath, "DELIVERY_JOB_TOKEN": "race-fixture"})
        controller.save(self.root / "runtime.json", {"pid": proc.pid, "token": "race-fixture"})
        original_iterdir = Path.iterdir
        injected = False
        child_fd = None

        def race(path):
            nonlocal injected, child_fd
            if path == Path("/proc") and not injected:
                injected = True
                # The directory snapshot predates the fork; its parent vanishes
                # before fence can inspect it. A single empty scan is not proof.
                entries = [path / str(proc.pid)]
                proc.stdin.write("fork\n")
                proc.stdin.flush()
                child_fd = os.pidfd_open(int(proc.stdout.readline()))
                proc.wait(timeout=5)
                return iter(entries)
            return original_iterdir(path)

        try:
            with patch.object(Path, "iterdir", race):
                self.assertTrue(controller.fence(self.root))
            with self.assertRaises(ProcessLookupError):
                signal.pidfd_send_signal(child_fd, 0)
        finally:
            if child_fd is not None:
                try:
                    signal.pidfd_send_signal(child_fd, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                os.close(child_fd)
            if proc.poll() is None:
                proc.kill()
                proc.wait(timeout=5)
            proc.stdin.close()
            proc.stdout.close()

    def test_single_supervisor_owns_job_and_fences_orphaned_worker(self):
        self.mode("work", "spawn-child-and-wait-once")
        with (self.root / "supervisor.log").open("w") as log:
            proc = subprocess.Popen([sys.executable, str(HERE / "controller.py"), "run", str(self.root)],
                                    stdout=log, stderr=log)
            try:
                deadline = time.monotonic() + 10
                while not (self.root / "child-started").exists():
                    self.assertLess(time.monotonic(), deadline, "fixture did not start")
                    self.assertIsNone(proc.poll())
                    time.sleep(0.02)
                other = self.run_job()
                self.assertEqual(other.returncode, 3, other.stderr)
                pid = int((self.root / "controller.pid").read_text())
                os.kill(pid, signal.SIGKILL)
                self.assertEqual(proc.wait(timeout=15), 0)
                self.assert_delivered()
                # The old child was fenced before the replacement could observe the source.
                self.assertFalse((self.root / "orphan-survived").exists())
            finally:
                if proc.poll() is None:
                    proc.terminate()
                    proc.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
