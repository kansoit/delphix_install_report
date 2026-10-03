#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_SCRIPT="${SCRIPT_DIR}/cc_install_report_fetch.py"
RENDER_SCRIPT="${SCRIPT_DIR}/cc_install_report_render.py"
OUTPUT_FILE=""
FETCH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      echo "Uso: $0 [opciones]"
      echo "  -c, --client CLIENTE                  Nombre del cliente."
      echo "  -p, --prefix PREFIJO                  Prefijo de filtrado."
      echo "  -o, --output ARCHIVO.md                Markdown de salida."
      echo "      --profile-set NOMBRE              Profile Set; puede repetirse."
      echo "      --profile-sets NOMBRE1,NOMBRE2   Profile Sets separados por comas."
      echo "  Ejecuta fetcher y renderer en una sola operación."
      exit 0
      ;;
    -o|--output|--output-file) OUTPUT_FILE="$2"; shift 2 ;;
    *) FETCH_ARGS+=("$1"); shift ;;
  esac
done

DATA_FILE="$(mktemp --suffix=.report-data.json)"
trap 'rm -f "${DATA_FILE}"' EXIT

"${FETCH_SCRIPT}" "${FETCH_ARGS[@]}" --data-output "${DATA_FILE}"

RENDER_ARGS=(-d "${DATA_FILE}")
[[ -n "${OUTPUT_FILE}" ]] && RENDER_ARGS+=(-o "${OUTPUT_FILE}")
"${RENDER_SCRIPT}" "${RENDER_ARGS[@]}"
