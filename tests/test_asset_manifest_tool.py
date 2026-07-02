import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "validate_asset_manifest.py"
MANIFEST = ROOT / "assets" / "asset_manifest.json"
PROTOTYPE_MANIFEST = ROOT / "assets" / "asset_manifest_prototype.json"


class AssetManifestToolTests(unittest.TestCase):
    def test_default_manifest_is_valid(self):
        result = subprocess.run(
            [sys.executable, str(TOOL)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertIn("OK: asset_manifest valid.", result.stdout)
        self.assertIn("mode=placeholder", result.stdout)

    def test_json_output_reports_placeholder_mode(self):
        result = subprocess.run(
            [sys.executable, str(TOOL), "--json"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
        data = json.loads(result.stdout)
        self.assertEqual(data["mode"], "placeholder")
        self.assertEqual(data["errors"], [])
        self.assertEqual(data["references"]["missing"], 0)
        self.assertGreater(data["references"]["placeholder_files"], 0)
        self.assertEqual(data["references"]["production_files"], 0)

    def test_require_production_fails_until_manifest_uses_production_assets(self):
        result = subprocess.run(
            [sys.executable, str(TOOL), "--require-production"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("assets/placeholders", result.stderr)
        self.assertIn("requires manifest mode to be production", result.stderr)

    def test_prototype_manifest_schema_is_valid(self):
        # 外部アセットはコミットされないため、clean clone では「ファイル未配置」エラーのみ許容する。
        # アセット配置済み環境では errors が空になる。どちらの状態でも green になることを検証する。
        result = subprocess.run(
            [sys.executable, str(TOOL), "--manifest", str(PROTOTYPE_MANIFEST), "--json"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        data = json.loads(result.stdout)
        self.assertEqual(data["mode"], "production")
        for error in data["errors"]:
            self.assertIn("does not exist", error, f"unexpected schema error: {error}")

    def test_missing_manifest_path_is_reported(self):
        manifest = json.loads(MANIFEST.read_text())
        manifest["tiles"]["grass"] = "res://assets/placeholders/tiles/missing_grass.svg"

        with tempfile.TemporaryDirectory() as tmp:
            temp_manifest = Path(tmp) / "asset_manifest.json"
            temp_manifest.write_text(json.dumps(manifest), encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(TOOL), "--manifest", str(temp_manifest)],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing_grass.svg", result.stderr)


if __name__ == "__main__":
    unittest.main()
