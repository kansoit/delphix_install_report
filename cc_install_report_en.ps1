<#
.SYNOPSIS
    Generates a Markdown (.md) report of algorithms, Data Classes (domains), profiling classifiers, Profile Sets (Discovery Policies), data connections (Connectors / JDBC), Rule Sets, and profiling/masking job definitions configured in Delphix Continuous Compliance using DCT Toolkit.

.DESCRIPTION
    This script executes 'dct-toolkit get_algorithms', 'dct-toolkit get_data_classes', 'dct-toolkit get_classifiers',
    'dct-toolkit get_discovery_policies', 'dct-toolkit get_connectors', 'dct-toolkit get_rule_sets', and 'dct-toolkit get_compliance_jobs' to retrieve the list of elements defined in Delphix DCT, filters by the specified prefix (default '0-'), and presents a comprehensive executive report. Pass an empty string ("") to retrieve all elements without filtering.

.PARAMETER ClientName
    Name of the client. Default: "Client".

.PARAMETER OutputFile
    Path for the output Markdown file. Default: "<ClientName> - Delphix Continuous Compliance Configuration Report.md".

.PARAMETER Prefix
    Prefix to filter algorithms, domains, and classifiers to document. Default: '0-'. Pass an empty string ("") or no prefix to retrieve all elements without filtering.

.PARAMETER Limit
    Maximum number of records to request from DCT Toolkit. Default: 1000.

.EXAMPLE
    .\Install_report_en.ps1 -Prefix "0-"
    .\Install_report_en.ps1 -Prefix ""
    .\Install_report_en.ps1 -OutputFile "Delphix_Compliance_Configuration_Report.md"
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [Alias('c', 'Client')]
    [string]$ClientName = "Client",

    [Parameter(Position = 1)]
    [Alias('p')]
    [string]$Prefix = "0-",

    [Parameter(Position = 2)]
    [Alias('o', 'Output')]
    [string]$OutputFile,

    [Parameter(Position = 3)]
    [Alias('l')]
    [int]$Limit = 1000
)

$ErrorActionPreference = "Stop"

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $scriptDir "$ClientName - Delphix Continuous Compliance Configuration Report.md"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile = Join-Path $scriptDir $OutputFile
}

function Get-SafeProperty {
    param(
        [PSCustomObject]$Object,
        [string]$PropertyName,
        $DefaultValue = "-"
    )
    if ($null -ne $Object -and $Object.PSObject.Properties[$PropertyName] -and $null -ne $Object.$PropertyName) {
        return $Object.$PropertyName
    }
    return $DefaultValue
}

function Get-TxtFileName {
    param([PSCustomObject]$AlgoObj)
    if ($AlgoObj -and $AlgoObj.config -and $AlgoObj.config.lookupFile -and $AlgoObj.config.lookupFile.uri) {
        $uri = $AlgoObj.config.lookupFile.uri
        return (Split-Path $uri -Leaf)
    }
    return "-"
}

# 0. Get Registered Engines
Write-Host "[+] Fetching registered engines from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$engineItems = @()
try {
    $rawEnginesJson = dct-toolkit get_registered_engines limit=$Limit -js 2>&1
    $enginesJsonObj = $rawEnginesJson | ConvertFrom-Json
    if ($enginesJsonObj -and $enginesJsonObj.items) {
        $engineItems = @($enginesJsonObj.items)
    }
}
catch {
    Write-Warning "Could not fetch registered engines via 'dct-toolkit get_registered_engines'."
}

# Filter Masking (Compliance) engines
$maskingEngines = @($engineItems | Where-Object { $_.type -eq 'MASKING' } | Sort-Object name)

# Detect Compliance engine version for Executive Summary
$detectedEngineVersion = "2026.X.0.0"
if ($maskingEngines.Count -gt 0 -and $maskingEngines[0].version) {
    $detectedEngineVersion = [string]$maskingEngines[0].version
}
elseif ($engineItems.Count -gt 0 -and $engineItems[0].version) {
    $detectedEngineVersion = [string]$engineItems[0].version
}

# Get SMTP and LDAP Configuration
Write-Host "[+] Fetching infrastructure service configurations (SMTP and LDAP) from Delphix DCT..." -ForegroundColor Cyan
$smtpConfigObj = $null
$ldapConfigObj = $null
try {
    $rawSmtpJson = dct-toolkit get_smtp_config -js 2>&1
    $smtpConfigObj = $rawSmtpJson | ConvertFrom-Json
}
catch {
    Write-Warning "Could not fetch global SMTP configuration via 'dct-toolkit get_smtp_config'."
}

try {
    $rawLdapJson = dct-toolkit get_ldap_config -js 2>&1
    $ldapConfigObj = $rawLdapJson | ConvertFrom-Json
}
catch {
    Write-Warning "Could not fetch global LDAP configuration via 'dct-toolkit get_ldap_config'."
}

# 1. Fetch Algorithms
Write-Host "[+] Fetching algorithms from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawAlgoJson = dct-toolkit get_algorithms limit=$Limit -js 2>&1
    $algoJsonObj = $rawAlgoJson | ConvertFrom-Json
}
catch {
    Write-Error "Error executing or receiving response from 'dct-toolkit get_algorithms'."
    exit 1
}

# 2. Fetch Domains (Data Classes)
Write-Host "[+] Fetching domains (Data Classes) from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawDcJson = dct-toolkit get_data_classes limit=$Limit -js 2>&1
    $dcJsonObj = $rawDcJson | ConvertFrom-Json
}
catch {
    Write-Error "Error executing or receiving response from 'dct-toolkit get_data_classes'."
    exit 1
}

