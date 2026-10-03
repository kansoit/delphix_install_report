#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE=""
OUTPUT_FILE=""
TEMPLATE_FILE=""

if [[ $# -eq 0 ]]; then
  cat <<'EOF'
Usage: ./cc_install_report_render.sh [options]
  -i, --input FILE.json         Normalized input JSON (required).
  -o, --output FILE.md          Markdown output (required).
  -t, --template FILE.md        Report template (required).

Example:
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
Usage: ./cc_install_report_render.sh [options]
  -i, --input FILE.json         Normalized input JSON (required).
  -o, --output FILE.md          Markdown output (required).
  -t, --template FILE.md        Report template (required).

Example:
  ./cc_install_report_render.sh -i ACME_Corp_20261003-115138.json \
    -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" -t "cc_install_report_sp.md"
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "${DATA_FILE}" ]] || { echo "ERROR: -i/--input is required." >&2; exit 1; }
[[ -n "${OUTPUT_FILE}" ]] || { echo "ERROR: -o/--output is required." >&2; exit 1; }
[[ -n "${TEMPLATE_FILE}" ]] || { echo "ERROR: -t/--template is required." >&2; exit 1; }
[[ -f "${DATA_FILE}" ]] || { echo "ERROR: JSON file not found: ${DATA_FILE}" >&2; exit 1; }
[[ -f "${TEMPLATE_FILE}" ]] || { echo "ERROR: template not found: ${TEMPLATE_FILE}" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is not installed." >&2; exit 1; }
command -v knap >/dev/null || { echo "ERROR: knap is not installed." >&2; exit 1; }
jq -e . "${DATA_FILE}" >/dev/null || { echo "ERROR: invalid JSON: ${DATA_FILE}" >&2; exit 1; }

CLIENT_NAME="$(jq -r '.client // "Cliente"' "${DATA_FILE}")"
if [[ -z "${OUTPUT_FILE}" ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${CLIENT_NAME} - Delphix Continuous Compliance Configuration Report.md"
elif [[ "${OUTPUT_FILE}" != /* && "${OUTPUT_FILE}" != ./* && "${OUTPUT_FILE}" != ../* ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${OUTPUT_FILE}"
fi
mkdir -p "$(dirname "${OUTPUT_FILE}")"

knap validate "${TEMPLATE_FILE}"
knap render "${TEMPLATE_FILE}" --data "${DATA_FILE}" -o "${OUTPUT_FILE}"
printf '\n' >> "${OUTPUT_FILE}"
printf '[+] Markdown report generated at: %s\n' "${OUTPUT_FILE}"
