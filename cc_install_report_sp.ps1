<#
.SYNOPSIS
    Genera un informe en formato Markdown (.md) de los algoritmos, dominios (Data Classes), clasificadores de profiling, Profile Sets (Discovery Policies), conexiones de datos (Connectors / JDBC), Rule Sets y definiciones de trabajos de perfilado/enmascaramiento configurados en Delphix Continuous Compliance utilizando DCT Toolkit.

.DESCRIPTION
    Este script ejecuta 'dct-toolkit get_algorithms', 'dct-toolkit get_data_classes', 'dct-toolkit get_classifiers',
    'dct-toolkit get_discovery_policies', 'dct-toolkit get_connectors', 'dct-toolkit get_rule_sets' y 'dct-toolkit get_compliance_jobs' para obtener la lista de elementos definidos en Delphix DCT, filtra por el prefijo especificado (por defecto '0-') y presenta una documentacion ejecutiva completa.

.PARAMETER ClientName
    Nombre del cliente. Por defecto: "Cliente".

.PARAMETER OutputFile
    Ruta del archivo Markdown de salida. Por defecto: "<ClientName> - Reporte Configuracion Delphix Continuous Compliance.md" en la carpeta del script.

.PARAMETER Prefix
    Prefijo para filtrar los algoritmos, dominios y clasificadores a documentar. Por defecto: '0-'. Pasar una cadena vacia ("") o sin prefijo para recuperar todos los elementos sin filtro.

.PARAMETER Limit
    Cantidad maxima de registros a solicitar a DCT Toolkit. Por defecto: 1000.

.EXAMPLE
    .\Install_report.ps1 -Prefix "0-"
    .\Install_report.ps1 -Prefix ""
    .\Install_report.ps1 -OutputFile "Configuracion_Delphix_Compliance.md"
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [Alias('c', 'Client')]
    [string]$ClientName = "Cliente",

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
    $OutputFile = Join-Path $scriptDir "$ClientName - Reporte Configuracion Delphix Continuous Compliance.md"
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

# 0. Obtener Motores Registrados (Engines)
Write-Host "[+] Obteniendo motores registrados (Engines) desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$engineItems = @()
try {
    $rawEnginesJson = dct-toolkit get_registered_engines limit=$Limit -js 2>&1
    $enginesJsonObj = $rawEnginesJson | ConvertFrom-Json
    if ($enginesJsonObj -and $enginesJsonObj.items) {
        $engineItems = @($enginesJsonObj.items)
    }
}
catch {
    Write-Warning "No se pudieron obtener los motores registrados mediante 'dct-toolkit get_registered_engines'."
}

# Filtrar motores de Masking (Compliance)
$maskingEngines = @($engineItems | Where-Object { $_.type -eq 'MASKING' } | Sort-Object name)

# Detectar versión del motor de Compliance para el Resumen Ejecutivo
$detectedEngineVersion = "2026.X.0.0"
if ($maskingEngines.Count -gt 0 -and $maskingEngines[0].version) {
    $detectedEngineVersion = [string]$maskingEngines[0].version
}
elseif ($engineItems.Count -gt 0 -and $engineItems[0].version) {
    $detectedEngineVersion = [string]$engineItems[0].version
}

# Obtener Configuración de SMTP y LDAP
Write-Host "[+] Obteniendo configuración de servicios de infraestructura (SMTP y LDAP) desde Delphix DCT..." -ForegroundColor Cyan
$smtpConfigObj = $null
$ldapConfigObj = $null
try {
    $rawSmtpJson = dct-toolkit get_smtp_config -js 2>&1
    $smtpConfigObj = $rawSmtpJson | ConvertFrom-Json
}
catch {
    Write-Warning "No se pudo obtener la configuración global de SMTP mediante 'dct-toolkit get_smtp_config'."
}

try {
    $rawLdapJson = dct-toolkit get_ldap_config -js 2>&1
    $ldapConfigObj = $rawLdapJson | ConvertFrom-Json
}
catch {
    Write-Warning "No se pudo obtener la configuración global de LDAP mediante 'dct-toolkit get_ldap_config'."
}