# 3. Fetch Profiling Classifiers (Classifiers)
Write-Host "[+] Fetching profiling classifiers from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawClJson = dct-toolkit get_classifiers limit=$Limit -js 2>&1
    $clJsonObj = $rawClJson | ConvertFrom-Json
}
catch {
    Write-Error "Error executing or receiving response from 'dct-toolkit get_classifiers'."
    exit 1
}

# 4. Fetch Profile Sets (Discovery Policies)
Write-Host "[+] Fetching Profile Sets (Discovery Policies) from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawDpJson = dct-toolkit get_discovery_policies limit=$Limit -js 2>&1
    $dpJsonObj = $rawDpJson | ConvertFrom-Json
}
catch {
    Write-Error "Error executing or receiving response from 'dct-toolkit get_discovery_policies'."
    exit 1
}

# 5. Fetch Data Connections (Connectors)
Write-Host "[+] Fetching Data Connections (Connectors) from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$connItems = @()
try {
    $rawConnJson = dct-toolkit get_connectors limit=$Limit -js 2>&1
    $connJsonObj = $rawConnJson | ConvertFrom-Json
    if ($connJsonObj -and $connJsonObj.items) {
        $connItems = @($connJsonObj.items)
    }
}
catch {
    Write-Warning "Could not fetch data connections via 'dct-toolkit get_connectors'."
}

