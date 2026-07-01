#!/usr/bin/env python3
"""Run the local Code Village developer debug checklist.

This tool is local-only. It uses temporary save and inbox paths for runtime
checks so the developer's real game save and Claude Code inbox are not touched.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[1]
PYTHON_TESTS = [
    "tests/test_code_village_event.py",
    "tests/test_asset_manifest_tool.py",
    "tests/test_claude_hook_status.py",
    "tests/test_macos_export_tool.py",
]
FORBIDDEN_PRIVACY_STRINGS = [
    "/Users/example/private-project",
    "raw-dev-debug-session-secret",
    "do not store dev debug prompt",
    "do not store dev debug response",
]


@dataclass
class CheckResult:
    name: str
    status: str
    duration_seconds: float
    command: str
    detail: str = ""

    def failed(self) -> bool:
        return self.status == "failed"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run Code Village developer debug checks.")
    parser.add_argument("--json", action="store_true", help="Print a machine-readable report.")
    parser.add_argument("--list", action="store_true", help="List planned checks without running them.")
    parser.add_argument("--fast", action="store_true", help="Skip the macOS debug export smoke.")
    parser.add_argument("--skip-godot", action="store_true", help="Skip Godot runtime checks.")
    parser.add_argument("--skip-export", action="store_true", help="Skip macOS debug export smoke.")
    parser.add_argument("--keep-temp", action="store_true", help="Keep the temporary debug directory.")
    args = parser.parse_args(argv)

    skip_godot = args.skip_godot
    skip_export = args.skip_export or args.fast or skip_godot
    checks = build_checks(skip_godot=skip_godot, skip_export=skip_export)

    if args.list:
        for name, _runner in checks:
            print(name)
        return 0

    report = run_checks(checks, keep_temp=args.keep_temp)
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print_text_report(report)

    return 1 if any(result["status"] == "failed" for result in report["checks"]) else 0


def build_checks(skip_godot: bool = False, skip_export: bool = False) -> list[tuple[str, Callable[[dict[str, str], Path], CheckResult]]]:
    checks: list[tuple[str, Callable[[dict[str, str], Path], CheckResult]]] = [
        ("python syntax", lambda env, tmp: run_command("python syntax", _py_compile_command(), env, timeout=30)),
        (
            "asset manifest",
            lambda env, tmp: run_command(
                "asset manifest",
                [sys.executable, "tools/validate_asset_manifest.py"],
                env,
                timeout=30,
            ),
        ),
        (
            "python unit tests",
            lambda env, tmp: run_command(
                "python unit tests",
                [sys.executable, "-m", "unittest", *PYTHON_TESTS],
                env,
                timeout=90,
            ),
        ),
        (
            "Claude hook self-test",
            lambda env, tmp: run_command(
                "Claude hook self-test",
                [sys.executable, "tools/claude_hook_self_test.py", *([] if not skip_godot else ["--skip-godot"])],
                env,
                timeout=45,
            ),
        ),
        ("temporary inbox import probe", lambda env, tmp: run_import_probe(env, tmp, skip_godot=skip_godot)),
    ]

    if skip_godot:
        checks.append(("Godot headless load", lambda env, tmp: skipped("Godot headless load", "--skip-godot")))
        checks.append(("Godot unit tests", lambda env, tmp: skipped("Godot unit tests", "--skip-godot")))
    else:
        checks.append(
            (
                "Godot headless load",
                lambda env, tmp: run_command(
                    "Godot headless load",
                    ["godot", "--headless", "--path", ".", "--quit-after", "1"],
                    env,
                    timeout=30,
                    require_executable="godot",
                ),
            )
        )
        checks.append(
            (
                "Godot unit tests",
                lambda env, tmp: run_command(
                    "Godot unit tests",
                    ["godot", "--headless", "--path", ".", "--script", "res://tests/run_unit_tests.gd"],
                    env,
                    timeout=45,
                    require_executable="godot",
                ),
            )
        )

    if skip_export:
        checks.append(("macOS debug export smoke", lambda env, tmp: skipped("macOS debug export smoke", "skipped by flag")))
    else:
        checks.append(
            (
                "macOS debug export smoke",
                lambda env, tmp: run_command(
                    "macOS debug export smoke",
                    [sys.executable, "tools/verify_macos_export.py", "--zip", str(tmp / "CodeVillage.zip")],
                    env,
                    timeout=150,
                    require_executable="godot",
                ),
            )
        )

    checks.append(("git diff whitespace", lambda env, tmp: run_command("git diff whitespace", ["git", "diff", "--check"], env, timeout=15)))
    return checks


def _py_compile_command() -> list[str]:
    tool_files = sorted(str(path.relative_to(ROOT)) for path in (ROOT / "tools").glob("*.py"))
    return [sys.executable, "-m", "py_compile", *tool_files]


def run_checks(
    checks: list[tuple[str, Callable[[dict[str, str], Path], CheckResult]]],
    keep_temp: bool = False,
) -> dict[str, Any]:
    temp_root = Path(tempfile.mkdtemp(prefix="code-village-dev-debug-"))
    env = os.environ.copy()
    env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(temp_root / "activity_inbox" / "claude_code_events.jsonl")
    env["CODE_VILLAGE_SAVE_PATH"] = str(temp_root / "save" / "code_village_save.json")
    env["CODE_VILLAGE_DEBUG"] = "1"
    Path(env["CODE_VILLAGE_ACTIVITY_INBOX"]).parent.mkdir(parents=True, exist_ok=True)
    Path(env["CODE_VILLAGE_SAVE_PATH"]).parent.mkdir(parents=True, exist_ok=True)

    results: list[CheckResult] = []
    for _name, runner in checks:
        results.append(runner(env, temp_root))
    report = {
        "ok": not any(result.failed() for result in results),
        "repo": str(ROOT),
        "temporary_root": str(temp_root),
        "temporary_root_kept": keep_temp,
        "real_user_save_touched": False,
        "real_user_inbox_touched": False,
        "checks": [asdict(result) for result in results],
    }
    if not keep_temp:
        shutil.rmtree(temp_root, ignore_errors=True)
    return report


def run_command(
    name: str,
    command: list[str],
    env: dict[str, str],
    timeout: int,
    require_executable: str | None = None,
) -> CheckResult:
    if require_executable and shutil.which(require_executable) is None:
        return CheckResult(
            name=name,
            status="failed",
            duration_seconds=0.0,
            command=join_command(command),
            detail=f"missing executable: {require_executable}",
        )

    start = time.monotonic()
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        return CheckResult(
            name=name,
            status="failed",
            duration_seconds=time.monotonic() - start,
            command=join_command(command),
            detail=f"timeout after {timeout}s\n{trim_output((exc.stdout or '') + (exc.stderr or ''))}",
        )

    detail = trim_output(result.stdout + result.stderr)
    return CheckResult(
        name=name,
        status="passed" if result.returncode == 0 else "failed",
        duration_seconds=time.monotonic() - start,
        command=join_command(command),
        detail=detail,
    )


def run_import_probe(env: dict[str, str], temp_root: Path, skip_godot: bool = False) -> CheckResult:
    name = "temporary inbox import probe"
    start = time.monotonic()
    inbox = Path(env["CODE_VILLAGE_ACTIVITY_INBOX"])
    save = Path(env["CODE_VILLAGE_SAVE_PATH"])
    payload = {
        "session_id": "raw-dev-debug-session-secret",
        "cwd": "/Users/example/private-project",
        "prompt": "do not store dev debug prompt",
        "response": "do not store dev debug response",
    }
    try:
        event_inputs = (
            ("claude_code_session", "SessionStart"),
            ("claude_code_turn_completed", "Stop"),
        )
        for event_type, hook_event in event_inputs:
            subprocess.run(
                [
                    sys.executable,
                    "tools/code_village_event.py",
                    "--stdin-json",
                    "--type",
                    event_type,
                    "--hook-event",
                    hook_event,
                ],
                cwd=ROOT,
                env=env,
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                check=True,
                timeout=10,
            )

        event_text = inbox.read_text(encoding="utf-8")
        assert_no_private_values(event_text, "temporary inbox")
        events = [json.loads(line) for line in event_text.splitlines() if line.strip()]

        if skip_godot:
            return CheckResult(
                name=name,
                status="passed",
                duration_seconds=time.monotonic() - start,
                command="temporary inbox write only",
                detail=f"inbox={inbox}\nevents={len(events)}\nsave_import=skipped",
            )

        if shutil.which("godot") is None:
            return CheckResult(
                name=name,
                status="failed",
                duration_seconds=time.monotonic() - start,
                command="temporary inbox -> Godot save",
                detail="missing executable: godot",
            )

        subprocess.run(
            ["godot", "--headless", "--path", ".", "--quit-after", "1"],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=True,
            timeout=30,
        )
        if not save.exists():
            raise RuntimeError("temporary save file was not created")
        save_text = save.read_text(encoding="utf-8")
        assert_no_private_values(save_text, "temporary save")
        save_data = json.loads(save_text)
        village = save_data.get("village_state", {})
        latest_event = events[-1] if events else {}
        latest_metadata = latest_event.get("metadata", {}) if isinstance(latest_event.get("metadata", {}), dict) else {}
        detail = "\n".join(
            [
                f"temp_root={temp_root}",
                f"inbox={inbox}",
                f"save={save}",
                f"inbox_events={len(events)}",
                f"latest_event={latest_event.get('type', '')}",
                f"latest_project={latest_metadata.get('project_label', '')}",
                f"latest_hook={latest_metadata.get('hook_event', '')}",
                f"activity_events={len(save_data.get('activity_events', []))}",
                f"growth_events={len(save_data.get('growth_events', []))}",
                f"workshop_level={village.get('workshop_level')}",
                f"flowers={village.get('flowers')}",
            ]
        )
        if len(save_data.get("activity_events", [])) < 2 or len(save_data.get("growth_events", [])) < 2:
            raise RuntimeError("temporary Claude Code events were not imported into save")
        return CheckResult(name=name, status="passed", duration_seconds=time.monotonic() - start, command="temporary inbox -> Godot save", detail=detail)
    except Exception as exc:  # noqa: BLE001 - debug report should capture failures instead of crashing
        return CheckResult(
            name=name,
            status="failed",
            duration_seconds=time.monotonic() - start,
            command="temporary inbox -> Godot save",
            detail=trim_output(str(exc)),
        )


def assert_no_private_values(text: str, label: str) -> None:
    for value in FORBIDDEN_PRIVACY_STRINGS:
        if value in text:
            raise RuntimeError(f"{label} leaked private value: {value}")


def skipped(name: str, reason: str) -> CheckResult:
    return CheckResult(name=name, status="skipped", duration_seconds=0.0, command="", detail=reason)


def join_command(command: list[str]) -> str:
    return " ".join(command)


def trim_output(output: str, limit: int = 1600) -> str:
    clean = output.strip()
    if len(clean) <= limit:
        return clean
    return clean[-limit:]


def print_text_report(report: dict[str, Any]) -> None:
    print("Code Village developer debug")
    print(f"repo={report['repo']}")
    print(f"temporary_root={report['temporary_root']}")
    print(f"temporary_root_kept={str(report.get('temporary_root_kept', False)).lower()}")
    print("real_user_save_touched=false")
    print("real_user_inbox_touched=false")
    for check in report["checks"]:
        status = check["status"].upper()
        print(f"{status}: {check['name']} ({check['duration_seconds']:.2f}s)")
        if check["detail"] and (check["status"] != "passed" or check["name"] == "temporary inbox import probe"):
            print(indent(check["detail"]))
    if report["ok"]:
        print("OK: developer debug checks passed.")
    else:
        print("FAIL: developer debug checks failed.", file=sys.stderr)


def indent(text: str) -> str:
    return "\n".join(f"  {line}" for line in text.splitlines())


if __name__ == "__main__":
    raise SystemExit(main())