# 1. Obtener Algoritmos
Write-Host "[+] Obteniendo algoritmos desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawAlgoJson = dct-toolkit get_algorithms limit=$Limit -js 2>&1
    $algoJsonObj = $rawAlgoJson | ConvertFrom-Json
}
catch {
    Write-Error "Error al ejecutar u obtener respuesta de 'dct-toolkit get_algorithms'."
    exit 1
}

# 2. Obtener Dominios (Data Classes)
Write-Host "[+] Obteniendo dominios (Data Classes) desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawDcJson = dct-toolkit get_data_classes limit=$Limit -js 2>&1
    $dcJsonObj = $rawDcJson | ConvertFrom-Json
}
catch {
    Write-Error "Error al ejecutar u obtener respuesta de 'dct-toolkit get_data_classes'."
    exit 1
}

# 3. Obtener Clasificadores de Profiling (Classifiers)
Write-Host "[+] Obteniendo clasificadores de profiling desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawClJson = dct-toolkit get_classifiers limit=$Limit -js 2>&1
    $clJsonObj = $rawClJson | ConvertFrom-Json
}
catch {
    Write-Error "Error al ejecutar u obtener respuesta de 'dct-toolkit get_classifiers'."
    exit 1
}

# 4. Obtener Profile Sets (Discovery Policies)
Write-Host "[+] Obteniendo Profile Sets (Discovery Policies) desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
try {
    $rawDpJson = dct-toolkit get_discovery_policies limit=$Limit -js 2>&1
    $dpJsonObj = $rawDpJson | ConvertFrom-Json
}
catch {
    Write-Error "Error al ejecutar u obtener respuesta de 'dct-toolkit get_discovery_policies'."
    exit 1
}

# 5. Obtener Conexiones de Datos (Connectors)
Write-Host "[+] Obteniendo Conexiones de Datos (Connectors) desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$connItems = @()
try {
    $rawConnJson = dct-toolkit get_connectors limit=$Limit -js 2>&1
    $connJsonObj = $rawConnJson | ConvertFrom-Json
    if ($connJsonObj -and $connJsonObj.items) {
        $connItems = @($connJsonObj.items)
    }
}
catch {
    Write-Warning "No se pudieron obtener las conexiones de datos mediante 'dct-toolkit get_connectors'."
}

# 6. Obtener Rule Sets y su Meta-informacion de Tablas y Columnas
Write-Host "[+] Obteniendo Rule Sets y metadata de tablas/columnas desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
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
                                $logicalKeyStr = "Llave Primaria"
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
                        Write-Warning "No se pudieron obtener las columnas para la tabla '$($tbl.table_name)' en el RuleSet '$($rs.name)'."
                    }
                }
            }
            catch {
                Write-Warning "No se pudieron obtener las tablas para el RuleSet '$($rs.name)'."
            }
        }
    }
}
catch {
    Write-Warning "No se pudieron obtener los Rule Sets mediante 'dct-toolkit get_rule_sets'."
}

# 7. Obtener Definiciones de Trabajos (Compliance Jobs: Masking & Discovery/Profiling)
Write-Host "[+] Obteniendo definiciones de trabajos (Compliance Jobs) desde Delphix Data Control Tower (DCT)..." -ForegroundColor Cyan
$jobItems = @()
try {
    $rawJobsJson = dct-toolkit get_compliance_jobs limit=$Limit -js 2>&1
    $jobsJsonObj = $rawJobsJson | ConvertFrom-Json
    if ($jobsJsonObj -and $jobsJsonObj.items) {
        $jobItems = @($jobsJsonObj.items)
    }
}
catch {
    Write-Warning "No se pudieron obtener los trabajos mediante 'dct-toolkit get_compliance_jobs'."
}

$allItems = $algoJsonObj.items
if (-not $allItems) {
    Write-Warning "No se encontraron algoritmos en la respuesta de DCT."
    exit 0
}

# Mapa global de algoritmos por nombre para resolucion de referencias
$algoMap = @{}
foreach ($item in $allItems) {
    $algoMap[$item.name] = $item
}

# Filtrar elementos por prefijo
$targetAlgos = @($allItems | Where-Object { $_.name -like "$Prefix*" })
$targetDcs = @($dcJsonObj.items | Where-Object { $_.name -like "$Prefix*" } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$targetCls = @($clJsonObj.items | Where-Object { $_.name -like "$Prefix*" } | Sort-Object name)

# Recorrer todas las Discovery Policies para encontrar las que contienen clasificadores con el prefijo $Prefix
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
            Write-Warning "No se pudieron obtener los clasificadores para la Discovery Policy '$($dp.name)'."
        }
    }
}

