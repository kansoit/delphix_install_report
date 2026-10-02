# ACME Corp - Delphix Continuous Compliance Configuration Report

---

## 1. Executive Summary

For the implementation of Delphix Continuous Compliance Version **`2026.4.0.1`**, **`ACME Corp`** has selected the database **`ACME_REJECTS_DB`** on **`SQLSRV`** as the pilot case for sensitive data masking.

The main objective of this report is to consolidate the configuration applied in the customer environment, including masking algorithms, data domains, profiling classifiers, rule sets, data connectors, and job execution definitions.

---

## 2. Delphix Continuous Compliance Engine Infrastructure and Services

### 2.1. Registered Delphix Continuous Compliance Engines (Masking Engines)

Summary table of Continuous Compliance (Masking) engines registered in Delphix DCT, their version, IP address/hostname, connection status, and allocated resources:

| Engine Name | Type | Version | Connection Status | CPU Cores | RAM Memory | Total Storage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **DPXMSK** | MASKING | `2026.4.0.1` | ONLINE | 8 Cores | 32 GB | 48 GB |

| Engine Name | Network Parameter         | Configured Value             |
| :---------- | :------------------------ | :--------------------------- |
| **DPXMSK**  | **IP Address / Hostname** | `192.168.1.2`                |
| **DPXMSK**  | **Gateway**               | `192.168.1.1`                |
| **DPXMSK**  | **DNS Servers**           | `192.168.1.1`                |
| **DPXMSK**  | **NTP Servers**           | `south-america.pool.ntp.org` |

### 2.2. Infrastructure Services Configuration (SMTP & LDAP / Active Directory Authentication)

#### 2.2.1. Mail Server Configuration (SMTP)

Summary table of SMTP mail server settings for event and alert notifications:

| SMTP Parameter | Configured Value |
| :--- | :--- |
| **SMTP Server (Host)** | `-` |
| **Port** | `25` |
| **Enabled Status** | `false` |
| **Authentication Enabled (Auth)** | `false` |
| **TLS Encryption** | `false` |
| **Sender Address (From)** | `-` |

#### 2.2.2. LDAP / Domain Controller Authentication Configuration (Active Directory)

Summary table of LDAP / Active Directory integration for user authentication:

| LDAP / Active Directory Parameter | Configured Value |
| :--- | :--- |
| **LDAP Integration Enabled** | `false` |
| **LDAP Host Server / Domain Controller** | `-` |
| **Port** | `-` |
| **Registered Domains** | - |
| **Auto-create Users** | `true` |
| **Secure Connection (SSL)** | `true` |

---

## 3. Text File Lookup Algorithms (`Secure Lookup` / `Name`)

Summary table of algorithms based on replacement value text files:

| Algorithm | Framework | TXT File Used | Engine | Description |
| :--- | :--- | :--- | :--- | :--- |
| **0-Apellido-NM** | Name | `APELLIDO.txt` | DPXMSK | Algoritmo para el dominio 0-APELLIDO |
| **0-Ciudad-SL** | Secure Lookup | `CIUDAD.txt` | DPXMSK | Algoritmo para el dominio 0-CIUDAD |
| **0-Comentario-SL** | Secure Lookup | `COMENTARIO.txt` | DPXMSK | Algoritmo para el dominio 0-COMENTARIO |
| **0-Direccion-SL** | Secure Lookup | `DIRECCION.txt` | DPXMSK | Algoritmo para el dominio 0-DIRECCION |
| **0-Nacionalidad-SL** | Secure Lookup | `NACIONALIDAD.txt` | DPXMSK | Algoritmo para el Dominio 0-NACIONALIDAD |
| **0-Nombre_Empresa-SL** | Secure Lookup | `NOMBRE_EMPRESA.txt` | DPXMSK | Algoritmo para el Dominio 0-NOMBRE_EMPRESA |
| **0-Nombre-NM** | Name | `NOMBRE.txt` | DPXMSK | Algoritmo para el dominio 0-NOMBRE |
| **0-Pais-SL** | Secure Lookup | `PAIS.txt` | DPXMSK | Algoritmo para el Dominio 0-PAIS |
| **0-Provincia-SL** | Secure Lookup | `PROVINCIA.txt` | DPXMSK | Algoritmo para el dominio 0-PROVINCIA |

---

## 4. Composite Algorithms (`FullName`)

Detailed table of the composite algorithm `FullName` and the simple algorithms that compose it:

| Composite Algorithm | Framework | First Name Component | First Name TXT File | Last Name Component | Last Name TXT File | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **0-Nombre_Completo-FN** | FullName | **0-Apellido-NM** | `APELLIDO.txt` | **0-Nombre-NM** | `NOMBRE.txt` | Algoritmo para el dominio 0-NOMBRE_COMPLETO |

---

## 5. Domains (Data Classes) and Algorithm Association

Association table between defined domains (Data Classes) and their assigned masking algorithm:

| Domain (Data Class) | Assigned Algorithm | Engine |
| :--- | :--- | :--- |
| **0-APELLIDO** | 0-Apellido-NM | DPXMSK |
| **0-BIOMETRICO** | NullValueLookup | DPXMSK |
| **0-CASILLA_POSTAL** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-CIUDAD** | 0-Ciudad-SL | DPXMSK |
| **0-CODIGO_POSTAL** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-CODIGO_SEGURIDAD** | NullValueLookup | DPXMSK |
| **0-CODIGO_SWIFT** | dlpx-core:SwiftCode SL | DPXMSK |
| **0-COMENTARIO** | 0-Comentario-SL | DPXMSK |
| **0-CONTRASENA** | NullValueLookup | DPXMSK |
| **0-DIRECCION** | 0-Direccion-SL | DPXMSK |
| **0-DIRECCION_IP** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-EDAD** | dlpx-core:CM Digits | DPXMSK |
| **0-EMAIL** | EmailLookup | DPXMSK |
| **0-FECHA_NACIMIENTO** | DateShiftFixed | DPXMSK |
| **0-FIRMA** | NullValueLookup | DPXMSK |
| **0-IBAN** | dlpx-core:IBAN | DPXMSK |
| **0-ID_IDENTIDAD** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-ID_IMPUESTO** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-ID_USUARIO** | NullValueLookup | DPXMSK |
| **0-NACIONALIDAD** | 0-Nacionalidad-SL | DPXMSK |
| **0-NOM_COMPLETO** | 0-Nombre_Completo-FN | DPXMSK |
| **0-NOMBRE** | 0-Nombre-NM | DPXMSK |
| **0-NOMBRE_EMPRESA** | 0-Nombre_Empresa-SL | DPXMSK |
| **0-NRO_BENEF** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-NRO_CLIENTE** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-NRO_CUENTA** | dlpx-core:CM Alpha-Numeric | DPXMSK |
| **0-NRO_TELEFONO** | dlpx-core:Phone Unique | DPXMSK |
| **0-PAIS** | 0-Pais-SL | DPXMSK |
| **0-PROVINCIA** | 0-Provincia-SL | DPXMSK |
| **0-TARJETA_PAGO** | CreditCard | DPXMSK |
| **0-WEB_URL** | dlpx-core:CM Alpha-Numeric | DPXMSK |

