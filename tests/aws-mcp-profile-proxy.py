"""Unit tests for the AWS MCP profile proxy launcher."""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock


SCRIPT = Path(sys.argv.pop(1))
SPEC = spec_from_file_location("aws_mcp_profile_proxy", SCRIPT)
assert SPEC and SPEC.loader
PROXY = module_from_spec(SPEC)
SPEC.loader.exec_module(PROXY)


class ProfileDiscoveryTests(unittest.TestCase):
    def test_only_read_only_upside_profiles_with_account_ids_match(self):
        output = """\
default
ReadOnlyUpsideEngineerAccess-123456789012
ReadOnlyUpsideEngineerAccess-123456789012
ReadOnlyUpsideEngineerAccess-999999999999
ReadOnlyUpsideEngineerAccess-not-an-account
ReadOnlyUpsideEngineerAccess-123
AdministratorAccess-123456789012
"""
        self.assertEqual(
            PROXY.matching_profiles(
                output, ("ReadOnlyUpsideEngineerAccess-[0-9]" + "[0-9]" * 11,)
            ),
            [
                "ReadOnlyUpsideEngineerAccess-123456789012",
                "ReadOnlyUpsideEngineerAccess-999999999999",
            ],
        )

    def test_multiple_custom_globs(self):
        self.assertEqual(
            PROXY.matching_profiles(
                "dev-one\nstaging-two\nproduction-three\n",
                ("dev-*", "staging-*"),
            ),
            ["dev-one", "staging-two"],
        )

    @mock.patch.object(subprocess, "run")
    def test_discovery_uses_aws_cli(self, run):
        run.return_value.stdout = "ReadOnlyUpsideEngineerAccess-123456789012\n"
        with mock.patch.dict("os.environ", {}, clear=True):
            self.assertEqual(
                PROXY.discover_profiles("/nix/store/aws/bin/aws"),
                ["ReadOnlyUpsideEngineerAccess-123456789012"],
            )
        run.assert_called_once_with(
            ["/nix/store/aws/bin/aws", "configure", "list-profiles"],
            check=True,
            capture_output=True,
            text=True,
        )

    @mock.patch.object(subprocess, "run")
    def test_discovery_fails_without_matching_profiles(self, run):
        run.return_value.stdout = "default\ndev\n"
        with mock.patch.dict("os.environ", {}, clear=True):
            with self.assertRaisesRegex(SystemExit, "no AWS profiles match"):
                PROXY.discover_profiles("aws")

    @mock.patch.object(subprocess, "run")
    def test_discovery_uses_patterns_from_environment(self, run):
        run.return_value.stdout = "dev-one\nstaging-two\nproduction-three\n"
        with mock.patch.dict(
            "os.environ", {"AWS_MCP_PROFILE_PATTERNS": "dev-* staging-*"}, clear=True
        ):
            self.assertEqual(
                PROXY.discover_profiles("aws"), ["dev-one", "staging-two"]
            )


class ExplicitProfileTests(unittest.TestCase):
    authenticated_tools = {"aws___call_aws", "aws___run_script"}

    def test_authenticated_call_requires_profile(self):
        self.assertTrue(
            PROXY.profile_is_required(
                "aws___call_aws",
                {"command": "sts get-caller-identity"},
                self.authenticated_tools,
            )
        )

    def test_authenticated_call_with_profile_is_allowed(self):
        self.assertFalse(
            PROXY.profile_is_required(
                "aws___call_aws",
                {"aws_profile": "ReadOnlyUpsideEngineerAccess-123456789012"},
                self.authenticated_tools,
            )
        )

    def test_unauthenticated_call_does_not_require_profile(self):
        self.assertFalse(
            PROXY.profile_is_required(
                "aws___search_documentation", {}, self.authenticated_tools
            )
        )


if __name__ == "__main__":
    unittest.main()
