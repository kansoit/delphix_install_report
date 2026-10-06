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

The report tools require Node.js 24 and npm. Install Node.js with NVM,
following the official Node.js installation procedure:

```bash
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash

# Load nvm without restarting the shell:
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v  # Should print "v24.21.0".

# Verify the npm version:
npm -v   # Should print "11.19.0".
```

Install and verify Knap:

```bash
npm install -g knap
knap --version
knap --help
```

The report scripts invoke `knap` directly. Verify that NVM exposes the global
npm binaries on `PATH`:

```bash
command -v knap
knap --version
```

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
  --client "ACME Corp" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/acme-corp.json
```

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
| `-o`, `--output FILE.md` | Required output Markdown file. |
| `-t`, `--template FILE.md` | Required template used for rendering. |
| `-h`, `--help` | Display help. |

Example:

```bash
./cc_install_report_render.py -i ACME_Corp_20261003-115138.json \
  -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
  -t "cc_install_report_sp.md"
```

Render in Portuguese or English by selecting the template explicitly:

```bash
./cc_install_report_render.py \
  -i ACME_Corp_20261003-115138.json \
  -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
  -t "cc_install_report_pt.md"

./cc_install_report_render.py \
  -i ACME_Corp_20261003-115138.json \
  -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
  -t "cc_install_report_en.md"
```

Before rendering, the script:

1. Verifies that the JSON exists and is valid.
2. Validates the template.
3. Runs the render operation.
4. Adds a final newline to keep the output compatible with the original report.

The output path is always supplied explicitly with `-o`/`--output`.

## Complete wrapper

To generate the final report directly:

```bash
./cc_install_report.py \
  -c "ACME Corp" \
  -p "0-" \
  -o "ACME_Corp_$(date +%Y%m%d-%H%M%S).md" \
  -t cc_install_report_sp.md \
  -s "ASDD Spanish"
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
  --client "ACME Corp" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/acme-corp.json

./cc_install_report_render.py \
  --input report-data/acme-corp.json \
  --template cc_install_report_sp.md \
  --output "ACME Corp - Reporte Configuracion Delphix Continuous Compliance.md"
```

This allows the Markdown to be regenerated multiple times without querying DCT again:

```bash
./cc_install_report_render.py \
  --input report-data/acme-corp.json \
  --template cc_install_report_sp.md \
  --output /tmp/reviewed-report.md
```

## Environment variables

| Variable | Purpose | Default |
| :--- | :--- | :--- |
| `DCT_TOOLKIT_BIN` | Optional path to the `dct-toolkit` executable. | `~/.local/bin/dct-toolkit` |

No variable is required when `dct-toolkit` is installed at the default path:

```bash
./cc_install_report_fetch.py \
  --client "ACME Corp" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/acme-corp.json
```

Use `DCT_TOOLKIT_BIN` only when the executable is installed somewhere else:

```bash
DCT_TOOLKIT_BIN="/opt/dct-toolkit/bin/dct-toolkit" \
./cc_install_report_fetch.py \
  --client "ACME Corp" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/acme-corp.json
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
python3 -m json.tool report-data/acme-corp.json >/dev/null
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
