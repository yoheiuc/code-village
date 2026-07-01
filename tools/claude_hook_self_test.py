#!/usr/bin/env python3
"""Run a local, privacy-safe smoke test for Code Village Claude Code hooks."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CLAUDE_SETTINGS = ROOT / ".claude" / "settings.json"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify repo-local Claude Code hook commands with a temporary inbox/save."
    )
    parser.add_argument(
        "--skip-godot",
        action="store_true",
        help="Only test hook command event writing, without starting Godot.",
    )
    args = parser.parse_args()

    try:
        run_self_test(skip_godot=args.skip_godot)
    except SelfTestError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print("OK: Claude Code hook self-test passed.")
    return 0


class SelfTestError(RuntimeError):
    pass


def run_self_test(skip_godot: bool = False) -> None:
    hook_commands = _load_hook_commands()
    with tempfile.TemporaryDirectory(prefix="code-village-hook-") as tmp:
        tmp_dir = Path(tmp)
        inbox = tmp_dir / "hook_events.jsonl"
        save_path = tmp_dir / "hook_save.json"
        payload = {
            "session_id": "raw-self-test-session-secret",
            "cwd": "/Users/example/private-project",
            "prompt": "do not store self-test prompt",
            "response": "do not store self-test response",
        }
        env = os.environ.copy()
        env["CLAUDE_PROJECT_DIR"] = str(ROOT)
        env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox)

        for hook_name, command in hook_commands.items():
            subprocess.run(
                command,
                shell=True,
                executable="/bin/zsh",
                input=json.dumps({**payload, "hook_event": hook_name}),
                text=True,
                cwd=tmp_dir,
                env=env,
                check=True,
                timeout=10,
            )

        events = _read_jsonl(inbox)
        _assert_equal([event.get("type") for event in events], ["claude_code_session", "claude_code_turn_completed"])
        _assert_safe_payload(events, "inbox")

        if skip_godot:
            return
        if shutil.which("godot") is None:
            raise SelfTestError("Godot CLI is not installed. Re-run with --skip-godot to test hooks only.")

        env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
        result = subprocess.run(
            ["godot", "--headless", "--path", ".", "--quit-after", "1"],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
            timeout=20,
        )
        if result.returncode != 0:
            raise SelfTestError("Godot import failed:\n%s%s" % (result.stdout, result.stderr))

        if not save_path.exists():
            raise SelfTestError("Godot did not create a temporary save file.")
        save_data = json.loads(save_path.read_text(encoding="utf-8"))
        _assert_equal(len(save_data.get("repositories", [])), 0)
        _assert_equal(len(save_data.get("activity_events", [])), 2)
        village = save_data.get("village_state", {})
        if int(village.get("workshop_level", 0)) < 2:
            raise SelfTestError("Claude Code session did not grow the workshop.")
        if int(village.get("flowers", 0)) < 4:
            raise SelfTestError("Claude Code turn did not grow flowers.")
        _assert_safe_payload(save_data, "save")


def _load_hook_commands() -> dict[str, str]:
    if not CLAUDE_SETTINGS.exists():
        raise SelfTestError(".claude/settings.json is missing.")
    settings = json.loads(CLAUDE_SETTINGS.read_text(encoding="utf-8"))
    hooks = settings.get("hooks", {})
    commands: dict[str, str] = {}
    for hook_name in ("SessionStart", "Stop"):
        try:
            command = hooks[hook_name][0]["hooks"][0]["command"]
        except (KeyError, IndexError, TypeError) as exc:
            raise SelfTestError(f"Missing hook command for {hook_name}.") from exc
        if not isinstance(command, str) or "tools/code_village_event.py" not in command:
            raise SelfTestError(f"Unexpected hook command for {hook_name}.")
        if "http://" in command or "https://" in command or "curl" in command:
            raise SelfTestError(f"Hook command for {hook_name} appears to use network access.")
        commands[hook_name] = command
    return commands


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise SelfTestError("Hook commands did not create the temporary inbox.")
    events: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parsed = json.loads(line)
        if not isinstance(parsed, dict):
            raise SelfTestError("Inbox contained a non-object JSON line.")
        events.append(parsed)
    if len(events) != 2:
        raise SelfTestError(f"Expected 2 hook events, found {len(events)}.")
    return events


def _assert_safe_payload(value: Any, label: str) -> None:
    encoded = json.dumps(value, ensure_ascii=False)
    forbidden = [
        str(ROOT),
        "/Users/example/private-project",
        "raw-self-test-session-secret",
        "do not store self-test prompt",
        "do not store self-test response",
    ]
    for needle in forbidden:
        if needle in encoded:
            raise SelfTestError(f"{label} leaked private value: {needle}")
    if label == "inbox" and "code-village" not in encoded:
        raise SelfTestError("Inbox did not keep the safe repo project label.")


def _assert_equal(actual: Any, expected: Any) -> None:
    if actual != expected:
        raise SelfTestError(f"Expected {expected!r}, got {actual!r}.")


if __name__ == "__main__":
    raise SystemExit(main())
