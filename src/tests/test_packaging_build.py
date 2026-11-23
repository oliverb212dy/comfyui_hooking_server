import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
import unittest


SOURCE_DIR = Path(__file__).resolve().parents[1]


class PackagingBuildTests(unittest.TestCase):
    def copy_helpers(self, root: Path) -> None:
        for name in (
            "update_payload.py",
            "update_policy.py",
            "preset_locations.py",
            "app_paths.py",
        ):
            source = SOURCE_DIR / "packaging/macos/update_payload.py" if name == "update_payload.py" else SOURCE_DIR / name
            shutil.copy2(source, root / name)

    def test_packaging_helpers_exclude_python_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = root / "SoyaComfy"
            (payload / "src" / "__pycache__").mkdir(parents=True)
            (payload / "src" / "server.py").write_text("print('ok')\n", encoding="utf-8")
            (payload / "src" / "__pycache__" / "app_paths.cpython-312.pyc").write_bytes(b"cache")

            self.copy_helpers(root)

            result = subprocess.run(
                [sys.executable, root / "update_payload.py", payload],
                cwd=root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            inventory = json.loads((payload / ".soya-app-files.json").read_text(encoding="utf-8"))
            self.assertIn("src/server.py", inventory)
            self.assertNotIn("src/__pycache__/app_paths.cpython-312.pyc", inventory)

    def test_update_ignores_stale_cache_entries(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = root / "payload"
            destination = root / "destination"
            (payload / "src").mkdir(parents=True)
            (destination / "src" / "__pycache__").mkdir(parents=True)
            (payload / "src" / "server.py").write_text("print('ok')\n", encoding="utf-8")
            (destination / "src" / "__pycache__" / "app_paths.cpython-312.pyc").write_bytes(b"cache")

            self.copy_helpers(root)

            inventory_result = subprocess.run(
                [sys.executable, root / "update_payload.py", payload],
                cwd=root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(inventory_result.returncode, 0, inventory_result.stderr)

            stale_inventory = json.loads((payload / ".soya-app-files.json").read_text(encoding="utf-8"))
            stale_inventory["__pycache__/app_paths.cpython-312.pyc"] = "stale"
            (payload / ".soya-app-files.json").write_text(
                json.dumps(stale_inventory), encoding="utf-8"
            )

            update_result = subprocess.run(
                [sys.executable, root / "update_payload.py", payload, destination],
                cwd=root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(update_result.returncode, 0, update_result.stderr)
            self.assertFalse((destination / "src" / "__pycache__").exists())