# 6. Fetch Rule Sets and Table/Column Metadata
Write-Host "[+] Fetching Rule Sets and table/column metadata from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$ruleSetItems = @()
$ruleSetTableCols = @()
$ruleSetTables = @()
try {
    $rawRsJson = dct-toolkit get_rule_sets limit=$Limit -js 2>&1
    $rsJsonObj = $rawRsJson | ConvertFrom-Json
    if ($rsJsonObj -and $rsJsonObj.items) {
        $ruleSetItems = @($rsJsonObj.items)
        
        foreach ($rs in $ruleSetItems) {
            try {
                $rawTblJson = dct-toolkit search_database_table_metadata rule_set_id=$($rs.id) limit=$Limit -js 2>&1
                $tblObj = $rawTblJson | ConvertFrom-Json
                $tables = if ($tblObj.items) { $tblObj.items } else { @() }
                
                foreach ($tbl in $tables) {
                    try {
                        $rawColsJson = dct-toolkit search_database_column_metadata database_table_metadata_id=$($tbl.id) limit=$Limit -js 2>&1
                        $colsObj = $rawColsJson | ConvertFrom-Json
                        $cols = if ($colsObj.items) { $colsObj.items } else { @() }
                        
                        $logicalKeyStr = "-"
                        if ($tbl.key_column -and [string]$tbl.key_column -ne "") {
                            $logicalKeyStr = [string]$tbl.key_column
                        }
                        else {
                            $pkCols = @($cols | Where-Object { $_.is_primary_key -eq $true })
                            if ($pkCols.Count -gt 0) {
                                $logicalKeyStr = "Primary Key"
                            }
                        }
                        
                        $existingTbl = $ruleSetTables | Where-Object { $_.RuleSetName -eq $rs.name -and $_.TableName -eq $tbl.table_name }
                        if (-not $existingTbl) {
                            $ruleSetTables += [PSCustomObject]@{
                                RuleSetName = $rs.name
                                TableName   = $tbl.table_name
                                LogicalKey  = $logicalKeyStr
                            }
                        }

                        $assignedCols = @($cols | Where-Object { $_.is_sensitive -eq $true -or $_.algorithm_name -or $_.data_class_name })
                        foreach ($c in $assignedCols) {
                            $ruleSetTableCols += [PSCustomObject]@{
                                RuleSetName   = $rs.name
                                TableName     = $tbl.table_name
                                ColumnName    = $c.column_name
                                DataClassName = if ($c.data_class_name) { $c.data_class_name } else { "-" }
                                AlgorithmName = if ($c.algorithm_name) { $c.algorithm_name } else { "-" }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Could not fetch columns for table '$($tbl.table_name)' in RuleSet '$($rs.name)'."
                    }
                }
            }
            catch {
                Write-Warning "Could not fetch tables for RuleSet '$($rs.name)'."
            }
        }
    }
}
catch {
    Write-Warning "Could not fetch Rule Sets via 'dct-toolkit get_rule_sets'."
}

# 7. Fetch Job Definitions (Compliance Jobs: Masking & Discovery/Profiling)
Write-Host "[+] Fetching job definitions (Compliance Jobs) from Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$jobItems = @()
try {
    $rawJobsJson = dct-toolkit get_compliance_jobs limit=$Limit -js 2>&1
    $jobsJsonObj = $rawJobsJson | ConvertFrom-Json
    if ($jobsJsonObj -and $jobsJsonObj.items) {
        $jobItems = @($jobsJsonObj.items)
    }
}
catch {
    Write-Warning "Could not fetch jobs via 'dct-toolkit get_compliance_jobs'."
}

$allItems = $algoJsonObj.items
if (-not $allItems) {
    Write-Warning "No algorithms found in DCT response."
    exit 0
}

# Global map of algorithms by name for reference resolution
$algoMap = @{}
foreach ($item in $allItems) {
    $algoMap[$item.name] = $item
}

# Filter items by prefix
$targetAlgos = @($allItems | Where-Object { $_.name -like "$Prefix*" })
$targetDcs = @($dcJsonObj.items | Where-Object { $_.name -like "$Prefix*" } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$targetCls = @($clJsonObj.items | Where-Object { $_.name -like "$Prefix*" } | Sort-Object name)

# Loop through all Discovery Policies to find those containing classifiers matching $Prefix
$dpResults = @()
if ($dpJsonObj -and $dpJsonObj.items) {
    foreach ($dp in $dpJsonObj.items) {
        try {
            $rawDpClJson = dct-toolkit get_discovery_policy_classifiers discovery_policy_id=$($dp.id) limit=$Limit -js 2>&1
            $dpClJsonObj = $rawDpClJson | ConvertFrom-Json
            $matchedDpCls = @($dpClJsonObj.items | Where-Object { $_.name -like "$Prefix*" } | Sort-Object name)
            if ($matchedDpCls.Count -gt 0) {
                $dpResults += [PSCustomObject]@{
                    Name             = $dp.name
                    ClassifiersCount = $matchedDpCls.Count
                    ClassifiersList  = ($matchedDpCls | ForEach-Object { "``$($_.name)``" }) -join ", "
                }
            }
        }
        catch {
            Write-Warning "Could not fetch classifiers for Discovery Policy '$($dp.name)'."
        }
    }
}

# Loop through Connectors to fetch JDBC Driver Properties (filtering by edited == false or empty)
$jdbcPropResults = @()
foreach ($conn in $connItems) {
    if ($conn.id -and $conn.dct_managed) {
        try {
            $rawPropsJson = dct-toolkit get_connection_properties connector_id=$($conn.id) -js 2>&1
            $propsObj = $rawPropsJson | ConvertFrom-Json
            $propItems = if ($propsObj.items) { $propsObj.items } else { $propsObj }
            
            foreach ($p in $propItems) {
                $isEditedFalse = ($null -eq $p.edited) -or ([string]$p.edited -eq "false") -or ([string]$p.edited -eq "False")
                if ($isEditedFalse -and $null -ne $p.value -and [string]$p.value -ne "") {
                    $jdbcPropResults += [PSCustomObject]@{
                        ConnectorName = $conn.name
                        PropertyName  = $p.name
                        PropertyValue = $p.value
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not fetch JDBC properties for connector '$($conn.name)'."
        }
    }
}

# Categorize Profiling (DISCOVERY) and Masking (MASKING) jobs, sorted by Engine and Name
$profilingJobs = @($jobItems | Where-Object { $_.type -eq 'DISCOVERY' -or $_.type -eq 'PROFILING' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$maskingJobs = @($jobItems | Where-Object { $_.type -eq 'MASKING' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)

Write-Host "[+] Registered engines in DCT: $($engineItems.Count)" -ForegroundColor Green
Write-Host "[+] Masking (Compliance) engines detected: $($maskingEngines.Count)" -ForegroundColor Green
Write-Host "[+] Total algorithms in DCT: $($allItems.Count)" -ForegroundColor Green
Write-Host "[+] Algorithms filtered with prefix '$Prefix': $($targetAlgos.Count)" -ForegroundColor Green
Write-Host "[+] Data classes (Domains) filtered with prefix '$Prefix': $($targetDcs.Count)" -ForegroundColor Green
Write-Host "[+] Classifiers filtered with prefix '$Prefix': $($targetCls.Count)" -ForegroundColor Green
Write-Host "[+] Profile Sets with classifiers matching '$Prefix': $($dpResults.Count)" -ForegroundColor Green
Write-Host "[+] Data connections detected: $($connItems.Count)" -ForegroundColor Green
Write-Host "[+] JDBC parameters (edited=false) retrieved: $($jdbcPropResults.Count)" -ForegroundColor Green
Write-Host "[+] Rule Sets detected: $($ruleSetItems.Count)" -ForegroundColor Green
Write-Host "[+] Tables in Rule Sets retrieved: $($ruleSetTables.Count)" -ForegroundColor Green
Write-Host "[+] Table/column assignments in Rule Sets retrieved: $($ruleSetTableCols.Count)" -ForegroundColor Green
Write-Host "[+] Profiling job definitions (Discovery): $($profilingJobs.Count)" -ForegroundColor Green
Write-Host "[+] Masking job definitions (Masking): $($maskingJobs.Count)" -ForegroundColor Green

# Categorize algorithms into simple (TXT-based) and composite (FullName), sorting simple ones by Engine and Name
$simpleAlgos = @($targetAlgos | Where-Object { $_.framework_name -ne 'FullName' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$compositeAlgos = @($targetAlgos | Where-Object { $_.framework_name -eq 'FullName' })

# Build Markdown content
$md = [System.Text.StringBuilder]::new()

$null = $md.AppendLine("# $ClientName - Delphix Continuous Compliance Configuration Report")
$null = $md.AppendLine()
$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 1. Executive Summary')
$null = $md.AppendLine()
$null = $md.AppendLine("For the implementation of Delphix Continuous Compliance Version **$detectedEngineVersion**, **$ClientName** has selected the database <**Database Name**> on <**Database Vendor**> as the pilot case for sensitive data masking.")
$null = $md.AppendLine()
$null = $md.AppendLine('The main objective of this report is to consolidate the configuration applied in the customer environment, including masking algorithms, data domains, profiling classifiers, rule sets, data connectors, and job execution definitions.')
$null = $md.AppendLine()
$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 2. Delphix Continuous Compliance Engine Infrastructure and Services')
$null = $md.AppendLine()
$null = $md.AppendLine('### 2.1. Registered Delphix Continuous Compliance Engines (Masking Engines)')
$null = $md.AppendLine()
$null = $md.AppendLine('Summary table of Continuous Compliance (Masking) engines registered in Delphix DCT, their version, IP address/hostname, connection status, and allocated resources:')
$null = $md.AppendLine()

if ($maskingEngines.Count -eq 0) {
    $null = $md.AppendLine('_No Masking engines registered in the current instance._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Engine Name | Type | Version | Connection Status | CPU Cores | RAM Memory | Total Storage |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($eng in $maskingEngines) {
        $eName = Get-SafeProperty -Object $eng -PropertyName 'name' -DefaultValue '-'
        $eType = Get-SafeProperty -Object $eng -PropertyName 'type' -DefaultValue 'MASKING'
        $eVer  = Get-SafeProperty -Object $eng -PropertyName 'version' -DefaultValue '-'
        $eStat = Get-SafeProperty -Object $eng -PropertyName 'connection_status' -DefaultValue (Get-SafeProperty -Object $eng -PropertyName 'status' -DefaultValue '-')
        $eCores = Get-SafeProperty -Object $eng -PropertyName 'cpu_core_count' -DefaultValue '-'
        if ($eCores -ne '-') { $eCores = "$eCores Cores" }
        
        $eRamBytes = Get-SafeProperty -Object $eng -PropertyName 'memory_size' -DefaultValue '-'
        $eRamStr = "-"
        if ($eRamBytes -ne '-' -and [long]$eRamBytes -gt 0) {
            $eRamStr = "$([math]::Round([long]$eRamBytes / 1GB, 1)) GB"
        }
        
        $eStorageBytes = Get-SafeProperty -Object $eng -PropertyName 'data_storage_capacity' -DefaultValue '-'
        $eStorageStr = "-"
        if ($eStorageBytes -ne '-' -and [long]$eStorageBytes -gt 0) {
            $eStorageStr = "$([math]::Round([long]$eStorageBytes / 1GB, 1)) GB"
        }

        $null = $md.AppendLine("| **$eName** | $eType | ``$eVer`` | $eStat | $eCores | $eRamStr | $eStorageStr |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('| Engine Name | Network Parameter | Configured Value |')
$null = $md.AppendLine('| :--- | :--- | :--- |')
if ($maskingEngines.Count -eq 0) {
    $null = $md.AppendLine('| **-** | **IP Address / Hostname** | - |')
    $null = $md.AppendLine('| **-** | **Gateway** | <**Gateway**> |')
    $null = $md.AppendLine('| **-** | **DNS Servers** | <**DNS Servers**> |')
    $null = $md.AppendLine('| **-** | **NTP Servers** | <**NTP Servers**> |')
}
else {
    foreach ($eng in $maskingEngines) {
        $engName = Get-SafeProperty -Object $eng -PropertyName 'name' -DefaultValue '-'
        $engHost = Get-SafeProperty -Object $eng -PropertyName 'hostname' -DefaultValue '-'
        $engHostStr = if ($engHost -ne '-' -and [string]$engHost -ne '') { "``$engHost``" } else { "-" }

        $null = $md.AppendLine("| **$engName** | **IP Address / Hostname** | $engHostStr |")
        $null = $md.AppendLine("| **$engName** | **Gateway** | <**Gateway**> |")
        $null = $md.AppendLine("| **$engName** | **DNS Servers** | <**DNS Servers**> |")
        $null = $md.AppendLine("| **$engName** | **NTP Servers** | <**NTP Servers**> |")
    }
}
$null = $md.AppendLine()

$null = $md.AppendLine('### 2.2. Infrastructure Services Configuration (SMTP & LDAP / Active Directory Authentication)')
$null = $md.AppendLine()
$null = $md.AppendLine('#### 2.2.1. Mail Server Configuration (SMTP)')
$null = $md.AppendLine()
$null = $md.AppendLine('Summary table of SMTP mail server settings for event and alert notifications:')
$null = $md.AppendLine()

$smtpHost = if ($smtpConfigObj -and $null -ne $smtpConfigObj.hostname -and [string]$smtpConfigObj.hostname -ne "") { $smtpConfigObj.hostname } elseif ($smtpConfigObj -and $null -ne $smtpConfigObj.host -and [string]$smtpConfigObj.host -ne "") { $smtpConfigObj.host } else { "-" }
$smtpPort = if ($smtpConfigObj -and $null -ne $smtpConfigObj.port) { [string]$smtpConfigObj.port } else { "-" }
$smtpEnabled = if ($smtpConfigObj -and $null -ne $smtpConfigObj.enabled) { ([string]$smtpConfigObj.enabled).ToLower() } else { "-" }
$smtpAuth = if ($smtpConfigObj -and $null -ne $smtpConfigObj.authentication_enabled) { ([string]$smtpConfigObj.authentication_enabled).ToLower() } else { "-" }
$smtpTls = if ($smtpConfigObj -and $null -ne $smtpConfigObj.tls_enabled) { ([string]$smtpConfigObj.tls_enabled).ToLower() } else { "-" }
$smtpFrom = if ($smtpConfigObj -and $null -ne $smtpConfigObj.from_address -and [string]$smtpConfigObj.from_address -ne "") { $smtpConfigObj.from_address } else { "-" }

$null = $md.AppendLine('| SMTP Parameter | Configured Value |')
$null = $md.AppendLine('| :--- | :--- |')
$null = $md.AppendLine("| **SMTP Server (Host)** | ``$smtpHost`` |")
$null = $md.AppendLine("| **Port** | ``$smtpPort`` |")
$null = $md.AppendLine("| **Enabled Status** | ``$smtpEnabled`` |")
$null = $md.AppendLine("| **Authentication Enabled (Auth)** | ``$smtpAuth`` |")
$null = $md.AppendLine("| **TLS Encryption** | ``$smtpTls`` |")
$null = $md.AppendLine("| **Sender Address (From)** | ``$smtpFrom`` |")
$null = $md.AppendLine()

$null = $md.AppendLine('#### 2.2.2. LDAP / Domain Controller Authentication Configuration (Active Directory)')
$null = $md.AppendLine()
$null = $md.AppendLine('Summary table of LDAP / Active Directory integration for user authentication:')
$null = $md.AppendLine()

$ldapEnabled = if ($ldapConfigObj -and $null -ne $ldapConfigObj.enabled) { ([string]$ldapConfigObj.enabled).ToLower() } else { "-" }
$ldapHost = if ($ldapConfigObj -and $null -ne $ldapConfigObj.hostname -and [string]$ldapConfigObj.hostname -ne "") { $ldapConfigObj.hostname } elseif ($ldapConfigObj -and $null -ne $ldapConfigObj.host -and [string]$ldapConfigObj.host -ne "") { $ldapConfigObj.host } else { "-" }
$ldapPort = if ($ldapConfigObj -and $null -ne $ldapConfigObj.port) { [string]$ldapConfigObj.port } else { "-" }
$ldapDomains = "-"
if ($ldapConfigObj -and $ldapConfigObj.domains -and $ldapConfigObj.domains.Count -gt 0) {
    $ldapDomains = ($ldapConfigObj.domains | ForEach-Object { "``$_``" }) -join ", "
}
$ldapAutoCreate = if ($ldapConfigObj -and $null -ne $ldapConfigObj.auto_create_users) { ([string]$ldapConfigObj.auto_create_users).ToLower() } else { "-" }
$ldapSsl = if ($ldapConfigObj -and $null -ne $ldapConfigObj.enable_ssl) { ([string]$ldapConfigObj.enable_ssl).ToLower() } else { "-" }

$null = $md.AppendLine('| LDAP / Active Directory Parameter | Configured Value |')
$null = $md.AppendLine('| :--- | :--- |')
$null = $md.AppendLine("| **LDAP Integration Enabled** | ``$ldapEnabled`` |")
$null = $md.AppendLine("| **LDAP Host Server / Domain Controller** | ``$ldapHost`` |")
$null = $md.AppendLine("| **Port** | ``$ldapPort`` |")
$null = $md.AppendLine("| **Registered Domains** | $ldapDomains |")
$null = $md.AppendLine("| **Auto-create Users** | ``$ldapAutoCreate`` |")
$null = $md.AppendLine("| **Secure Connection (SSL)** | ``$ldapSsl`` |")
$null = $md.AppendLine()

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 3. Text File Lookup Algorithms (`Secure Lookup` / `Name`)')
$null = $md.AppendLine()
$null = $md.AppendLine('Summary table of algorithms based on replacement value text files:')
$null = $md.AppendLine()

if ($simpleAlgos.Count -eq 0) {
    $null = $md.AppendLine('_No simple algorithms found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Algorithm | Framework | TXT File Used | Engine | Description |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- |')
    foreach ($algo in $simpleAlgos) {
        $nameStr = $algo.name
        $fwStr = Get-SafeProperty -Object $algo -PropertyName 'framework_name' -DefaultValue '-'
        $txtStr = Get-TxtFileName -AlgoObj $algo
        $engineStr = Get-SafeProperty -Object $algo -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        $descRaw = Get-SafeProperty -Object $algo -PropertyName 'description' -DefaultValue '-'
        $descStr = $descRaw -replace '\r?\n', ' '
        
        $null = $md.AppendLine("| **$nameStr** | $fwStr | ``$txtStr`` | $engineStr | $descStr |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 4. Composite Algorithms (`FullName`)')
$null = $md.AppendLine()
$null = $md.AppendLine('Detailed table of the composite algorithm `FullName` and the simple algorithms that compose it:')
$null = $md.AppendLine()

if ($compositeAlgos.Count -eq 0) {
    $null = $md.AppendLine('_No composite algorithms (FullName) found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Composite Algorithm | Framework | First Name Component | First Name TXT File | Last Name Component | Last Name TXT File | Description |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    
    foreach ($algo in $compositeAlgos) {
        $nameStr = $algo.name
        $fwStr = Get-SafeProperty -Object $algo -PropertyName 'framework_name' -DefaultValue 'FullName'
        $descRaw = Get-SafeProperty -Object $algo -PropertyName 'description' -DefaultValue '-'
        $descStr = $descRaw -replace '\r?\n', ' '
        
        # Component references
        $firstNameAlgoName = "-"
        $firstNameTxt = "-"
        $lastNameAlgoName = "-"
        $lastNameTxt = "-"
        
        if ($algo.config) {
            if ($algo.config.firstNameAlgorithmRef -and $algo.config.firstNameAlgorithmRef.name) {
                $firstNameAlgoName = $algo.config.firstNameAlgorithmRef.name
                if ($algoMap.ContainsKey($firstNameAlgoName)) {
                    $firstNameTxt = Get-TxtFileName -AlgoObj $algoMap[$firstNameAlgoName]
                }
            }
            if ($algo.config.lastNameAlgorithmRef -and $algo.config.lastNameAlgorithmRef.name) {
                $lastNameAlgoName = $algo.config.lastNameAlgorithmRef.name
                if ($algoMap.ContainsKey($lastNameAlgoName)) {
                    $lastNameTxt = Get-TxtFileName -AlgoObj $algoMap[$lastNameAlgoName]
                }
            }
        }
        
        $null = $md.AppendLine("| **$nameStr** | $fwStr | **$firstNameAlgoName** | ``$firstNameTxt`` | **$lastNameAlgoName** | ``$lastNameTxt`` | $descStr |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 5. Domains (Data Classes) and Algorithm Association')
$null = $md.AppendLine()
$null = $md.AppendLine('Association table between defined domains (Data Classes) and their assigned masking algorithm:')
$null = $md.AppendLine()

if ($targetDcs.Count -eq 0) {
    $null = $md.AppendLine('_No domains (Data Classes) found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Domain (Data Class) | Assigned Algorithm | Engine |')
    $null = $md.AppendLine('| :--- | :--- | :--- |')
    foreach ($dc in $targetDcs) {
        $dcName = $dc.name
        $algoAssigned = Get-SafeProperty -Object $dc -PropertyName 'default_algorithm_name' -DefaultValue '-'
        $dcEngine = Get-SafeProperty -Object $dc -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        
        $null = $md.AppendLine("| **$dcName** | $algoAssigned | $dcEngine |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 6. Profiling Classifiers (Classifiers)')
$null = $md.AppendLine()
$null = $md.AppendLine('Breakdown of classifiers used in Profiling rules, categorized by Framework type:')
$null = $md.AppendLine()

$pathRegexCls = @($targetCls | Where-Object { $_.framework -eq 'PATH' -or $_.framework -eq 'REGEX' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$listCls      = @($targetCls | Where-Object { $_.framework -eq 'LIST' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$dataTypeCls  = @($targetCls | Where-Object { $_.framework -eq 'DATA_TYPE' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)

# 6.1. PATH and REGEX Classifiers
$null = $md.AppendLine('### 6.1. Column Name and Regular Expression Classifiers (PATH / REGEX)')
$null = $md.AppendLine()
if ($pathRegexCls.Count -eq 0) {
    $null = $md.AppendLine('_No PATH or REGEX classifiers found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Regular Expression (Regex) | Engine |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($cl in $pathRegexCls) {
        $clName = $cl.name
        $clFw = Get-SafeProperty -Object $cl -PropertyName 'framework' -DefaultValue '-'
        $clDc = Get-SafeProperty -Object $cl -PropertyName 'data_class_name' -DefaultValue '-'
        $clEngine = Get-SafeProperty -Object $cl -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        
        $clPeso = "-"
        $clRegex = "-"
        
        if ($cl.framework -eq 'PATH' -and $cl.config -and $cl.config.paths) {
            $pesos = @()
            $regexes = @()
            foreach ($p in $cl.config.paths) {
                if ($null -ne $p.matchStrength) { $pesos += [string]$p.matchStrength }
                if ($null -ne $p.fieldValue) {
                    $cleanRx = ($p.fieldValue -replace '\|', '\|')
                    $regexes += "``$cleanRx``"
                }
            }
            if ($pesos.Count -gt 0) { $clPeso = ($pesos | Select-Object -Unique) -join ", " }
            if ($regexes.Count -gt 0) { $clRegex = $regexes -join "<br>" }
        }
        elseif ($cl.framework -eq 'REGEX' -and $cl.config -and $cl.config.dataPatterns) {
            $pesos = @()
            $regexes = @()
            foreach ($dp in $cl.config.dataPatterns) {
                if ($null -ne $dp.matchStrength) { $pesos += [string]$dp.matchStrength }
                if ($null -ne $dp.regex) {
                    $cleanRx = ($dp.regex -replace '\|', '\|')
                    $regexes += "``$cleanRx``"
                }
            }
            if ($pesos.Count -gt 0) { $clPeso = ($pesos | Select-Object -Unique) -join ", " }
            if ($regexes.Count -gt 0) { $clRegex = $regexes -join "<br>" }
        }
        
        $null = $md.AppendLine("| **$clName** | $clFw | **$clDc** | $clPeso | $clRegex | $clEngine |")
    }
    $null = $md.AppendLine()
}

# 6.2. LIST Classifiers
$null = $md.AppendLine('### 6.2. Value List Classifiers (LIST)')
$null = $md.AppendLine()
if ($listCls.Count -eq 0) {
    $null = $md.AppendLine('_No LIST classifiers found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | TXT File Name | Engine |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($cl in $listCls) {
        $clName = $cl.name
        $clFw = Get-SafeProperty -Object $cl -PropertyName 'framework' -DefaultValue 'LIST'
        $clDc = Get-SafeProperty -Object $cl -PropertyName 'data_class_name' -DefaultValue '-'
        $clEngine = Get-SafeProperty -Object $cl -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        
        $clPeso = "-"
        $clFile = "-"
        
        if ($cl.config -and $cl.config.valueLists) {
            $pesos = @()
            $files = @()
            foreach ($vl in $cl.config.valueLists) {
                if ($null -ne $vl.matchStrength) { $pesos += [string]$vl.matchStrength }
                if ($null -ne $vl.file) {
                    $fileName = Split-Path $vl.file -Leaf
                    $files += "``$fileName``"
                }
            }
            if ($pesos.Count -gt 0) { $clPeso = ($pesos | Select-Object -Unique) -join ", " }
            if ($files.Count -gt 0) { $clFile = $files -join "<br>" }
        }
        
        $null = $md.AppendLine("| **$clName** | $clFw | **$clDc** | $clPeso | $clFile | $clEngine |")
    }
    $null = $md.AppendLine()
}

# 6.3. DATA_TYPE Classifiers
$null = $md.AppendLine('### 6.3. Data Type Classifiers (DATA_TYPE)')
$null = $md.AppendLine()
if ($dataTypeCls.Count -eq 0) {
    $null = $md.AppendLine('_No DATA_TYPE classifiers found with the specified prefix._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Allowed Data Types | Engine |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($cl in $dataTypeCls) {
        $clName = $cl.name
        $clFw = Get-SafeProperty -Object $cl -PropertyName 'framework' -DefaultValue 'DATA_TYPE'
        $clDc = Get-SafeProperty -Object $cl -PropertyName 'data_class_name' -DefaultValue '-'
        $clEngine = Get-SafeProperty -Object $cl -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        
        $clPeso = if ($null -ne $cl.config -and $null -ne $cl.config.matchStrength) { [string]$cl.config.matchStrength } else { "-" }
        $clTypes = "-"
        
        if ($cl.config -and $cl.config.allowedTypes) {
            $typeStrs = @()
            foreach ($at in $cl.config.allowedTypes) {
                $minLen = if ($null -ne $at.minimumLength) { " (min: $($at.minimumLength))" } else { "" }
                $typeStrs += "$($at.typeName)$minLen"
            }
            if ($typeStrs.Count -gt 0) { $clTypes = $typeStrs -join ", " }
        }
        
        $null = $md.AppendLine("| **$clName** | $clFw | **$clDc** | $clPeso | $clTypes | $clEngine |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 7. Profile Sets (Discovery Policies) and Assigned Classifiers')
$null = $md.AppendLine()
$null = $md.AppendLine('Relationship between the Profiling Profile Set and the complete list of constituent classifiers:')
$null = $md.AppendLine()

if ($dpResults.Count -eq 0) {
    $null = $md.AppendLine("_No Profile Sets found containing classifiers matching prefix '$Prefix'._")
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Profile Set (Discovery Policy) | Classifier List |')
    $null = $md.AppendLine('| :--- | :--- |')
    foreach ($dpRes in $dpResults) {
        $null = $md.AppendLine("| **$($dpRes.Name)** | $($dpRes.ClassifiersList) |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 8. Data Connections (Connectors) and JDBC Parameters')
$null = $md.AppendLine()

$null = $md.AppendLine('### 8.1. Defined Data Connections')
$null = $md.AppendLine()
$null = $md.AppendLine('Summary table of data connections (Connectors), including server, database, schema, and user:')
$null = $md.AppendLine()

if ($connItems.Count -eq 0) {
    $null = $md.AppendLine('_No data connections found in the current instance._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Connection (Connector) | Server / Host | Database | Schema | User | Type / Platform | Engine |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    
    $uniqueConns = @($connItems | Sort-Object @{ Expression = { if ($_.engine_name) { $_.engine_name } elseif ($_.job_orchestrator_name) { "$($_.job_orchestrator_name) (Orchestrator)" } else { "DCT / Global" } } }, name, id)
    foreach ($c in $uniqueConns) {
        $cName = Get-SafeProperty -Object $c -PropertyName 'name' -DefaultValue '-'
        $cHost = Get-SafeProperty -Object $c -PropertyName 'hostname' -DefaultValue '-'
        $cDb = Get-SafeProperty -Object $c -PropertyName 'database_name' -DefaultValue '-'
        $cSch = Get-SafeProperty -Object $c -PropertyName 'schema_name' -DefaultValue '-'
        $cUser = Get-SafeProperty -Object $c -PropertyName 'username' -DefaultValue '-'
        $cPlat = Get-SafeProperty -Object $c -PropertyName 'platform' -DefaultValue '-'
        $cEng = if ($c.engine_name) { $c.engine_name } elseif ($c.job_orchestrator_name) { "$($c.job_orchestrator_name) (Orchestrator)" } else { "DCT / Global" }
        
        $null = $md.AppendLine("| **$cName** | $cHost | $cDb | $cSch | $cUser | $cPlat | $cEng |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('### 8.2. Configured JDBC Driver Parameters')
$null = $md.AppendLine()
$null = $md.AppendLine('Table of JDBC driver parameters retrieved with configured values:')
$null = $md.AppendLine()

if ($jdbcPropResults.Count -eq 0) {
    $null = $md.AppendLine('_No JDBC driver parameters found for current connections._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Connection (Connector) | JDBC Driver Parameter | Configured Value |')
    $null = $md.AppendLine('| :--- | :--- | :--- |')
    foreach ($prop in $jdbcPropResults) {
        $valClean = [string]$prop.PropertyValue -replace '\|', '\|'
        $null = $md.AppendLine("| **$($prop.ConnectorName)** | ``$($prop.PropertyName)`` | ``$valClean`` |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 9. Rule Sets, Tables, and Algorithm / Domain Assignments')
$null = $md.AppendLine()
$null = $md.AppendLine('### 9.1. Rule Sets, Tables, and Algorithm / Domain Assignments')
$null = $md.AppendLine()

if ($ruleSetTableCols.Count -eq 0) {
    $null = $md.AppendLine('_No column/algorithm assignments found in current Rule Sets._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Rule Set | Table | Column | Domain (Data Class) | Assigned Algorithm |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- |')
    
    $sortedRsCols = @($ruleSetTableCols | Sort-Object RuleSetName, TableName, ColumnName)
    foreach ($row in $sortedRsCols) {
        $null = $md.AppendLine("| **$($row.RuleSetName)** | **$($row.TableName)** | ``$($row.ColumnName)`` | **$($row.DataClassName)** | $($row.AlgorithmName) |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('### 9.2. Database Tables and Logical Keys')
$null = $md.AppendLine()

if ($ruleSetTables.Count -eq 0) {
    $null = $md.AppendLine('_No registered tables found in current Rule Sets._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Rule Set | Table | Logical Key |')
    $null = $md.AppendLine('| :--- | :--- | :--- |')
    
    $sortedRsTables = @($ruleSetTables | Sort-Object RuleSetName, TableName -Unique)
    foreach ($row in $sortedRsTables) {
        $null = $md.AppendLine("| **$($row.RuleSetName)** | **$($row.TableName)** | ``$($row.LogicalKey)`` |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 10. Profiling and Masking Job Definitions (Jobs)')
$null = $md.AppendLine()
$null = $md.AppendLine('### 10.1. Profiling Jobs (Profiling / Discovery Jobs)')
$null = $md.AppendLine()
$null = $md.AppendLine('Definition of profiling jobs (Discovery), Rule Set association, Profile Set, and execution attributes:')
$null = $md.AppendLine()

if ($profilingJobs.Count -eq 0) {
    $null = $md.AppendLine('_No profiling jobs (Profiling / Discovery) defined._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Job Name | Type | Rule Set | Profile Set (Discovery Policy) | Connector / Platform | Execution Type | Engine | Environment / Application |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($j in $profilingJobs) {
        $jName = $j.name
        $jType = Get-SafeProperty -Object $j -PropertyName 'type' -DefaultValue 'DISCOVERY'
        $jRs = Get-SafeProperty -Object $j -PropertyName 'rule_set_name' -DefaultValue '-'
        $jDp = Get-SafeProperty -Object $j -PropertyName 'discovery_policy_name' -DefaultValue '-'
        $jConn = Get-SafeProperty -Object $j -PropertyName 'connector_type' -DefaultValue '-'
        $jExec = Get-SafeProperty -Object $j -PropertyName 'execution_type' -DefaultValue 'STANDARD'
        $jEng = Get-SafeProperty -Object $j -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        $jEnv = Get-SafeProperty -Object $j -PropertyName 'environment_name' -DefaultValue '-'
        $jApp = Get-SafeProperty -Object $j -PropertyName 'application_name' -DefaultValue '-'
        
        $null = $md.AppendLine("| **$jName** | $jType | **$jRs** | **$jDp** | $jConn | $jExec | $jEng | $jEnv / $jApp |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('### 10.2. Masking Jobs')
$null = $md.AppendLine()
$null = $md.AppendLine('Definition of masking jobs, Rule Set association, and masking attributes:')
$null = $md.AppendLine()

if ($maskingJobs.Count -eq 0) {
    $null = $md.AppendLine('_No masking jobs defined._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Job Name | Type | Rule Set | On-The-Fly | Truncate Tables | Drop Indexes | Connector / Platform | Execution Type | Engine | Environment / Application |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    foreach ($j in $maskingJobs) {
        $jName = $j.name
        $jType = Get-SafeProperty -Object $j -PropertyName 'type' -DefaultValue 'MASKING'
        $jRs = Get-SafeProperty -Object $j -PropertyName 'rule_set_name' -DefaultValue '-'
        $jOtf = if ($null -ne $j.is_on_the_fly_masking) { ([string]$j.is_on_the_fly_masking).ToLower() } else { "false" }
        $jTrunc = if ($null -ne $j.truncate_tables) { ([string]$j.truncate_tables).ToLower() } else { "false" }
        $jDrop = if ($null -ne $j.drop_indexes) { ([string]$j.drop_indexes).ToLower() } else { "false" }
        $jConn = Get-SafeProperty -Object $j -PropertyName 'connector_type' -DefaultValue '-'
        $jExec = Get-SafeProperty -Object $j -PropertyName 'execution_type' -DefaultValue 'STANDARD'
        $jEng = Get-SafeProperty -Object $j -PropertyName 'engine_name' -DefaultValue 'DCT / Global'
        $jEnv = Get-SafeProperty -Object $j -PropertyName 'environment_name' -DefaultValue '-'
        $jApp = Get-SafeProperty -Object $j -PropertyName 'application_name' -DefaultValue '-'
        
        $null = $md.AppendLine("| **$jName** | $jType | **$jRs** | ``$jOtf`` | ``$jTrunc`` | ``$jDrop`` | $jConn | $jExec | $jEng | $jEnv / $jApp |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 11. Key Configuration Criteria for Rule Sets (_In-Place Masking_)')
$null = $md.AppendLine()
$null = $md.AppendLine('As a general architecture guideline for future **_In-Place Masking_** implementations, record identification within a _Rule Set_ must adhere to the following directives:')
$null = $md.AppendLine()
$null = $md.AppendLine('**1. Use of Logical Keys:**')
$null = $md.AppendLine('Whenever a column (or set of columns) exists that guarantees uniqueness, non-null values, and whose columns **are not subject to masking**, it must be explicitly defined as a _Logical Key_ in the _Rule Set_. This enables the tool to execute direct, optimized update statements (`UPDATE`) using existing database engine indexes.')
$null = $md.AppendLine()
$null = $md.AppendLine('**2. Temporary Identity Column Mechanism:**')
$null = $md.AppendLine('When a table lacks a unique key with these characteristics, or when the existing primary/unique key consists of fields that require masking, **no _Logical Key_ should be defined in the _Rule Set_**. In these scenarios, Delphix automatically creates a temporary identity column (`MASK_ROW_ID`) in the target table to manage batch masking pointers, automatically dropping it upon job completion.')
$null = $md.AppendLine()
$null = $md.AppendLine('### Decision Summary (Reference Matrix)')
$null = $md.AppendLine()
$null = $md.AppendLine('| **Table Scenario** | **Rule Set Action** | **Update Mechanism** |')
$null = $md.AppendLine('| :--- | :--- | :--- |')
$null = $md.AppendLine('| Has non-null PK/UQ and its fields are **not** masked | Define explicit **Logical Key** | Lookup via existing index |')
$null = $md.AppendLine('| Lacks PK/UQ, or existing key **is masked** | **Do not define** Logical Key | Temporary identity column (`MASK_ROW_ID`) |')
$null = $md.AppendLine()

# Save UTF8 file
[System.IO.File]::WriteAllText($OutputFile, $md.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "[+] Document successfully generated at: $OutputFile" -ForegroundColor Green
