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

This section documents the runtime prerequisites. The report host may be
isolated from the Internet, but it still needs network access to the private
DCT endpoint.

### Online installation on RHEL 9.8

Knap requires Node.js 20 or later and npm. First check whether a suitable
module stream is already available:

```bash
sudo dnf module list nodejs
```

If RHEL provides a Node.js 20 or newer stream through the configured
repositories, install it directly. For the Node.js 20 stream:

```bash
sudo dnf module install -y nodejs:20
```

If the required stream is not available, use the official Node.js LTS binary
bundle. Replace `NODE_VERSION` with the approved current LTS version:

```bash
NODE_VERSION=24.21.0
NODE_ARCHIVE="node-v${NODE_VERSION}-linux-x64.tar.xz"

curl -fLO "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_ARCHIVE}"
sudo mkdir -p /opt/node
sudo tar -xJf "${NODE_ARCHIVE}" -C /opt/node
sudo ln -sfn "/opt/node/node-v${NODE_VERSION}-linux-x64" /opt/node/current
sudo ln -sfn /opt/node/current/bin/node /usr/local/bin/node
sudo ln -sfn /opt/node/current/bin/npm /usr/local/bin/npm
sudo ln -sfn /opt/node/current/bin/npx /usr/local/bin/npx
```

For ARM64, use the corresponding `linux-arm64` archive and adjust the
installation directory name in the symbolic link.

Verify the runtime before installing Knap:

```bash
node --version
npm --version
```

Install and verify Knap:

```bash
npm install -g knap
knap --version
knap --help
```

The report scripts require `knap` to be available on `PATH`. `npx knap`
may be used for manual commands, but it does not satisfy the current renderer
prerequisite.

### Offline installation for RHEL 9.8

For a customer environment without Internet access, prepare the complete
bundle on an Internet-connected RHEL 9.8 machine with the same CPU
architecture. The bundle should contain:

- Node.js 20 or later.
- Knap and all npm dependencies.
- The report repository and its three templates.
- `dct-toolkit`.
- The matching `dct-toolkit.properties` file.

The properties file may contain credentials or private connection details.
Transfer it securely and never commit it to Git or include it in a public
artifact.

On the connected preparation machine:

```bash
NODE_VERSION=24.21.0
NODE_ARCHIVE="node-v${NODE_VERSION}-linux-x64.tar.xz"

mkdir -p node-knap-offline/node node-knap-offline/knap
curl -fLO "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_ARCHIVE}"
tar -xJf "${NODE_ARCHIVE}" \
  -C node-knap-offline/node \
  --strip-components=1
npm install --prefix ./node-knap-offline/knap knap
tar -czf node-knap-offline.tar.gz node-knap-offline
```

Transfer `node-knap-offline.tar.gz`, the report repository, `dct-toolkit`,
and the properties file through the customer's approved media or transfer
process. On the offline report host:

```bash
mkdir -p "$HOME/.local/opt"
tar -xzf node-knap-offline.tar.gz -C "$HOME/.local/opt"
export PATH="$HOME/.local/opt/node-knap-offline/node/bin:$HOME/.local/opt/node-knap-offline/knap/node_modules/.bin:$PATH"

node --version
npm --version
knap --version
```

For a persistent user-level installation:

```bash
mkdir -p "$HOME/.local/bin"
ln -sfn "$HOME/.local/opt/node-knap-offline/node/bin/node" "$HOME/.local/bin/node"
ln -sfn "$HOME/.local/opt/node-knap-offline/node/bin/npm" "$HOME/.local/bin/npm"
ln -sfn "$HOME/.local/opt/node-knap-offline/node/bin/npx" "$HOME/.local/bin/npx"
ln -sfn "$HOME/.local/opt/node-knap-offline/knap/node_modules/.bin/knap" "$HOME/.local/bin/knap"
```

Install the toolkit separately, for example:

```bash
install -m 0755 dct-toolkit "$HOME/.local/bin/dct-toolkit"
mkdir -p "$HOME/.config"
install -m 0640 dct-toolkit.properties "$HOME/.config/dct-toolkit.properties"
export DCT_TOOLKIT_BIN="$HOME/.local/bin/dct-toolkit"
```

The exact toolkit properties location must match the toolkit configuration
used by the customer. The fetcher only needs private network connectivity to
DCT; it does not need public Internet access.

### Knap installation decision

No project-specific package needs to be built for Knap. Online RHEL 9.8
environments can use DNF or the official Node.js LTS bundle. Offline
environments should use the versioned Node.js/Knap bundle and transfer the DCT
toolkit and its properties file separately and securely.

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

### Pagination

The fetcher does not limit the total number of results. It repeatedly queries DCT using `response_metadata.next_cursor` until all records have been retrieved.

The fetcher uses an internal page size of `1000` and continues until DCT
returns no next cursor; this is not a result limit.

```bash
./cc_install_report_fetch.py \
  --client "ACME Corp" \
  --prefix "0-" \
  --profile-set "ASDD Spanish" \
  --output report-data/acme-corp.json
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
| `DCT_TOOLKIT_BIN` | Path to the `dct-toolkit` executable. | `~/.local/bin/dct-toolkit` |

Example:

```bash
DCT_TOOLKIT_BIN=/opt/dct-toolkit/bin/dct-toolkit \
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
