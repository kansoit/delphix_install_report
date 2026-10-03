#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE=""
OUTPUT_FILE=""
TEMPLATE_FILE="${SCRIPT_DIR}/cc_install_report_sp.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--data|--input) DATA_FILE="$2"; shift 2 ;;
    -o|--output|--output-file) OUTPUT_FILE="$2"; shift 2 ;;
    -t|--template) TEMPLATE_FILE="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: $0 [opciones]"
      echo "  -d, --data ARCHIVO.json       JSON normalizado de entrada."
      echo "  -o, --output ARCHIVO.md       Markdown de salida."
      echo "  -t, --template ARCHIVO.md     Plantilla de informe."
      exit 0
      ;;
    *) echo "Opción desconocida: $1" >&2; exit 1 ;;
  esac
done

[[ -n "${DATA_FILE}" ]] || { echo "ERROR: debe indicar el JSON con -d/--data." >&2; exit 1; }
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
