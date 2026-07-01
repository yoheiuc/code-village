import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "code_village_event.py"
SELF_TEST = ROOT / "tools" / "claude_hook_self_test.py"
CLAUDE_SETTINGS = ROOT / ".claude" / "settings.json"


class CodeVillageEventToolTests(unittest.TestCase):
    def test_dry_run_sanitizes_stdin_json(self):
        payload = {
            "session_id": "raw-session-secret",
            "hook_event": "Stop",
            "cwd": "/Users/example/private-project",
            "prompt": "do not store this prompt",
            "response": "do not store this response",
        }
        result = subprocess.run(
            [sys.executable, str(TOOL), "--stdin-json", "--dry-run"],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        event = json.loads(result.stdout)
        encoded = json.dumps(event, ensure_ascii=False)
        self.assertEqual(event["type"], "claude_code_session")
        self.assertEqual(event["source"], "claude_code_hook")
        self.assertEqual(event["privacy_level"], "metadata_only")
        self.assertIn("session_hash", event["metadata"])
        self.assertIn("private-project", encoded)
        self.assertNotIn("/Users/example/private-project", encoded)
        self.assertNotIn("raw-session-secret", encoded)
        self.assertNotIn("do not store this prompt", encoded)
        self.assertNotIn("do not store this response", encoded)

    def test_repo_claude_hook_settings_are_local_only(self):
        settings = json.loads(CLAUDE_SETTINGS.read_text())
        hooks = settings["hooks"]
        self.assertIn("SessionStart", hooks)
        self.assertIn("Stop", hooks)
        encoded = json.dumps(settings)
        self.assertIn("tools/code_village_event.py", encoded)
        self.assertIn("--stdin-json", encoded)
        self.assertIn("claude_code_session", encoded)
        self.assertIn("claude_code_turn_completed", encoded)
        self.assertNotIn("curl", encoded)
        self.assertNotIn("http://", encoded)
        self.assertNotIn("https://", encoded)

    def test_project_label_argument_does_not_store_raw_path(self):
        result = subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "--dry-run",
                "--project-label",
                "/Users/example/private-project",
            ],
            text=True,
            capture_output=True,
            check=True,
        )
        event = json.loads(result.stdout)
        encoded = json.dumps(event, ensure_ascii=False)
        self.assertIn("private-project", encoded)
        self.assertNotIn("/Users/example/private-project", encoded)

    def test_godot_startup_imports_claude_inbox_without_git(self):
        if shutil.which("godot") is None:
            self.skipTest("Godot CLI is not installed")

        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "claude_events.jsonl"
            save_path = tmp_dir / "code_village_save.json"
            payload = {
                "session_id": "raw-startup-session-secret",
                "cwd": str(ROOT),
                "prompt": "do not store startup prompt",
                "response": "do not store startup response",
            }

            for event_type in ("claude_code_session", "claude_code_turn_completed"):
                subprocess.run(
                    [
                        sys.executable,
                        str(TOOL),
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

            env = os.environ.copy()
            env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox)
            env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
            result = subprocess.run(
                ["godot", "--headless", "--path", ".", "--quit-after", "1"],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=True,
                timeout=20,
            )

            self.assertTrue(save_path.exists(), result.stdout + result.stderr)
            data = json.loads(save_path.read_text())
            village = data["village_state"]
            self.assertEqual(data["repositories"], [])
            self.assertEqual(len(data["activity_events"]), 2)
            self.assertGreaterEqual(village["workshop_level"], 2)
            self.assertGreaterEqual(village["flowers"], 4)

            encoded = json.dumps(data, ensure_ascii=False)
            self.assertIn("code-village", encoded)
            self.assertNotIn(str(ROOT), encoded)
            self.assertNotIn("raw-startup-session-secret", encoded)
            self.assertNotIn("do not store startup prompt", encoded)
            self.assertNotIn("do not store startup response", encoded)

    def test_godot_startup_respects_auto_import_off(self):
        if shutil.which("godot") is None:
            self.skipTest("Godot CLI is not installed")

        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "claude_events.jsonl"
            save_path = tmp_dir / "code_village_save.json"
            save_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "settings": {
                            "local_only": True,
                            "store_commit_messages": False,
                            "store_file_names": False,
                            "enable_external_network": False,
                            "show_rest_day_messages": True,
                            "auto_import_claude_events": False,
                        },
                        "repositories": [],
                        "onboarding_guide_dismissed": False,
                        "imported_activity_event_ids": [],
                        "village_state": {
                            "village_level": 1,
                            "flowers": 0,
                            "lanterns": 0,
                            "repaired_paths": 0,
                            "bridge_state": "worn",
                            "library_level": 1,
                            "workshop_level": 1,
                            "branch_tree_level": 1,
                            "release_bell_rings": 0,
                            "diary_entries": [],
                            "resident_messages": [],
                            "last_updated_at": "",
                        },
                        "activity_events": [],
                        "growth_events": [],
                    }
                ),
                encoding="utf-8",
            )
            payload = {
                "session_id": "raw-auto-off-session-secret",
                "cwd": str(ROOT),
                "prompt": "do not store auto off prompt",
                "response": "do not store auto off response",
            }

            subprocess.run(
                [
                    sys.executable,
                    str(TOOL),
                    "--stdin-json",
                    "--type",
                    "claude_code_session",
                    "--inbox",
                    str(inbox),
                ],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                check=True,
            )

            env = os.environ.copy()
            env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox)
            env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
            subprocess.run(
                ["godot", "--headless", "--path", ".", "--quit-after", "1"],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=True,
                timeout=20,
            )

            data = json.loads(save_path.read_text())
            self.assertEqual(data["settings"]["auto_import_claude_events"], False)
            self.assertEqual(data["imported_activity_event_ids"], [])
            self.assertEqual(data["activity_events"], [])
            self.assertEqual(data["growth_events"], [])
            self.assertEqual(data["village_state"]["workshop_level"], 1)

    def test_godot_startup_recovers_empty_save_file(self):
        if shutil.which("godot") is None:
            self.skipTest("Godot CLI is not installed")

        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "empty_inbox.jsonl"
            save_path = tmp_dir / "empty_save.json"
            inbox.write_text("", encoding="utf-8")
            save_path.write_text("", encoding="utf-8")

            env = os.environ.copy()
            env["CODE_VILLAGE_ACTIVITY_INBOX"] = str(inbox)
            env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
            result = subprocess.run(
                ["godot", "--headless", "--path", ".", "--quit-after", "1"],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=True,
                timeout=20,
            )

            output = result.stdout + result.stderr
            self.assertNotIn("Parse JSON failed", output)
            self.assertEqual(save_path.read_text(encoding="utf-8"), "")

    def test_repo_claude_hook_commands_write_safe_events_and_grow_village(self):
        if shutil.which("godot") is None:
            self.skipTest("Godot CLI is not installed")

        settings = json.loads(CLAUDE_SETTINGS.read_text())
        hook_commands = {
            "SessionStart": settings["hooks"]["SessionStart"][0]["hooks"][0]["command"],
            "Stop": settings["hooks"]["Stop"][0]["hooks"][0]["command"],
        }

        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            inbox = tmp_dir / "hook_events.jsonl"
            save_path = tmp_dir / "hook_save.json"
            payload = {
                "session_id": "raw-hook-session-secret",
                "cwd": "/Users/example/private-project",
                "prompt": "do not store hook prompt",
                "response": "do not store hook response",
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

            self.assertTrue(inbox.exists(), "hook commands should write the local inbox")
            events = [json.loads(line) for line in inbox.read_text().splitlines() if line.strip()]
            self.assertEqual([event["type"] for event in events], ["claude_code_session", "claude_code_turn_completed"])
            encoded_events = json.dumps(events, ensure_ascii=False)
            self.assertIn("code-village", encoded_events)
            self.assertNotIn(str(ROOT), encoded_events)
            self.assertNotIn("/Users/example/private-project", encoded_events)
            self.assertNotIn("raw-hook-session-secret", encoded_events)
            self.assertNotIn("do not store hook prompt", encoded_events)
            self.assertNotIn("do not store hook response", encoded_events)

            env["CODE_VILLAGE_SAVE_PATH"] = str(save_path)
            result = subprocess.run(
                ["godot", "--headless", "--path", ".", "--quit-after", "1"],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=True,
                timeout=20,
            )

            self.assertTrue(save_path.exists(), result.stdout + result.stderr)
            data = json.loads(save_path.read_text())
            self.assertEqual(data["repositories"], [])
            self.assertEqual(len(data["activity_events"]), 2)
            self.assertGreaterEqual(data["village_state"]["workshop_level"], 2)
            self.assertGreaterEqual(data["village_state"]["flowers"], 4)
            encoded_save = json.dumps(data, ensure_ascii=False)
            self.assertNotIn(str(ROOT), encoded_save)
            self.assertNotIn("/Users/example/private-project", encoded_save)
            self.assertNotIn("raw-hook-session-secret", encoded_save)
            self.assertNotIn("do not store hook prompt", encoded_save)
            self.assertNotIn("do not store hook response", encoded_save)

    def test_claude_hook_self_test_cli(self):
        if shutil.which("godot") is None:
            self.skipTest("Godot CLI is not installed")

        result = subprocess.run(
            [sys.executable, str(SELF_TEST)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
            timeout=30,
        )
        self.assertIn("OK: Claude Code hook self-test passed.", result.stdout)


if __name__ == "__main__":
    unittest.main()
