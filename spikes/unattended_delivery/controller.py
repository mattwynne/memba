"""Non-production delivery spike. Only creates and publishes to its own local bare remote.

The supervisor owns one job and fences its controller's process group before restart.
Fixture commands are trusted test doubles, NOT a sandbox for untrusted agents.
"""
from __future__ import annotations

import argparse
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import uuid

HERE = Path(__file__).resolve().parent
PHASES = ("work", "review", "check", "package", "publish", "deploy", "verify")


def save(path: Path, value: dict) -> None:
    temporary = path.with_suffix(".new")
    with temporary.open("w") as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)
    directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(directory)
    finally:
        os.close(directory)


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(repo: Path, *args: str) -> str:
    env = {"PATH": os.defpath, "LANG": "C.UTF-8", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull}
    result = subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-C", str(repo), *args],
                            text=True, env=env, capture_output=True, check=True, timeout=15)
    return result.stdout.strip()


def create_job(root: Path) -> None:
    # Refuse reuse: there is deliberately no arbitrary source/remote input in this spike.
    root = root.resolve()
    root.mkdir(parents=True, exist_ok=False)
    remote, repo = root / "remote.git", root / "candidate"
    git(root, "init", "--bare", "--initial-branch=main", str(remote))
    git(root, "clone", str(remote), str(repo))
    git(repo, "config", "user.name", "Delivery skeleton fixture")
    git(repo, "config", "user.email", "delivery-fixture@example.invalid")
    for private_repo in (repo, remote):
        git(private_repo, "config", "gc.auto", "0")
        git(private_repo, "config", "maintenance.auto", "false")
    (repo / "value.txt").write_text("old\n")
    git(repo, "add", "value.txt")
    git(repo, "commit", "-m", "Fixture baseline")
    git(repo, "push", "origin", "HEAD:refs/heads/main")
    base = git(repo, "rev-parse", "HEAD")
    contract = {"id": str(uuid.uuid4()), "base": base, "max_attempts": 3,
                "max_restarts": 10, "max_operations": 30,
                "deadline": time.time() + 300, "command_timeout": 5,
                "fixture_actor_sha256": digest(HERE / "fixture_actor.py")}
    save(root / "contract.json", contract)
    save(root / "state.json", {"status": "running", "phase": "work", "base": base,
        "candidate": base, "contract_sha256": digest(root / "contract.json"),
        "receipts": {}, "attempts": {}, "restarts": 0, "checkpoints": [base],
        "events": [], "operations": 0})


class SafetyError(Exception):
    pass


class RetryableError(Exception):
    pass


def snapshot(root: Path, state: dict) -> None:
    repo = root / "candidate"
    if git(repo, "status", "--porcelain"):
        git(repo, "add", "-A")
        git(repo, "commit", "-m", "Unaccepted candidate checkpoint")
    candidate = git(repo, "rev-parse", "HEAD")
    state["candidate"] = candidate
    if candidate not in state["checkpoints"]:
        state["checkpoints"].append(candidate)
    save(root / "state.json", state)


def unchanged(root: Path, state: dict) -> None:
    repo = root / "candidate"
    if git(repo, "rev-parse", "HEAD") != state["candidate"] or git(repo, "status", "--porcelain"):
        raise SafetyError("candidate changed outside the builder; evidence is stale")


def verified_contract(root: Path, state: dict) -> dict:
    if digest(root / "contract.json") != state["contract_sha256"]:
        raise SafetyError("approved contract changed")
    contract = load(root / "contract.json")
    if digest(HERE / "fixture_actor.py") != contract["fixture_actor_sha256"]:
        raise SafetyError("trusted fixture runner changed")
    if time.time() > contract["deadline"]:
        raise SafetyError("delivery deadline exhausted")
    return contract


