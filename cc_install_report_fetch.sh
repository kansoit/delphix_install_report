#!/usr/bin/env bash

set -euo pipefail

CLIENT_NAME="Cliente"
PREFIX="0-"
DATA_FILE=""
PAGE_SIZE="${DCT_PAGE_SIZE:-1000}"
DCT_TOOLKIT_BIN="${DCT_TOOLKIT_BIN:-${HOME}/.local/bin/dct-toolkit}"
# Profile Sets incluidos deliberadamente en el informe. Agregar nombres aquí
# permite ampliar el alcance sin tocar la plantilla.
PROFILE_SET_ALLOWLIST=()
PROFILE_SET_EXPLICIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client|--client-name) CLIENT_NAME="$2"; shift 2 ;;
    -p|--prefix) PREFIX="$2"; shift 2 ;;
    -o|--output|--data-output) DATA_FILE="$2"; shift 2 ;;
    --profile-set)
      PROFILE_SET_ALLOWLIST+=("$2")
      PROFILE_SET_EXPLICIT=true
      shift 2
      ;;
    --profile-sets)
      IFS=',' read -r -a PROFILE_SET_ALLOWLIST <<< "$2"
      PROFILE_SET_EXPLICIT=true
      shift 2
      ;;
    -h|--help)
      echo "Uso: $0 [opciones]"
      echo "  -c, --client CLIENTE                  Nombre del cliente."
      echo "  -p, --prefix PREFIJO                  Prefijo de filtrado."
      echo "  -o, --output ARCHIVO.json             JSON normalizado de salida."
      echo "      --profile-set NOMBRE              Profile Set; puede repetirse."
      echo "      --profile-sets NOMBRE1,NOMBRE2   Profile Sets separados por comas."
      echo "  Genera los datos normalizados para el renderer."
      exit 0
      ;;
    *) echo "Opción desconocida: $1" >&2; exit 1 ;;
  esac
done

if [[ "${PROFILE_SET_EXPLICIT}" == false ]]; then
  PROFILE_SET_ALLOWLIST=("AR - Ley 25.326 - v1" "ASDD Spanish")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${DATA_FILE}" ]]; then
  DATA_DIR="${SCRIPT_DIR}/report-data"
  mkdir -p "${DATA_DIR}"
  SAFE_CLIENT_NAME="$(printf '%s' "${CLIENT_NAME}" | tr ' /' '__' | tr -cd '[:alnum:]_.-')"
  DATA_FILE="${DATA_DIR}/${SAFE_CLIENT_NAME}-$(date '+%Y%m%d-%H%M%S').json"
