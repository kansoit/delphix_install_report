#!/usr/bin/env python3
"""Collect and normalize Delphix DCT data for the report renderer."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path
from typing import Any


FETCH_WORKERS = 4
PAGE_SIZE = 1000


def text(value: Any, fallback: str = "-") -> str:
    if value is None or value == "":
        return fallback
    return str(value)


def file_name(value: Any) -> str:
    if value is None or value == "":
        return "-"
    return str(value).rstrip("/").rsplit("/", 1)[-1]


def engine(value: Any) -> str:
    return text(value, "DCT / Global")


def get_value(obj: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = obj.get(key)
        if value is not None and value != "":
            return value
    return None


class DCTClient:
    def __init__(self, binary: str, page_size: int) -> None:
        self.binary = binary
        self.page_size = page_size

    def call(self, command: str, *parameters: str) -> dict[str, Any]:
        process = subprocess.run(
            [self.binary, command, *parameters, "-js"],
            check=True,
            text=True,
            capture_output=True,
        )
        try:
            value = json.loads(process.stdout)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid JSON returned by {command}: {exc}") from exc
        if not isinstance(value, dict):
            raise RuntimeError(f"Unexpected response from {command}: expected an object")
        return value

    def once(self, command: str, *parameters: str) -> dict[str, Any]:
        return self.call(command, *parameters)

    def paged(self, command: str, *parameters: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        cursor: str | None = None
        page = 0

        while True:
            page += 1
            request = [*parameters, f"limit={self.page_size}"]
            if cursor:
                request.append(f"cursor={cursor}")
            response = self.call(command, *request)
            page_items = response.get("items", [])
            if isinstance(page_items, list):
                items.extend(item for item in page_items if isinstance(item, dict))

            metadata = response.get("response_metadata") or {}
            next_cursor = metadata.get("next_cursor")
            if not next_cursor or next_cursor == cursor:
                return items
            if page >= 10000:
                raise RuntimeError(f"Too many pages while collecting {command}")
            cursor = str(next_cursor)


def parallel_map(values: list[Any], function: Any) -> list[Any]:
    """Run independent DCT calls concurrently while preserving input order."""
    if not values:
        return []
    with ThreadPoolExecutor(max_workers=FETCH_WORKERS) as executor:
        return list(executor.map(function, values))


def classifier_weight(item: dict[str, Any]) -> str:
    config = item.get("config") or {}
    if config.get("matchStrength") is not None:
        return str(config["matchStrength"])
    for key in ("paths", "dataPatterns", "valueLists"):
        values = config.get(key)
        if values:
            strengths = sorted({str(value.get("matchStrength")) for value in values})
            return ", ".join(strengths) or "-"
    return "-"


def classifier_values(item: dict[str, Any]) -> str:
    config = item.get("config") or {}
    framework = item.get("framework")
    if framework == "PATH":
        values = [value.get("fieldValue") for value in config.get("paths", [])]
        rendered = []
        for value in values:
            if value is not None:
                escaped = str(value).replace("|", "\\|")
                rendered.append(f"`{escaped}`")
        return "<br>".join(rendered) or "-"
    if framework == "REGEX":
        values = [value.get("regex") for value in config.get("dataPatterns", [])]
        rendered = []
        for value in values:
            if value is not None:
                escaped = str(value).replace("|", "\\|")
                rendered.append(f"`{escaped}`")
        return "<br>".join(rendered) or "-"
    if framework == "LIST":
        values = [file_name(value.get("file")) for value in config.get("valueLists", [])]
        return "<br>".join(f"`{value}`" for value in values if value != "-") or "-"
    if framework == "DATA_TYPE":
        result = []
        for value in config.get("allowedTypes", []):
            item_value = text(value.get("typeName"), "-")
            if value.get("minimumLength") is not None:
                item_value += f" (min: {value['minimumLength']})"
            result.append(item_value)
        return ", ".join(result) or "-"
    return "-"


def safe_client_name(client: str) -> str:
    value = client.replace(" ", "_").replace("/", "_")
    return re.sub(r"[^A-Za-z0-9_.-]", "", value)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect and normalize Delphix DCT data.",
        epilog=(
            "Example:\n"
            "  ./cc_install_report_fetch.py \\\n"
            "    -c \"ACME Corp\" \\\n"
            "    -p \"0-\" \\\n"
            "    -o \"ACME_Corp_$(date +%Y%m%d-%H%M%S).json\" \\\n"
            "    -s \"ASDD Spanish\""
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-c", "--client", required=True)
    parser.add_argument("-p", "--prefix", required=True)
    parser.add_argument("-o", "--output", dest="data_file", metavar="JSON_FILE", required=True)
    parser.add_argument("--data-output", dest="data_file", help=argparse.SUPPRESS)
    parser.add_argument("-s", "--profile-set", action="append", dest="profile_sets", metavar="PROFILE_SET", required=True)
    if len(sys.argv) == 1:
        parser.print_help()
        raise SystemExit(0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    binary = os.environ.get("DCT_TOOLKIT_BIN", str(Path.home() / ".local/bin/dct-toolkit"))
    if not os.access(binary, os.X_OK):
        print(f"ERROR: Toolkit not found or not executable: {binary}", file=sys.stderr)
        return 1
    allowed_profiles = args.profile_sets

    script_dir = Path(__file__).resolve().parent
    data_file = Path(args.data_file)
    if not data_file.is_absolute():
        data_file = script_dir / data_file
    data_file.parent.mkdir(parents=True, exist_ok=True)

    try:
        dct = DCTClient(binary, PAGE_SIZE)
        print("[+] Collecting JSON data from DCT...")
        initial_calls = [
            ("paged", "get_registered_engines"),
            ("once", "get_smtp_config"),
            ("once", "get_ldap_config"),
            ("paged", "get_algorithms"),
            ("paged", "get_data_classes"),
            ("paged", "get_classifiers"),
            ("paged", "get_discovery_policies"),
            ("paged", "get_connectors"),
            ("paged", "get_rule_sets"),
            ("paged", "get_compliance_jobs"),
        ]

        def run_initial(call: tuple[str, str]) -> Any:
            method, command = call
            return getattr(dct, method)(command)

        (
            engines_raw, smtp, ldap, algorithms_raw, data_classes_raw,
            classifiers_raw, policies_raw, connectors_raw, rule_sets_raw, jobs_raw,
        ) = parallel_map(initial_calls, run_initial)

        selected_policies = [policy for policy in policies_raw if policy.get("name") in allowed_profiles]
        def fetch_policy_classifiers(policy: dict[str, Any]) -> tuple[str, list[dict[str, Any]]]:
            policy_id = str(policy.get("id"))
            return policy_id, dct.paged(
                "get_discovery_policy_classifiers", f"discovery_policy_id={policy_id}"
            )

        policy_classifiers = dict(parallel_map(selected_policies, fetch_policy_classifiers))

        def fetch_connection_properties(connector: dict[str, Any]) -> dict[str, Any] | None:
            if connector.get("dct_managed") is not True:
                return None
            try:
                raw_properties = dct.once("get_connection_properties", f"connector_id={connector.get('id')}")
            except (RuntimeError, subprocess.CalledProcessError):
                return None
            values = raw_properties.get("items", []) if isinstance(raw_properties, dict) else raw_properties
            if isinstance(values, list):
                return {
                    "connector_name": connector.get("name"),
                    "items": values,
                }
            return None

        connection_properties = [
            value for value in parallel_map(connectors_raw, fetch_connection_properties)
            if value is not None
        ]

        rule_tables_raw: list[dict[str, Any]] = []
        def fetch_rule_set_tables(rule_set: dict[str, Any]) -> list[dict[str, Any]]:
            rule_set_id = rule_set.get("id")
            tables = dct.paged("search_database_table_metadata", f"rule_set_id={rule_set_id}")
            def fetch_table(table: dict[str, Any]) -> dict[str, Any]:
                table_id = table.get("id")
                columns = dct.paged(
                    "search_database_column_metadata", f"database_table_metadata_id={table_id}"
                )
                return {
                    "rule_set_name": rule_set.get("name"),
                    "table_name": table.get("table_name"),
                    "key_column": table.get("key_column") or "",
                    "columns": columns,
                }
            return parallel_map(tables, fetch_table)

        for tables in parallel_map(rule_sets_raw, fetch_rule_set_tables):
            rule_tables_raw.extend(tables)

        def prefixed(item: dict[str, Any]) -> bool:
            return str(item.get("name") or "").startswith(args.prefix)

        simple_algorithms = []
        composite_algorithms = []
        for item in algorithms_raw:
            if not prefixed(item):
                continue
            if item.get("framework_name") == "FullName":
                continue
            simple_algorithms.append({
                "name": text(item.get("name")),
                "framework": text(item.get("framework_name")),
                "lookup_file": file_name(((item.get("config") or {}).get("lookupFile") or {}).get("uri")),
                "engine": engine(item.get("engine_name")),
                "description": text(item.get("description")).replace("\r", "").replace("\n", " "),
            })
        algorithm_by_name = {item.get("name"): item for item in algorithms_raw}
        for item in algorithms_raw:
            if not prefixed(item) or item.get("framework_name") != "FullName":
                continue
            config = item.get("config") or {}
            first_name = ((config.get("firstNameAlgorithmRef") or {}).get("name"))
            last_name = ((config.get("lastNameAlgorithmRef") or {}).get("name"))
            first = algorithm_by_name.get(first_name, {})
            last = algorithm_by_name.get(last_name, {})
            composite_algorithms.append({
                "name": text(item.get("name")), "first_name": text(first_name), "last_name": text(last_name),
                "first_file": file_name(((first.get("config") or {}).get("lookupFile") or {}).get("uri")),
                "last_file": file_name(((last.get("config") or {}).get("lookupFile") or {}).get("uri")),
                "description": text(item.get("description")).replace("\r", "").replace("\n", " "),
            })
        simple_algorithms.sort(key=lambda item: item["name"])
        composite_algorithms.sort(key=lambda item: item["name"])

        masking_engines = []
        for item in engines_raw:
            if item.get("type") != "MASKING":
                continue
            def size(value: Any) -> str:
                if value is None:
                    return "-"
                rendered = f"{round(float(value) / 1073741824 * 10) / 10:.1f}".rstrip("0").rstrip(".")
                return f"{rendered} GB"
            masking_engines.append({
                "name": text(item.get("name")), "type": text(item.get("type"), "MASKING"),
                "version": text(item.get("version")), "status": text(get_value(item, "connection_status", "status")),
                "cpu": f"{item['cpu_core_count']} Cores" if item.get("cpu_core_count") is not None else "-",
                "memory": size(item.get("memory_size")), "storage": size(item.get("data_storage_capacity")),
                "hostname": text(item.get("hostname")), "gateway": "<Gateway>",
                "dns": "<Servidores DNS>", "ntp": "<Servidores NTP>",
            })
        masking_engines.sort(key=lambda item: item["name"])

        classifier_groups = {"PATH": [], "REGEX": [], "LIST": [], "DATA_TYPE": []}
        for item in classifiers_raw:
            if not prefixed(item) or item.get("framework") not in classifier_groups:
                continue
            classifier_groups[item["framework"]].append({
                "name": text(item.get("name")), "framework": text(item.get("framework")),
                "data_class": text(item.get("data_class_name")), "weight": classifier_weight(item),
                "values": classifier_values(item), "engine": engine(item.get("engine_name")),
            })
        classifiers_path_regex = classifier_groups["PATH"] + classifier_groups["REGEX"]
        classifiers_path_regex.sort(key=lambda item: (item["engine"], item["name"]))
        classifiers_list = sorted(classifier_groups["LIST"], key=lambda item: (item["engine"], item["name"]))
        classifiers_data_type = sorted(classifier_groups["DATA_TYPE"], key=lambda item: (item["engine"], item["name"]))

        profile_sets = []
        for policy in sorted(selected_policies, key=lambda item: item.get("name") or ""):
            classifiers = [item.get("name") for item in policy_classifiers.get(str(policy.get("id")), []) if str(item.get("name") or "").startswith(args.prefix)]
            profile_sets.append({"name": text(policy.get("name")), "classifiers": ", ".join(f"`{name}`" for name in sorted(classifiers))})

        def connector_engine(item: dict[str, Any]) -> str:
            return text(item.get("engine_name") or (f"{item['job_orchestrator_name']} (Orchestrator)" if item.get("job_orchestrator_name") else None), "DCT / Global")

        connectors = sorted([
            {"name": text(item.get("name")), "host": text(item.get("hostname")), "database": text(item.get("database_name")),
             "schema": text(item.get("schema_name")), "user": text(item.get("username")), "platform": text(item.get("platform")),
             "engine": connector_engine(item)} for item in connectors_raw
        ], key=lambda item: item["name"])
        jdbc_properties = []
        for connection in connection_properties:
            for item in connection.get("items", []):
                if item.get("edited") not in (None, False) or item.get("value") in (None, ""):
                    continue
                jdbc_properties.append({"connector": connection.get("connector_name"), "name": text(item.get("name")), "value": str(item.get("value")).replace("|", "\\|")})

        rule_columns = []
        rule_tables = []
        for table in rule_tables_raw:
            columns = [column for column in table["columns"] if column.get("is_sensitive") is True or column.get("algorithm_name") is not None or column.get("data_class_name") is not None]
            for column in sorted(columns, key=lambda item: item.get("column_name") or ""):
                rule_columns.append({"rule_set": table["rule_set_name"], "table": table["table_name"], "column": text(column.get("column_name")), "data_class": text(column.get("data_class_name")), "algorithm": text(column.get("algorithm_name"))})
            logical_key = table["key_column"]
            if not logical_key and any(column.get("is_primary_key") is True for column in table["columns"]):
                logical_key = "Llave Primaria"
            rule_tables.append({"rule_set": table["rule_set_name"], "table": table["table_name"], "logical_key": logical_key or "-"})
        rule_tables.sort(key=lambda item: (item["rule_set"], item["table"]))

        profiling_jobs = []
        masking_jobs = []
        for item in jobs_raw:
            common = {"name": text(item.get("name")), "type": text(item.get("type")), "rule_set": text(item.get("rule_set_name")),
                      "connector": text(item.get("connector_type")), "execution": text(item.get("execution_type"), "STANDARD"),
                      "engine": engine(item.get("engine_name")), "environment": text(item.get("environment_name")), "application": text(item.get("application_name"))}
            if item.get("type") in ("DISCOVERY", "PROFILING"):
                profiling_jobs.append({**common, "profile_set": text(item.get("discovery_policy_name"))})
            elif item.get("type") == "MASKING":
                masking_jobs.append({**common, "on_the_fly": str(bool(item.get("is_on_the_fly_masking", False))).lower(), "truncate": str(bool(item.get("truncate_tables", False))).lower(), "drop_indexes": str(bool(item.get("drop_indexes", False))).lower()})
        masking_jobs.sort(key=lambda item: item["name"])

        smtp = smtp if isinstance(smtp, dict) else {}
        ldap = ldap if isinstance(ldap, dict) else {}
        ldap_domains = ldap.get("domains") or []
        report = {
            "client": args.client, "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "prefix": args.prefix,
            "detected_version": next((item.get("version") for item in engines_raw if item.get("type") == "MASKING" and item.get("version")), next((item.get("version") for item in engines_raw if item.get("version")), "2026.X.0.0")),
            "masking_engine_count": len(masking_engines), "engines": masking_engines,
            "smtp": {"host": text(get_value(smtp, "hostname", "host")), "port": text(smtp.get("port")), "enabled": str(bool(smtp.get("enabled", False))).lower(), "authentication": str(bool(smtp.get("authentication_enabled", False))).lower(), "tls": str(bool(smtp.get("tls_enabled", False))).lower(), "from": text(smtp.get("from_address"))},
            "ldap": {"enabled": str(bool(ldap.get("enabled", False))).lower(), "host": text(get_value(ldap, "hostname", "host")), "port": text(ldap.get("port")), "domains": ", ".join(f"`{value}`" for value in ldap_domains) or "-", "auto_create_users": str(bool(ldap.get("auto_create_users", False))).lower(), "ssl": str(bool(ldap.get("enable_ssl", False))).lower()},
            "simple_algorithms": simple_algorithms, "composite_algorithms": composite_algorithms,
            "data_classes": sorted([{"name": text(item.get("name")), "algorithm": text(item.get("default_algorithm_name")), "engine": engine(item.get("engine_name"))} for item in data_classes_raw if prefixed(item)], key=lambda item: item["name"]),
            "classifiers_path_regex": classifiers_path_regex, "classifiers_list": classifiers_list, "classifiers_data_type": classifiers_data_type,
            "profile_sets": profile_sets,
            "connectors": connectors, "jdbc_properties": jdbc_properties,
            "rule_sets": sorted([{
                "name": text(item.get("name")),
                "engine": engine(item.get("engine_name")),
                "description": text(item.get("description")),
                "id": text(item.get("id")),
            } for item in rule_sets_raw], key=lambda item: item["name"]),
            "rule_columns": rule_columns, "rule_tables": rule_tables,
            "profiling_jobs": profiling_jobs, "masking_jobs": masking_jobs,
        }
        data_file.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"[+] Normalized data generated at: {data_file}")
        return 0
    except (OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
