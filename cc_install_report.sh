#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_SCRIPT="${SCRIPT_DIR}/cc_install_report_fetch.py"
RENDER_SCRIPT="${SCRIPT_DIR}/cc_install_report_render.py"
OUTPUT_FILE=""
TEMPLATE_FILE=""
FETCH_ARGS=()
CLIENT_SET=false
PREFIX_SET=false
PROFILE_SET_SET=false

if [[ $# -eq 0 ]]; then
  cat <<'EOF'
Uso: ./cc_install_report.sh [opciones]
  -c, --client CLIENTE                  Nombre del cliente (requerido).
  -p, --prefix PREFIJO                  Prefijo de filtrado (requerido).
  -o, --output ARCHIVO.md               Markdown de salida (requerido).
  -t, --template ARCHIVO.md             Plantilla de informe (requerida).
  -s, --profile-set NOMBRE              Profile Set; puede repetirse.

Ejemplo:
  ./cc_install_report.sh -c "Demo Client" -p "0-" \
    --profile-set "ASDD Spanish" -t cc_install_report_sp.md \
    -o report-data/demo-client.md
EOF
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client|--client-name) FETCH_ARGS+=("$1" "$2"); CLIENT_SET=true; shift 2 ;;
    -p|--prefix) FETCH_ARGS+=("$1" "$2"); PREFIX_SET=true; shift 2 ;;
    -s|--profile-set) FETCH_ARGS+=("$1" "$2"); PROFILE_SET_SET=true; shift 2 ;;
    -t|--template) TEMPLATE_FILE="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Uso: ./cc_install_report.sh [opciones]
  -c, --client CLIENTE                  Nombre del cliente (requerido).
  -p, --prefix PREFIJO                  Prefijo de filtrado (requerido).
  -o, --output ARCHIVO.md               Markdown de salida (requerido).
  -t, --template ARCHIVO.md             Plantilla de informe (requerida).
  -s, --profile-set NOMBRE              Profile Set; puede repetirse.

Ejemplo:
  ./cc_install_report.sh -c "Demo Client" -p "0-" \
    --profile-set "ASDD Spanish" -t cc_install_report_sp.md \
    -o report-data/demo-client.md
EOF
      exit 0
      ;;
    -o|--output|--output-file) OUTPUT_FILE="$2"; shift 2 ;;
    *) FETCH_ARGS+=("$1"); shift ;;
  esac
done

[[ "${CLIENT_SET}" == true ]] || { echo "ERROR: debe indicar --client." >&2; exit 1; }
[[ "${PREFIX_SET}" == true ]] || { echo "ERROR: debe indicar --prefix." >&2; exit 1; }
[[ "${PROFILE_SET_SET}" == true ]] || { echo "ERROR: debe indicar --profile-set." >&2; exit 1; }
[[ -n "${OUTPUT_FILE}" ]] || { echo "ERROR: debe indicar --output." >&2; exit 1; }
[[ -n "${TEMPLATE_FILE}" ]] || { echo "ERROR: debe indicar --template." >&2; exit 1; }

DATA_FILE="$(mktemp --suffix=.report-data.json)"
trap 'rm -f "${DATA_FILE}"' EXIT

"${FETCH_SCRIPT}" "${FETCH_ARGS[@]}" --data-output "${DATA_FILE}"

RENDER_ARGS=(-d "${DATA_FILE}" -t "${TEMPLATE_FILE}" -o "${OUTPUT_FILE}")
"${RENDER_SCRIPT}" "${RENDER_ARGS[@]}"
