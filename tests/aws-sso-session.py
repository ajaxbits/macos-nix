"""Exercise the activation helper against isolated AWS config files."""

import configparser
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = sys.argv.pop(1)


class SeedSessionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.config = Path(self.directory.name) / ".aws" / "config"

    def run_seed(self, success=True):
        result = subprocess.run(
            [sys.executable, SCRIPT, str(self.config)], capture_output=True
        )
        self.assertEqual(result.returncode == 0, success, result.stderr.decode())

    def write_config(self, contents):
        self.config.parent.mkdir()
        self.config.write_bytes(contents)

    def test_new_config_and_repeated_activation(self):
        self.run_seed()
        parsed = configparser.RawConfigParser()
        parsed.read(self.config)
        self.assertEqual(dict(parsed["sso-session upside"]), {
            "sso_start_url": "https://upside-services.awsapps.com/start",
            "sso_region": "us-east-1",
            "sso_registration_scopes": "sso:account:access",
        })
        self.assertEqual(self.config.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.config.parent.stat().st_mode & 0o777, 0o700)
        original = self.config.read_bytes()
        modified = self.config.stat().st_mtime_ns
        self.run_seed()
        self.assertEqual(self.config.read_bytes(), original)
        self.assertEqual(self.config.stat().st_mtime_ns, modified)

    def test_existing_profiles_preserved_without_final_newline(self):
        original = b"# Keep this comment\r\n[profile dev]\r\nregion = eu-west-1"
        self.write_config(original)
        self.config.chmod(0o640)
        self.run_seed()
        self.assertTrue(self.config.read_bytes().startswith(original + b"\n"))
        self.assertEqual(self.config.stat().st_mode & 0o777, 0o640)
        parsed = configparser.RawConfigParser()
        parsed.read(self.config)
        self.assertEqual(parsed["profile dev"]["region"], "eu-west-1")

    def test_existing_session_is_not_updated(self):
        original = b"[sso-session upside]\nsso_region = eu-west-1\n"
        self.write_config(original)
        self.run_seed()
        self.assertEqual(self.config.read_bytes(), original)

    def test_malformed_config_is_not_modified(self):
        original = b"not an INI file\n"
        self.write_config(original)
        self.run_seed(success=False)
        self.assertEqual(self.config.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
