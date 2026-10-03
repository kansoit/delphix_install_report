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
        description="Recolecta datos desde DCT y genera el reporte Markdown."
    )
    parser.add_argument("-c", "--client", "--client-name", default="Cliente")
    parser.add_argument("-p", "--prefix", default="0-")
    parser.add_argument("-o", "--output", "--output-file", dest="output_file")
    parser.add_argument("--profile-set", action="append", dest="profile_sets")
    parser.add_argument("--profile-sets", dest="profile_sets_csv")
    parser.add_argument("--page-size", type=int)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    fetch_args = ["--client", args.client, "--prefix", args.prefix]

    for profile_set in args.profile_sets or []:
        fetch_args.extend(["--profile-set", profile_set])
    if args.profile_sets_csv is not None:
        fetch_args.extend(["--profile-sets", args.profile_sets_csv])
    if args.page_size is not None:
        fetch_args.extend(["--page-size", str(args.page_size)])

    try:
        with tempfile.NamedTemporaryFile(
            prefix="cc-install-", suffix=".report-data.json", delete=True
        ) as temporary_data:
            temporary_data_path = Path(temporary_data.name)
            subprocess.run(
                [str(FETCH_SCRIPT), *fetch_args, "--data-output", str(temporary_data_path)],
                check=True,
            )

            render_args = [str(RENDER_SCRIPT), "--data", str(temporary_data_path)]
            if args.output_file is not None:
                render_args.extend(["--output", args.output_file])
            subprocess.run(render_args, check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: no se pudo generar el reporte: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
