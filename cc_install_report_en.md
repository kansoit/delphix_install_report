# {{ client }} - Delphix Continuous Compliance Configuration Report

---

## 1. Executive Summary

For the implementation of Delphix Continuous Compliance version **{{ detected_version }}**, **{{ client }}** has selected the database <**Database Name**> on <**Database Vendor Name**> as the pilot case for sensitive-data masking.

The main purpose of this report is to consolidate the configuration applied in the customer environment, including masking algorithms, data classes, profiling classifiers, masking rules, connectors, and execution jobs.

---

## 2. Delphix Continuous Compliance Engines and Services

### 2.1. Registered Delphix Continuous Compliance Engines (Masking Engines)

Summary of the masking engines registered in Delphix DCT, including version, IP address/hostname, connection status, and allocated resources:

{% if engines %}
| Engine Name | Type | Version | Connection Status | CPU Cores | RAM | Total Storage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | {{ engine.type }} | `{{ engine.version }}` | {{ engine.status }} | {{ engine.cpu }} | {{ engine.memory }} | {{ engine.storage }} |
{% endfor %}
{% else %}
_No Masking engines were registered in the current instance._
{% endif %}

| Engine Name | Network Parameter | Configured Value |
| :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | **IP Address / Hostname** | `{{ engine.hostname }}` |
| **{{ engine.name }}** | **Gateway** | <**Gateway**> |
| **{{ engine.name }}** | **DNS Servers** | <**DNS Servers**> |
| **{{ engine.name }}** | **NTP Servers** | <**NTP Servers**> |
{% endfor %}

### 2.2. Infrastructure Services Configuration (SMTP and LDAP / Active Directory Authentication)

#### 2.2.1. SMTP Server Configuration

Summary of the SMTP server configuration used for event notifications and alerts:

| SMTP Parameter | Configured Value |
| :--- | :--- |
| **SMTP Server (Host)** | `{{ smtp.host }}` |
| **Port** | `{{ smtp.port }}` |
| **Enabled** | `{{ smtp.enabled }}` |
| **Authentication Enabled** | `{{ smtp.authentication }}` |
| **TLS Encryption** | `{{ smtp.tls }}` |
| **Sender Address (From)** | `{{ smtp.from }}` |

#### 2.2.2. LDAP / Active Directory Authentication Configuration

Summary of the LDAP / Active Directory integration used for user authentication:

| LDAP / Active Directory Parameter | Configured Value |
| :--- | :--- |
| **LDAP Integration Enabled** | `{{ ldap.enabled }}` |
| **LDAP Host / Domain Controller** | `{{ ldap.host }}` |
| **Port** | `{{ ldap.port }}` |
| **Registered Domains** | {{ ldap.domains }} |
| **Automatic User Creation** | `{{ ldap.auto_create_users }}` |
| **Secure Connection (SSL)** | `{{ ldap.ssl }}` |

---

## 3. TXT File Lookup Algorithms (`Secure Lookup` / `Name`)

Summary of the simple algorithms based on replacement-value text files:

{% if simple_algorithms %}
| Algorithm | Framework | TXT File | Engine | Description |
| :--- | :--- | :--- | :--- | :--- |
{% for algorithm in simple_algorithms %}
| **{{ algorithm.name }}** | {{ algorithm.framework }} | `{{ algorithm.lookup_file }}` | {{ algorithm.engine }} | {{ algorithm.description }} |
{% endfor %}
{% else %}
_No simple algorithms were found with the specified prefix._
{% endif %}

---

## 3. Composite Algorithms (`FullName`)

Detailed view of the `FullName` composite algorithm and its constituent simple algorithms:

{% if composite_algorithms %}
| Composite Algorithm | Framework | First Name Component | First Name TXT File | Last Name Component | Last Name TXT File | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for algorithm in composite_algorithms %}
| **{{ algorithm.name }}** | FullName | **{{ algorithm.first_name }}** | `{{ algorithm.first_file }}` | **{{ algorithm.last_name }}** | `{{ algorithm.last_file }}` | {{ algorithm.description }} |
{% endfor %}
{% else %}
_No composite algorithms were found with the specified prefix._
{% endif %}

---

## 4. Data Classes and Their Algorithm Assignment

Relationship between the defined Data Classes and their assigned masking algorithms:

