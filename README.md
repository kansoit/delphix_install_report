# Delphix Install Report

Generator for Delphix Continuous Compliance Markdown reports using information retrieved from Data Control Tower (DCT).

The project separates data collection from document generation:

```text
DCT Toolkit → fetcher → report-data.json → renderer → report.md
```

Three equivalent templates are provided:

- `cc_install_report_sp.md` — Spanish.
- `cc_install_report_pt.md` — Portuguese.
- `cc_install_report_en.md` — English.

## Installation

This section currently covers the Knap prerequisite only. The project repository installation procedure will be added once the GitHub repository is defined.

### Online installation

Knap requires Node.js 20 or later. Verify the runtime first:

```bash
node --version
npm --version
```

Install Knap globally with npm:

```bash
npm install -g knap
```

Verify the installation:

```bash
knap --version
knap --help
```

The report scripts require `knap` to be available on `PATH`. `npx knap` is also supported for manual Knap commands, but it does not satisfy the current renderer prerequisite unless the renderer is changed to invoke `npx`.

### Offline installation

Offline installation is possible, but Node.js 20 or later must already be installed on the target machine. The safest approach is to prepare a complete local bundle on an Internet-connected machine, including Knap and its npm dependencies.

On the online machine:

```bash
mkdir knap-offline
cd knap-offline
npm install --prefix ./bundle knap
tar -czf knap-offline.tar.gz bundle
```

Transfer `knap-offline.tar.gz` to the offline machine and extract it, for example under `~/.local/opt`:

```bash
mkdir -p "$HOME/.local/opt"
tar -xzf knap-offline.tar.gz -C "$HOME/.local/opt"
export PATH="$HOME/.local/opt/bundle/node_modules/.bin:$PATH"
knap --version
```

For a persistent user-level command, create a link after verifying the bundle:

```bash
ln -sfn "$HOME/.local/opt/bundle/node_modules/.bin/knap" \
  "$HOME/.local/bin/knap"
```

This bundle method avoids relying on the npm registry or an npm cache on the offline machine. It does not include Node.js itself; if Node.js is also missing, it must be installed or transferred separately as a compatible runtime.

The alternative below can work when the required package and dependency tarballs already exist in the local npm cache, but it is less reliable for a clean offline machine:

```bash
npm install --global --offline ./knap-*.tgz
```

### Knap installation decision

No project-specific package needs to be built for Knap. For online environments, npm installation is sufficient. For offline environments, we should distribute a versioned bundle containing the installed Node.js packages, and separately ensure that Node.js 20 or later is available.

## Requirements

- `dct-toolkit`
- `knap`
- Network access to DCT
- A configured `dct-toolkit` properties file

By default, the fetcher looks for the toolkit at:

```text
~/.local/bin/dct-toolkit
```

This can be changed with the `DCT_TOOLKIT_BIN` environment variable.

## Current components

### `cc_install_report_fetch.py`

The Python fetcher is the implementation used by the complete wrapper. It can
also be executed independently and writes the normalized JSON consumed by the
renderer.

Built-in help:

```bash
./cc_install_report_fetch.py --help
```

Syntax:

```bash
./cc_install_report_fetch.py [options]
```

It supports the report parameters documented below. The toolkit binary can be
overridden with `DCT_TOOLKIT_BIN`.

Queries DCT, follows all available pages, applies filters, and generates normalized JSON. It does not generate Markdown and does not depend on Knap.

### `cc_install_report_render.py`

Receives normalized JSON and generates Markdown using the selected template. It does not query DCT.

### `cc_install_report.py`

Convenience wrapper. Runs the Python fetcher and renderer in a single operation. The intermediate JSON is created temporarily and removed when the process finishes.

### Report templates

The templates define the same report structure, fields, tables, and formatting in Spanish, Portuguese, and English.

## Fetcher

Built-in help:

```bash
./cc_install_report_fetch.py --help
```

Syntax:

```bash
./cc_install_report_fetch.py [options]
```

Parameters:

| Parameter | Description |
| :--- | :--- |
| `-c`, `--client CLIENT` | Client name included in the data and report. |
| `-p`, `--prefix PREFIX` | Prefix used to filter algorithms, data classes, and classifiers. |
| `-o`, `--output FILE.json` | Required output path for the normalized JSON. |
| `-s`, `--profile-set NAME` | Required Profile Set selection; may be repeated. |
| `-h`, `--help` | Display help. |

