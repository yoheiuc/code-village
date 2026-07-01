#!/usr/bin/env python3
"""Inspect local Claude Code hook status for Code Village.

The status check reads only repo hook settings, the Code Village activity inbox,
and the Code Village save file. It never prints prompt/response content, raw
paths, raw session ids, or other unapproved fields.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import deque
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CLAUDE_SETTINGS = ROOT / ".claude" / "settings.json"
DEFAULT_INBOX = Path.home() / "Library/Application Support/Code Village/activity_inbox/claude_code_events.jsonl"
DEFAULT_SAVE = Path.home() / "Library/Application Support/Godot/app_userdata/Code Village/code_village_save.json"
ALLOWED_EVENT_TYPES = {"claude_code_session", "claude_code_turn_completed"}
ALLOWED_TOP_LEVEL_KEYS = {
    "schema_version",
    "id",
    "type",
    "occurred_at",
    "source",
    "repository_id",
    "metadata",
    "privacy_level",
}
ALLOWED_METADATA_KEYS = {"source", "project_label", "hook_event", "session_hash"}
PRIVATE_FIELD_KEYS = {
    "prompt",
    "response",
    "cwd",
    "workspace",
    "workspace_path",
    "project_path",
    "projectPath",
    "session_id",
    "sessionId",
    "conversation_id",
    "transcript",
    "messages",
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Inspect local Code Village Claude Code hook status.")
    parser.add_argument("--inbox", type=Path, default=Path(os.environ.get("CODE_VILLAGE_ACTIVITY_INBOX", DEFAULT_INBOX)))
    parser.add_argument("--save", type=Path, default=_default_save_path())
    parser.add_argument("--max-events", type=int, default=25)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--require-events", action="store_true", help="Fail if the inbox has no valid Claude Code events.")
    parser.add_argument(
        "--require-save-import",
        action="store_true",
        help="Fail if the save file has no imported Claude Code events.",
    )
    args = parser.parse_args(argv)

    result = build_status(args.inbox.expanduser(), args.save.expanduser(), max(1, args.max_events))

    if args.require_events and result["inbox"]["valid_events"] == 0:
        result["errors"].append("required Claude Code inbox events were not found")
    if args.require_save_import and result["save"]["claude_activity_events"] == 0:
        result["errors"].append("required imported Claude Code save events were not found")

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_text_status(result)

    return 1 if result["errors"] else 0


def _default_save_path() -> Path:
    override = os.environ.get("CODE_VILLAGE_SAVE_PATH", "").strip()
    if override:
        return Path(override)
    return DEFAULT_SAVE


def build_status(inbox_path: Path, save_path: Path, max_events: int) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []
    hook_status = inspect_hook_settings(errors, warnings)
    inbox_status = inspect_inbox(inbox_path, max_events, errors, warnings)
    save_status = inspect_save(save_path, errors, warnings)
    return {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "hook_settings": hook_status,
        "inbox": inbox_status,
        "save": save_status,
        "privacy": {
            "prints_private_values": False,
            "allowed_metadata_keys": sorted(ALLOWED_METADATA_KEYS),
            "external_network": False,
        },
    }


def inspect_hook_settings(errors: list[str], warnings: list[str]) -> dict[str, Any]:
    status: dict[str, Any] = {
        "path": str(CLAUDE_SETTINGS),
        "exists": CLAUDE_SETTINGS.exists(),
        "events": {},
        "local_only": True,
    }
    if not CLAUDE_SETTINGS.exists():
        errors.append(".claude/settings.json is missing")
        return status

    try:
        settings = json.loads(CLAUDE_SETTINGS.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f".claude/settings.json could not be read as JSON: {exc}")
        return status

    hooks = settings.get("hooks", {})
    if not isinstance(hooks, dict):
        errors.append(".claude/settings.json hooks must be an object")
        return status

    for hook_name, expected_type in (
        ("SessionStart", "claude_code_session"),
        ("Stop", "claude_code_turn_completed"),
    ):
        command = _extract_hook_command(hooks, hook_name)
        configured = bool(command)
        uses_tool = configured and "tools/code_village_event.py" in command
        expected = configured and f"--type {expected_type}" in command
        local_only = configured and all(token not in command for token in ("http://", "https://", "curl "))
        status["events"][hook_name] = {
            "configured": configured,
            "uses_code_village_event_tool": uses_tool,
            "expected_event_type": expected,
            "local_only": local_only,
        }
        if not configured:
            errors.append(f"hook command missing: {hook_name}")
        if configured and not uses_tool:
            errors.append(f"hook command does not use tools/code_village_event.py: {hook_name}")
        if configured and not expected:
            errors.append(f"hook command does not write {expected_type}: {hook_name}")
        if configured and not local_only:
            errors.append(f"hook command appears to use network access: {hook_name}")
            status["local_only"] = False

    if not status["events"]:
        warnings.append("no hook events found in .claude/settings.json")
    return status


def _extract_hook_command(hooks: dict[str, Any], hook_name: str) -> str:
    try:
        command = hooks[hook_name][0]["hooks"][0]["command"]
    except (KeyError, IndexError, TypeError):
        return ""
    return command if isinstance(command, str) else ""


def inspect_inbox(
    inbox_path: Path,
    max_events: int,
    errors: list[str],
    warnings: list[str],
) -> dict[str, Any]:
    status: dict[str, Any] = {
        "path": str(inbox_path),
        "exists": inbox_path.exists(),
        "lines": 0,
        "valid_events": 0,
        "malformed_lines": 0,
        "unsafe_lines": 0,
        "latest_events": [],
    }
    if not inbox_path.exists():
        warnings.append("Claude Code activity inbox does not exist yet")
        return status

    latest: deque[dict[str, Any]] = deque(maxlen=max_events)
    try:
        with inbox_path.open("r", encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                stripped = line.strip()
                if not stripped:
                    continue
                status["lines"] += 1
                try:
                    parsed = json.loads(stripped)
                except json.JSONDecodeError:
                    status["malformed_lines"] += 1
                    continue
                if not isinstance(parsed, dict):
                    status["malformed_lines"] += 1
                    continue
                issue_count = len(_event_privacy_issues(parsed))
                if issue_count:
                    status["unsafe_lines"] += 1
                    errors.append(f"inbox line {line_number} contains unsupported/private fields")
                    continue
                if parsed.get("type") in ALLOWED_EVENT_TYPES:
                    status["valid_events"] += 1
                    latest.append(_safe_event_summary(parsed, line_number))
    except OSError as exc:
        errors.append(f"Claude Code activity inbox could not be read: {exc}")
        return status

    status["latest_events"] = list(latest)
    if status["malformed_lines"]:
        warnings.append(f"inbox has malformed JSON lines: {status['malformed_lines']}")
    return status


def _event_privacy_issues(event: dict[str, Any]) -> list[str]:
    issues: list[str] = []
    for key in event.keys():
        key_string = str(key)
        if key_string in PRIVATE_FIELD_KEYS:
            issues.append(f"private top-level key: {key_string}")
        if key_string not in ALLOWED_TOP_LEVEL_KEYS:
            issues.append(f"unsupported top-level key: {key_string}")

    metadata = event.get("metadata", {})
    if not isinstance(metadata, dict):
        issues.append("metadata must be an object")
        return issues

    for key in metadata.keys():
        key_string = str(key)
        if key_string in PRIVATE_FIELD_KEYS:
            issues.append(f"private metadata key: {key_string}")
        if key_string not in ALLOWED_METADATA_KEYS:
            issues.append(f"unsupported metadata key: {key_string}")

    if event.get("source") != "claude_code_hook":
        issues.append("source must be claude_code_hook")
    if event.get("repository_id", "") not in ("", None):
        issues.append("Claude Code inbox repository_id must be empty")
    if event.get("privacy_level") != "metadata_only":
        issues.append("privacy_level must be metadata_only")
    return issues


def _safe_event_summary(event: dict[str, Any], line_number: int) -> dict[str, Any]:
    metadata = event.get("metadata", {})
    metadata = metadata if isinstance(metadata, dict) else {}
    return {
        "line": line_number,
        "type": event.get("type", ""),
        "occurred_at": str(event.get("occurred_at", ""))[:40],
        "project_label": str(metadata.get("project_label", ""))[:80],
        "hook_event": str(metadata.get("hook_event", ""))[:80],
        "session_hash_present": bool(metadata.get("session_hash")),
    }


def inspect_save(save_path: Path, errors: list[str], warnings: list[str]) -> dict[str, Any]:
    status: dict[str, Any] = {
        "path": str(save_path),
        "exists": save_path.exists(),
        "activity_events": 0,
        "claude_activity_events": 0,
        "imported_activity_event_ids": 0,
        "growth_events": 0,
        "village": {},
    }
    if not save_path.exists():
        warnings.append("Code Village save file does not exist yet")
        return status

    try:
        data = json.loads(save_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"Code Village save file could not be read as JSON: {exc}")
        return status
    if not isinstance(data, dict):
        errors.append("Code Village save file must be a JSON object")
        return status

    private_keys = _find_private_keys(data)
    if private_keys:
        errors.append("save file contains unsupported/private keys: " + ", ".join(sorted(private_keys)[:12]))

    activity_events = data.get("activity_events", [])
    if isinstance(activity_events, list):
        status["activity_events"] = len(activity_events)
        status["claude_activity_events"] = sum(
            1
            for event in activity_events
            if isinstance(event, dict)
            and event.get("source") == "claude_code_hook"
            and event.get("type") in ALLOWED_EVENT_TYPES
        )
    imported_ids = data.get("imported_activity_event_ids", [])
    if isinstance(imported_ids, list):
        status["imported_activity_event_ids"] = len(imported_ids)
    growth_events = data.get("growth_events", [])
    if isinstance(growth_events, list):
        status["growth_events"] = len(growth_events)

    village = data.get("village_state", {})
    if isinstance(village, dict):
        status["village"] = {
            "village_level": int(village.get("village_level", 0)),
            "flowers": int(village.get("flowers", 0)),
            "workshop_level": int(village.get("workshop_level", 0)),
            "resident_messages": len(village.get("resident_messages", []))
            if isinstance(village.get("resident_messages", []), list)
            else 0,
        }
    return status


def _find_private_keys(value: Any) -> set[str]:
    found: set[str] = set()
    if isinstance(value, dict):
        for key, nested in value.items():
            key_string = str(key)
            if key_string in PRIVATE_FIELD_KEYS:
                found.add(key_string)
            found.update(_find_private_keys(nested))
    elif isinstance(value, list):
        for item in value:
            found.update(_find_private_keys(item))
    return found


def print_text_status(result: dict[str, Any]) -> None:
    if result["errors"]:
        print("ERROR: Claude Code hook status check failed.", file=sys.stderr)
    else:
        print("OK: Claude Code hook status check completed.")

    hook = result["hook_settings"]
    print(f"Hook settings: {'found' if hook['exists'] else 'missing'} ({hook['path']})")
    for hook_name, details in hook.get("events", {}).items():
        print(
            f"- {hook_name}: configured={details['configured']} "
            f"tool={details['uses_code_village_event_tool']} "
            f"event_type={details['expected_event_type']} "
            f"local_only={details['local_only']}"
        )

    inbox = result["inbox"]
    print(f"Inbox: {'found' if inbox['exists'] else 'missing'} ({inbox['path']})")
    print(
        f"- lines={inbox['lines']} valid_events={inbox['valid_events']} "
        f"malformed={inbox['malformed_lines']} unsafe={inbox['unsafe_lines']}"
    )
    for event in inbox["latest_events"]:
        print(
            f"- latest line {event['line']}: {event['type']} "
            f"{event['occurred_at']} project={event['project_label']} "
            f"hook={event['hook_event']} session_hash={event['session_hash_present']}"
        )

    save = result["save"]
    print(f"Save: {'found' if save['exists'] else 'missing'} ({save['path']})")
    print(
        f"- activity_events={save['activity_events']} "
        f"claude_activity_events={save['claude_activity_events']} "
        f"imported_ids={save['imported_activity_event_ids']} growth_events={save['growth_events']}"
    )
    village = save.get("village", {})
    if village:
        print(
            f"- village_level={village['village_level']} flowers={village['flowers']} "
            f"workshop_level={village['workshop_level']} resident_messages={village['resident_messages']}"
        )

    for warning in result["warnings"]:
        print(f"WARNING: {warning}", file=sys.stderr)
    for error in result["errors"]:
        print(f"- {error}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
