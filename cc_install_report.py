#!/usr/bin/env python3
"""Run the Python fetcher and renderer as one report command."""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
FETCH_SCRIPT = SCRIPT_DIR / "cc_install_report_fetch.py"
RENDER_SCRIPT = SCRIPT_DIR / "cc_install_report_render.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collects data from DCT and generates the Markdown report.",
        epilog=(
            "Example:\n"
            "  ./cc_install_report.py \\\n"
            "    -c \"ACME Corp\" \\\n"
            "    -p \"0-\" \\\n"
            "    -o \"ACME_Corp_$(date +%Y%m%d-%H%M%S).md\" \\\n"
            "    -t cc_install_report_sp.md \\\n"
            "    -s \"ASDD Spanish\""
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-c", "--client", required=True)
    parser.add_argument("-p", "--prefix", required=True)
    parser.add_argument("-o", "--output", dest="output_file", metavar="MARKDOWN_FILE", required=True)
    parser.add_argument("-t", "--template", required=True)
    parser.add_argument("-s", "--profile-set", action="append", dest="profile_sets", metavar="PROFILE_SET", required=True)
    if len(sys.argv) == 1:
        parser.print_help()
        raise SystemExit(0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    fetch_args = ["--client", args.client, "--prefix", args.prefix]

    for profile_set in args.profile_sets or []:
        fetch_args.extend(["--profile-set", profile_set])
    try:
        with tempfile.NamedTemporaryFile(
            prefix="cc-install-", suffix=".report-data.json", delete=True
        ) as temporary_data:
            temporary_data_path = Path(temporary_data.name)
            subprocess.run(
                [str(FETCH_SCRIPT), *fetch_args, "--output", str(temporary_data_path)],
                check=True,
            )

            render_args = [
                str(RENDER_SCRIPT),
                "--input", str(temporary_data_path),
                "--template", args.template,
                "--output", args.output_file,
            ]
            subprocess.run(render_args, check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: could not generate the report: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