To generate a report for only the Spanish Profile Set:

```bash
./cc_install_report_fetch.py \
  --client "Omarchy Test" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/omarchy-test.json
```

### Pagination

The fetcher does not limit the total number of results. It repeatedly queries DCT using `response_metadata.next_cursor` until all records have been retrieved.

The fetcher uses an internal page size of `1000` and continues until DCT
returns no next cursor; this is not a result limit.

```bash
./cc_install_report_fetch.py \
  --client "Demo Client" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/demo-client.json
```

The page size controls only the size of each request; it is not a result limit.

## Renderer

Built-in help:

```bash
./cc_install_report_render.py --help
```

Syntax:

```bash
./cc_install_report_render.py [options]
```

Parameters:

| Parameter | Description |
| :--- | :--- |
| `-i`, `--input FILE.json` | Required input normalized JSON. |
| `-o`, `--output FILE.md` | Required output Markdown file. Also accepts `--output-file`. |
| `-t`, `--template FILE.md` | Required template used for rendering. |
| `-h`, `--help` | Display help. |

Example:

```bash
./cc_install_report_render.py \
  --input /tmp/report-data.json \
  --output /tmp/report.md
```

Render in Portuguese or English by selecting the template explicitly:

```bash
./cc_install_report_render.py \
  --input /tmp/report-data.json \
  --template cc_install_report_pt.md \
  --output /tmp/report-pt.md

./cc_install_report_render.py \
  --input /tmp/report-data.json \
  --template cc_install_report_en.md \
  --output /tmp/report-en.md
```

Before rendering, the script:

1. Verifies that the JSON exists and is valid.
2. Validates the template.
3. Runs the render operation.
4. Adds a final newline to keep the output compatible with the original report.

When `-o` is omitted, the output filename is built from `.client` in the JSON:

```text
<client> - Reporte Configuracion Delphix Continuous Compliance.md
```

## Complete wrapper

To generate the final report directly:

```bash
./cc_install_report.py \
  --client "Omarchy Test" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --template cc_install_report_sp.md \
  --output /tmp/final-report.md
```

The wrapper:

1. Runs the fetcher.
2. Stores the intermediate JSON in a temporary file.
3. Runs the renderer.
4. Deletes the temporary JSON.

To preserve the JSON for auditing or future regeneration, run the fetcher and renderer separately.

## Recommended workflow for preserving data

```bash
./cc_install_report_fetch.py \
  --client "Demo Client" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/demo-client.json

./cc_install_report_render.py \
  --input report-data/demo-client.json \
  --template cc_install_report_sp.md \
  --output "Demo Client - Reporte Configuracion Delphix Continuous Compliance.md"
```

This allows the Markdown to be regenerated multiple times without querying DCT again:

```bash
./cc_install_report_render.py \
  --input report-data/demo-client.json \
  --template cc_install_report_sp.md \
  --output /tmp/reviewed-report.md
```

## Environment variables

| Variable | Purpose | Default |
| :--- | :--- | :--- |
| `DCT_TOOLKIT_BIN` | Path to the `dct-toolkit` executable. | `~/.local/bin/dct-toolkit` |

Example:

```bash
DCT_TOOLKIT_BIN=/opt/dct-toolkit/bin/dct-toolkit \
./cc_install_report_fetch.py \
  --client "Demo Client" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/demo-client.json
```

## Quick checks

Validate the Python entry points:

```bash
python3 -m py_compile cc_install_report_fetch.py
python3 -m py_compile cc_install_report.py
python3 -m py_compile cc_install_report_render.py
```

Validate the template:

```bash
knap validate cc_install_report_sp.md
```

Validate a generated JSON file:

```bash
python3 -m json.tool report-data/demo-client.json >/dev/null
```

Compare two reports:

```bash
diff -u original-report.md new-report.md
```

## Report coverage

The normalized JSON and template cover:

- Masking Engines.
- SMTP and LDAP configuration.
- Simple and composite algorithms.
- Data Classes.
- PATH, REGEX, LIST, and DATA_TYPE classifiers.
- Profile Sets and associated classifiers.
- Connectors and JDBC properties.
- Rule Sets, tables, columns, and Logical Keys.
- Profiling and Masking jobs.

The collection phase preserves the data as JSON, while the presentation phase remains isolated in the template. This makes it possible to change the report format without querying DCT again.