---

## 6. Profiling Classifiers (Classifiers)

Breakdown of classifiers used in Profiling rules, categorized by Framework type:

### 6.1. Column Name and Regular Expression Classifiers (PATH / REGEX)

| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Regular Expression (Regex) | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0-APELLIDO-PTH** | PATH | **0-APELLIDO** | 0.67 | `(?i)(?:^\|[_\s-])apel(?:lido)?s?.*$` | DPXMSK |
| **0-BIOMETRICO-PTH** | PATH | **0-BIOMETRICO** | 0.67 | `(?i)(?:^\|[_\s-])(?:biometr\|patron\|token\|registro\|huella).*$` | DPXMSK |
| **0-CASILLA_POSTAL-PTH** | PATH | **0-CASILLA_POSTAL** | 0.67 | `(?i)(?:^\|[_\s-])(?:casilla[_\s-]?(?:postal\|de[_\s-]?correos?)\|casilla).*$` | DPXMSK |
| **0-CIUDAD-PTH** | PATH | **0-CIUDAD** | 0.67 | `(?i)(?:^\|[_\s-])(?:nom(?:bre)?[_\s-]?\|cod(?:igo)?[_\s-]?\|id[_\s-]?)?(?:ciu(?:dad)?\|loc(?:alidad)?\|muni(?:cipio)?).*$` | DPXMSK |
| **0-CODIGO_POSTAL-PTH** | PATH | **0-CODIGO_POSTAL** | 0.67 | `(?i)(?:^\|[_\s-])(?:c(?:odigo)?_?p(?:ostal)?).*$` | DPXMSK |
| **0-CODIGO_SEGURIDAD-PTH** | PATH | **0-CODIGO_SEGURIDAD** | 0.67 | `(?i)(?:^\|[_\s-])(?:tarj(?:eta)?_?cvv\|cvc?\|pin\|cod(?:igo)?[_\s-]?seg(?:uridad)?\|seguridad\|token).*$` | DPXMSK |
| **0-CODIGO_SWIFT-DAT** | REGEX | **0-CODIGO_SWIFT** | 0.7 | `^(?i)[A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?$` | DPXMSK |
| **0-CODIGO_SWIFT-PTH** | PATH | **0-CODIGO_SWIFT** | 0.67 | `(?i)(?:^\|[_\s-])(?:swift\|bic\|cod(?:igo)?[_\s-]?(?:swift\|bic)).*$` | DPXMSK |
| **0-COMENTARIO-PTH** | PATH | **0-COMENTARIO** | 0.67 | `(?i)(?:^\|[_\s-])(?:com(?:entari?os?)?\|obs(?:ervaci(?:on\|ones))?\|notas?\|desc(?:ripcion)?\|txt\|texto).*$` | DPXMSK |
| **0-CONTRASENA-PTH** | PATH | **0-CONTRASENA** | 0.67 | `(?i)(?:^\|[_\s-])(?:contra(?:sena\|senia)?\|clv\|claves?).*$` | DPXMSK |
| **0-DIRECCION_IP-DAT** | REGEX | **0-DIRECCION_IP** | 0.7 | `^(?:(?:25[0-5]\|2[0-4][0-9]\|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]\|2[0-4][0-9]\|[01]?[0-9][0-9]?)$`<br>`(?i)^(?:(?:[0-9a-f]{1,4}:){1,7}:\|:(?::[0-9a-f]{1,4}){1,7}\|(?:[0-9a-f]{1,4}:){1,7}[0-9a-f]{1,4}\|(?:[0-9a-f]{1,4}:){1,6}:[0-9a-f]{1,4}\|(?:[0-9a-f]{1,4}:){1,5}(?::[0-9a-f]{1,4}){1,2}\|(?:[0-9a-f]{1,4}:){1,4}(?::[0-9a-f]{1,4}){1,3}\|(?:[0-9a-f]{1,4}:){1,3}(?::[0-9a-f]{1,4}){1,4}\|(?:[0-9a-f]{1,4}:){1,2}(?::[0-9a-f]{1,4}){1,5}\|[0-9a-f]{1,4}:(?::[0-9a-f]{1,4}){1,6})$` | DPXMSK |
| **0-DIRECCION_IP-PTH** | PATH | **0-DIRECCION_IP** | 0.67 | `(?i)(?:^\|[_\s-])(?:ip\|dir(?:eccion)?_?ip).*$` | DPXMSK |
| **0-DIRECCION-DAT** | REGEX | **0-DIRECCION** | 0.7 | `(?i)(?:calle\|av(?:da\|enida)?\.?\|bulevar\|pasaje\|camino\|ruta\|carretera\|autopista)\s+(?:[a-z0-9¬░._-]+\s+){1,5}[0-9]{1,5}(?:\s+(?:piso\|dpto\|depto\|oficina\|of)\s*[0-9a-z]{1,3})?`<br>`(?i)(?:calle\|av(?:da\|enida)?\.?\|ruta)\s+[a-z0-9¬░._-]+\s+(?:n(?:ro\|um)?\|km\|n░)\s*[0-9]{1,5}` | DPXMSK |
| **0-DIRECCION-PTH** | PATH | **0-DIRECCION** | 0.67 | `(?i)(?:^\|[_\s-])(?:dir(?:eccion)?\|dom(?:icilio)?\|calle).*$` | DPXMSK |
| **0-EDAD-PTH** | PATH | **0-EDAD** | 0.67 | `(?i)(?:^\|[_\s-])edad.*$` | DPXMSK |
| **0-EMAIL-DAT** | REGEX | **0-EMAIL** | 0.7 | `(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$` | DPXMSK |
| **0-EMAIL-PTH** | PATH | **0-EMAIL** | 0.67 | `(?i)(?:^\|[_\s-])(?:e?mail\|correo).*$` | DPXMSK |
| **0-FECHA_NACIMIENTO-PTH** | PATH | **0-FECHA_NACIMIENTO** | 0.67 | `(?i)(?:^\|[_\s-])(?:f(?:ec(?:ha)?)?_?nac(?:im(?:iento)?)?\|nacimiento).*$` | DPXMSK |
| **0-FIRMA-PTH** | PATH | **0-FIRMA** | 0.67 | `(?i)(?:^\|[_\s-])(?:frm\|firma).*$` | DPXMSK |
| **0-IBAN-DAT** | REGEX | **0-IBAN** | 0.7 | `(?i)^(?:(AD[0-9]{10}[A-Z0-9]{12})\|(AE[0-9]{21})\|(AL[0-9]{10}[A-Z0-9]{16})\|(AT[0-9]{18})\|(AZ[0-9]{2}[A-Z]{4}[A-Z0-9]{20})\|(BA[0-9]{18})\|(BE[0-9]{14})\|(BG[0-9]{2}[A-Z]{4}[0-9]{6}[A-Z0-9]{8})\|(BH[0-9]{2}[A-Z]{4}[A-Z0-9]{14})\|(BI[0-9]{25})\|(BR[0-9]{25}[A-Z]{1}[A-Z0-9]{1})\|(BY[0-9]{2}[A-Z0-9]{4}[0-9]{4}[A-Z0-9]{16})\|(CH[0-9]{7}[A-Z0-9]{12})\|(CR[0-9]{20})\|(CY[0-9]{10}[A-Z0-9]{16})\|(CZ[0-9]{22})\|(DE[0-9]{20})\|(DJ[0-9]{25})\|(DK[0-9]{16})\|(DO[0-9]{2}[A-Z0-9]{4}[0-9]{20})\|(EE[0-9]{18})\|(EG[0-9]{27})\|(ES[0-9]{22})\|(FI[0-9]{16})\|(FO[0-9]{16})\|(FR[0-9]{12}[A-Z0-9]{11}[0-9]{2})\|(GB[0-9]{2}[A-Z]{4}[0-9]{14})\|(GE[0-9]{2}[A-Z]{2}[0-9]{16})\|(GI[0-9]{2}[A-Z]{4}[A-Z0-9]{15})\|(GL[0-9]{16})\|(GR[0-9]{9}[A-Z0-9]{16})\|(GT[0-9]{2}[A-Z0-9]{24})\|(HR[0-9]{19})\|(HU[0-9]{26})\|(IE[0-9]{2}[A-Z]{4}[0-9]{14})\|(IL[0-9]{21})\|(IQ[0-9]{2}[A-Z]{4}[0-9]{15})\|(IS[0-9]{24})\|(IT[0-9]{2}[A-Z]{1}[0-9]{10}[A-Z0-9]{12})\|(JO[0-9]{2}[A-Z]{4}[0-9]{4}[A-Z0-9]{18})\|(KW[0-9]{2}[A-Z]{4}[A-Z0-9]{22})\|(KZ[0-9]{5}[A-Z0-9]{13})\|(LB[0-9]{6}[A-Z0-9]{20})\|(LC[0-9]{2}[A-Z]{4}[A-Z0-9]{24})\|(LI[0-9]{7}[A-Z0-9]{12})\|(LT[0-9]{18})\|(LU[0-9]{5}[A-Z0-9]{13})\|(LV[0-9]{2}[A-Z]{4}[A-Z0-9]{13})\|(LY[0-9]{23})\|(MC[0-9]{12}[A-Z0-9]{11}[0-9]{2})\|(MD[0-9]{2}[A-Z0-9]{20})\|(ME[0-9]{20})\|(MK[0-9]{5}[A-Z0-9]{10}[0-9]{2})\|(MR[0-9]{25})\|(MT[0-9]{2}[A-Z]{4}[0-9]{5}[A-Z0-9]{18})\|(MU[0-9]{2}[A-Z]{4}[0-9]{19}[A-Z]{3})\|(NL[0-9]{2}[A-Z]{4}[0-9]{10})\|(NO[0-9]{13})\|(PK[0-9]{2}[A-Z]{4}[A-Z0-9]{16})\|(PL[0-9]{26})\|(PS[0-9]{2}[A-Z]{4}[A-Z0-9]{21})\|(PT[0-9]{23})\|(QA[0-9]{2}[A-Z]{4}[A-Z0-9]{21})\|(RO[0-9]{2}[A-Z]{4}[A-Z0-9]{16})\|(RS[0-9]{20})\|(RU[0-9]{31})\|(SA[0-9]{4}[A-Z0-9]{18})\|(SC[0-9]{2}[A-Z]{4}[0-9]{20}[A-Z]{3})\|(SD[0-9]{16})\|(SE[0-9]{22})\|(SI[0-9]{17})\|(SK[0-9]{22})\|(SM[0-9]{2}[A-Z]{1}[0-9]{10}[A-Z0-9]{12})\|(SO[0-9]{21})\|(ST[0-9]{23})\|(SV[0-9]{2}[A-Z]{4}[0-9]{20})\|(TL[0-9]{21})\|(TN[0-9]{22})\|(TR[0-9]{8}[A-Z0-9]{16})\|(UA[0-9]{8}[A-Z0-9]{19})\|(VA[0-9]{20})\|(VG[0-9]{2}[A-Z]{4}[0-9]{16})\|(XK[0-9]{18}))$` | DPXMSK |
| **0-IBAN-PTH** | PATH | **0-IBAN** | 0.67 | `(?i)(?:^\|[_\s-])(?:iban\|id[_\s-]?iban).*$` | DPXMSK |
| **0-ID_IDENTIDAD-DAT** | REGEX | **0-ID_IDENTIDAD** | 0.7 | `(?i)(?:dni\|ci\|ced\|cedula\|lc\|le)[_\s-]?[0-9]{5,12}` | DPXMSK |
| **0-ID_IDENTIDAD-PTH** | PATH | **0-ID_IDENTIDAD** | 0.67 | `(?i)(?:^\|[_\s-])(?:dni\|cedula\|ci\|lc\|le\|documento\|doc\|nro_doc\|(?:id\|num(?:ero)?\|doc(?:umento)?)[_\s-]?(?:identidad\|id\|dni\|cedula\|ci\|lc\|le)).*$` | DPXMSK |
| **0-ID_IMPUESTO-DAT** | REGEX | **0-ID_IMPUESTO** | 0.7 | `^\d{2}-\d{8}-\d$`<br>`(?i)(?:cuit\|cuil\|ruc\|nit\|cpf\|cnpj\|rfc)[_\s-]?\b[0-9a-z]{8,14}\b` | DPXMSK |
| **0-ID_IMPUESTO-PTH** | PATH | **0-ID_IMPUESTO** | 0.67 | `(?i)(?:^\|[_\s-])(?:cuit\|cuil\|ruc\|nit\|rfc\|cpf\|cnpj\|id_impuesto\|id_tributo\|num(?:ero)?[_\s-]?(?:impuesto\|tributo)).*$` | DPXMSK |
| **0-ID_USUARIO-PTH** | PATH | **0-ID_USUARIO** | 0.67 | `(?i)(?:^\|[_\s-])(?:id_usu(?:ario)?\|usu(?:ario)?_?id\|usu(?:ario)?\|nom(?:bre)?_usu(?:ario)?\|alias_usu(?:ario)?).*$` | DPXMSK |
| **0-NACIONALIDAD-PTH** | PATH | **0-NACIONALIDAD** | 0.67 | `(?i)(?:^\|[_\s-])(?:nac(?:ionalidad)?\|pais(?:[_\s-]?orig(?:en)?)?\|cod(?:igo)?[_\s-]?pais).*$` | DPXMSK |
| **0-NOM_COMPLETO-PTH** | PATH | **0-NOM_COMPLETO** | 0.67 | `(?i)(?:^\|[_\s-])(?:nom(?:bre)?s?(?:[_\s-]?y)?_?apellidom?s?\|apellidom?s?(?:[_\s-]?y)?_?nom(?:bre)?s?\|nom[_\s-]?ape\|ape[_\s-]?nom\|nombre?s?[_\s-]?compl(?:eto)?s?).*$` | DPXMSK |
| **0-NOMBRE_EMPRESA-PTH** | PATH | **0-NOMBRE_EMPRESA** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:nom(?:bre)?[_\s-]?)?(?:empresa\|compania\|sociedad)\|razon[_\s-]?soc(?:ial)?\|rs).*$` | DPXMSK |
| **0-NOMBRE-PTH** | PATH | **0-NOMBRE** | 0.67 | `(?i)(?:^\|[_\s-])(?:nom(?:bre)s?\|(?:pri(?:mer)?\|seg(?:undo)?)[_\s-]?nom(?:bre)?\|nom(?:bre)?[_\s-]pers(?:ona)?).*$` | DPXMSK |
| **0-NRO_BENEF-PTH** | PATH | **0-NRO_BENEF** | 0.67 | `(?i)(?:^\|[_\s-])(?:num(?:ero)?\|id)[_\s-]?benef(?:iciario)?s?.*$` | DPXMSK |
| **0-NRO_CLIENTE-PTH** | PATH | **0-NRO_CLIENTE** | 0.67 | `(?i)(?:^\|[_\s-])(?:id\|cod(?:igo)?\|num(?:ero)?\|nro)[_\s-]?(?:cli(?:ente)?\|usu(?:ario)?\|abo(?:nado)?).*$` | DPXMSK |
| **0-NRO_CUENTA-PTH** | PATH | **0-NRO_CUENTA** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:nro[_\s-]?\|num(?:ero)?[_\s-]?)?(?:cta\|cuenta)\|cbu\|cvu\|alias[_\s-]?(?:banc(?:ario)?\|cbu\|cta)).*$` | DPXMSK |
| **0-NRO_TELEFONO-DAT** | REGEX | **0-NRO_TELEFONO** | 0.7 | `^(?:\+?54)?(?:9)?(?:11\|[23]\d{2,3})\d{6,8}$`<br>`^(?:\+?54[- ]?)?(?:9[- ]?)?\(?(?:11\|[23]\d{2,3})\)?[- ]?(?:15[- ]?)?\d{3,4}[- ]?\d{4}$` | DPXMSK |
| **0-NRO_TELEFONO-PTH** | PATH | **0-NRO_TELEFONO** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:num(?:ero)?[_\s-]?)?(?:tel(?:e(?:fono)?)?\|cel(?:ular)?\|movil\|contacto)\|fijo).*$` | DPXMSK |
| **0-PAIS-PTH** | PATH | **0-PAIS** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:nom(?:bre)?\|cod(?:igo)?\|id)[_\s-]?pais\|pais).*$` | DPXMSK |
| **0-PROVINCIA-PTH** | PATH | **0-PROVINCIA** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:nom(?:bre)?\|cod(?:igo)?\|id)[_\s-]?(?:prov(?:incia)?\|pcia\|estado)\|prov(?:incia)?\|pcia\|estado_geo\|nom_estado).*$` | DPXMSK |
| **0-TARJETA_PAGO-DAT** | REGEX | **0-TARJETA_PAGO** | 0.7 | `^(?:3[47]\d{13})$`<br>`^(?:4\d{12}(?:\d{3})?(?:\d{3})?)$`<br>`^(?:5[1-5]\d{2}\|222[1-9]\|22[3-9]\d\|2[3-6]\d{2}\|27[01]\d\|2720)\d{12}$`<br>`^(?:2131\|1800\|35\d{3})\d{11}$`<br>`^(?:3(?:0[0-5,9]\|6\d)\d{11}\|3[89]\d{12}?(?:\d{1,3})?)$`<br>`^6(?:(011\|5\d{2})\d{2}\|4[4-9]\d{3}\|2212[6-9]\|221[3-9]\d\|22[2-8]\d{2}\|229[0-1]\d\|2292[0-5])\d{10}?(?:\d{3})?$` | DPXMSK |
| **0-TARJETA_PAGO-PTH** | PATH | **0-TARJETA_PAGO** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:nro?\|num(?:ero)?)[_\s-]?)?tarj(?:eta)?.*$` | DPXMSK |
| **0-WEB_URL-DAT** | REGEX | **0-WEB_URL** | 0.7 | `(?i)(?:https?:\/\/(?:[a-z0-9-]+\.)+[a-z]{2,6}(?::[0-9]+)?\|\bwww\.(?:[a-z0-9-]+\.)+[a-z]{2,6})(?:\/\S*)?` | DPXMSK |
| **0-WEB_URL-PTH** | PATH | **0-WEB_URL** | 0.67 | `(?i)(?:^\|[_\s-])(?:(?:web[_\s-]?)?url\|uri\|endpoint\|link\|enlace\|sitio\|pag(?:ina)?\|home\|direccion).*$` | DPXMSK |