def invoke(root: Path, state: dict, contract: dict, phase: str) -> dict:
    # No inherited application secrets, provider credentials or shell command expansion.
    env = {"PATH": os.defpath, "LANG": "C.UTF-8", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
           "DELIVERY_CANDIDATE": state["candidate"],
           "DELIVERY_OPERATION": contract["id"] + ":" + state["candidate"],
           "DELIVERY_JOB_TOKEN": os.environ.get("DELIVERY_JOB_TOKEN", "")}
    log_base = root / f"{state['operations']:03}-{phase}"
    with log_base.with_suffix(".stdout").open("w") as stdout, log_base.with_suffix(".stderr").open("w") as stderr:
        proc = subprocess.Popen([sys.executable, str(HERE / "fixture_actor.py"), phase, str(root)],
                                cwd=root / "candidate", env=env, stdout=stdout, stderr=stderr)
        try:
            code = proc.wait(timeout=contract["command_timeout"])
        except subprocess.TimeoutExpired:
            # The supervisor fences the entire group before a replacement starts.
            raise RetryableError(f"{phase} timed out without a complete receipt")
    if code == 75 or code < 0:
        raise RetryableError(f"{phase} interrupted/unavailable: exit {code}")
    if code != 0:
        raise SafetyError(f"{phase} failed: " + log_base.with_suffix(".stderr").read_text()[-2000:])
    if phase == "work":
        return {}  # Readiness comes from independent review/checks, not builder prose.
    try:
        result = json.loads(log_base.with_suffix(".stdout").read_text())
    except (ValueError, OSError) as error:
        raise SafetyError(f"{phase} did not provide a valid observation") from error
    if not isinstance(result, dict):
        raise SafetyError(f"{phase} observation is not an object")
    if phase != "work":
        unchanged(root, state)
        if result.get("candidate") != state["candidate"]:
            raise SafetyError(f"{phase} returned stale candidate evidence")
    return result


def require_receipts(root: Path, state: dict, phases: tuple[str, ...]) -> None:
    unchanged(root, state)
    for phase in phases:
        receipt = state["receipts"].get(phase, {})
        if receipt.get("candidate") != state["candidate"] or receipt.get("contract") != state["contract_sha256"]:
            raise SafetyError(f"missing/stale {phase} receipt")
    if "package" in phases and digest(root / "artifact.bin") != state["receipts"]["package"]["artifact_sha256"]:
        raise SafetyError("release artifact changed after packaging")


def publish(root: Path, state: dict) -> dict:
    require_receipts(root, state, ("review", "check", "package"))
    remote = root / "remote.git"
    actual = git(remote, "rev-parse", "refs/heads/main")
    if actual == state["candidate"]:
        return {"candidate": actual, "reconciled": True}
    if actual != state["base"]:
        raise SafetyError("main moved: integrate and revalidate a new candidate before publication")
    # This remote was created by create_job; there is no configurable production target.
    # Import immutable objects separately, then fast-forward with an atomic expected-base
    # check. A plain push leaves a race between the preflight and the actual ref update.
    git(root / "candidate", "merge-base", "--is-ancestor", state["base"], state["candidate"])
    git(root / "candidate", "push", str(remote), f"{state['candidate']}:refs/candidates/{state['candidate']}")
    try:
        git(remote, "update-ref", "refs/heads/main", state["candidate"], state["base"])
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        actual = git(remote, "rev-parse", "refs/heads/main")
        if actual == state["candidate"]:
            return {"candidate": actual, "reconciled": True}
        if actual == state["base"] and isinstance(error, subprocess.TimeoutExpired):
            raise RetryableError("publication response lost; remote still at approved base") from error
        raise SafetyError("main moved or publication was rejected; candidate needs inspection") from error
    return {"candidate": state["candidate"], "reconciled": False}


