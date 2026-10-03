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
Usage: ./cc_install_report.sh [options]
  -c, --client CLIENT                   Client name (required).
  -p, --prefix PREFIX                   Filter prefix (required).
  -o, --output FILE.md                  Markdown output (required).
  -t, --template FILE.md                Report template (required).
  -s, --profile-set NAME                Profile Set; may be repeated.

Example:
  ./cc_install_report.sh \
    -c "ACME Corp" \
    -p "0-" \
    -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
    -t cc_install_report_sp.md \
    -s "ASDD Spanish"
EOF
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client) FETCH_ARGS+=("$1" "$2"); CLIENT_SET=true; shift 2 ;;
    -p|--prefix) FETCH_ARGS+=("$1" "$2"); PREFIX_SET=true; shift 2 ;;
    -s|--profile-set) FETCH_ARGS+=("$1" "$2"); PROFILE_SET_SET=true; shift 2 ;;
    -t|--template) TEMPLATE_FILE="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./cc_install_report.sh [options]
  -c, --client CLIENT                   Client name (required).
  -p, --prefix PREFIX                   Filter prefix (required).
  -o, --output FILE.md                  Markdown output (required).
  -t, --template FILE.md                Report template (required).
  -s, --profile-set NAME                Profile Set; may be repeated.

Example:
  ./cc_install_report.sh \
    -c "ACME Corp" \
    -p "0-" \
    -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
    -t cc_install_report_sp.md \
    -s "ASDD Spanish"
EOF
      exit 0
      ;;
    -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
    *) FETCH_ARGS+=("$1"); shift ;;
  esac
done

[[ "${CLIENT_SET}" == true ]] || { echo "ERROR: --client is required." >&2; exit 1; }
[[ "${PREFIX_SET}" == true ]] || { echo "ERROR: --prefix is required." >&2; exit 1; }
[[ "${PROFILE_SET_SET}" == true ]] || { echo "ERROR: --profile-set is required." >&2; exit 1; }
[[ -n "${OUTPUT_FILE}" ]] || { echo "ERROR: --output is required." >&2; exit 1; }
[[ -n "${TEMPLATE_FILE}" ]] || { echo "ERROR: --template is required." >&2; exit 1; }

DATA_FILE="$(mktemp --suffix=.report-data.json)"
trap 'rm -f "${DATA_FILE}"' EXIT

"${FETCH_SCRIPT}" "${FETCH_ARGS[@]}" --output "${DATA_FILE}"

RENDER_ARGS=(-i "${DATA_FILE}" -t "${TEMPLATE_FILE}" -o "${OUTPUT_FILE}")
"${RENDER_SCRIPT}" "${RENDER_ARGS[@]}"