### 6.2. Value List Classifiers (LIST)

| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | TXT File Name | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0-APELLIDO-LST** | LIST | **0-APELLIDO** | 0.9 | `PRF_APELLIDOS_S_ARG.txt` | DPXMSK |
| **0-CIUDAD-LST** | LIST | **0-CIUDAD** | 1 | `PRF_CIUDAD.txt` | DPXMSK |
| **0-NACIONALIDAD-LST** | LIST | **0-NACIONALIDAD** | 1 | `PRF_NACIONALIDAD.txt` | DPXMSK |
| **0-NOM_COMPLETO-LIST** | LIST | **0-NOM_COMPLETO** | 0.7 | `PRF_NOMBRES_S_ARG.txt`<br>`PRF_APELLIDOS_S_ARG.txt` | DPXMSK |
| **0-NOMBRE_EMPRESA-LST** | LIST | **0-NOMBRE_EMPRESA** | 1 | `PRF_NOMBRE_EMPRESA.txt` | DPXMSK |
| **0-NOMBRE-LST** | LIST | **0-NOMBRE** | 1 | `PRF_NOMBRES_S_ARG.txt` | DPXMSK |
| **0-PAIS-LST** | LIST | **0-PAIS** | 1 | `PRF_PAIS.txt` | DPXMSK |
| **0-PROVINCIA-LST** | LIST | **0-PROVINCIA** | 1 | `PRF_PROVINCIA.txt` | DPXMSK |

