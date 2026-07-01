#!/usr/bin/env python3
"""Build and verify the unsigned Code Village macOS debug export.

This tool is local-only. It does not sign, notarize, upload, publish, or read
secrets. It verifies the debug zip shape and launches the extracted app with
temporary save/inbox paths so real user data is not touched.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXPORT = ROOT / "builds" / "mac" / "CodeVillage.zip"
APP_NAME = "Code Village.app"
APP_BINARY = Path(APP_NAME) / "Contents" / "MacOS" / "Code Village"
FORBIDDEN_EXPORT_PREFIXES = (
    ".agents/",
    ".ai/",
    ".claude/",
    "artifacts/",
    "docs/",
    "notes/",
    "tests/",
    "tools/",
)


@dataclass(frozen=True)
class ExportReport:
    export_path: Path
    exported: bool
    entry_count: int
    forbidden_entries: list[str]
    app_binary_found: bool
    launched: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "export_path": str(self.export_path),
            "exported": self.exported,
            "entry_count": self.entry_count,
            "forbidden_entries": self.forbidden_entries,
            "app_binary_found": self.app_binary_found,
            "launched": self.launched,
        }


class ExportVerificationError(RuntimeError):
    pass


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify Code Village macOS debug export.")
    parser.add_argument("--zip", default=str(DEFAULT_EXPORT), help="Export zip path.")
    parser.add_argument("--skip-export", action="store_true", help="Do not run Godot export first.")
    parser.add_argument("--skip-launch", action="store_true", help="Do not launch the extracted app.")
    parser.add_argument("--json", action="store_true", help="Print JSON report.")
    args = parser.parse_args()

    try:
        report = verify_export(
            Path(args.zip),
            run_export=not args.skip_export,
            launch_app=not args.skip_launch,
        )
    except ExportVerificationError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(report.to_dict(), ensure_ascii=False, indent=2))
    else:
        print(
            "OK: macOS debug export verified. "
            f"zip={report.export_path} entries={report.entry_count} launched={report.launched}"
        )
    return 0


def verify_export(export_path: Path, run_export: bool = True, launch_app: bool = True) -> ExportReport:
    export_path = export_path if export_path.is_absolute() else ROOT / export_path
    if run_export:
        _run_export(export_path)
    elif not export_path.exists():
        raise ExportVerificationError(f"export zip does not exist: {export_path}")

    entries = inspect_zip_entries(export_path)
    forbidden_entries = find_forbidden_entries(entries)
    if forbidden_entries:
        raise ExportVerificationError("export zip contains non-distribution paths: " + ", ".join(forbidden_entries[:5]))

    app_binary_found = any(entry == str(APP_BINARY) for entry in entries)
    if not app_binary_found:
        raise ExportVerificationError(f"export zip does not contain app binary: {APP_BINARY}")

    launched = False
    if launch_app:
        _launch_exported_app(export_path)
        launched = True

    return ExportReport(
        export_path=export_path,
        exported=run_export,
        entry_count=len(entries),
        forbidden_entries=[],
        app_binary_found=app_binary_found,
        launched=launched,
    )


def inspect_zip_entries(export_path: Path) -> list[str]:
    if not export_path.exists():
        raise ExportVerificationError(f"export zip does not exist: {export_path}")
    try:
        with zipfile.ZipFile(export_path) as archive:
            return sorted(info.filename for info in archive.infolist())
    except zipfile.BadZipFile as exc:
        raise ExportVerificationError(f"export is not a valid zip: {export_path}: {exc}") from exc


def find_forbidden_entries(entries: list[str]) -> list[str]:
    blocked: list[str] = []
    for entry in entries:
        normalized = entry.lstrip("/")
        if any(normalized.startswith(prefix) for prefix in FORBIDDEN_EXPORT_PREFIXES):
            blocked.append(entry)
            continue
        for prefix in FORBIDDEN_EXPORT_PREFIXES:
            if f"/{prefix}" in normalized:
                blocked.append(entry)
                break
    return blocked


def _run_export(export_path: Path) -> None:
    if shutil.which("godot") is None:
        raise ExportVerificationError("godot command is not installed")
    export_path.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["godot", "--headless", "--path", ".", "--export-debug", "macOS", str(export_path)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
        timeout=120,
    )
    if result.returncode != 0:
        raise ExportVerificationError("Godot export failed:\n" + result.stdout + result.stderr)


def _launch_exported_app(export_path: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="code-village-mac-export-") as tmp:
        tmp_dir = Path(tmp)
        with zipfile.ZipFile(export_path) as archive:
            archive.extractall(tmp_dir)

        app_binary = tmp_dir / APP_BINARY
        if not app_binary.exists():
            raise ExportVerificationError(f"extracted app binary is missing: {app_binary}")
        app_binary.chmod(app_binary.stat().st_mode | 0o755)

        inbox = tmp_dir / "empty_inbox.jsonl"
        save = tmp_dir / "save.json"
        inbox.write_text("", encoding="utf-8")
        env = os.environ.copy()
        env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox)
        env["CODE_VILLAGE_SAVE_PATH"] = str(save)
        result = subprocess.run(
            [str(app_binary), "--headless", "--quit-after", "1"],
            cwd=tmp_dir,
            env=env,
            text=True,
            capture_output=True,
            check=False,
            timeout=30,
        )
        if result.returncode != 0:
            raise ExportVerificationError("exported app launch failed:\n" + result.stdout + result.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
