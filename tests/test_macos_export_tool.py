import importlib.util
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "verify_macos_export.py"

spec = importlib.util.spec_from_file_location("verify_macos_export", TOOL)
verify_macos_export = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["verify_macos_export"] = verify_macos_export
spec.loader.exec_module(verify_macos_export)


class MacOSExportToolTests(unittest.TestCase):
    def test_forbidden_export_entries_are_reported(self):
        entries = [
            "Code Village.app/Contents/MacOS/Code Village",
            "Code Village.app/Contents/Resources/docs/privacy.md",
            "tools/code_village_event.py",
        ]
        blocked = verify_macos_export.find_forbidden_entries(entries)
        self.assertIn("Code Village.app/Contents/Resources/docs/privacy.md", blocked)
        self.assertIn("tools/code_village_event.py", blocked)

    def test_skip_export_validates_minimal_app_zip(self):
        with tempfile.TemporaryDirectory() as tmp:
            export_zip = Path(tmp) / "CodeVillage.zip"
            with zipfile.ZipFile(export_zip, "w") as archive:
                archive.writestr("Code Village.app/", "")
                archive.writestr("Code Village.app/Contents/MacOS/Code Village", "")

            report = verify_macos_export.verify_export(
                export_zip,
                run_export=False,
                launch_app=False,
            )

        self.assertFalse(report.exported)
        self.assertTrue(report.app_binary_found)
        self.assertFalse(report.launched)
        self.assertEqual(report.forbidden_entries, [])

    def test_skip_export_rejects_docs_in_zip(self):
        with tempfile.TemporaryDirectory() as tmp:
            export_zip = Path(tmp) / "CodeVillage.zip"
            with zipfile.ZipFile(export_zip, "w") as archive:
                archive.writestr("Code Village.app/Contents/MacOS/Code Village", "")
                archive.writestr("Code Village.app/Contents/Resources/docs/privacy.md", "")

            with self.assertRaises(verify_macos_export.ExportVerificationError):
                verify_macos_export.verify_export(export_zip, run_export=False, launch_app=False)


if __name__ == "__main__":
    unittest.main()