### 6.3. Data Type Classifiers (DATA_TYPE)

| Classifier | Framework | Associated Domain (Data Class) | Relative Weight | Allowed Data Types | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0-APELLIDO-TYP** | DATA_TYPE | **0-APELLIDO** | 0 | String (min: 10) | DPXMSK |
| **0-BIOMETRICO-TYP** | DATA_TYPE | **0-BIOMETRICO** | 0 | String (min: 10), Binary (min: 10) | DPXMSK |
| **0-CASILLA_POSTAL-TYP** | DATA_TYPE | **0-CASILLA_POSTAL** | 0 | String (min: 4), Number (min: 4) | DPXMSK |
| **0-CIUDAD-TYP** | DATA_TYPE | **0-CIUDAD** | 0 | String (min: 10) | DPXMSK |
| **0-CODIGO_POSTAL-TYP** | DATA_TYPE | **0-CODIGO_POSTAL** | 0 | String (min: 4), Number (min: 4) | DPXMSK |
| **0-CODIGO_SEGURIDAD-TYP** | DATA_TYPE | **0-CODIGO_SEGURIDAD** | 0 | String (min: 3), Number (min: 3) | DPXMSK |
| **0-CODIGO_SWIFT-TYP** | DATA_TYPE | **0-CODIGO_SWIFT** | 0 | String (min: 8) | DPXMSK |
| **0-COMENTARIO-TYP** | DATA_TYPE | **0-COMENTARIO** | 0 | String (min: 128) | DPXMSK |
| **0-CONTRASENA-TYP** | DATA_TYPE | **0-CONTRASENA** | 0 | String (min: 6) | DPXMSK |
| **0-DIRECCION_IP-TYP** | DATA_TYPE | **0-DIRECCION_IP** | 0 | String (min: 7) | DPXMSK |
| **0-DIRECCION-TYP** | DATA_TYPE | **0-DIRECCION** | 0 | String (min: 10) | DPXMSK |
| **0-EDAD-TYP** | DATA_TYPE | **0-EDAD** | 0 | String (min: 1), Number (min: 1) | DPXMSK |
| **0-EMAIL-TYP** | DATA_TYPE | **0-EMAIL** | 0 | String (min: 6) | DPXMSK |
| **0-FECHA_NACIMIENTO-TYP** | DATA_TYPE | **0-FECHA_NACIMIENTO** | 0 | String (min: 6), Number (min: 8), Date | DPXMSK |
| **0-FIRMA-TYP** | DATA_TYPE | **0-FIRMA** | 0 | String (min: 1), Binary (min: 50) | DPXMSK |
| **0-IBAN-TYP** | DATA_TYPE | **0-IBAN** | 0 | String (min: 15) | DPXMSK |
| **0-ID_IDENTIDAD-TYP** | DATA_TYPE | **0-ID_IDENTIDAD** | 0 | String (min: 5), Number (min: 5) | DPXMSK |
| **0-ID_IMPUESTO-TYP** | DATA_TYPE | **0-ID_IMPUESTO** | 0 | String (min: 8), Number (min: 8) | DPXMSK |
| **0-ID_USUARIO-TYP** | DATA_TYPE | **0-ID_USUARIO** | 0 | String (min: 1), Number (min: 1) | DPXMSK |
| **0-NACIONALIDAD-TYP** | DATA_TYPE | **0-NACIONALIDAD** | 0 | String (min: 4) | DPXMSK |
| **0-NOM_COMPLETO-TYP** | DATA_TYPE | **0-NOM_COMPLETO** | 0 | String (min: 10) | DPXMSK |
| **0-NOMBRE_EMPRESA-TYP** | DATA_TYPE | **0-NOMBRE_EMPRESA** | 0 | String (min: 5) | DPXMSK |
| **0-NOMBRE-TYP** | DATA_TYPE | **0-NOMBRE** | 0 | String (min: 3) | DPXMSK |
| **0-NRO_BENEF-TYP** | DATA_TYPE | **0-NRO_BENEF** | 0 | String (min: 1), Number (min: 1) | DPXMSK |
| **0-NRO_CLIENTE-TYP** | DATA_TYPE | **0-NRO_CLIENTE** | 0 | String (min: 5), Number (min: 5) | DPXMSK |
| **0-NRO_CUENTA-TYP** | DATA_TYPE | **0-NRO_CUENTA** | 0 | String (min: 5), Number (min: 5) | DPXMSK |
| **0-NRO_TELEFONO-TYP** | DATA_TYPE | **0-NRO_TELEFONO** | 0 | String (min: 7), Number (min: 7) | DPXMSK |
| **0-PAIS-TYP** | DATA_TYPE | **0-PAIS** | 0 | String (min: 4) | DPXMSK |
| **0-PROVINCIA-TYP** | DATA_TYPE | **0-PROVINCIA** | 0 | String (min: 5) | DPXMSK |
| **0-TARJETA_PAGO-TYP** | DATA_TYPE | **0-TARJETA_PAGO** | 0 | Number (min: 15), String (min: 15) | DPXMSK |
| **0-WEB_URL-TYP** | DATA_TYPE | **0-WEB_URL** | 0 | String (min: 10) | DPXMSK |

