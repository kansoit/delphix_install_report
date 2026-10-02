#!/usr/bin/env bash

# ==============================================================================
# Script: Install_report.sh
# Descripción: Genera un informe en formato Markdown (.md) de los algoritmos,
#              dominios (Data Classes), clasificadores de profiling, Profile Sets,
#              conexiones de datos, Rule Sets y definiciones de trabajos de perfilado/enmascaramiento
#              configurados en Delphix Continuous Compliance utilizando DCT Toolkit.
# Requisitos: dct-toolkit, jq
# ==============================================================================

set -euo pipefail

CLIENT_NAME="Cliente"
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
      echo "Uso: $0 [CLIENT_NAME] [PREFIX] [OUTPUT_FILE] [-c CLIENT_NAME] [-p PREFIX] [-o OUTPUT_FILE] [-l LIMIT]"
      echo "  CLIENT_NAME   Nombre del cliente (default: Cliente)"
      echo "  -c, --client  Nombre del cliente (default: Cliente)"
      echo "  -p, --prefix  Prefijo para filtrar (default: 0-). Use '' para recuperar todo sin filtro."
      echo "  -o, --output  Ruta del archivo Markdown de salida"
      echo "  -l, --limit   Límite de registros a recuperar (default: 1000)"
      exit 0
      ;;
    -*)
      echo "Opción desconocida: $1"
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
  OUTPUT_FILE="${SCRIPT_DIR}/${CLIENT_NAME} - Reporte Configuracion Delphix Continuous Compliance.md"
