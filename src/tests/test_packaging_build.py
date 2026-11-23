import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
import unittest


SOURCE_DIR = Path(__file__).resolve().parents[1]


class PackagingBuildTests(unittest.TestCase):
    def test_packaging_helpers_can_create_inventory(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = root / "SoyaComfy"
            (payload / "src").mkdir(parents=True)
            (payload / "src" / "server.py").write_text("print('ok')\n", encoding="utf-8")

            for name in (
                "update_payload.py",
                "update_policy.py",
                "preset_locations.py",
                "app_paths.py",
            ):
                source = SOURCE_DIR / "packaging/macos/update_payload.py" if name == "update_payload.py" else SOURCE_DIR / name
                shutil.copy2(source, root / name)

            result = subprocess.run(
                [sys.executable, root / "update_payload.py", payload],
                cwd=root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((payload / ".soya-app-files.json").is_file())