---

## 7. Profile Sets (Discovery Policies) and Assigned Classifiers

Relationship between the Profiling Profile Set and the complete list of constituent classifiers:

| Profile Set (Discovery Policy) | Classifier List |
| :--- | :--- |
| **ASDD Spanish** | `0-APELLIDO-LST`, `0-APELLIDO-PTH`, `0-APELLIDO-TYP`, `0-BIOMETRICO-PTH`, `0-BIOMETRICO-TYP`, `0-CASILLA_POSTAL-PTH`, `0-CASILLA_POSTAL-TYP`, `0-CIUDAD-LST`, `0-CIUDAD-PTH`, `0-CIUDAD-TYP`, `0-CODIGO_POSTAL-PTH`, `0-CODIGO_POSTAL-TYP`, `0-CODIGO_SEGURIDAD-PTH`, `0-CODIGO_SEGURIDAD-TYP`, `0-CODIGO_SWIFT-DAT`, `0-CODIGO_SWIFT-PTH`, `0-CODIGO_SWIFT-TYP`, `0-COMENTARIO-PTH`, `0-COMENTARIO-TYP`, `0-CONTRASENA-PTH`, `0-CONTRASENA-TYP`, `0-DIRECCION_IP-DAT`, `0-DIRECCION_IP-PTH`, `0-DIRECCION_IP-TYP`, `0-DIRECCION-DAT`, `0-DIRECCION-PTH`, `0-DIRECCION-TYP`, `0-EDAD-PTH`, `0-EDAD-TYP`, `0-EMAIL-DAT`, `0-EMAIL-PTH`, `0-EMAIL-TYP`, `0-FECHA_NACIMIENTO-PTH`, `0-FECHA_NACIMIENTO-TYP`, `0-FIRMA-PTH`, `0-FIRMA-TYP`, `0-IBAN-DAT`, `0-IBAN-PTH`, `0-IBAN-TYP`, `0-ID_IDENTIDAD-DAT`, `0-ID_IDENTIDAD-PTH`, `0-ID_IDENTIDAD-TYP`, `0-ID_IMPUESTO-DAT`, `0-ID_IMPUESTO-PTH`, `0-ID_IMPUESTO-TYP`, `0-ID_USUARIO-PTH`, `0-ID_USUARIO-TYP`, `0-NACIONALIDAD-LST`, `0-NACIONALIDAD-PTH`, `0-NACIONALIDAD-TYP`, `0-NOM_COMPLETO-LIST`, `0-NOM_COMPLETO-PTH`, `0-NOM_COMPLETO-TYP`, `0-NOMBRE_EMPRESA-LST`, `0-NOMBRE_EMPRESA-PTH`, `0-NOMBRE_EMPRESA-TYP`, `0-NOMBRE-LST`, `0-NOMBRE-PTH`, `0-NOMBRE-TYP`, `0-NRO_BENEF-PTH`, `0-NRO_BENEF-TYP`, `0-NRO_CLIENTE-PTH`, `0-NRO_CLIENTE-TYP`, `0-NRO_CUENTA-PTH`, `0-NRO_CUENTA-TYP`, `0-NRO_TELEFONO-DAT`, `0-NRO_TELEFONO-PTH`, `0-NRO_TELEFONO-TYP`, `0-PAIS-LST`, `0-PAIS-PTH`, `0-PAIS-TYP`, `0-PROVINCIA-LST`, `0-PROVINCIA-PTH`, `0-PROVINCIA-TYP`, `0-TARJETA_PAGO-DAT`, `0-TARJETA_PAGO-PTH`, `0-TARJETA_PAGO-TYP`, `0-WEB_URL-DAT`, `0-WEB_URL-PTH`, `0-WEB_URL-TYP` |