elif [[ "${DATA_FILE}" != /* && "${DATA_FILE}" != ./* && "${DATA_FILE}" != ../* ]]; then
  DATA_FILE="${SCRIPT_DIR}/${DATA_FILE}"
fi

[[ -x "${DCT_TOOLKIT_BIN}" ]] || { echo "ERROR: Toolkit no encontrado: ${DCT_TOOLKIT_BIN}" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq no está instalado." >&2; exit 1; }
mkdir -p "$(dirname "${DATA_FILE}")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
printf '%s\n' "${PROFILE_SET_ALLOWLIST[@]}" | jq -R . | jq -s . > "${TMP_DIR}/profile_set_allowlist.json"

run_json_once() {
  local name="$1"
  shift
  "${DCT_TOOLKIT_BIN}" "$@" -js > "${TMP_DIR}/${name}.json"
}

# Consume todas las páginas expuestas por DCT mediante response_metadata.next_cursor.
# PAGE_SIZE solo controla el tamaño de cada consulta; nunca limita el total recuperado.
run_json_paged() {
  local name="$1"
  shift
  local output="${TMP_DIR}/${name}.json"
  local ndjson="${TMP_DIR}/${name}.ndjson"
  local cursor=""
  local next_cursor=""
  local page=0
  : > "${ndjson}"

  while :; do
    page=$((page + 1))
    if [[ -n "${cursor}" ]]; then
      raw_json=$("${DCT_TOOLKIT_BIN}" "$@" limit="${PAGE_SIZE}" cursor="${cursor}" -js)
    else
      raw_json=$("${DCT_TOOLKIT_BIN}" "$@" limit="${PAGE_SIZE}" -js)
    fi
    jq -e . >/dev/null <<<"${raw_json}"
    jq -c '.items[]?' <<<"${raw_json}" >> "${ndjson}"
    next_cursor=$(jq -r '.response_metadata.next_cursor // empty' <<<"${raw_json}")
    [[ -n "${next_cursor}" && "${next_cursor}" != "${cursor}" ]] || break
    [[ "${page}" -lt 10000 ]] || { echo "ERROR: demasiadas páginas en ${name}" >&2; return 1; }
    cursor="${next_cursor}"
  done

  jq -s '{items: .}' "${ndjson}" > "${output}"
}

printf '[+] Recolectando datos JSON desde DCT...\n'
run_json_paged engines get_registered_engines
run_json_once smtp get_smtp_config
run_json_once ldap get_ldap_config
run_json_paged algorithms get_algorithms
run_json_paged data_classes get_data_classes
run_json_paged classifiers get_classifiers
run_json_paged discovery_policies get_discovery_policies
run_json_paged connectors get_connectors
run_json_paged rule_sets get_rule_sets
run_json_paged jobs get_compliance_jobs

# Los clasificadores asignados a cada Profile Set se consultan por política.
# Se mantiene esta etapa separada para que el template reciba datos ya normalizados.
dp_ids="$(jq -r --slurpfile allowed "${TMP_DIR}/profile_set_allowlist.json" \
  '.items[]? | select((.name as $n | ($allowed[0] | index($n))) != null) | .id // empty' \
  "${TMP_DIR}/discovery_policies.json")"
: > "${TMP_DIR}/discovery_policy_classifiers.ndjson"
while IFS= read -r dp_id; do
  [[ -n "${dp_id}" ]] || continue
  if run_json_paged "discovery-policy-${dp_id}" get_discovery_policy_classifiers discovery_policy_id="${dp_id}"; then
    raw_dp_cls=$(cat "${TMP_DIR}/discovery-policy-${dp_id}.json")
    jq -c --arg id "${dp_id}" '{policy_id:$id, items:(.items // [])}' <<<"${raw_dp_cls}" >> "${TMP_DIR}/discovery_policy_classifiers.ndjson"
  fi
done <<< "${dp_ids}"
jq -s '{items: .}' "${TMP_DIR}/discovery_policy_classifiers.ndjson" > "${TMP_DIR}/discovery_policy_classifiers.json"

# Parámetros JDBC configurados por conexión administrada.
: > "${TMP_DIR}/connection_properties.ndjson"
conn_ids="$(jq -r '.items[]? | select(.dct_managed == true) | [.id, .name] | @tsv' "${TMP_DIR}/connectors.json")"
while IFS=$'\t' read -r conn_id conn_name; do
  [[ -n "${conn_id}" ]] || continue
  if raw_props=$("${DCT_TOOLKIT_BIN}" get_connection_properties connector_id="${conn_id}" -js 2>/dev/null); then
    jq -c --arg id "${conn_id}" --arg name "${conn_name}" \
      '{connector_id:$id, connector_name:$name, items:(if type == "object" then (.items // []) else . end)}' \
      <<<"${raw_props}" >> "${TMP_DIR}/connection_properties.ndjson"
  fi
done <<< "${conn_ids}"
jq -s '{items: .}' "${TMP_DIR}/connection_properties.ndjson" > "${TMP_DIR}/connection_properties.json"

# Detalle de Rule Sets: una consulta de tablas y otra de columnas por tabla.
: > "${TMP_DIR}/rule_tables.ndjson"
rs_rows="$(jq -r '.items[]? | [.id, .name] | @tsv' "${TMP_DIR}/rule_sets.json")"
while IFS=$'\t' read -r rs_id rs_name; do
  [[ -n "${rs_id}" ]] || continue
  if run_json_paged "tables-${rs_id}" search_database_table_metadata rule_set_id="${rs_id}"; then
    raw_tbls=$(cat "${TMP_DIR}/tables-${rs_id}.json")
  else
    raw_tbls='{"items":[]}'
  fi
  while IFS=$'\t' read -r tbl_id tbl_name tbl_key; do
    [[ -n "${tbl_id}" ]] || continue
    if run_json_paged "columns-${tbl_id}" search_database_column_metadata database_table_metadata_id="${tbl_id}"; then
      raw_cols=$(cat "${TMP_DIR}/columns-${tbl_id}.json")
    else
      raw_cols='{"items":[]}'
    fi
    jq -cn --arg rsid "${rs_id}" --arg rsname "${rs_name}" --arg tid "${tbl_id}" --arg tname "${tbl_name}" --arg tkey "${tbl_key}" \
      --argjson columns "$(jq -c '.items // []' <<<"${raw_cols}" 2>/dev/null || echo '[]')" \
      '{rule_set_id:$rsid, rule_set_name:$rsname, table_id:$tid, table_name:$tname, key_column:$tkey, columns:$columns}' \
      >> "${TMP_DIR}/rule_tables.ndjson"
  done < <(jq -r '.items[]? | [.id, .table_name, (.key_column // "")] | @tsv' <<<"${raw_tbls}" 2>/dev/null || true)
done <<< "${rs_rows}"
jq -s '{items: .}' "${TMP_DIR}/rule_tables.ndjson" > "${TMP_DIR}/rule_tables.json"

jq -n \
  --arg client "${CLIENT_NAME}" \
  --arg prefix "${PREFIX}" \
  --arg generated_at "$(date '+%Y-%m-%d %H:%M:%S')" \
  --slurpfile engines "${TMP_DIR}/engines.json" \
  --slurpfile smtp "${TMP_DIR}/smtp.json" \
  --slurpfile ldap "${TMP_DIR}/ldap.json" \
  --slurpfile algorithms "${TMP_DIR}/algorithms.json" \
  --slurpfile data_classes "${TMP_DIR}/data_classes.json" \
  --slurpfile classifiers "${TMP_DIR}/classifiers.json" \
  --slurpfile discovery_policies "${TMP_DIR}/discovery_policies.json" \
  --slurpfile profile_set_allowlist "${TMP_DIR}/profile_set_allowlist.json" \
  --slurpfile policy_classifiers "${TMP_DIR}/discovery_policy_classifiers.json" \
  --slurpfile connection_properties "${TMP_DIR}/connection_properties.json" \
  --slurpfile connectors "${TMP_DIR}/connectors.json" \
  --slurpfile rule_sets "${TMP_DIR}/rule_sets.json" \
  --slurpfile rule_tables "${TMP_DIR}/rule_tables.json" \
  --slurpfile jobs "${TMP_DIR}/jobs.json" '
  def items($x): ($x[0].items // []);
  def text($x; $fallback): if $x == null or $x == "" then $fallback else ($x | tostring) end;
  def file_name($x): if $x == null or $x == "" then "-" else ($x | split("/") | last) end;
  def engine($x): text($x; "DCT / Global");
  def prefixed($x): [($x // [])[] | select((.name // "") | startswith($prefix))];
  def simple_algorithms: [items($algorithms)[] | select((.name // "" | startswith($prefix)) and .framework_name != "FullName") | {
    name: text(.name; "-"), framework: text(.framework_name; "-"), lookup_file: file_name(.config.lookupFile.uri // ""),
    engine: engine(.engine_name), description: (text(.description; "-") | gsub("\\r?\\n"; " "))
  }] | sort_by(.name);
  def composite_algorithms: (items($algorithms) as $all | [ $all[] | select((.name // "" | startswith($prefix)) and .framework_name == "FullName") |
    (.config.firstNameAlgorithmRef.name // "") as $first_ref |
    (.config.lastNameAlgorithmRef.name // "") as $last_ref |
    {
      name: text(.name; "-"), first_name: text($first_ref; "-"), last_name: text($last_ref; "-"),
      first_file: file_name(([$all[] | select(.name == $first_ref) | .config.lookupFile.uri][0]) // ""),
      last_file: file_name(([$all[] | select(.name == $last_ref) | .config.lookupFile.uri][0]) // ""),
      description: (text(.description; "-") | gsub("\\r?\\n"; " "))
    }
  ]) | sort_by(.name);
  def engines: [items($engines)[] | select(.type == "MASKING") | {
    name: text(.name; "-"), type: text(.type; "MASKING"), version: text(.version; "-"), status: text(.connection_status // .status; "-"),
    cpu: (if .cpu_core_count then ((.cpu_core_count|tostring) + " Cores") else "-" end),
    memory: (if .memory_size then (((.memory_size / 1073741824 * 10 | round) / 10 | tostring) + " GB") else "-" end),
    storage: (if .data_storage_capacity then (((.data_storage_capacity / 1073741824 * 10 | round) / 10 | tostring) + " GB") else "-" end),
    hostname: text(.hostname; "-"), gateway: "<Gateway>", dns: "<Servidores DNS>", ntp: "<Servidores NTP>"
  }] | sort_by(.name);
  def classifier_weight:
    if .config and .config.matchStrength != null then (.config.matchStrength | tostring)
    elif .config and .config.paths then ([.config.paths[]?.matchStrength | tostring] | unique | join(", "))
    elif .config and .config.dataPatterns then ([.config.dataPatterns[]?.matchStrength | tostring] | unique | join(", "))
    elif .config and .config.valueLists then ([.config.valueLists[]?.matchStrength | tostring] | unique | join(", "))
    else "-" end;
  def classifiers_path_regex: [items($classifiers)[] | select((.name // "" | startswith($prefix)) and (.framework == "PATH" or .framework == "REGEX")) | {
    name: text(.name; "-"), framework: text(.framework; "-"), data_class: text(.data_class_name; "-"), weight: classifier_weight,
    values: (if .framework == "PATH" then ([.config.paths[]?.fieldValue | select(. != null) | "`" + (gsub("\\|"; "\\|")) + "`"] | join("<br>")) else ([.config.dataPatterns[]?.regex | select(. != null) | "`" + (gsub("\\|"; "\\|")) + "`"] | join("<br>")) end),
    engine: engine(.engine_name)
  }] | sort_by(.engine, .name);
  def classifiers_list: [items($classifiers)[] | select((.name // "" | startswith($prefix)) and .framework == "LIST") | {
    name: text(.name; "-"), framework: "LIST", data_class: text(.data_class_name; "-"), weight: classifier_weight,
    values: ([.config.valueLists[]?.file | select(. != null) | "`" + file_name(.) + "`"] | join("<br>")), engine: engine(.engine_name)
  }] | sort_by(.engine, .name);
  def classifiers_data_type: [items($classifiers)[] | select((.name // "" | startswith($prefix)) and .framework == "DATA_TYPE") | {
    name: text(.name; "-"), framework: "DATA_TYPE", data_class: text(.data_class_name; "-"), weight: classifier_weight,
    values: ([.config.allowedTypes[]? | (.typeName + (if .minimumLength != null then " (min: " + (.minimumLength | tostring) + ")" else "" end))] | join(", ")), engine: engine(.engine_name)
  }] | sort_by(.engine, .name);
  {
    client: $client, generated_at: $generated_at, prefix: $prefix,
    detected_version: ((items($engines) | map(select(.type == "MASKING") | .version) | first) // "2026.X.0.0"),
    masking_engine_count: (engines|length), engines: engines,
    smtp: {host: text($smtp[0].hostname // $smtp[0].host; "-"), port: text($smtp[0].port; "-"), enabled: (($smtp[0].enabled // false)|tostring), authentication: (($smtp[0].authentication_enabled // false)|tostring), tls: (($smtp[0].tls_enabled // false)|tostring), from: text($smtp[0].from_address; "-")},
    ldap: {enabled: (($ldap[0].enabled // false)|tostring), host: text($ldap[0].hostname // $ldap[0].host; "-"), port: text($ldap[0].port; "-"), domains: (if (($ldap[0].domains // []) | length) > 0 then ([($ldap[0].domains // [])[] | "`" + . + "`"] | join(", ")) else "-" end), auto_create_users: (($ldap[0].auto_create_users // false)|tostring), ssl: (($ldap[0].enable_ssl // false)|tostring)},
    simple_algorithms: simple_algorithms, composite_algorithms: composite_algorithms,
    data_classes: ([items($data_classes)[] | select((.name // "" | startswith($prefix))) | {name: text(.name; "-"), algorithm: text(.default_algorithm_name; "-"), engine: engine(.engine_name)}] | sort_by(.name)),
    classifiers_path_regex: classifiers_path_regex, classifiers_list: classifiers_list, classifiers_data_type: classifiers_data_type,
    profile_sets: [items($discovery_policies)[] as $policy | select(($policy.name as $n | ($profile_set_allowlist[0] | index($n))) != null) |
      {name: text($policy.name; "-"), classifiers:
        ([items($policy_classifiers)[] | select(.policy_id == ($policy.id|tostring)) | .items[]?
          | select((.name // "") | startswith($prefix)) | .name] | sort | map("`" + . + "`") | join(", "))
      }] | sort_by(.name),
    connectors: ([items($connectors)[] | {name: text(.name; "-"), host: text(.hostname; "-"), database: text(.database_name; "-"), schema: text(.schema_name; "-"), user: text(.username; "-"), platform: text(.platform; "-"), engine: (if .engine_name then .engine_name elif .job_orchestrator_name then (.job_orchestrator_name + " (Orchestrator)") else "DCT / Global" end)}] | sort_by(.name)),
    jdbc_properties: [items($connection_properties)[] as $conn | $conn.items[]? | select((.edited == null or .edited == false) and .value != null and .value != "") | {connector: $conn.connector_name, name: text(.name; "-"), value: ((.value|tostring)|gsub("\\|"; "\\|"))}],
    rule_sets: ([items($rule_sets)[] | {name: text(.name; "-"), engine: engine(.engine_name), description: text(.description; "-"), id: .id}] | sort_by(.name)),
    rule_columns: [items($rule_tables)[] as $table | (($table.columns // []) | map(select(.is_sensitive == true or .algorithm_name != null or .data_class_name != null)) | sort_by(.column_name))[] | {rule_set: $table.rule_set_name, table: $table.table_name, column: text(.column_name; "-"), data_class: text(.data_class_name; "-"), algorithm: text(.algorithm_name; "-")}],
    rule_tables: ([items($rule_tables)[] | {rule_set: .rule_set_name, table: .table_name, logical_key: (if .key_column != "" then .key_column elif ([.columns[]? | select(.is_primary_key == true)] | length) > 0 then "Llave Primaria" else "-" end)}] | sort_by(.rule_set, .table)),
    profiling_jobs: [items($jobs)[] | select(.type == "DISCOVERY" or .type == "PROFILING") | {name: text(.name; "-"), type: text(.type; "-"), rule_set: text(.rule_set_name; "-"), profile_set: text(.discovery_policy_name; "-"), connector: text(.connector_type; "-"), execution: text(.execution_type; "STANDARD"), engine: engine(.engine_name), environment: text(.environment_name; "-"), application: text(.application_name; "-")}],
    masking_jobs: [items($jobs)[] | select(.type == "MASKING") | {name: text(.name; "-"), type: text(.type; "MASKING"), rule_set: text(.rule_set_name; "-"), on_the_fly: ((.is_on_the_fly_masking // false)|tostring), truncate: ((.truncate_tables // false)|tostring), drop_indexes: ((.drop_indexes // false)|tostring), connector: text(.connector_type; "-"), execution: text(.execution_type; "STANDARD"), engine: engine(.engine_name), environment: text(.environment_name; "-"), application: text(.application_name; "-")}] | sort_by(.name)
  }
' > "${DATA_FILE}"

printf '[+] Datos normalizados generados en: %s\n' "${DATA_FILE}"
