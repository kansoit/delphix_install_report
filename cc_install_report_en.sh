#!/usr/bin/env bash

# ==============================================================================
# Script: Install_report_en.sh
# Description: Generates a Markdown (.md) report of algorithms, Data Classes (domains),
#              profiling classifiers, Profile Sets, data connections, Rule Sets, and
#              profiling/masking job definitions configured in Delphix Continuous Compliance
#              using DCT Toolkit.
# Requirements: dct-toolkit, jq
# ==============================================================================

set -euo pipefail

CLIENT_NAME="Client"
PREFIX="0-"
OUTPUT_FILE=""
LIMIT=1000

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client|--client-name)
      CLIENT_NAME="$2"
      shift 2
      ;;
    -p|--prefix)
      PREFIX="$2"
      shift 2
      ;;
    -o|--output|--output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -l|--limit)
      LIMIT="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [CLIENT_NAME] [PREFIX] [OUTPUT_FILE] [-c CLIENT_NAME] [-p PREFIX] [-o OUTPUT_FILE] [-l LIMIT]"
      echo "  CLIENT_NAME   Customer Name (default: Client)"
      echo "  -c, --client  Customer Name (default: Client)"
      echo "  -p, --prefix  Prefix to filter (default: 0-). Use '' for no filter."
      echo "  -o, --output  Output Markdown file path"
      echo "  -l, --limit   Max items limit (default: 1000)"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  CLIENT_NAME="${POSITIONAL_ARGS[0]}"
