#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE=""
OUTPUT_FILE=""
TEMPLATE_FILE=""

if [[ $# -eq 0 ]]; then
  cat <<'EOF'
Uso: ./cc_install_report_render.sh [opciones]
  -i, --input ARCHIVO.json      JSON normalizado de entrada (requerido).
  -o, --output ARCHIVO.md       Markdown de salida (requerido).
  -t, --template ARCHIVO.md     Plantilla de informe (requerido).

Ejemplo:
  ./cc_install_report_render.sh -i ACME_Corp_20261003-115138.json \
    -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" -t "cc_install_report_sp.md"
EOF
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input) DATA_FILE="$2"; shift 2 ;;
    -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
    -t|--template) TEMPLATE_FILE="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Uso: ./cc_install_report_render.sh [opciones]
  -i, --input ARCHIVO.json      JSON normalizado de entrada (requerido).
  -o, --output ARCHIVO.md       Markdown de salida (requerido).
  -t, --template ARCHIVO.md     Plantilla de informe (requerido).

Ejemplo:
  ./cc_install_report_render.sh -i ACME_Corp_20261003-115138.json \
    -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" -t "cc_install_report_sp.md"
EOF
      exit 0
      ;;
    *) echo "Opción desconocida: $1" >&2; exit 1 ;;
  esac
done

[[ -n "${DATA_FILE}" ]] || { echo "ERROR: debe indicar el JSON con -i/--input." >&2; exit 1; }
[[ -n "${OUTPUT_FILE}" ]] || { echo "ERROR: debe indicar el Markdown con -o/--output." >&2; exit 1; }
[[ -n "${TEMPLATE_FILE}" ]] || { echo "ERROR: debe indicar la plantilla con -t/--template." >&2; exit 1; }
[[ -f "${DATA_FILE}" ]] || { echo "ERROR: JSON no encontrado: ${DATA_FILE}" >&2; exit 1; }
[[ -f "${TEMPLATE_FILE}" ]] || { echo "ERROR: plantilla no encontrada: ${TEMPLATE_FILE}" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq no está instalado." >&2; exit 1; }
command -v knap >/dev/null || { echo "ERROR: knap no está instalado." >&2; exit 1; }
jq -e . "${DATA_FILE}" >/dev/null || { echo "ERROR: JSON inválido: ${DATA_FILE}" >&2; exit 1; }

CLIENT_NAME="$(jq -r '.client // "Cliente"' "${DATA_FILE}")"
if [[ -z "${OUTPUT_FILE}" ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${CLIENT_NAME} - Reporte Configuracion Delphix Continuous Compliance.md"
elif [[ "${OUTPUT_FILE}" != /* && "${OUTPUT_FILE}" != ./* && "${OUTPUT_FILE}" != ../* ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${OUTPUT_FILE}"
fi
mkdir -p "$(dirname "${OUTPUT_FILE}")"

knap validate "${TEMPLATE_FILE}"
knap render "${TEMPLATE_FILE}" --data "${DATA_FILE}" -o "${OUTPUT_FILE}"
printf '\n' >> "${OUTPUT_FILE}"
printf '[+] Reporte Markdown generado en: %s\n' "${OUTPUT_FILE}"