# Recorrer Conexiones para obtener sus Propiedades de Driver JDBC (filtrando por edited == false o vacio)
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
            Write-Warning "No se pudieron obtener las propiedades JDBC para la conexion '$($conn.name)'."
        }
    }
}

# Clasificar trabajos de Perfilado (DISCOVERY) y Enmascaramiento (MASKING), ordenados por Motor y Nombre
$profilingJobs = @($jobItems | Where-Object { $_.type -eq 'DISCOVERY' -or $_.type -eq 'PROFILING' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$maskingJobs = @($jobItems | Where-Object { $_.type -eq 'MASKING' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)

Write-Host "[+] Motores registrados en DCT: $($engineItems.Count)" -ForegroundColor Green
Write-Host "[+] Motores de Masking (Compliance) detectados: $($maskingEngines.Count)" -ForegroundColor Green
Write-Host "[+] Total de algoritmos en DCT: $($allItems.Count)" -ForegroundColor Green
Write-Host "[+] Algoritmos filtrados con prefijo '$Prefix': $($targetAlgos.Count)" -ForegroundColor Green
Write-Host "[+] Dominios (Data Classes) filtrados con prefijo '$Prefix': $($targetDcs.Count)" -ForegroundColor Green
Write-Host "[+] Clasificadores (Classifiers) filtrados con prefijo '$Prefix': $($targetCls.Count)" -ForegroundColor Green
Write-Host "[+] Profile Sets con clasificadores '$Prefix': $($dpResults.Count)" -ForegroundColor Green
Write-Host "[+] Conexiones de datos detectadas: $($connItems.Count)" -ForegroundColor Green
Write-Host "[+] Parametros JDBC (edited=false) recuperados: $($jdbcPropResults.Count)" -ForegroundColor Green
Write-Host "[+] Rule Sets detectados: $($ruleSetItems.Count)" -ForegroundColor Green
Write-Host "[+] Tablas en Rule Sets recuperadas: $($ruleSetTables.Count)" -ForegroundColor Green
Write-Host "[+] Asignaciones de tabla/columna en Rule Sets recuperadas: $($ruleSetTableCols.Count)" -ForegroundColor Green
Write-Host "[+] Definiciones de trabajos de perfilado (Discovery): $($profilingJobs.Count)" -ForegroundColor Green
Write-Host "[+] Definiciones de trabajos de enmascaramiento (Masking): $($maskingJobs.Count)" -ForegroundColor Green

# Clasificar algoritmos en simples (basados en TXT) y compuestos (FullName)
$simpleAlgos = @($targetAlgos | Where-Object { $_.framework_name -ne 'FullName' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$compositeAlgos = @($targetAlgos | Where-Object { $_.framework_name -eq 'FullName' })

# Construir contenido Markdown
$md = [System.Text.StringBuilder]::new()

$null = $md.AppendLine("# $ClientName - Reporte Configuracion Delphix Continuous Compliance")
$null = $md.AppendLine()
$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 1. Resumen Ejecutivo')
$null = $md.AppendLine()
$null = $md.AppendLine("Para la implementacion de Delphix Continuous Compliance en Version **$detectedEngineVersion**, **$ClientName** ha seleccionado la base de datos <**Nombre base de datos**> en <**Nombre Fabricante BD**> como caso piloto de enmascaramiento de datos sensibles.")
$null = $md.AppendLine()
$null = $md.AppendLine('El objetivo principal de este informe es consolidar la parametrizacion aplicada en el entorno del cliente, incluyendo los algoritmos de enmascaramiento, dominios de datos, clasificadores de perfilado, reglas de enmascaramiento, conectores y trabajos de ejecucion.')
$null = $md.AppendLine()
$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 2. Infraestructura y Servicios de Motores Delphix Continuous Compliance')
$null = $md.AppendLine()
$null = $md.AppendLine('### 2.1. Motores Delphix Continuous Compliance Registrados (Masking Engines)')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla resumen de los motores de enmascaramiento (Continuous Compliance) registrados en Delphix DCT, su versión, dirección IP/hostname, estado de conexión y recursos asignados:')
$null = $md.AppendLine()

if ($maskingEngines.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron motores de enmascaramiento (Masking) registrados en la instancia actual._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Nombre Motor | Tipo | Versión | Estado Conexión | Cores CPU | Memoria RAM | Almacenamiento Total |')
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

$null = $md.AppendLine('| Nombre Motor | Parámetro de Red | Valor Configurado |')
$null = $md.AppendLine('| :--- | :--- | :--- |')
if ($maskingEngines.Count -eq 0) {
    $null = $md.AppendLine('| **-** | **Dirección IP / Hostname** | - |')
    $null = $md.AppendLine('| **-** | **Gateway / Puerta de Enlace** | <**Gateway**> |')
    $null = $md.AppendLine('| **-** | **Servidores DNS** | <**Servidores DNS**> |')
    $null = $md.AppendLine('| **-** | **Servidores NTP** | <**Servidores NTP**> |')
}
else {
    foreach ($eng in $maskingEngines) {
        $engName = Get-SafeProperty -Object $eng -PropertyName 'name' -DefaultValue '-'
        $engHost = Get-SafeProperty -Object $eng -PropertyName 'hostname' -DefaultValue '-'
        $engHostStr = if ($engHost -ne '-' -and [string]$engHost -ne '') { "``$engHost``" } else { "-" }

        $null = $md.AppendLine("| **$engName** | **Dirección IP / Hostname** | $engHostStr |")
        $null = $md.AppendLine("| **$engName** | **Gateway / Puerta de Enlace** | <**Gateway**> |")
        $null = $md.AppendLine("| **$engName** | **Servidores DNS** | <**Servidores DNS**> |")
        $null = $md.AppendLine("| **$engName** | **Servidores NTP** | <**Servidores NTP**> |")
    }
}
$null = $md.AppendLine()

$null = $md.AppendLine('### 2.2. Configuración de Servicios de Infraestructura (SMTP y Autenticación LDAP / Active Directory)')
$null = $md.AppendLine()
$null = $md.AppendLine('#### 2.2.1. Configuración del Servidor de Correo (SMTP)')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla resumen de la configuración del servidor SMTP para notificaciones de eventos y alertas:')
$null = $md.AppendLine()

$smtpHost = if ($smtpConfigObj -and $null -ne $smtpConfigObj.hostname -and [string]$smtpConfigObj.hostname -ne "") { $smtpConfigObj.hostname } elseif ($smtpConfigObj -and $null -ne $smtpConfigObj.host -and [string]$smtpConfigObj.host -ne "") { $smtpConfigObj.host } else { "-" }
$smtpPort = if ($smtpConfigObj -and $null -ne $smtpConfigObj.port) { [string]$smtpConfigObj.port } else { "-" }
$smtpEnabled = if ($smtpConfigObj -and $null -ne $smtpConfigObj.enabled) { ([string]$smtpConfigObj.enabled).ToLower() } else { "-" }
$smtpAuth = if ($smtpConfigObj -and $null -ne $smtpConfigObj.authentication_enabled) { ([string]$smtpConfigObj.authentication_enabled).ToLower() } else { "-" }
$smtpTls = if ($smtpConfigObj -and $null -ne $smtpConfigObj.tls_enabled) { ([string]$smtpConfigObj.tls_enabled).ToLower() } else { "-" }
$smtpFrom = if ($smtpConfigObj -and $null -ne $smtpConfigObj.from_address -and [string]$smtpConfigObj.from_address -ne "") { $smtpConfigObj.from_address } else { "-" }

$null = $md.AppendLine('| Parámetro SMTP | Valor Configurado |')
$null = $md.AppendLine('| :--- | :--- |')
$null = $md.AppendLine("| **Servidor SMTP (Host)** | ``$smtpHost`` |")
$null = $md.AppendLine("| **Puerto** | ``$smtpPort`` |")
$null = $md.AppendLine("| **Estado Habilitado (Enabled)** | ``$smtpEnabled`` |")
$null = $md.AppendLine("| **Autenticación Habilitada (Auth)** | ``$smtpAuth`` |")
$null = $md.AppendLine("| **Cifrado TLS** | ``$smtpTls`` |")
$null = $md.AppendLine("| **Dirección Remitente (From)** | ``$smtpFrom`` |")
$null = $md.AppendLine()

$null = $md.AppendLine('#### 2.2.2. Configuración de Autenticación LDAP / Controlador de Dominio (Active Directory)')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla resumen de la integración con LDAP / Active Directory para autenticación de usuarios:')
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

$null = $md.AppendLine('| Parámetro LDAP / Active Directory | Valor Configurado |')
$null = $md.AppendLine('| :--- | :--- |')
$null = $md.AppendLine("| **Integración LDAP Habilitada** | ``$ldapEnabled`` |")
$null = $md.AppendLine("| **Servidor Host LDAP / Controlador de Dominio** | ``$ldapHost`` |")
$null = $md.AppendLine("| **Puerto** | ``$ldapPort`` |")
$null = $md.AppendLine("| **Dominios Registrados** | $ldapDomains |")
$null = $md.AppendLine("| **Auto-creación de Usuarios** | ``$ldapAutoCreate`` |")
$null = $md.AppendLine("| **Conexión Segura (SSL)** | ``$ldapSsl`` |")
$null = $md.AppendLine()

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 3. Algoritmos de Consulta de Archivo TXT (`Secure Lookup` / `Name`)')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla resumen de los algoritmos basados en archivos de texto de valores de reemplazo:')
$null = $md.AppendLine()

if ($simpleAlgos.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron algoritmos simples con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Algoritmo | Framework | Archivo TXT Utilizado | Motor / Engine | Descripcion |')
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
$null = $md.AppendLine('## 3. Algoritmos Compuestos (`FullName`)')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla detallada del algoritmo compuesto `FullName` y los algoritmos sencillos que lo integran:')
$null = $md.AppendLine()

if ($compositeAlgos.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron algoritmos compuestos (FullName) con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Algoritmo Compuesto | Framework | Componente Nombres (First Name) | Archivo TXT Nombres | Componente Apellidos (Last Name) | Archivo TXT Apellidos | Descripcion |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    
    foreach ($algo in $compositeAlgos) {
        $nameStr = $algo.name
        $fwStr = Get-SafeProperty -Object $algo -PropertyName 'framework_name' -DefaultValue 'FullName'
        $descRaw = Get-SafeProperty -Object $algo -PropertyName 'description' -DefaultValue '-'
        $descStr = $descRaw -replace '\r?\n', ' '
        
        # Referencias de componentes
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
$null = $md.AppendLine('## 4. Dominios (Data Classes) y su Relacion con Algoritmos')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla de relacion entre los dominios (Data Classes) definidos y su algoritmo de enmascaramiento asignado:')
$null = $md.AppendLine()

if ($targetDcs.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron dominios (Data Classes) con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Dominio (Data Class) | Algoritmo Asignado | Motor / Engine |')
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
$null = $md.AppendLine('## 5. Clasificadores de Profiling (Classifiers)')
$null = $md.AppendLine()
$null = $md.AppendLine('Desglose de clasificadores utilizados en las reglas de perfilado (Profiling), categorizados por tipo de Framework:')
$null = $md.AppendLine()

$pathRegexCls = @($targetCls | Where-Object { $_.framework -eq 'PATH' -or $_.framework -eq 'REGEX' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$listCls      = @($targetCls | Where-Object { $_.framework -eq 'LIST' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)
$dataTypeCls  = @($targetCls | Where-Object { $_.framework -eq 'DATA_TYPE' } | Sort-Object @{ Expression = { Get-SafeProperty -Object $_ -PropertyName 'engine_name' -DefaultValue 'DCT / Global' } }, name)

# 5.1. Clasificadores PATH y REGEX
$null = $md.AppendLine('### 5.1. Clasificadores de Nombre de Columna y Expresion Regular (PATH / REGEX)')
$null = $md.AppendLine()
if ($pathRegexCls.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron clasificadores de tipo PATH o REGEX con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Expresion Regular (Regex) | Motor / Engine |')
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

# 5.2. Clasificadores LIST
$null = $md.AppendLine('### 5.2. Clasificadores de Lista de Valores (LIST)')
$null = $md.AppendLine()
if ($listCls.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron clasificadores de tipo LIST con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Nombre de Archivo TXT | Motor / Engine |')
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

# 5.3. Clasificadores DATA_TYPE
$null = $md.AppendLine('### 5.3. Clasificadores de Tipo de Datos (DATA_TYPE)')
$null = $md.AppendLine()
if ($dataTypeCls.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron clasificadores de tipo DATA_TYPE con el prefijo especificado._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Tipos de Datos Permitidos | Motor / Engine |')
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
$null = $md.AppendLine('## 6. Profile Sets (Discovery Policies) y Clasificadores Asignados')
$null = $md.AppendLine()
$null = $md.AppendLine('Relacion entre el Profile Set de perfilado y la lista completa de clasificadores que lo componen:')
$null = $md.AppendLine()

if ($dpResults.Count -eq 0) {
    $null = $md.AppendLine("_No se encontraron Profile Sets que contengan clasificadores con el prefijo '$Prefix'._")
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Profile Set (Discovery Policy) | Lista de Clasificadores (Classifiers) |')
    $null = $md.AppendLine('| :--- | :--- |')
    foreach ($dpRes in $dpResults) {
        $null = $md.AppendLine("| **$($dpRes.Name)** | $($dpRes.ClassifiersList) |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 7. Conexiones de Datos (Connectors) y Parametros JDBC')
$null = $md.AppendLine()

$null = $md.AppendLine('### 7.1. Conexiones de Datos Definidas')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla resumen de las conexiones de datos (Connectors), incluyendo servidor, base de datos, esquema y usuario:')
$null = $md.AppendLine()

if ($connItems.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron conexiones de datos en la instancia actual._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Conexion (Connector) | Servidor / Host | Base de Datos | Esquema | Usuario | Tipo / Plataforma | Motor / Engine |')
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

$null = $md.AppendLine('### 7.2. Parametros de Driver JDBC Configurados')
$null = $md.AppendLine()
$null = $md.AppendLine('Tabla de parametros del driver JDBC recuperados con valor configurado:')
$null = $md.AppendLine()

if ($jdbcPropResults.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron parametros de driver JDBC para las conexiones actuales._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Conexion (Connector) | Parametro Driver JDBC | Valor Configurado |')
    $null = $md.AppendLine('| :--- | :--- | :--- |')
    foreach ($prop in $jdbcPropResults) {
        $valClean = [string]$prop.PropertyValue -replace '\|', '\|'
        $null = $md.AppendLine("| **$($prop.ConnectorName)** | ``$($prop.PropertyName)`` | ``$valClean`` |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 8. Rule Sets, Tablas y Asignacion de Algoritmos / Dominios')
$null = $md.AppendLine()
$null = $md.AppendLine('Relacion de los Rule Sets definidos, sus tablas correspondientes, los elementos/columnas con algoritmos y dominios asignados, y sus llaves logicas (Logical Keys):')
$null = $md.AppendLine()

$null = $md.AppendLine('### 8.1. Rule Sets, Tablas y Asignacion de Algoritmos / Dominios')
$null = $md.AppendLine()

if ($ruleSetTableCols.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron asignaciones de columnas/algoritmos en los Rule Sets actuales._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Rule Set | Tabla (Table) | Columna (Column) | Dominio (Data Class) | Algoritmo Asignado |')
    $null = $md.AppendLine('| :--- | :--- | :--- | :--- | :--- |')
    
    $sortedRsCols = @($ruleSetTableCols | Sort-Object RuleSetName, TableName, ColumnName)
    foreach ($row in $sortedRsCols) {
        $null = $md.AppendLine("| **$($row.RuleSetName)** | **$($row.TableName)** | ``$($row.ColumnName)`` | **$($row.DataClassName)** | $($row.AlgorithmName) |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('### 8.2. Tablas de Base de Datos y Llaves Logicas (Logical Keys)')
$null = $md.AppendLine()

if ($ruleSetTables.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron tablas registradas en los Rule Sets actuales._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Rule Set | Tabla (Table) | Llave Logica (Logical Key) |')
    $null = $md.AppendLine('| :--- | :--- | :--- |')
    
    $sortedRsTables = @($ruleSetTables | Sort-Object RuleSetName, TableName -Unique)
    foreach ($row in $sortedRsTables) {
        $null = $md.AppendLine("| **$($row.RuleSetName)** | **$($row.TableName)** | ``$($row.LogicalKey)`` |")
    }
    $null = $md.AppendLine()
}

$null = $md.AppendLine('---')
$null = $md.AppendLine()
$null = $md.AppendLine('## 10. Definicion de Trabajos de Perfilado y Enmascaramiento (Jobs)')
$null = $md.AppendLine()

$null = $md.AppendLine('### 10.1. Trabajos de Perfilado (Profiling / Discovery Jobs)')
$null = $md.AppendLine()
$null = $md.AppendLine('Definicion de los trabajos de perfilado (Discovery), asociacion de Rule Set, Profile Set y atributos de ejecucion:')
$null = $md.AppendLine()

if ($profilingJobs.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron trabajos de perfilado (Profiling / Discovery) definidos._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Trabajo (Job Name) | Tipo | Rule Set | Profile Set (Discovery Policy) | Conector / Plataforma | Tipo Ejecucion | Motor / Engine | Ambiente / Aplicacion |')
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

$null = $md.AppendLine('### 10.2. Trabajos de Enmascaramiento (Masking Jobs)')
$null = $md.AppendLine()
$null = $md.AppendLine('Definicion de los trabajos de enmascaramiento (Masking), asociacion de Rule Set y atributos de enmascaramiento:')
$null = $md.AppendLine()

if ($maskingJobs.Count -eq 0) {
    $null = $md.AppendLine('_No se encontraron trabajos de enmascaramiento (Masking) definidos._')
    $null = $md.AppendLine()
}
else {
    $null = $md.AppendLine('| Trabajo (Job Name) | Tipo | Rule Set | On-The-Fly | Truncar Tablas | Eliminar Indices | Conector / Plataforma | Tipo Ejecucion | Motor / Engine | Ambiente / Aplicacion |')
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
$null = $md.AppendLine('## 11. Criterios de Configuracion de Claves para el Rule Set (_In-Place Masking_)')
$null = $md.AppendLine()
$null = $md.AppendLine('Como criterio general de arquitectura para futuras implementaciones de **_In-Place Masking_**, la definicion de la identificacion de registros dentro del _Rule Set_ debe cumplir con las siguientes directrices:')
$null = $md.AppendLine()
$null = $md.AppendLine('**1. Uso de Clave Logica (_Logical Key_):**')
$null = $md.AppendLine('Siempre que exista una columna (o conjunto de columnas) que garantice unicidad, valor no nulo y cuyas columnas **no sean objeto de enmascaramiento**, debe definirse explicitamente como _Logical Key_ en el _Rule Set_. Esto permite a la herramienta ejecutar las sentencias de actualizacion (`UPDATE`) de forma directa y optimizada mediante los indices existentes en el motor de base de datos.')
$null = $md.AppendLine()
$null = $md.AppendLine('**2. Mecanismo por Columna Temporal (_Identity Column_):**')
$null = $md.AppendLine('Cuando la tabla no disponga de una clave unica con dichas caracteristicas, o cuando la clave primaria/unica existente este compuesta por campos que requieran ser enmascarados, **no debe definirse ninguna _Logical Key_ en el _Rule Set_**. En estos escenarios, Delphix creara de forma automatica una columna identidad temporal (`MASK_ROW_ID`) en la tabla destino para gestionar el puntero de enmascaramiento por lote, eliminandola automaticamente al concluir el _Job_.')
$null = $md.AppendLine()
$null = $md.AppendLine('### Resumen de Decision (Matriz de Referencia)')
$null = $md.AppendLine()
$null = $md.AppendLine('| **Escenario de la Tabla** | **Accion en el Rule Set** | **Mecanismo de Update** |')
$null = $md.AppendLine('| :--- | :--- | :--- |')
$null = $md.AppendLine('| Tiene PK/UQ no nula y sus campos **no** se enmascaran | Definir **Logical Key** explicita | Busqueda por indice existente |')
$null = $md.AppendLine('| No tiene PK/UQ, o la clave existente **se enmascara** | **No definir** Logical Key | Columna identidad temporal (`MASK_ROW_ID`) |')
$null = $md.AppendLine()

# Guardar archivo en UTF8
[System.IO.File]::WriteAllText($OutputFile, $md.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "[+] Documento generado exitosamente en: $OutputFile" -ForegroundColor Green