{% if data_classes %}
| Data Class | Assigned Algorithm | Engine |
| :--- | :--- | :--- |
{% for item in data_classes %}
| **{{ item.name }}** | {{ item.algorithm }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No Data Classes were found with the specified prefix._
{% endif %}

---

## 5. Profiling Classifiers

Breakdown of the classifiers used by profiling rules, grouped by framework type:

### 5.1. Column Name and Regular Expression Classifiers (PATH / REGEX)

{% if classifiers_path_regex %}
| Classifier | Framework | Associated Data Class | Relative Weight | Regular Expression | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_path_regex %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No PATH / REGEX classifiers were found with the specified prefix._
{% endif %}

### 5.2. Value List Classifiers (LIST)

{% if classifiers_list %}
| Classifier | Framework | Associated Data Class | Relative Weight | TXT Filename | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_list %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No LIST classifiers were found with the specified prefix._
{% endif %}

### 5.3. Data Type Classifiers (DATA_TYPE)

{% if classifiers_data_type %}
| Classifier | Framework | Associated Data Class | Relative Weight | Allowed Data Types | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_data_type %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No DATA_TYPE classifiers were found with the specified prefix._
{% endif %}

---

## 6. Profile Sets (Discovery Policies) and Assigned Classifiers

Relationship between each profiling Profile Set and its complete list of classifiers:

{% if profile_sets %}
| Profile Set (Discovery Policy) | Classifier List |
| :--- | :--- |
{% for item in profile_sets %}
| **{{ item.name }}** | {{ item.classifiers ?? "-" }} |
{% endfor %}
{% else %}
_No Profile Sets containing classifiers with the specified prefix were found._
{% endif %}

---

## 7. Data Connections (Connectors) and JDBC Parameters

### 7.1. Defined Data Connections

Summary of the data connections, including server, database, schema, and user:

{% if connectors %}
| Connector | Server / Host | Database | Schema | User | Type / Platform | Engine |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in connectors %}
| **{{ item.name }}** | {{ item.host }} | {{ item.database }} | {{ item.schema }} | {{ item.user }} | {{ item.platform }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No data connections were found in the current instance._
{% endif %}

### 7.2. Configured JDBC Driver Parameters

JDBC driver parameters retrieved with configured values:

{% if jdbc_properties %}
| Connector | JDBC Driver Parameter | Configured Value |
| :--- | :--- | :--- |
{% for item in jdbc_properties %}
| **{{ item.connector }}** | `{{ item.name }}` | `{{ item.value }}` |
{% endfor %}
{% else %}
_No JDBC driver parameters were found for the current connections._
{% endif %}

---

## 8. Rule Sets, Tables, and Algorithm / Data Class Assignment

Relationship between the defined Rule Sets, their tables, assigned algorithms and Data Classes, and their Logical Keys:

{% if rule_columns %}
### 8.1. Rule Sets, Tables, and Algorithm / Data Class Assignment

| Rule Set | Table | Column | Data Class | Assigned Algorithm |
| :--- | :--- | :--- | :--- | :--- |
{% for item in rule_columns %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.column }}` | **{{ item.data_class }}** | {{ item.algorithm }} |
{% endfor %}
{% endif %}

{% if rule_tables %}
### 8.2. Database Tables and Logical Keys

| Rule Set | Table | Logical Key |
| :--- | :--- | :--- |
{% for item in rule_tables %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.logical_key }}` |
{% endfor %}
{% endif %}
{% if not rule_columns and not rule_tables %}
_No Rule Sets were found._
{% endif %}


---

## 10. Profiling and Masking Jobs

{% if profiling_jobs %}
### 10.1. Profiling Jobs (Profiling / Discovery Jobs)

Definition of the profiling jobs, including Rule Set, Profile Set, and execution attributes:

| Job Name | Type | Rule Set | Profile Set (Discovery Policy) | Connector / Platform | Execution Type | Engine | Environment / Application |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in profiling_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | **{{ item.profile_set }}** | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

{% if masking_jobs %}
### 10.2. Masking Jobs

Definition of the masking jobs, including Rule Set and masking attributes:

| Job Name | Type | Rule Set | On-The-Fly | Truncate Tables | Drop Indexes | Connector / Platform | Execution Type | Engine | Environment / Application |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in masking_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | `{{ item.on_the_fly }}` | `{{ item.truncate }}` | `{{ item.drop_indexes }}` | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

---

## 11. Logical Key Configuration Criteria for the Rule Set (_In-Place Masking_)

As a general architectural criterion for future **_In-Place Masking_** implementations, record identification within the _Rule Set_ should follow these guidelines:

**1. Use of a Logical Key:**
Whenever a column or column set guarantees uniqueness, is not nullable, and is **not** subject to masking, it should be explicitly defined as a _Logical Key_ in the _Rule Set_. This allows the tool to execute `UPDATE` statements directly and efficiently using existing database indexes.

**2. Temporary Identity Column Mechanism:**
When the table has no suitable unique key, or when the existing primary/unique key contains fields that must be masked, **no _Logical Key_ should be defined in the _Rule Set_**. In these scenarios, Delphix automatically creates a temporary identity column (`MASK_ROW_ID`) in the target table to manage batch masking, and removes it when the _Job_ finishes.

### Decision Summary

| **Table Scenario** | **Rule Set Action** | **Update Mechanism** |
| :--- | :--- | :--- |
| Has a non-null PK/UQ whose fields are **not** masked | Define an explicit **Logical Key** | Lookup using the existing index |
| Has no suitable PK/UQ, or the existing key **is** masked | **Do not define** a Logical Key | Temporary identity column (`MASK_ROW_ID`) |
