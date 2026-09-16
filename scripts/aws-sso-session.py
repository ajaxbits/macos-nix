"""Seed the company SSO session without rewriting existing AWS configuration."""

import configparser
import os
from pathlib import Path
import sys


def seed(path: Path) -> None:
    # New config files can later contain sensitive settings. Existing file
    # permissions and contents are preserved, including comments and line endings.
    os.umask(0o077)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+", encoding="utf-8", newline="") as config:
        config.seek(0)
        contents = config.read()
        parsed = configparser.RawConfigParser()
        parsed.read_string(contents)
        if parsed.has_section("sso-session upside"):
            return

        if contents and not contents.endswith("\n"):
            config.write("\n")
        config.write(
            "\n[sso-session upside]\n"
            "sso_start_url = https://upside-services.awsapps.com/start\n"
            "sso_region = us-east-1\n"
            "sso_registration_scopes = sso:account:access\n"
        )


if __name__ == "__main__":
    seed(Path(sys.argv[1]))