elif [[ "${OUTPUT_FILE}" != /* && "${OUTPUT_FILE}" != ./* && "${OUTPUT_FILE}" != ../* ]]; then
  OUTPUT_FILE="${SCRIPT_DIR}/${OUTPUT_FILE}"
fi

printf "\033[0;32m[+] Obteniendo datos desde Delphix Data Control Tower (DCT)...\033[0m\n"

if ! command -v dct-toolkit &> /dev/null; then
  echo "ERROR: 'dct-toolkit' no se encuentra instalado o en el PATH." >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "ERROR: 'jq' no está instalado. Se requiere 'jq' para procesar la salida de dct-toolkit en Bash." >&2
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

printf "\033[0;32m[+] Total de motores registrados en DCT: %s\033[0m\n" "${TOTAL_ENGINES_COUNT}"
printf "\033[0;32m[+] Motores de Masking (Compliance) detectados: %s\033[0m\n" "${MASKING_ENGINES_COUNT}"
printf "\033[0;32m[+] Total de algoritmos detectados con prefijo '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_ALGO_COUNT}"
printf "\033[0;32m    - Algoritmos de consulta TXT (Secure Lookup / Name): %s\033[0m\n" "${SIMPLE_COUNT}"
printf "\033[0;32m    - Algoritmos Compuestos (FullName): %s\033[0m\n" "${COMPOSITE_COUNT}"
printf "\033[0;32m[+] Total de dominios (Data Classes) detectados con prefijo '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_DC_COUNT}"
printf "\033[0;32m[+] Total de clasificadores (Profiling Classifiers) detectados con prefijo '%s': %s\033[0m\n" "${PREFIX}" "${TOTAL_CL_COUNT}"
printf "\033[0;32m[+] Total de conexiones de datos (Connectors): %s\033[0m\n" "${TOTAL_CONN_COUNT}"
printf "\033[0;32m[+] Total de Rule Sets detectados: %s\033[0m\n" "${TOTAL_RS_COUNT}"
printf "\033[0;32m[+] Trabajos de perfilado (Profiling / Discovery Jobs): %s\033[0m\n" "${PROFILING_JOBS_COUNT}"
printf "\033[0;32m[+] Trabajos de enmascaramiento (Masking Jobs): %s\033[0m\n" "${MASKING_JOBS_COUNT}"

FECHA=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo "# ${CLIENT_NAME} - Reporte Configuracion Delphix Continuous Compliance"
  echo ""
  echo "---"
  echo ""
  echo "## 1. Resumen Ejecutivo"
  echo ""
  echo "Para la implementación de Delphix Continuous Compliance en Version **${DETECTED_VERSION}**, **${CLIENT_NAME}** ha seleccionado la base de datos <**Nombre base de datos**> en <**Nombre Fabricante BD**> como caso piloto de enmascaramiento de datos sensibles."
  echo ""
  echo "El objetivo principal de este informe es consolidar la parametrización aplicada en el entorno del cliente, incluyendo los algoritmos de enmascaramiento, dominios de datos, clasificadores de perfilado, reglas de enmascaramiento, conectores y trabajos de ejecución."
  echo ""
  echo "---"
  echo ""
  echo "## 2. Infraestructura y Servicios de Motores Delphix Continuous Compliance"
  echo ""
  echo "### 2.1. Motores Delphix Continuous Compliance Registrados (Masking Engines)"
  echo ""
  echo "Tabla resumen de los motores de enmascaramiento (Continuous Compliance) registrados en Delphix DCT, su versión, dirección IP/hostname, estado de conexión y recursos asignados:"
  echo ""

  if [[ "${MASKING_ENGINES_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron motores de enmascaramiento (Masking) registrados en la instancia actual._"
    echo ""
  else
    echo "| Nombre Motor | Tipo | Versión | Estado Conexión | Cores CPU | Memoria RAM | Almacenamiento Total |"
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

  echo "| Nombre Motor | Parámetro de Red | Valor Configurado |"
  echo "| :--- | :--- | :--- |"
  if [[ "${MASKING_ENGINES_COUNT}" -eq 0 ]]; then
    echo "| **-** | **Dirección IP / Hostname** | - |"
    echo "| **-** | **Gateway / Puerta de Enlace** | <**Gateway**> |"
    echo "| **-** | **Servidores DNS** | <**Servidores DNS**> |"
    echo "| **-** | **Servidores NTP** | <**Servidores NTP**> |"
  else
    echo "${RAW_ENGINES_JSON}" | jq -r '
      [.items[] | select(.type == "MASKING")] | sort_by(.name)[] |
      [
        "| **" + (.name // "-") + "** | **Dirección IP / Hostname** | `" + (.hostname // "-") + "` |",
        "| **" + (.name // "-") + "** | **Gateway / Puerta de Enlace** | <**Gateway**> |",
        "| **" + (.name // "-") + "** | **Servidores DNS** | <**Servidores DNS**> |",
        "| **" + (.name // "-") + "** | **Servidores NTP** | <**Servidores NTP**> |"
      ] | .[]
    '
  fi
  echo ""
  echo "### 2.2. Configuración de Servicios de Infraestructura (SMTP y Autenticación LDAP / Active Directory)"
  echo ""
  echo "#### 2.2.1. Configuración del Servidor de Correo (SMTP)"
  echo ""
  echo "Tabla resumen de la configuración del servidor SMTP para notificaciones de eventos y alertas:"
  echo ""
  echo "| Parámetro SMTP | Valor Configurado |"
  echo "| :--- | :--- |"
  echo "${RAW_SMTP_JSON}" | jq -r '
    [
      "| **Servidor SMTP (Host)** | `" + (.hostname // .host // "-") + "` |",
      "| **Puerto** | `" + ((.port // "-") | tostring) + "` |",
      "| **Estado Habilitado (Enabled)** | `" + ((.enabled // false) | tostring) + "` |",
      "| **Autenticación Habilitada (Auth)** | `" + ((.authentication_enabled // false) | tostring) + "` |",
      "| **Cifrado TLS** | `" + ((.tls_enabled // false) | tostring) + "` |",
      "| **Dirección Remitente (From)** | `" + (.from_address // "-") + "` |"
    ] | .[]
  '
  echo ""
  echo "#### 2.2.2. Configuración de Autenticación LDAP / Controlador de Dominio (Active Directory)"
  echo ""
  echo "Tabla resumen de la integración con LDAP / Active Directory para autenticación de usuarios:"
  echo ""
  echo "| Parámetro LDAP / Active Directory | Valor Configurado |"
  echo "| :--- | :--- |"
  echo "${RAW_LDAP_JSON}" | jq -r '
    [
      "| **Integración LDAP Habilitada** | `" + ((.enabled // false) | tostring) + "` |",
      "| **Servidor Host LDAP / Controlador de Dominio** | `" + (.hostname // .host // "-") + "` |",
      "| **Puerto** | `" + ((.port // "-") | tostring) + "` |",
      "| **Dominios Registrados** | " + (if .domains and (.domains | length) > 0 then ([.domains[] | "`" + . + "`"] | join(", ")) else "-" end) + " |",
      "| **Auto-creación de Usuarios** | `" + ((.auto_create_users // false) | tostring) + "` |",
      "| **Conexión Segura (SSL)** | `" + ((.enable_ssl // false) | tostring) + "` |"
    ] | .[]
  '
  echo ""
  echo "---"
  echo ""
  echo "## 3. Algoritmos de Consulta de Archivo TXT (\`Secure Lookup\` / \`Name\`)"
  echo ""
  echo "Tabla resumen de los algoritmos sencillos basados en archivos de texto de valores de reemplazo:"
  echo ""

  if [[ "${SIMPLE_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron algoritmos simples con el prefijo especificado._"
    echo ""
  else
    echo "| Algoritmo | Framework | Archivo TXT Utilizado | Motor / Engine | Descripción |"
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
  echo "## 3. Algoritmos Compuestos (\`FullName\`)"
  echo ""
  echo "Tabla detallada del algoritmo compuesto \`FullName\` y los algoritmos sencillos que lo integran:"
  echo ""

  if [[ "${COMPOSITE_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron algoritmos compuestos (FullName) con el prefijo especificado._"
    echo ""
  else
    echo "| Algoritmo Compuesto | Framework | Componente Nombres (First Name) | Archivo TXT Nombres | Componente Apellidos (Last Name) | Archivo TXT Apellidos | Descripción |"
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
  echo "## 4. Dominios (Data Classes) y su Relación con Algoritmos"
  echo ""
  echo "Tabla de relación entre los dominios (Data Classes) definidos y su algoritmo de enmascaramiento asignado:"
  echo ""

  if [[ "${TOTAL_DC_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron dominios (Data Classes) con el prefijo especificado._"
    echo ""
  else
    echo "| Dominio (Data Class) | Algoritmo Asignado | Motor / Engine |"
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
  echo "## 5. Clasificadores de Profiling (Classifiers)"
  echo ""
  echo "Desglose de clasificadores utilizados en las reglas de perfilado (Profiling), categorizados por tipo de Framework:"
  echo ""

  echo "### 5.1. Clasificadores de Nombre de Columna y Expresión Regular (PATH / REGEX)"
  echo ""
  echo "| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Expresión Regular (Regex) | Motor / Engine |"
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

  echo "### 5.2. Clasificadores de Lista de Valores (LIST)"
  echo ""
  echo "| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Nombre de Archivo TXT | Motor / Engine |"
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

  echo "### 5.3. Clasificadores de Tipo de Datos (DATA_TYPE)"
  echo ""
  echo "| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Tipos de Datos Permitidos | Motor / Engine |"
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
  echo "## 6. Profile Sets (Discovery Policies) y Clasificadores Asignados"
  echo ""
  echo "Relación entre el Profile Set de perfilado y la lista completa de clasificadores que lo componen:"
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
        echo "| Profile Set (Discovery Policy) | Lista de Clasificadores (Classifiers) |"
        echo "| :--- | :--- |"
        HAS_ANY_DP=true
      fi
      echo "| **${dp_name}** | ${cl_list_str} |"
    fi
  done

  if [[ "${HAS_ANY_DP}" == false ]]; then
    echo "_No se encontraron Profile Sets que contengan clasificadores con el prefijo '${PREFIX}'._"
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 7. Conexiones de Datos (Connectors) y Parámetros JDBC"
  echo ""
  echo "### 7.1. Conexiones de Datos Definidas"
  echo ""
  echo "Tabla resumen de las conexiones de datos (Connectors), incluyendo servidor, base de datos, esquema y usuario:"
  echo ""

  if [[ "${TOTAL_CONN_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron conexiones de datos en la instancia actual._"
    echo ""
  else
    echo "| Conexión (Connector) | Servidor / Host | Base de Datos | Esquema | Usuario | Tipo / Plataforma | Motor / Engine |"
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

  echo "### 7.2. Parámetros de Driver JDBC Configurados"
  echo ""
  echo "Tabla de parámetros del driver JDBC recuperados con valor configurado:"
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
          echo "| Conexión (Connector) | Parámetro Driver JDBC | Valor Configurado |"
          echo "| :--- | :--- | :--- |"
          HAS_ANY_JDBC=true
        fi
        echo "${props_rows}"
      fi
    fi
  done

  if [[ "${HAS_ANY_JDBC}" == false ]]; then
    echo "_No se encontraron parámetros de driver JDBC para las conexiones actuales._"
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 8. Rule Sets, Tablas y Asignación de Algoritmos / Dominios"
  echo ""
  echo "Relación de los Rule Sets definidos, sus tablas correspondientes, los elementos/columnas con algoritmos y dominios asignados, y sus llaves lógicas (Logical Keys):"
  echo ""

  echo "### 8.1. Rule Sets, Tablas y Asignación de Algoritmos / Dominios"
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
              "Llave Primaria"
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
    echo "_No se encontraron asignaciones de columnas/algoritmos en los Rule Sets actuales._"
    echo ""
  else
    echo "| Rule Set | Tabla (Table) | Columna (Column) | Dominio (Data Class) | Algoritmo Asignado |"
    echo "| :--- | :--- | :--- | :--- | :--- |"
    echo "${TABLE1_ROWS}"
    echo ""
  fi

  echo "### 8.2. Tablas de Base de Datos y Llaves Lógicas (Logical Keys)"
  echo ""

  if [[ -z "${TABLE2_ROWS}" ]]; then
    echo "_No se encontraron tablas registradas en los Rule Sets actuales._"
    echo ""
  else
    echo "| Rule Set | Tabla (Table) | Llave Lógica (Logical Key) |"
    echo "| :--- | :--- | :--- |"
    echo "${TABLE2_ROWS}" | sort -u
    echo ""
  fi
  echo ""

  echo "---"
  echo ""
  echo "## 10. Definición de Trabajos de Perfilado y Enmascaramiento (Jobs)"
  echo ""
  echo "### 10.1. Trabajos de Perfilado (Profiling / Discovery Jobs)"
  echo ""
  echo "Definición de los trabajos de perfilado (Discovery), asociación de Rule Set, Profile Set y atributos de ejecución:"
  echo ""

  if [[ "${PROFILING_JOBS_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron trabajos de perfilado (Profiling / Discovery) definidos._"
    echo ""
  else
    echo "| Trabajo (Job Name) | Tipo | Rule Set | Profile Set (Discovery Policy) | Conector / Plataforma | Tipo Ejecución | Motor / Engine | Ambiente / Aplicación |"
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

  echo "### 10.2. Trabajos de Enmascaramiento (Masking Jobs)"
  echo ""
  echo "Definición de los trabajos de enmascaramiento (Masking), asociación de Rule Set y atributos de enmascaramiento:"
  echo ""

  if [[ "${MASKING_JOBS_COUNT}" -eq 0 ]]; then
    echo "_No se encontraron trabajos de enmascaramiento (Masking) definidos._"
    echo ""
  else
    echo "| Trabajo (Job Name) | Tipo | Rule Set | On-The-Fly | Truncar Tablas | Eliminar Índices | Conector / Plataforma | Tipo Ejecución | Motor / Engine | Ambiente / Aplicación |"
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
  echo "## 11. Criterios de Configuración de Claves para el Rule Set (_In-Place Masking_)"
  echo ""
  echo "Como criterio general de arquitectura para futuras implementaciones de **_In-Place Masking_**, la definición de la identificación de registros dentro del _Rule Set_ debe cumplir con las siguientes directrices:"
  echo ""
  echo "**1. Uso de Clave Lógica (_Logical Key_):**"
  echo "Siempre que exista una columna (o conjunto de columnas) que garantice unicidad, valor no nulo y cuyas columnas **no sean objeto de enmascaramiento**, debe definirse explícitamente como _Logical Key_ en el _Rule Set_. Esto permite a la herramienta ejecutar las sentencias de actualización (\`UPDATE\`) de forma directa y optimizada mediante los índices existentes en el motor de base de datos."
  echo ""
  echo "**2. Mecanismo por Columna Temporal (_Identity Column_):**"
  echo "Cuando la tabla no disponga de una clave única con dichas características, o cuando la clave primaria/única existente esté compuesta por campos que requieran ser enmascarados, **no debe definirse ninguna _Logical Key_ en el _Rule Set_**. En estos escenarios, Delphix creará de forma automática una columna identidad temporal (\`MASK_ROW_ID\`) en la tabla destino para gestionar el puntero de enmascaramiento por lote, eliminándola automáticamente al concluir el _Job_."
  echo ""
  echo "### Resumen de Decisión (Matriz de Referencia)"
  echo ""
  echo "| **Escenario de la Tabla** | **Acción en el Rule Set** | **Mecanismo de Update** |"
  echo "| :--- | :--- | :--- |"
  echo "| Tiene PK/UQ no nula y sus campos **no** se enmascaran | Definir **Logical Key** explícita | Búsqueda por índice existente |"
  echo "| No tiene PK/UQ, o la clave existente **se enmascara** | **No definir** Logical Key | Columna identidad temporal (\`MASK_ROW_ID\`) |"
  echo ""

} > "${OUTPUT_FILE}"

printf "\033[0;32m[+] Documento generado exitosamente en: %s\033[0m\n" "${OUTPUT_FILE}"