---

## 8. Data Connections (Connectors) and JDBC Parameters

### 8.1. Defined Data Connections

Summary table of data connections (Connectors), including server, database, schema, and user:

| Connection (Connector) | Server / Host | Database          | Schema | User | Type / Platform | Engine                |
| :--------------------- | :------------ | :---------------- | :----- | :--- | :-------------- | :-------------------- |
| **SQLSRV-TGT**         | 192.168.1.3   | `ACME_REJECTS_DB` | dbo    | sa   | MSSQL           | DPXMSK                |
| **SQLSRV-TGT**         | 192.168.1.3   | `ACME_REJECTS_DB` | dbo    | sa   | MSSQL           | SQLSRV (Orchestrator) |

### 8.2. Configured JDBC Driver Parameters

Table of JDBC driver parameters retrieved with configured values:

| Connection (Connector) | JDBC Driver Parameter                                    | Configured Value                       |
| :--------------------- | :------------------------------------------------------- | :------------------------------------- |
| **SQLSRV-TGT**         | `databaseName`                                           | `ACME_REJECTS_DB`                      |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertAllowEncryptedValueModifications` | `false`                                |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertKeepNulls`                        | `false`                                |
| **SQLSRV-TGT**         | `cancelQueryTimeout`                                     | `-1`                                   |
| **SQLSRV-TGT**         | `useDefaultGSSCredential`                                | `false`                                |
| **SQLSRV-TGT**         | `sendStringParametersAsUnicode`                          | `true`                                 |
| **SQLSRV-TGT**         | `sendTemporalDataTypesAsStringForBulkCopy`               | `true`                                 |
| **SQLSRV-TGT**         | `portNumber`                                             | `1433`                                 |
| **SQLSRV-TGT**         | `trustStorePassword`                                     | `REDACTED`                             |
| **SQLSRV-TGT**         | `serverPreparedStatementDiscardThreshold`                | `10`                                   |
| **SQLSRV-TGT**         | `password`                                               | `REDACTED`                             |
| **SQLSRV-TGT**         | `useDefaultJaasConfig`                                   | `false`                                |
| **SQLSRV-TGT**         | `integratedSecurity`                                     | `false`                                |
| **SQLSRV-TGT**         | `xopenStates`                                            | `false`                                |
| **SQLSRV-TGT**         | `applicationIntent`                                      | `readwrite`                            |
| **SQLSRV-TGT**         | `socketTimeout`                                          | `0`                                    |
| **SQLSRV-TGT**         | `maxResultBuffer`                                        | `-1`                                   |
| **SQLSRV-TGT**         | `useBulkCopyForBatchInsert`                              | `false`                                |
| **SQLSRV-TGT**         | `trustStoreType`                                         | `JKS`                                  |
| **SQLSRV-TGT**         | `cacheBulkCopyMetadata`                                  | `false`                                |
| **SQLSRV-TGT**         | `responseBuffering`                                      | `adaptive`                             |
| **SQLSRV-TGT**         | `delayLoadingLobs`                                       | `true`                                 |
| **SQLSRV-TGT**         | `vectorTypeSupport`                                      | `v1`                                   |
| **SQLSRV-TGT**         | `fips`                                                   | `false`                                |
| **SQLSRV-TGT**         | `trustServerCertificate`                                 | `false`                                |
| **SQLSRV-TGT**         | `connectRetryCount`                                      | `1`                                    |
| **SQLSRV-TGT**         | `multiSubnetFailover`                                    | `false`                                |
| **SQLSRV-TGT**         | `enablePrepareOnFirstPreparedStatementCall`              | `false`                                |
| **SQLSRV-TGT**         | `calcBigDecimalPrecision`                                | `false`                                |
| **SQLSRV-TGT**         | `serverNameAsACE`                                        | `false`                                |
| **SQLSRV-TGT**         | `prepareMethod`                                          | `prepexec`                             |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertBatchSize`                        | `0`                                    |
| **SQLSRV-TGT**         | `sslProtocol`                                            | `TLS`                                  |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertFireTriggers`                     | `false`                                |
| **SQLSRV-TGT**         | `statementPoolingCacheSize`                              | `0`                                    |
| **SQLSRV-TGT**         | `iPAddressPreference`                                    | `IPv4First`                            |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertCheckConstraints`                 | `false`                                |
| **SQLSRV-TGT**         | `queryTimeout`                                           | `-1`                                   |
| **SQLSRV-TGT**         | `datetimeParameterType`                                  | `datetime2`                            |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertTableLock`                        | `false`                                |
| **SQLSRV-TGT**         | `serverName`                                             | `192.168.1.3`                          |
| **SQLSRV-TGT**         | `quotedIdentifier`                                       | `ON`                                   |
| **SQLSRV-TGT**         | `TransparentNetworkIPResolution`                         | `true`                                 |
| **SQLSRV-TGT**         | `concatNullYieldsNull`                                   | `ON`                                   |
| **SQLSRV-TGT**         | `authenticationScheme`                                   | `nativeAuthentication`                 |
| **SQLSRV-TGT**         | `encrypt`                                                | `false`                                |
| **SQLSRV-TGT**         | `loginTimeout`                                           | `30`                                   |
| **SQLSRV-TGT**         | `sendTimeAsDatetime`                                     | `true`                                 |
| **SQLSRV-TGT**         | `connectRetryInterval`                                   | `10`                                   |
| **SQLSRV-TGT**         | `applicationName`                                        | `Microsoft JDBC Driver for SQL Server` |
| **SQLSRV-TGT**         | `authentication`                                         | `NotSpecified`                         |
| **SQLSRV-TGT**         | `replication`                                            | `false`                                |
| **SQLSRV-TGT**         | `lockTimeout`                                            | `-1`                                   |
| **SQLSRV-TGT**         | `selectMethod`                                           | `direct`                               |
| **SQLSRV-TGT**         | `disableStatementPooling`                                | `true`                                 |
| **SQLSRV-TGT**         | `packetSize`                                             | `8000`                                 |
| **SQLSRV-TGT**         | `lastUpdateCount`                                        | `true`                                 |
| **SQLSRV-TGT**         | `bulkCopyForBatchInsertKeepIdentity`                     | `false`                                |
| **SQLSRV-TGT**         | `useFmtOnly`                                             | `false`                                |
| **SQLSRV-TGT**         | `columnEncryptionSetting`                                | `Disabled`                             |
| **SQLSRV-TGT**         | `jaasConfigurationName`                                  | `SQLJDBCDriver`                        |
| **SQLSRV-TGT**         | `clientKeyPassword`                                      | `REDACTED`                             |

