#!/usr/bin/env python3
"""Render a normalized Delphix report JSON through a Knap template."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_TEMPLATE = SCRIPT_DIR / "cc_install_report_sp.md"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render a normalized report with Knap.")
    parser.add_argument("-d", "--data", "--input", dest="data_file", required=True)
    parser.add_argument("-o", "--output", "--output-file", dest="output_file")
    parser.add_argument("-t", "--template", default=str(DEFAULT_TEMPLATE))
    return parser.parse_args()


def resolve_output(path: str | None, client: str) -> Path:
    if not path:
        return SCRIPT_DIR / f"{client} - Reporte Configuracion Delphix Continuous Compliance.md"
    output = Path(path)
    if not output.is_absolute() and not path.startswith("./") and not path.startswith("../"):
        output = SCRIPT_DIR / output
    return output


def main() -> int:
    args = parse_args()
    data_file = Path(args.data_file)
    template_file = Path(args.template)

    if not data_file.is_file():
        print(f"ERROR: JSON no encontrado: {data_file}", file=sys.stderr)
        return 1
    if not template_file.is_file():
        print(f"ERROR: plantilla no encontrada: {template_file}", file=sys.stderr)
        return 1
    if shutil.which("knap") is None:
        print("ERROR: knap no está instalado.", file=sys.stderr)
        return 1

    try:
        with data_file.open(encoding="utf-8") as handle:
            data = json.load(handle)
        if not isinstance(data, dict):
            raise ValueError("el JSON raíz debe ser un objeto")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"ERROR: JSON inválido: {data_file}: {exc}", file=sys.stderr)
        return 1

    client = data.get("client") or "Cliente"
    output_file = resolve_output(args.output_file, str(client))
    output_file.parent.mkdir(parents=True, exist_ok=True)

    try:
        subprocess.run(["knap", "validate", str(template_file)], check=True)
        subprocess.run(
            ["knap", "render", str(template_file), "--data", str(data_file), "-o", str(output_file)],
            check=True,
        )
        with output_file.open("a", encoding="utf-8") as handle:
            handle.write("\n")
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: no se pudo generar el reporte: {exc}", file=sys.stderr)
        return 1

    print(f"[+] Reporte Markdown generado en: {output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
