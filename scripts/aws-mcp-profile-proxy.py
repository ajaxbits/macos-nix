"""Start the AWS MCP proxy with explicitly selected, read-only AWS profiles."""

from __future__ import annotations

import fnmatch
import os
import subprocess
import sys
from pathlib import Path

ENDPOINT = "https://aws-mcp.us-east-1.api.aws/mcp"
DEFAULT_PROFILE_PATTERNS = ("ReadOnlyUpsideEngineerAccess-*",)
PROXY_PACKAGE = "mcp-proxy-for-aws-cli==1.7.0"
AWS = "@aws@"
UV = "@uv@"

def matching_profiles(output: str, patterns: tuple[str, ...]) -> list[str]:
    """Return unique matching profiles in a deterministic order."""
    return sorted(
        {
            profile.strip()
            for profile in output.splitlines()
            if any(fnmatch.fnmatchcase(profile.strip(), pattern) for pattern in patterns)
        }
    )

def discover_profiles(aws: str) -> list[str]:
    patterns = tuple(os.environ.get("AWS_MCP_PROFILE_PATTERNS", "").split())
    patterns = patterns or DEFAULT_PROFILE_PATTERNS
    result = subprocess.run(
        [aws, "configure", "list-profiles"],
        check=True,
        capture_output=True,
        text=True,
    )
    profiles = matching_profiles(result.stdout, patterns)
    if not profiles:
        raise SystemExit(
            "aws-mcp-profile-proxy: no AWS profiles match: " + " ".join(patterns)
        )
    return profiles

def profile_is_required(tool_name: str, arguments: object, authenticated_tools: set[str]) -> bool:
    """Whether an authenticated tool call omitted an explicit profile."""
    return tool_name in authenticated_tools and not (isinstance(arguments, dict) and arguments.get("aws_profile"))

def install_explicit_profile_middleware() -> None:
    """Add explicit-profile policy without replacing upstream routing logic."""
    from fastmcp.exceptions import ToolError  # type: ignore[import-not-found]
    from mcp_proxy_for_aws import server  # type: ignore[import-not-found]
    from mcp_proxy_for_aws.middleware.profile_switcher import (  # type: ignore[import-not-found]
        ProfileOverrideMiddleware,
    )

    original_call = ProfileOverrideMiddleware.on_call_tool

    async def on_call_tool(self, context, call_next):
        if profile_is_required(
            context.message.name,
            context.message.arguments,
            ProfileOverrideMiddleware.AUTH_REQUIRING_TOOLS,
        ):
            raise ToolError("An explicit aws_profile is required for every authenticated AWS tool call.")
        return await original_call(self, context, call_next)

    ProfileOverrideMiddleware.on_call_tool = on_call_tool

    original_add = server.add_profile_override_middleware

    def add_profile_override_middleware(mcp, profiles, *args, **kwargs):
        # Upstream only installs its switcher for two or more profiles. Repeating
        # a sole profile gets the same one-value allowlist while retaining all
        # upstream construction and routing behavior.
        if len(profiles) == 1:
            profiles = profiles * 2
        return original_add(mcp, profiles, *args, **kwargs)

    server.add_profile_override_middleware = add_profile_override_middleware

def run_server(arguments: list[str]) -> None:
    install_explicit_profile_middleware()
    from mcp_proxy_for_aws.server import main  # type: ignore[import-not-found]

    sys.argv = ["aws-mcp-profile-proxy", ENDPOINT, "--region", "us-east-1", *arguments]
    raise SystemExit(main())

def launch(arguments: list[str]) -> None:
    profiles = discover_profiles(AWS)

    environment = os.environ.copy()
    # The first profile is used only to establish the upstream MCP connection.
    # The middleware above still rejects every authenticated call that omits
    # aws_profile, including calls intended for this startup profile.
    environment["AWS_MCP_PROXY_PROFILES"] = " ".join(profiles)
    os.execve(
        UV,
        [
            UV,
            "run",
            "--quiet",
            "--no-project",
            "--with",
            PROXY_PACKAGE,
            "python",
            str(Path(__file__).resolve()),
            "--serve",
            *arguments,
        ],
        environment,
    )

if __name__ == "__main__":
    if sys.argv[1:2] == ["--serve"]:
        run_server(sys.argv[2:])
    else:
        launch(sys.argv[1:])
