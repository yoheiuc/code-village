#!/usr/bin/env python3
"""Write privacy-preserving Claude Code activity events for Code Village."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import sys
import uuid
from pathlib import Path
from typing import Any


ALLOWED_TYPES = {"claude_code_session", "claude_code_turn_completed"}
DEFAULT_INBOX = Path.home() / "Library/Application Support/Code Village/activity_inbox/claude_code_events.jsonl"


def main() -> int:
    parser = argparse.ArgumentParser(description="Record a local Code Village Claude Code activity event.")
    parser.add_argument("--type", choices=sorted(ALLOWED_TYPES), default="claude_code_session")
    parser.add_argument("--project-label", default="")
    parser.add_argument("--hook-event", default="")
    parser.add_argument("--session-id", default="")
    parser.add_argument("--inbox", default=os.environ.get("CODE_VILLAGE_ACTIVITY_INBOX", str(DEFAULT_INBOX)))
    parser.add_argument("--stdin-json", action="store_true", help="Read Claude Code hook JSON from stdin and sanitize it.")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--print-path", action="store_true")
    args = parser.parse_args()

    if args.print_path:
        print(args.inbox)
        return 0

    payload: dict[str, Any] = {}
    if args.stdin_json:
        raw_stdin = sys.stdin.read()
        if raw_stdin.strip():
            try:
                parsed = json.loads(raw_stdin)
                if isinstance(parsed, dict):
                    payload = parsed
            except json.JSONDecodeError:
                payload = {}

    event = build_event(args, payload)
    encoded = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
    if args.dry_run:
        print(encoded)
        return 0

    inbox = Path(args.inbox).expanduser()
    inbox.parent.mkdir(parents=True, exist_ok=True)
    with inbox.open("a", encoding="utf-8") as handle:
        handle.write(encoded + "\n")
    print(str(inbox))
    return 0


def build_event(args: argparse.Namespace, payload: dict[str, Any]) -> dict[str, Any]:
    session_id = args.session_id or first_string(payload, ["session_id", "sessionId", "conversation_id"])
    hook_event = args.hook_event or first_string(payload, ["hook_event", "hookEventName", "event", "type", "name"])
    project_label = safe_label(args.project_label or project_label_from_payload(payload))
    metadata = {
        "source": "claude_code_hook",
        "project_label": project_label[:80],
        "hook_event": hook_event[:80],
    }
    if session_id:
        metadata["session_hash"] = hashlib.sha256(session_id.encode("utf-8")).hexdigest()[:16]

    return {
        "schema_version": 1,
        "id": f"claude-{dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')}-{uuid.uuid4().hex[:8]}",
        "type": args.type,
        "occurred_at": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "source": "claude_code_hook",
        "repository_id": "",
        "metadata": {key: value for key, value in metadata.items() if value},
        "privacy_level": "metadata_only",
    }


def first_string(payload: dict[str, Any], keys: list[str]) -> str:
    for key in keys:
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def project_label_from_payload(payload: dict[str, Any]) -> str:
    explicit = first_string(payload, ["project_label", "projectLabel", "workspace_name", "workspaceName"])
    if explicit:
        return explicit
    cwd = first_string(payload, ["cwd", "workspace", "project_path", "projectPath"])
    if cwd:
        return Path(cwd).name[:80]
    return ""


def safe_label(value: str) -> str:
    stripped = value.strip()
    if "/" in stripped or "\\" in stripped:
        return Path(stripped).name[:80]
    return stripped[:80]


if __name__ == "__main__":
    raise SystemExit(main())
