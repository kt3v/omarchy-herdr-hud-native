import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("inotifywait") and shutil.which("flock"), "watcher dependencies required")
class DevWatchTests(unittest.TestCase):
    def test_save_burst_restarts_once_and_rejects_duplicate_watcher(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binaries = root / "bin"
            binaries.mkdir()
            watcher = binaries / "dev-watch"
            shutil.copy2(ROOT / "bin/dev-watch", watcher)
            calls = root / "calls"
            for name, body in {
                "omarchy-shell": "exit 0",
                "omarchy": 'printf "%s\\n" "$*" >> "$WATCH_CALLS"',
            }.items():
                executable = binaries / name
                executable.write_text("#!/bin/bash\n" + body + "\n")
                executable.chmod(0o755)
            env = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"], WATCH_CALLS=str(calls))
            with (root / "output").open("w+") as output:
                process = subprocess.Popen([str(watcher)], env=env, stdout=output, stderr=output)
                try:
                    time.sleep(0.3)
                    self.assertIsNone(process.poll())
                    duplicate = subprocess.run([str(watcher)], env=env, capture_output=True, text=True, timeout=3)
                    self.assertNotEqual(duplicate.returncode, 0)
                    self.assertIn("already running", duplicate.stderr)
                    (root / "note.txt").write_text("ignored")
                    time.sleep(0.7)
                    self.assertFalse(calls.exists())
                    for name in ("Panel.qml", "Helper.js", "manifest.json", "qmldir"):
                        (root / name).write_text("changed")
                    deadline = time.monotonic() + 4
                    while not calls.exists() and time.monotonic() < deadline:
                        time.sleep(0.05)
                    self.assertTrue(calls.exists())
                    time.sleep(0.7)
                    self.assertEqual(calls.read_text().splitlines(), ["restart shell"])
                finally:
                    process.terminate()
                    process.wait(timeout=4)