def run_controller(root: Path) -> int:
    state = load(root / "state.json")
    if state["status"] != "running":
        return 0 if state["status"] == "delivered" else 2
    try:
        while state["status"] == "running":
            contract = verified_contract(root, state)
            phase = state["phase"]
            if state["operations"] >= contract["max_operations"]:
                raise SafetyError("cumulative operation budget exhausted")
            if state["attempts"].get(phase, 0) >= contract["max_attempts"]:
                raise SafetyError(f"{phase} attempt budget exhausted")
            if phase == "work":
                # Any killed worker's dirty source is preserved, never accepted or discarded.
                snapshot(root, state)
                state["receipts"] = {}
            else:
                unchanged(root, state)
            if phase in ("deploy", "verify"):
                require_receipts(root, state, ("review", "check", "package", "publish"))
            state["operations"] += 1
            state["attempts"][phase] = state["attempts"].get(phase, 0) + 1
            state["events"].append({"event": "started", "phase": phase, "candidate": state["candidate"]})
            save(root / "state.json", state)  # Budget is charged before the external operation.
            result = publish(root, state) if phase == "publish" else invoke(root, state, contract, phase)
            if phase == "work":
                snapshot(root, state)
                result = {"candidate": state["candidate"]}
            if phase == "review":
                decision = result.get("decision")
                if decision == "repair":
                    state["events"].append({"event": "repair", "candidate": state["candidate"], "reason": result.get("reason")})
                    state["phase"] = "work"
                    save(root / "state.json", state)
                    continue
                if decision != "accept":
                    raise SafetyError("review requires a decision: " + str(result.get("reason")))
            if phase == "check" and (type(result.get("selected")) is not int or result["selected"] < 1):
                raise SafetyError("zero or invalid selected-test count is not green")
            if phase == "package" and result.get("artifact_sha256") != digest(root / "artifact.bin"):
                raise SafetyError("package receipt does not match the release artifact")
            if phase in ("deploy", "verify"):
                require_receipts(root, state, ("review", "check", "package", "publish"))
                if result.get("artifact_sha256") != state["receipts"]["package"]["artifact_sha256"]:
                    raise SafetyError(f"{phase} returned a different release artifact")
            # One-shot test injection: real SIGKILL after effect, before durable acknowledgment.
            fault = root / "crash-after"
            if fault.exists() and fault.read_text().strip() == phase:
                fault.unlink()
                os.kill(os.getpid(), signal.SIGKILL)
            result["contract"] = state["contract_sha256"]
            state["receipts"][phase] = result
            state["events"].append({"event": "completed", "phase": phase, "candidate": state["candidate"]})
            if time.time() > contract["deadline"]:
                # Keep completed observations, but never count late completion as success.
                state["status"], state["reason"] = "blocked", "delivery deadline exhausted during operation"
            elif phase == "verify":
                state["status"] = "delivered"
            else:
                state["phase"] = PHASES[PHASES.index(phase) + 1]
            save(root / "state.json", state)
        return 0 if state["status"] == "delivered" else 2
    except RetryableError as error:
        state["events"].append({"event": "retry", "phase": state["phase"], "reason": str(error)})
        save(root / "state.json", state)
        return 75
    except (SafetyError, OSError, subprocess.SubprocessError) as error:
        state["status"] = "blocked"
        state["reason"] = str(error)
        save(root / "state.json", state)
        return 2


def fence(root: Path) -> bool:
    """Linux-only: identify our session members and signal via pidfds, not reused PIDs.

    Trusted children must stay in their session and inherit the ownership token. This
    is crash isolation, not an adversarial sandbox; production needs OS isolation.
    """
    runtime = root / "runtime.json"
    if not runtime.exists():
        return False
    owner = load(runtime)
    deadline = time.monotonic() + 5
    while True:
        found = False
        for entry in Path("/proc").iterdir():
            if not entry.name.isdigit():
                continue
            fd = None
            try:
                fd = os.pidfd_open(int(entry.name))
                fields = (entry / "stat").read_text().rsplit(")", 1)[1].split()
                if fields[0] == "Z" or int(fields[2]) != owner["pid"] or int(fields[3]) != owner["pid"]:
                    continue
                token = f"DELIVERY_JOB_TOKEN={owner['token']}".encode()
                if token not in (entry / "environ").read_bytes().split(b"\0"):
                    raise SafetyError("cannot establish ownership of surviving process; refusing replacement")
                signal.pidfd_send_signal(fd, signal.SIGKILL)
                found = True
            except OSError as error:
                if error.errno in (errno.ENOENT, errno.ESRCH) or (error.errno == errno.EINVAL and not entry.exists()):
                    continue
                raise
            finally:
                if fd is not None:
                    os.close(fd)
        # Reap our own dead group members too: a stopped controller killed by this
        # supervisor otherwise remains a zombie until after fence, deadlocking it.
        try:
            while os.waitpid(-owner["pid"], os.WNOHANG)[0]:
                pass
        except ChildProcessError:
            pass
        if not found:
            # A process may fork and disappear between /proc enumeration and read.
            # Only the kernel's absence of the group proves no member can fork again.
            # Signal zero is a probe, never a destructive signal to a reused group ID.
            try:
                os.killpg(owner["pid"], 0)
            except ProcessLookupError:
                runtime.unlink()
                return True
        if time.monotonic() > deadline:
            raise SafetyError("unable to fence prior controller session")
        time.sleep(0.01)