---

## 9. Rule Sets, Tables, and Algorithm / Domain Assignments

### 9.1. Rule Sets, Tables, and Algorithm / Domain Assignments

| Rule Set   | Table                       | Column                   | Domain (Data Class)    | Assigned Algorithm         |
| :--------- | :-------------------------- | :----------------------- | :--------------------- | :------------------------- |
| **SQLSRV** | **FAILED_SENSITIVE_DATA**   | `apellido1`              | **0-APELLIDO**         | 0-Apellido-NM              |
| **SQLSRV** | **FAILED_SENSITIVE_DATA**   | `apellido2`              | **0-APELLIDO**         | 0-Apellido-NM              |
| **SQLSRV** | **FAILED_SENSITIVE_DATA**   | `cedula`                 | **0-ID_IDENTIDAD**     | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **FAILED_SENSITIVE_DATA**   | `nombre`                 | **0-NOMBRE**           | 0-Nombre-NM                |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `DNI`                    | **0-ID_IDENTIDAD**     | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `Domicilio`              | **0-DIRECCION**        | 0-Direccion-SL             |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `Localidad`              | **0-CIUDAD**           | 0-Ciudad-SL                |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `Nombre_Completo`        | **0-NOM_COMPLETO**     | 0-Nombre_Completo-FN       |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `Usuario_Email`          | **0-EMAIL**            | EmailLookup                |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `APELLIDO`               | **0-APELLIDO**         | 0-Apellido-NM              |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `BIOMETRICO`             | **0-BIOMETRICO**       | NullValueLookup            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `CIUDAD`                 | **0-CIUDAD**           | 0-Ciudad-SL                |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `CODIGO_POSTAL`          | **0-CODIGO_POSTAL**    | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `CODIGO_SWIFT`           | **0-CODIGO_SWIFT**     | dlpx-core:SwiftCode SL     |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `COMENTARIO`             | **0-COMENTARIO**       | 0-Comentario-SL            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `CONTRASENA`             | **0-CONTRASENA**       | NullValueLookup            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `DIRECCION`              | **0-DIRECCION**        | 0-Direccion-SL             |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `DIRECCION_IP`           | **0-DIRECCION_IP**     | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `EMAIL`                  | **0-EMAIL**            | EmailLookup                |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `FECHA_NACIMIENTO`       | **0-FECHA_NACIMIENTO** | DateShiftFixed             |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `FIRMA`                  | **0-FIRMA**            | NullValueLookup            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `IBAN`                   | **0-IBAN**             | dlpx-core:IBAN             |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `ID_IDENTIDAD`           | **0-ID_IDENTIDAD**     | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `ID_IMPUESTO`            | **0-ID_IMPUESTO**      | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `ID_TARJETA`             | **0-TARJETA_PAGO**     | CreditCard                 |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `ID_USUARIO`             | **0-ID_USUARIO**       | NullValueLookup            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NACIONALIDAD`           | **0-NACIONALIDAD**     | 0-Nacionalidad-SL          |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NOMBRE`                 | **0-NOMBRE**           | 0-Nombre-NM                |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NOMBRE_COMPLETO`        | **0-NOM_COMPLETO**     | 0-Nombre_Completo-FN       |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NOMBRE_EMPRESA`         | **0-NOMBRE_EMPRESA**   | 0-Nombre_Empresa-SL        |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NUMERO_BENEFICIARIO`    | **0-NRO_BENEF**        | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NUMERO_CLIENTE`         | **0-NRO_CLIENTE**      | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NUMERO_CUENTA_BANCARIA` | **0-NRO_CUENTA**       | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NUMERO_DIRECCION`       | **0-WEB_URL**          | dlpx-core:CM Alpha-Numeric |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `NUMERO_TELEFONO`        | **0-NRO_TELEFONO**     | dlpx-core:Phone Unique     |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `PAIS`                   | **0-PAIS**             | 0-Pais-SL                  |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `PROVINCIA`              | **0-PROVINCIA**        | 0-Provincia-SL             |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `TARJETA_CVV`            | **0-CODIGO_SEGURIDAD** | NullValueLookup            |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `WEB_URL`                | **0-WEB_URL**          | dlpx-core:CM Alpha-Numeric |

