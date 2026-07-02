#!/usr/bin/env python3
"""Capture reproducible Code Village MVP screenshots using temporary local data."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOT_DIR = ROOT / "artifacts" / "screenshots"
EVENT_TOOL = ROOT / "tools" / "code_village_event.py"
SCREENSHOT_KEYS = ("initial", "settings", "registered", "grown", "growth-effect")


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture Code Village MVP screenshots.")
    parser.add_argument(
        "--only",
        choices=[*SCREENSHOT_KEYS, *[f"mvp-{key}" for key in SCREENSHOT_KEYS]],
        action="append",
        help="Capture only the named screenshot. Can be passed multiple times.",
    )
    parser.add_argument("--frames", type=int, default=30, help="Movie frames to render before frame extraction.")
    parser.add_argument("--frame", type=int, default=10, help="Frame index extracted from each temporary AVI.")
    parser.add_argument(
        "--output-prefix",
        default="mvp",
        help="Output filename prefix. Use a non-default prefix (e.g. proto) to keep mvp-*.png intact.",
    )
    parser.add_argument(
        "--asset-manifest",
        default=None,
        help="Optional CODE_VILLAGE_ASSET_MANIFEST value passed to Godot (e.g. res://assets/asset_manifest_prototype.json).",
    )
    args = parser.parse_args()

    try:
        capture_all(
            only=args.only,
            frames=args.frames,
            frame=args.frame,
            prefix=args.output_prefix,
            asset_manifest=args.asset_manifest,
        )
    except CaptureError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print("OK: MVP screenshots captured.")
    return 0


class CaptureError(RuntimeError):
    pass


def capture_all(
    only: list[str] | None = None,
    frames: int = 30,
    frame: int = 10,
    prefix: str = "mvp",
    asset_manifest: str | None = None,
) -> None:
    _require_tool("godot")
    _require_tool("ffmpeg")
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    targets = {_normalize_target(name) for name in (only or SCREENSHOT_KEYS)}
    shared_env: dict[str, str] = {}
    if asset_manifest:
        shared_env["CODE_VILLAGE_ASSET_MANIFEST"] = asset_manifest

    with tempfile.TemporaryDirectory(prefix="code-village-shots-") as tmp:
        tmp_dir = Path(tmp)
        empty_inbox = tmp_dir / "empty_inbox.jsonl"
        empty_inbox.write_text("", encoding="utf-8")

        if "initial" in targets:
            _capture_godot(
                tmp_dir, f"{prefix}-initial.png", tmp_dir / "initial_save.json", empty_inbox, frames, frame, shared_env
            )
        if "settings" in targets:
            _capture_godot(
                tmp_dir,
                f"{prefix}-settings.png",
                tmp_dir / "settings_save.json",
                empty_inbox,
                frames,
                frame,
                {**shared_env, "CODE_VILLAGE_QA_PANEL": "settings"},
            )
        if "registered" in targets:
            registered_save = tmp_dir / "registered_save.json"
            _write_save(registered_save, _registered_save())
            _capture_godot(tmp_dir, f"{prefix}-registered.png", registered_save, empty_inbox, frames, frame, shared_env)
        if "grown" in targets:
            grown_save = tmp_dir / "grown_save.json"
            _write_save(grown_save, _grown_save())
            _capture_godot(tmp_dir, f"{prefix}-grown.png", grown_save, empty_inbox, frames, frame, shared_env)
        if "growth-effect" in targets:
            inbox = tmp_dir / "growth_effect_inbox.jsonl"
            _write_claude_event(inbox, "claude_code_session", "SessionStart")
            _write_claude_event(inbox, "claude_code_turn_completed", "Stop")
            _capture_godot(
                tmp_dir, f"{prefix}-growth-effect.png", tmp_dir / "effect_save.json", inbox, frames, frame, shared_env
            )

    _delete_generated_sidecars()


def _capture_godot(
    tmp_dir: Path,
    output_name: str,
    save_path: Path,
    inbox_path: Path,
    frames: int,
    frame: int,
    extra_env: dict[str, str] | None = None,
) -> None:
    movie_path = tmp_dir / f"{output_name}.avi"
    output_path = SCREENSHOT_DIR / output_name
    env = os.environ.copy()
    env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
    env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox_path)
    if extra_env:
        env.update(extra_env)

    result = subprocess.run(
        ["godot", "--path", ".", "--write-movie", str(movie_path), "--quit-after", str(frames)],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )
    if result.returncode != 0:
        raise CaptureError(f"Godot capture failed for {output_name}:\n{result.stdout}{result.stderr}")

    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-i",
            str(movie_path),
            "-vf",
            f"select=eq(n\\,{frame})",
            "-frames:v",
            "1",
            str(output_path),
        ],
        cwd=ROOT,
        check=True,
        timeout=20,
    )


def _write_claude_event(inbox: Path, event_type: str, hook_event: str) -> None:
    payload = {
        "session_id": f"capture-{event_type}",
        "cwd": str(ROOT),
        "hook_event": hook_event,
        "prompt": "do not store capture prompt",
        "response": "do not store capture response",
    }
    subprocess.run(
        [
            sys.executable,
            str(EVENT_TOOL),
            "--stdin-json",
            "--type",
            event_type,
            "--inbox",
            str(inbox),
        ],
        input=json.dumps(payload),
        text=True,
        cwd=ROOT,
        capture_output=True,
        check=True,
        timeout=10,
    )


def _registered_save() -> dict[str, Any]:
    data = _base_save()
    now = _now()
    data["repositories"] = [
        {
            "id": "repo-demo-local",
            "display_name": "demo-village-repo",
            "local_path": "/tmp/code-village-demo-repo",
            "enabled": True,
            "created_at": now,
            "last_scanned_at": "",
            "privacy_mode": "metadata_only",
        }
    ]
    return data


def _grown_save() -> dict[str, Any]:
    data = _registered_save()
    now = _now()
    entries = [
        _diary(now, "リリースの鐘", "広場の鐘が短く鳴りました。"),
        _diary(now, "静かな橋", "橋のきしみが少し静かになりました。"),
        _diary(now, "図書館のページ", "図書館に新しいページが増えました。"),
        _diary(now, "テストの灯り", "小さな灯りが増えました。"),
    ]
    data["village_state"] = {
        "village_level": 5,
        "flowers": 12,
        "lanterns": 5,
        "repaired_paths": 3,
        "bridge_state": "repaired",
        "library_level": 4,
        "workshop_level": 4,
        "branch_tree_level": 3,
        "release_bell_rings": 1,
        "diary_entries": entries,
        "resident_messages": [
            {
                "occurred_at": now,
                "message": "図書館と工房に、今日の小さな変化が残っています。",
                "growth_event_id": "capture-message",
            }
        ],
        "last_updated_at": now,
    }
    data["growth_events"] = [
        {
            "id": f"capture-growth-{index}",
            "type": "capture",
            "occurred_at": now,
            "activity_event_id": "",
            "title": entry["title"],
            "description": entry["description"],
            "visual_target": "",
            "intensity": 1,
        }
        for index, entry in enumerate(entries)
    ]
    return data


def _base_save() -> dict[str, Any]:
    now = _now()
    return {
        "schema_version": 1,
        "settings": {
            "local_only": True,
            "store_commit_messages": False,
            "store_file_names": False,
            "enable_external_network": False,
            "show_rest_day_messages": True,
            "auto_import_claude_events": True,
        },
        "repositories": [],
        "onboarding_guide_dismissed": False,
        "imported_activity_event_ids": [],
        "village_state": {
            "village_level": 1,
            "flowers": 3,
            "lanterns": 1,
            "repaired_paths": 0,
            "bridge_state": "worn",
            "library_level": 1,
            "workshop_level": 1,
            "branch_tree_level": 1,
            "release_bell_rings": 0,
            "diary_entries": [_diary(now, "村のはじまり", "小さな工房と図書館に灯りが入りました。")],
            "resident_messages": [
                {
                    "occurred_at": now,
                    "message": "何も変わらない日も、村はここにあります。",
                    "growth_event_id": "",
                }
            ],
            "last_updated_at": now,
        },
        "activity_events": [],
        "growth_events": [],
    }


def _diary(occurred_at: str, title: str, description: str) -> dict[str, str]:
    return {
        "occurred_at": occurred_at,
        "title": title,
        "description": description,
        "growth_event_id": f"capture-{title}",
        "growth_event_type": "capture",
    }


def _write_save(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise CaptureError(f"Required command is not installed: {name}")


def _delete_generated_sidecars() -> None:
	for directory in (SCREENSHOT_DIR, ROOT / "assets" / "placeholders" / "effects"):
		for pattern in ("*.import", "*.wav", "*000000*.png"):
			for path in directory.glob(pattern):
				path.unlink()


def _normalize_target(name: str) -> str:
    return name.removeprefix("mvp-").removesuffix(".png")


if __name__ == "__main__":
    raise SystemExit(main())