def preserve_orphaned_candidate_locks(root: Path, state: dict) -> None:
    # Only this freshly-created candidate repository has exclusive job ownership.
    # Never remove locks from a shared/production remote. Fence all old writers first.
    if state["phase"] != "work":
        return
    git_dir = root / "candidate" / ".git"
    for relative in ("index.lock", "HEAD.lock", "refs/heads/main.lock"):
        lock = git_dir / relative
        if lock.exists():
            archive = root / "orphaned-git-locks"
            archive.mkdir(exist_ok=True)
            destination = archive / (relative.replace("/", "_") + "-" + uuid.uuid4().hex)
            os.replace(lock, destination)
            state["events"].append({"event": "preserved_orphaned_lock", "path": str(destination.relative_to(root))})
            save(root / "state.json", state)


def supervise(root: Path) -> int:
    with (root / "supervisor.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return 3
        try:
            interrupted = fence(root)
            while True:
                state = load(root / "state.json")
                if state["status"] != "running":
                    return 0 if state["status"] == "delivered" else 2
                contract = verified_contract(root, state)
                if interrupted:
                    preserve_orphaned_candidate_locks(root, state)
                    state["restarts"] += 1
                    save(root / "state.json", state)
                    if state["restarts"] > contract["max_restarts"]:
                        raise SafetyError("cumulative restart budget exhausted")
                    time.sleep(min(0.05 * 2 ** (state["restarts"] - 1), 0.5))
                token = uuid.uuid4().hex
                env = {"PATH": os.defpath, "LANG": "C.UTF-8", "DELIVERY_JOB_TOKEN": token}
                proc = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "_controller", str(root)],
                                        env=env, start_new_session=True)
                # Child cannot start work until its ownership record is durable.
                save(root / "runtime.json", {"pid": proc.pid, "token": token})
                (root / "controller.pid").write_text(str(proc.pid))
                try:
                    try:
                        code = proc.wait(timeout=max(0.01, contract["deadline"] - time.time()))
                    except subprocess.TimeoutExpired as error:
                        raise SafetyError("delivery deadline exhausted waiting for controller") from error
                finally:
                    fence(root)
                    proc.wait(timeout=5)
                if code in (0, 2):
                    return code
                interrupted = True
        except (SafetyError, OSError, subprocess.SubprocessError) as error:
            state = load(root / "state.json")
            state["status"], state["reason"] = "blocked", str(error)
            save(root / "state.json", state)
            return 2


def await_ownership(root: Path) -> None:
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if (root / "runtime.json").exists():
            owner = load(root / "runtime.json")
            if owner == {"pid": os.getpid(), "token": os.environ.get("DELIVERY_JOB_TOKEN")}:
                return
        time.sleep(0.01)
    raise SafetyError("controller never received durable ownership")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("create", "run", "_controller"))
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    if args.action == "create":
        create_job(args.root)
        return 0
    root = args.root.resolve()
    if args.action == "_controller":
        await_ownership(root)
        return run_controller(root)
    return supervise(root)


if __name__ == "__main__":
    raise SystemExit(main())