### 9.2. Database Tables and Logical Keys

| Rule Set   | Table                       | Logical Key |
| :--------- | :-------------------------- | :---------- |
| **SQLSRV** | **FAILED_SENSITIVE_DATA**   | `-`         |
| **SQLSRV** | **FAILED_TRANSACTION_DATA** | `-`         |
| **SQLSRV** | **REJECTED_SENSITIVE_DATA** | `-`         |

---

## 10. Profiling and Masking Job Definitions (Jobs)

### 10.1. Profiling Jobs (Profiling / Discovery Jobs)

Definition of profiling jobs (Discovery), Rule Set association, Profile Set, and execution attributes:

| Job Name | Type | Rule Set | Profile Set (Discovery Policy) | Connector / Platform | Execution Type | Engine | Environment / Application |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **SQLSRV-PRF** | DISCOVERY | **SQLSRV** | **ASDD Spanish** | MSSQL | STANDARD | DPXMSK | SQLSRV / SQLSRV |

### 10.2. Masking Jobs

Definition of masking jobs, Rule Set association, and masking attributes:

| Job Name | Type | Rule Set | On-The-Fly | Truncate Tables | Drop Indexes | Connector / Platform | Execution Type | Engine | Environment / Application |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **SQLSRV-MSK** | MASKING | **SQLSRV** | `false` | `false` | `false` | MSSQL | STANDARD | DPXMSK | SQLSRV / SQLSRV |

---

## 11. Key Configuration Criteria for Rule Sets (_In-Place Masking_)

As a general architecture guideline for future **_In-Place Masking_** implementations, record identification within a _Rule Set_ must adhere to the following directives:

**1. Use of Logical Keys:**
Whenever a column (or set of columns) exists that guarantees uniqueness, non-null values, and whose columns **are not subject to masking**, it must be explicitly defined as a _Logical Key_ in the _Rule Set_. This enables the tool to execute direct, optimized update statements (`UPDATE`) using existing database engine indexes.

**2. Temporary Identity Column Mechanism:**
When a table lacks a unique key with these characteristics, or when the existing primary/unique key consists of fields that require masking, **no _Logical Key_ should be defined in the _Rule Set_**. In these scenarios, Delphix automatically creates a temporary identity column (`MASK_ROW_ID`) in the target table to manage batch masking pointers, automatically dropping it upon job completion.

### Decision Summary (Reference Matrix)

| **Table Scenario** | **Rule Set Action** | **Update Mechanism** |
| :--- | :--- | :--- |
| Has non-null PK/UQ and its fields are **not** masked | Define explicit **Logical Key** | Lookup via existing index |
| Lacks PK/UQ, or existing key **is masked** | **Do not define** Logical Key | Temporary identity column (`MASK_ROW_ID`) |

