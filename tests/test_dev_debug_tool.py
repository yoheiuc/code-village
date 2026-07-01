import json
import shutil
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEV_DEBUG = ROOT / "tools" / "dev_debug.py"


class DevDebugToolTests(unittest.TestCase):
    def test_list_outputs_expected_checks(self):
        result = subprocess.run(
            [sys.executable, str(DEV_DEBUG), "--list"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )

        checks = set(result.stdout.splitlines())
        self.assertIn("python syntax", checks)
        self.assertIn("temporary inbox import probe", checks)
        self.assertIn("macOS debug export smoke", checks)

    def test_skip_godot_json_uses_temporary_paths_and_keep_temp(self):
        result = subprocess.run(
            [sys.executable, str(DEV_DEBUG), "--skip-godot", "--json", "--keep-temp"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
            timeout=60,
        )
        report = json.loads(result.stdout)
        temp_root = Path(report["temporary_root"])
        try:
            self.assertTrue(report["ok"])
            self.assertTrue(report["temporary_root_kept"])
            self.assertTrue(temp_root.exists())
            self.assertFalse(report["real_user_save_touched"])
            self.assertFalse(report["real_user_inbox_touched"])
            probe = next(check for check in report["checks"] if check["name"] == "temporary inbox import probe")
            self.assertEqual(probe["status"], "passed")
            self.assertIn("save_import=skipped", probe["detail"])
        finally:
            shutil.rmtree(temp_root, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