fi
if [[ ${#POSITIONAL_ARGS[@]} -gt 1 ]]; then
  PREFIX="${POSITIONAL_ARGS[1]}"
fi
if [[ ${#POSITIONAL_ARGS[@]} -gt 2 ]]; then
  OUTPUT_FILE="${POSITIONAL_ARGS[2]}"
fi
if [[ ${#POSITIONAL_ARGS[@]} -gt 3 ]]; then
  LIMIT="${POSITIONAL_ARGS[3]}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${OUTPUT_FILE}" ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${CLIENT_NAME} - Delphix Continuous Compliance Configuration Report.md"
elif [[ "${OUTPUT_FILE}" != /* && "${OUTPUT_FILE}" != ./* && "${OUTPUT_FILE}" != ../* ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${OUTPUT_FILE}"
fi

printf "\033[0;32m[+] Fetching data from Delphix Data Control Tower (DCT)...\033[0m\n"

if ! command -v dct-toolkit &> /dev/null; then
  echo "ERROR: 'dct-toolkit' is not installed or not found in PATH." >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "ERROR: 'jq' is not installed. 'jq' is required to parse dct-toolkit output." >&2
  exit 1
fi

RAW_ENGINES_JSON=$(dct-toolkit get_registered_engines limit="${LIMIT}" -js 2>/dev/null || echo '{"items":[]}')
RAW_SMTP_JSON=$(dct-toolkit get_smtp_config -js 2>/dev/null || echo '{}')
RAW_LDAP_JSON=$(dct-toolkit get_ldap_config -js 2>/dev/null || echo '{}')

RAW_ALGO_JSON=$(dct-toolkit get_algorithms limit="${LIMIT}" -js)
RAW_DC_JSON=$(dct-toolkit get_data_classes limit="${LIMIT}" -js)
RAW_CL_JSON=$(dct-toolkit get_classifiers limit="${LIMIT}" -js)
RAW_DP_JSON=$(dct-toolkit get_discovery_policies limit="${LIMIT}" -js)
RAW_CONN_JSON=$(dct-toolkit get_connectors limit="${LIMIT}" -js)
RAW_RS_JSON=$(dct-toolkit get_rule_sets limit="${LIMIT}" -js)
RAW_JOBS_JSON=$(dct-toolkit get_compliance_jobs limit="${LIMIT}" -js)

DETECTED_VERSION=$(echo "${RAW_ENGINES_JSON}" | jq -r '([.items[] | select(.type == "MASKING").version][0]) // ([.items[].version][0]) // "2026.X.0.0"')
TOTAL_ENGINES_COUNT=$(echo "${RAW_ENGINES_JSON}" | jq '[.items[]] | length')
MASKING_ENGINES_COUNT=$(echo "${RAW_ENGINES_JSON}" | jq '[.items[] | select(.type == "MASKING")] | length')

TOTAL_ALGO_COUNT=$(echo "${RAW_ALGO_JSON}" | jq --arg p "${PREFIX}" '[.items[] | select(.name | startswith($p))] | length')
SIMPLE_COUNT=$(echo "${RAW_ALGO_JSON}" | jq --arg p "${PREFIX}" '[.items[] | select((.name | startswith($p)) and .framework_name != "FullName")] | length')
COMPOSITE_COUNT=$(echo "${RAW_ALGO_JSON}" | jq --arg p "${PREFIX}" '[.items[] | select((.name | startswith($p)) and .framework_name == "FullName")] | length')

TOTAL_DC_COUNT=$(echo "${RAW_DC_JSON}" | jq --arg p "${PREFIX}" '[.items[] | select(.name | startswith($p))] | length')
TOTAL_CL_COUNT=$(echo "${RAW_CL_JSON}" | jq --arg p "${PREFIX}" '[.items[] | select(.name | startswith($p))] | length')
TOTAL_CONN_COUNT=$(echo "${RAW_CONN_JSON}" | jq '[.items[]] | length')
TOTAL_RS_COUNT=$(echo "${RAW_RS_JSON}" | jq '[.items[]] | length')

PROFILING_JOBS_COUNT=$(echo "${RAW_JOBS_JSON}" | jq '[.items[] | select(.type == "DISCOVERY" or .type == "PROFILING")] | length')
MASKING_JOBS_COUNT=$(echo "${RAW_JOBS_JSON}" | jq '[.items[] | select(.type == "MASKING")] | length')

printf "\033[0;32m[+] Registered engines in DCT: %s\033[0m\n" "${TOTAL_ENGINES_COUNT}"
printf "\033[0;32m[+] Masking (Compliance) engines detected: %s\033[0m\n" "${MASKING_ENGINES_COUNT}"
printf "\033[0;32m[+] Total algorithms detected with prefix '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_ALGO_COUNT}"
printf "\033[0;32m    - Text lookup algorithms (Secure Lookup / Name): %s\033[0m\n" "${SIMPLE_COUNT}"
printf "\033[0;32m    - Composite algorithms (FullName): %s\033[0m\n" "${COMPOSITE_COUNT}"
printf "\033[0;32m[+] Data classes (Domains) detected with prefix '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_DC_COUNT}"
printf "\033[0;32m[+] Classifiers (Profiling Classifiers) detected with prefix '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_CL_COUNT}"
printf "\033[0;32m[+] Data connections (Connectors): %s\033[0m\n" "${TOTAL_CONN_COUNT}"
printf "\033[0;32m[+] Rule Sets detected: %s\033[0m\n" "${TOTAL_RS_COUNT}"
printf "\033[0;32m[+] Profiling jobs (Profiling / Discovery Jobs): %s\033[0m\n" "${PROFILING_JOBS_COUNT}"
printf "\033[0;32m[+] Masking jobs (Masking Jobs): %s\033[0m\n" "${MASKING_JOBS_COUNT}"

FECHA=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo "# ${CLIENT_NAME} - Delphix Continuous Compliance Configuration Report"
  echo ""
  echo "---"
  echo ""
  echo "## 1. Executive Summary"
  echo ""
  echo "For the implementation of Delphix Continuous Compliance Version **${DETECTED_VERSION}**, **${CLIENT_NAME}** has selected the database <**Database Name**> on <**Database Vendor**> as the pilot case for sensitive data masking."
  echo ""
  echo "The main objective of this report is to consolidate the configuration applied in the customer environment, including masking algorithms, data domains, profiling classifiers, rule sets, data connectors, and job execution definitions."
  echo ""
  echo "---"
  echo ""
  echo "## 2. Delphix Continuous Compliance Engine Infrastructure and Services"
  echo ""
  echo "### 2.1. Registered Delphix Continuous Compliance Engines (Masking Engines)"
  echo ""
  echo "Summary table of Continuous Compliance (Masking) engines registered in Delphix DCT, their version, IP address/hostname, connection status, and allocated resources:"
  echo ""

  if [[ "${MASKING_ENGINES_COUNT}" -eq 0 ]]; then
    echo "_No Masking engines registered in the current instance._"
    echo ""
  else
    echo "| Engine Name | Type | Version | Connection Status | CPU Cores | RAM Memory | Total Storage |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"
    echo "${RAW_ENGINES_JSON}" | jq -r '
      [.items[] | select(.type == "MASKING")] | sort_by(.name)[] |
      [
        "**" + (.name // "-") + "**",
        (.type // "MASKING"),
        ("`" + (.version // "-") + "`"),
        (.connection_status // .status // "-"),
        (if .cpu_core_count then (.cpu_core_count | tostring) + " Cores" else "-" end),
        (if .memory_size then (((.memory_size / 1073741824 * 10 | round) / 10 | tostring) + " GB") else "-" end),
        (if .data_storage_capacity then (((.data_storage_capacity / 1073741824 * 10 | round) / 10 | tostring) + " GB") else "-" end)
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "| Engine Name | Network Parameter | Configured Value |"
  echo "| :--- | :--- | :--- |"
  if [[ "${MASKING_ENGINES_COUNT}" -eq 0 ]]; then
    echo "| **-** | **IP Address / Hostname** | - |"
    echo "| **-** | **Gateway** | <**Gateway**> |"
    echo "| **-** | **DNS Servers** | <**DNS Servers**> |"
    echo "| **-** | **NTP Servers** | <**NTP Servers**> |"
  else
    echo "${RAW_ENGINES_JSON}" | jq -r '
      [.items[] | select(.type == "MASKING")] | sort_by(.name)[] |
      [
        "| **" + (.name // "-") + "** | **IP Address / Hostname** | `" + (.hostname // "-") + "` |",
        "| **" + (.name // "-") + "** | **Gateway** | <**Gateway**> |",
        "| **" + (.name // "-") + "** | **DNS Servers** | <**DNS Servers**> |",
        "| **" + (.name // "-") + "** | **NTP Servers** | <**NTP Servers**> |"
      ] | .[]
    '
  fi
  echo ""
  echo "### 2.2. Infrastructure Services Configuration (SMTP & LDAP / Active Directory Authentication)"
  echo ""
  echo "#### 2.2.1. Mail Server Configuration (SMTP)"
  echo ""
  echo "Summary table of SMTP mail server settings for event and alert notifications:"
  echo ""
  echo "| SMTP Parameter | Configured Value |"
  echo "| :--- | :--- |"
  echo "${RAW_SMTP_JSON}" | jq -r '
    [
      "| **SMTP Server (Host)** | `" + (.hostname // .host // "-") + "` |",
      "| **Port** | `" + ((.port // "-") | tostring) + "` |",
      "| **Enabled Status** | `" + ((.enabled // false) | tostring) + "` |",
      "| **Authentication Enabled (Auth)** | `" + ((.authentication_enabled // false) | tostring) + "` |",
      "| **TLS Encryption** | `" + ((.tls_enabled // false) | tostring) + "` |",
      "| **Sender Address (From)** | `" + (.from_address // "-") + "` |"
    ] | .[]
  '
  echo ""
  echo "#### 2.2.2. LDAP / Domain Controller Authentication Configuration (Active Directory)"
  echo ""
  echo "Summary table of LDAP / Active Directory integration for user authentication:"
  echo ""
  echo "| LDAP / Active Directory Parameter | Configured Value |"
  echo "| :--- | :--- |"
  echo "${RAW_LDAP_JSON}" | jq -r '
    [
      "| **LDAP Integration Enabled** | `" + ((.enabled // false) | tostring) + "` |",
      "| **LDAP Host Server / Domain Controller** | `" + (.hostname // .host // "-") + "` |",
      "| **Port** | `" + ((.port // "-") | tostring) + "` |",
      "| **Registered Domains** | " + (if .domains and (.domains | length) > 0 then ([.domains[] | "`" + . + "`"] | join(", ")) else "-" end) + " |",
      "| **Auto-create Users** | `" + ((.auto_create_users // false) | tostring) + "` |",
      "| **Secure Connection (SSL)** | `" + ((.enable_ssl // false) | tostring) + "` |"
    ] | .[]
  '
  echo ""
  echo "---"
  echo ""
  echo "## 3. Text File Lookup Algorithms (\`Secure Lookup\` / \`Name\`)"
  echo ""
  echo "Summary table of algorithms based on replacement value text files:"
  echo ""

  if [[ "${SIMPLE_COUNT}" -eq 0 ]]; then
    echo "_No simple algorithms found with the specified prefix._"
    echo ""
  else
    echo "| Algorithm | Framework | TXT File Used | Engine | Description |"
    echo "| :--- | :--- | :--- | :--- | :--- |"
    
    echo "${RAW_ALGO_JSON}" | jq -r --arg p "${PREFIX}" '
      [.items[] | select((.name | startswith($p)) and .framework_name != "FullName")] | sort_by((.engine_name // "DCT / Global"), .name)[] |
      [
        "**" + .name + "**",
        (.framework_name // "-"),
        ("`" + ((.config.lookupFile.uri // "") | split("/") | last // "-") + "`"),
        (.engine_name // "DCT / Global"),
        ((.description // "-") | gsub("\r?\n"; " "))
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "---"
  echo ""
  echo "## 4. Composite Algorithms (\`FullName\`)"
  echo ""
  echo "Detailed table of the composite algorithm \`FullName\` and its constituent simple algorithms:"
  echo ""

  if [[ "${COMPOSITE_COUNT}" -eq 0 ]]; then
    echo "_No composite algorithms (FullName) found with the specified prefix._"
    echo ""
  else
    echo "| Composite Algorithm | Framework | First Name Component | First Name TXT File | Last Name Component | Last Name TXT File | Description |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"
    
    echo "${RAW_ALGO_JSON}" | jq -r --arg p "${PREFIX}" '
      INDEX(.items[]; .name) as $map |
      .items[] | select((.name | startswith($p)) and .framework_name == "FullName") |
      .config.firstNameAlgorithmRef.name as $firstAlgo |
      .config.lastNameAlgorithmRef.name as $lastAlgo |
      (($map[$firstAlgo].config.lookupFile.uri // "") | split("/") | last // "-") as $firstTxt |
      (($map[$lastAlgo].config.lookupFile.uri // "") | split("/") | last // "-") as $lastTxt |
      [
        "**" + .name + "**",
        "FullName",
        "**" + ($firstAlgo // "-") + "**",
        "`" + $firstTxt + "`",
        "**" + ($lastAlgo // "-") + "**",
        "`" + $lastTxt + "`",
        ((.description // "-") | gsub("\r?\n"; " "))
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "---"
  echo ""
  echo "## 5. Domains (Data Classes) and Algorithm Association"
  echo ""
  echo "Association table between defined domains (Data Classes) and their assigned masking algorithm:"
  echo ""

  if [[ "${TOTAL_DC_COUNT}" -eq 0 ]]; then
    echo "_No domains (Data Classes) found with the specified prefix._"
    echo ""
  else
    echo "| Domain (Data Class) | Assigned Algorithm | Engine |"
    echo "| :--- | :--- | :--- |"

    echo "${RAW_DC_JSON}" | jq -r --arg p "${PREFIX}" '
      [.items[] | select(.name | startswith($p))] | sort_by((.engine_name // "DCT / Global"), .name)[] |
      [
        "**" + .name + "**",
        (.default_algorithm_name // "-"),
        (.engine_name // "DCT / Global")
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "---"
  echo ""
  echo "## 6. Profiling Classifiers (Classifiers)"
  echo ""
  echo "### 6.1. Column Name and Regular Expression Classifiers (PATH / REGEX)"
  echo ""
  echo "| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Regular Expression (Regex) | Engine |"
  echo "| :--- | :--- | :--- | :--- | :--- | :--- |"

  echo "${RAW_CL_JSON}" | jq -r --arg p "${PREFIX}" '
    [.items[] | select((.name | startswith($p)) and (.framework == "PATH" or .framework == "REGEX"))] | sort_by((.engine_name // "DCT / Global"), .name)[] |
    (
      if .framework == "PATH" and .config and .config.paths then
        ([.config.paths[].matchStrength | tostring] | unique | join(", "))
      elif .framework == "REGEX" and .config and .config.dataPatterns then
        ([.config.dataPatterns[].matchStrength | tostring] | unique | join(", "))
      else
        "-"
      end
    ) as $peso |
    (
      if .framework == "PATH" and .config and .config.paths then
        ([.config.paths[].fieldValue | select(. != null) | "`" + (gsub("\\|"; "\\|")) + "`"] | join("<br>"))
      elif .framework == "REGEX" and .config and .config.dataPatterns then
        ([.config.dataPatterns[].regex | select(. != null) | "`" + (gsub("\\|"; "\\|")) + "`"] | join("<br>"))
      else
        "-"
      end
    ) as $rx |
    [
      "**" + .name + "**",
      (.framework // "-"),
      "**" + (.data_class_name // "-") + "**",
      $peso,
      $rx,
      (.engine_name // "DCT / Global")
    ] | join(" | ") | "| " + . + " |"
  '
  echo ""

  echo "### 6.2. Value List Classifiers (LIST)"
  echo ""
  echo "| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | TXT File Name | Engine |"
  echo "| :--- | :--- | :--- | :--- | :--- | :--- |"

  echo "${RAW_CL_JSON}" | jq -r --arg p "${PREFIX}" '
    [.items[] | select((.name | startswith($p)) and .framework == "LIST")] | sort_by((.engine_name // "DCT / Global"), .name)[] |
    (
      if .config and .config.valueLists then
        ([.config.valueLists[].matchStrength | tostring] | unique | join(", "))
      else
        "-"
      end
    ) as $peso |
    (
      if .config and .config.valueLists then
        ([.config.valueLists[].file | select(. != null) | "`" + (. | split("/") | last) + "`"] | join("<br>"))
      else
        "-"
      end
    ) as $files |
    [
      "**" + .name + "**",
      "LIST",
      "**" + (.data_class_name // "-") + "**",
      $peso,
      $files,
      (.engine_name // "DCT / Global")
    ] | join(" | ") | "| " + . + " |"
  '
  echo ""

  echo "### 6.3. Data Type Classifiers (DATA_TYPE)"
  echo ""
  echo "| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Allowed Data Types | Engine |"
  echo "| :--- | :--- | :--- | :--- | :--- | :--- |"

  echo "${RAW_CL_JSON}" | jq -r --arg p "${PREFIX}" '
    [.items[] | select((.name | startswith($p)) and .framework == "DATA_TYPE")] | sort_by((.engine_name // "DCT / Global"), .name)[] |
    (
      if .config and .config.matchStrength != null then
        (.config.matchStrength | tostring)
      else
        "-"
      end
    ) as $peso |
    (
      if .config and .config.allowedTypes then
        ([.config.allowedTypes[] | .typeName + (if .minimumLength != null then " (min: " + (.minimumLength | tostring) + ")" else "" end)] | join(", "))
      else
        "-"
      end
    ) as $types |
    [
      "**" + .name + "**",
      "DATA_TYPE",
      "**" + (.data_class_name // "-") + "**",
      $peso,
      $types,
      (.engine_name // "DCT / Global")
    ] | join(" | ") | "| " + . + " |"
  '
  echo ""

  echo "---"
  echo ""
  echo "## 7. Profile Sets (Discovery Policies) and Assigned Classifiers"
  echo ""
  echo "Relationship between the Profiling Profile Set and the complete list of constituent classifiers:"
  echo ""

  DP_IDS=$(echo "${RAW_DP_JSON}" | jq -r '.items[].id')
  HAS_ANY_DP=false

  for dp_id in ${DP_IDS}; do
    dp_name=$(echo "${RAW_DP_JSON}" | jq -r --arg id "${dp_id}" '.items[] | select(.id == $id) | .name')
    raw_dp_cls=$(dct-toolkit get_discovery_policy_classifiers discovery_policy_id="${dp_id}" limit="${LIMIT}" -js)
    cl_list_str=$(echo "${raw_dp_cls}" | jq -r --arg p "${PREFIX}" '
      [.items[] | select(.name | startswith($p))] | sort_by(.name) | map("`" + .name + "`") | join(", ")
    ')
    if [[ -n "${cl_list_str}" && "${cl_list_str}" != "null" ]]; then
      if [[ "${HAS_ANY_DP}" == false ]]; then
        echo "| Profile Set (Discovery Policy) | Classifier List |"
        echo "| :--- | :--- |"
        HAS_ANY_DP=true
      fi
      echo "| **${dp_name}** | ${cl_list_str} |"
    fi
  done

  if [[ "${HAS_ANY_DP}" == false ]]; then
    echo "_No Profile Sets found containing classifiers matching prefix '${PREFIX}'._"
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 8. Data Connections (Connectors) and JDBC Parameters"
  echo ""
  echo "### 8.1. Defined Data Connections"
  echo ""
  echo "Summary table of data connections (Connectors), including server, database, schema, and user:"
  echo ""

  if [[ "${TOTAL_CONN_COUNT}" -eq 0 ]]; then
    echo "_No data connections found in current instance._"
    echo ""
  else
    echo "| Connection (Connector) | Server / Host | Database | Schema | User | Type / Platform | Engine |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"

    echo "${RAW_CONN_JSON}" | jq -r '
      [.items[]] | sort_by((if .engine_name then .engine_name elif .job_orchestrator_name then (.job_orchestrator_name + " (Orchestrator)") else "DCT / Global" end), .name, .id)[] |
      [
        "**" + (.name // "-") + "**",
        (.hostname // "-"),
        (.database_name // "-"),
        (.schema_name // "-"),
        (.username // "-"),
        (.platform // "-"),
        (if .engine_name then .engine_name elif .job_orchestrator_name then (.job_orchestrator_name + " (Orchestrator)") else "DCT / Global" end)
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "### 8.2. Configured JDBC Driver Parameters"
  echo ""
  echo "Table of JDBC driver parameters retrieved with configured values:"
  echo ""

  CONN_MANAGED_IDS=$(echo "${RAW_CONN_JSON}" | jq -r '.items[] | select(.dct_managed == true) | .id')
  HAS_ANY_JDBC=false

  for conn_id in ${CONN_MANAGED_IDS}; do
    conn_name=$(echo "${RAW_CONN_JSON}" | jq -r --arg id "${conn_id}" '.items[] | select(.id == $id) | .name')
    raw_props=$(dct-toolkit get_connection_properties connector_id="${conn_id}" -js 2>&1 || true)
    
    if echo "${raw_props}" | jq -e 'if type=="object" and .items then true elif type=="array" then true else false end' >/dev/null 2>&1; then
      props_rows=$(echo "${raw_props}" | jq -r --arg cname "${conn_name}" '
        (if type=="object" and .items then .items else . end) |
        .[] | select((.edited == null or .edited == false) and .value != null and .value != "") |
        [
          "**" + $cname + "**",
          "`" + .name + "`",
          "`" + (.value | tostring | gsub("\\|"; "\\|")) + "`"
        ] | join(" | ") | "| " + . + " |"
      ')
      if [[ -n "${props_rows}" ]]; then
        if [[ "${HAS_ANY_JDBC}" == false ]]; then
          echo "| Connection (Connector) | JDBC Driver Parameter | Configured Value |"
          echo "| :--- | :--- | :--- |"
          HAS_ANY_JDBC=true
        fi
        echo "${props_rows}"
      fi
    fi
  done

  if [[ "${HAS_ANY_JDBC}" == false ]]; then
    echo "_No JDBC driver parameters found for current connections._"
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 9. Rule Sets, Tables, and Algorithm / Domain Assignments"
  echo ""
  echo "### 9.1. Rule Sets, Tables, and Algorithm / Domain Assignments"
  echo ""

  RS_IDS=$(echo "${RAW_RS_JSON}" | jq -r '.items[].id')
  TABLE1_ROWS=""
  TABLE2_ROWS=""

  for rs_id in ${RS_IDS}; do
    rs_name=$(echo "${RAW_RS_JSON}" | jq -r --arg id "${rs_id}" '.items[] | select(.id == $id) | .name')
    raw_tbls=$(dct-toolkit search_database_table_metadata rule_set_id="${rs_id}" limit="${LIMIT}" -js 2>&1 || true)
    
    if echo "${raw_tbls}" | jq -e '.items' >/dev/null 2>&1; then
      tbl_ids=$(echo "${raw_tbls}" | jq -r '.items[].id')
      for tbl_id in ${tbl_ids}; do
        tbl_name=$(echo "${raw_tbls}" | jq -r --arg tid "${tbl_id}" '.items[] | select(.id == $tid) | .table_name')
        tbl_key=$(echo "${raw_tbls}" | jq -r --arg tid "${tbl_id}" '.items[] | select(.id == $tid) | .key_column // ""')
        
        raw_cols=$(dct-toolkit search_database_column_metadata database_table_metadata_id="${tbl_id}" limit="${LIMIT}" -js 2>&1 || true)
        
        lkey="-"
        if [[ -n "${raw_cols}" ]] && echo "${raw_cols}" | jq -e '.items' >/dev/null 2>&1; then
          lkey=$(echo "${raw_cols}" | jq -r --arg tkey "${tbl_key}" '
            if $tkey != "" then
              $tkey
            elif ([.items[]? | select(.is_primary_key == true)] | length) > 0 then
              "Primary Key"
            else
              "-"
            end
          ')
          
          cols_rows=$(echo "${raw_cols}" | jq -r --arg rsname "${rs_name}" --arg tname "${tbl_name}" '
            [.items[] | select(.is_sensitive == true or .algorithm_name != null or .data_class_name != null)] | sort_by(.column_name)[] |
            [
              "**" + $rsname + "**",
              "**" + $tname + "**",
              "`" + .column_name + "`",
              "**" + (.data_class_name // "-") + "**",
              (.algorithm_name // "-")
            ] | join(" | ") | "| " + . + " |"
          ')
          if [[ -n "${cols_rows}" ]]; then
            if [[ -z "${TABLE1_ROWS}" ]]; then
              TABLE1_ROWS="${cols_rows}"
            else
              TABLE1_ROWS="${TABLE1_ROWS}"$'\n'"${cols_rows}"
            fi
          fi
        else
          if [[ -n "${tbl_key}" ]]; then
            lkey="${tbl_key}"
          fi
        fi

        t2_row="| **${rs_name}** | **${tbl_name}** | \`${lkey}\` |"
        if [[ -z "${TABLE2_ROWS}" ]]; then
          TABLE2_ROWS="${t2_row}"
        elif ! echo "${TABLE2_ROWS}" | grep -qF "${t2_row}"; then
          TABLE2_ROWS="${TABLE2_ROWS}"$'\n'"${t2_row}"
        fi
      done
    fi
  done

  if [[ -z "${TABLE1_ROWS}" ]]; then
    echo "_No column/algorithm assignments found in current Rule Sets._"
    echo ""
  else
    echo "| Rule Set | Table | Column | Domain (Data Class) | Assigned Algorithm |"
    echo "| :--- | :--- | :--- | :--- | :--- |"
    echo "${TABLE1_ROWS}"
    echo ""
  fi

  echo "### 9.2. Database Tables and Logical Keys"
  echo ""

  if [[ -z "${TABLE2_ROWS}" ]]; then
    echo "_No registered tables found in current Rule Sets._"
    echo ""
  else
    echo "| Rule Set | Table | Logical Key |"
    echo "| :--- | :--- | :--- |"
    echo "${TABLE2_ROWS}" | sort -u
    echo ""
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 10. Profiling and Masking Job Definitions (Jobs)"
  echo ""
  echo "### 10.1. Profiling Jobs (Profiling / Discovery Jobs)"
  echo ""
  echo "Definition of profiling jobs (Discovery), Rule Set association, Profile Set, and execution attributes:"
  echo ""

  if [[ "${PROFILING_JOBS_COUNT}" -eq 0 ]]; then
    echo "_No profiling jobs (Profiling / Discovery) defined._"
    echo ""
  else
    echo "| Job Name | Type | Rule Set | Profile Set (Discovery Policy) | Connector / Platform | Execution Type | Engine | Environment / Application |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |"

    echo "${RAW_JOBS_JSON}" | jq -r '
      [.items[] | select(.type == "DISCOVERY" or .type == "PROFILING")] | sort_by((.engine_name // "DCT / Global"), .name)[] |
      [
        "**" + (.name // "-") + "**",
        (.type // "DISCOVERY"),
        "**" + (.rule_set_name // "-") + "**",
        "**" + (.discovery_policy_name // "-") + "**",
        (.connector_type // "-"),
        (.execution_type // "STANDARD"),
        (.engine_name // "DCT / Global"),
        ((.environment_name // "-") + " / " + (.application_name // "-"))
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "### 10.2. Masking Jobs"
  echo ""
  echo "Definition of masking jobs, Rule Set association, and masking attributes:"
  echo ""

  if [[ "${MASKING_JOBS_COUNT}" -eq 0 ]]; then
    echo "_No masking jobs defined._"
    echo ""
  else
    echo "| Job Name | Type | Rule Set | On-The-Fly | Truncate Tables | Drop Indexes | Connector / Platform | Execution Type | Engine | Environment / Application |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |"

    echo "${RAW_JOBS_JSON}" | jq -r '
      [.items[] | select(.type == "MASKING")] | sort_by((.engine_name // "DCT / Global"), .name)[] |
      [
        "**" + (.name // "-") + "**",
        (.type // "MASKING"),
        "**" + (.rule_set_name // "-") + "**",
        "`" + ((.is_on_the_fly_masking // false) | tostring) + "`",
        "`" + ((.truncate_tables // false) | tostring) + "`",
        "`" + ((.drop_indexes // false) | tostring) + "`",
        (.connector_type // "-"),
        (.execution_type // "STANDARD"),
        (.engine_name // "DCT / Global"),
        ((.environment_name // "-") + " / " + (.application_name // "-"))
      ] | join(" | ") | "| " + . + " |"
    '
    echo ""
  fi

  echo "---"
  echo ""
  echo "## 11. Key Configuration Criteria for Rule Sets (_In-Place Masking_)"
  echo ""
  echo "As a general architecture guideline for future **_In-Place Masking_** implementations, record identification within a _Rule Set_ must adhere to the following directives:"
  echo ""
  echo "**1. Use of Logical Keys:**"
  echo "Whenever a column (or set of columns) exists that guarantees uniqueness, non-null values, and whose columns **are not subject to masking**, it must be explicitly defined as a _Logical Key_ in the _Rule Set_. This enables the tool to execute direct, optimized update statements (\`UPDATE\`) using existing database engine indexes."
  echo ""
  echo "**2. Temporary Identity Column Mechanism:**"
  echo "When a table lacks a unique key with these characteristics, or when the existing primary/unique key consists of fields that require masking, **no _Logical Key_ should be defined in the _Rule Set_**. In these scenarios, Delphix automatically creates a temporary identity column (\`MASK_ROW_ID\`) in the target table to manage batch masking pointers, automatically dropping it upon job completion."
  echo ""
  echo "### Decision Summary (Reference Matrix)"
  echo ""
  echo "| **Table Scenario** | **Rule Set Action** | **Update Mechanism** |"
  echo "| :--- | :--- | :--- |"
  echo "| Has non-null PK/UQ and its fields are **not** masked | Define explicit **Logical Key** | Lookup via existing index |"
  echo "| Lacks PK/UQ, or existing key **is masked** | **Do not define** Logical Key | Temporary identity column (\`MASK_ROW_ID\`) |"
  echo ""

} > "${OUTPUT_FILE}"

printf "\033[0;32m[+] Document successfully generated at: %s\033[0m\n" "${OUTPUT_FILE}"
