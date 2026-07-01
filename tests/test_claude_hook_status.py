import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENT_TOOL = ROOT / "tools" / "code_village_event.py"
STATUS_TOOL = ROOT / "tools" / "claude_hook_status.py"


class ClaudeHookStatusToolTests(unittest.TestCase):
    def test_status_can_read_explicit_settings_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            settings = tmp_dir / "settings.json"
            settings.write_text(
                json.dumps(
                    {
                        "hooks": {
                            "SessionStart": [
                                {"hooks": [{"type": "command", "command": "echo unrelated"}]},
                                {
                                    "hooks": [
                                        {
                                            "type": "command",
                                            "command": 'python3 "/tmp/code-village/tools/code_village_event.py" --stdin-json --type claude_code_session',
                                        }
                                    ]
                                },
                            ],
                            "Stop": [
                                {
                                    "hooks": [
                                        {
                                            "type": "command",
                                            "command": 'python3 "/tmp/code-village/tools/code_village_event.py" --stdin-json --type claude_code_turn_completed',
                                        }
                                    ]
                                }
                            ],
                        }
                    }
                ),
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(STATUS_TOOL),
                    "--settings",
                    str(settings),
                    "--inbox",
                    str(tmp_dir / "missing.jsonl"),
                    "--save",
                    str(tmp_dir / "missing_save.json"),
                    "--json",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )

        data = json.loads(result.stdout)
        self.assertEqual(data["hook_settings"]["path"], str(settings))
        self.assertTrue(data["hook_settings"]["events"]["SessionStart"]["configured"])
        self.assertTrue(data["hook_settings"]["events"]["SessionStart"]["uses_code_village_event_tool"])
        self.assertTrue(data["hook_settings"]["events"]["Stop"]["expected_event_type"])

    def test_status_reports_safe_temp_inbox_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "events.jsonl"
            save = tmp_dir / "missing_save.json"
            payload = {
                "session_id": "raw-status-session-secret",
                "cwd": "/Users/example/private-project",
                "prompt": "do not store status prompt",
                "response": "do not store status response",
            }
            for event_type in ("claude_code_session", "claude_code_turn_completed"):
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
                    capture_output=True,
                    check=True,
                )

            result = subprocess.run(
                [
                    sys.executable,
                    str(STATUS_TOOL),
                    "--inbox",
                    str(inbox),
                    "--save",
                    str(save),
                    "--require-events",
                    "--json",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )

        data = json.loads(result.stdout)
        encoded = json.dumps(data, ensure_ascii=False)
        self.assertEqual(data["inbox"]["valid_events"], 2)
        self.assertEqual(data["inbox"]["unsafe_lines"], 0)
        self.assertEqual(data["save"]["exists"], False)
        self.assertIn("private-project", encoded)
        self.assertNotIn("/Users/example/private-project", encoded)
        self.assertNotIn("raw-status-session-secret", encoded)
        self.assertNotIn("do not store status prompt", encoded)
        self.assertNotIn("do not store status response", encoded)

    def test_status_rejects_private_fields_in_inbox(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "events.jsonl"
            inbox.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "id": "unsafe",
                        "type": "claude_code_session",
                        "occurred_at": "2026-07-01T00:00:00Z",
                        "source": "claude_code_hook",
                        "repository_id": "",
                        "privacy_level": "metadata_only",
                        "metadata": {"project_label": "private-project"},
                        "prompt": "should not be stored",
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(STATUS_TOOL),
                    "--inbox",
                    str(inbox),
                    "--save",
                    str(tmp_dir / "missing_save.json"),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported/private fields", result.stderr)
        self.assertNotIn("should not be stored", result.stdout + result.stderr)

    def test_require_events_fails_when_inbox_has_no_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            result = subprocess.run(
                [
                    sys.executable,
                    str(STATUS_TOOL),
                    "--inbox",
                    str(tmp_dir / "missing.jsonl"),
                    "--save",
                    str(tmp_dir / "missing_save.json"),
                    "--require-events",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required Claude Code inbox events", result.stderr)

    def test_status_reports_imported_save_without_private_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "missing.jsonl"
            save = tmp_dir / "save.json"
            save.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "imported_activity_event_ids": ["claude-1"],
                        "claude_activity_import_checkpoint": {
                            "schema_version": 1,
                            "path_hash": "abc123",
                            "offset": 128,
                            "file_size": 256,
                            "modified_time": 1782864000,
                            "updated_at": "2026-07-01T00:00:00Z",
                        },
                        "activity_events": [
                            {
                                "id": "claude-1",
                                "type": "claude_code_session",
                                "occurred_at": "2026-07-01T00:00:00Z",
                                "source": "claude_code_hook",
                                "repository_id": "",
                                "metadata": {"project_label": "code-village", "session_hash": "abc123"},
                                "privacy_level": "metadata_only",
                            }
                        ],
                        "growth_events": [{"id": "growth-1"}],
                        "village_state": {
                            "village_level": 2,
                            "flowers": 4,
                            "workshop_level": 2,
                            "resident_messages": ["小さな工房に灯りが入りました。"],
                        },
                    }
                ),
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(STATUS_TOOL),
                    "--inbox",
                    str(inbox),
                    "--save",
                    str(save),
                    "--require-save-import",
                    "--json",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )

        data = json.loads(result.stdout)
        self.assertEqual(data["save"]["claude_activity_events"], 1)
        self.assertTrue(data["save"]["claude_activity_import_checkpoint"]["present"])
        self.assertEqual(data["save"]["claude_activity_import_checkpoint"]["offset"], 128)
        self.assertNotIn("path", data["save"]["claude_activity_import_checkpoint"])
        self.assertEqual(data["save"]["growth_events"], 1)
        self.assertEqual(data["save"]["village"]["workshop_level"], 2)


if __name__ == "__main__":
    unittest.main()
