# {{ client }} - Reporte Configuracion Delphix Continuous Compliance

---

## 1. Resumen Ejecutivo

Para la implementación de Delphix Continuous Compliance en Version **{{ detected_version }}**, **{{ client }}** ha seleccionado la base de datos <**Nombre base de datos**> en <**Nombre Fabricante BD**> como caso piloto de enmascaramiento de datos sensibles.

El objetivo principal de este informe es consolidar la parametrización aplicada en el entorno del cliente, incluyendo los algoritmos de enmascaramiento, dominios de datos, clasificadores de perfilado, reglas de enmascaramiento, conectores y trabajos de ejecución.

---

## 2. Infraestructura y Servicios de Motores Delphix Continuous Compliance

### 2.1. Motores Delphix Continuous Compliance Registrados (Masking Engines)

Tabla resumen de los motores de enmascaramiento (Continuous Compliance) registrados en Delphix DCT, su versión, dirección IP/hostname, estado de conexión y recursos asignados:

{% if engines %}
| Nombre Motor | Tipo | Versión | Estado Conexión | Cores CPU | Memoria RAM | Almacenamiento Total |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | {{ engine.type }} | `{{ engine.version }}` | {{ engine.status }} | {{ engine.cpu }} | {{ engine.memory }} | {{ engine.storage }} |
{% endfor %}
{% else %}
_No se registraron motores de Masking en la instancia actual._
{% endif %}

| Nombre Motor | Parámetro de Red | Valor Configurado |
| :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | **Dirección IP / Hostname** | `{{ engine.hostname }}` |
| **{{ engine.name }}** | **Gateway / Puerta de Enlace** | <**Gateway**> |
| **{{ engine.name }}** | **Servidores DNS** | <**Servidores DNS**> |
| **{{ engine.name }}** | **Servidores NTP** | <**Servidores NTP**> |
{% endfor %}

### 2.2. Configuración de Servicios de Infraestructura (SMTP y Autenticación LDAP / Active Directory)

#### 2.2.1. Configuración del Servidor de Correo (SMTP)

Tabla resumen de la configuración del servidor SMTP para notificaciones de eventos y alertas:

| Parámetro SMTP | Valor Configurado |
| :--- | :--- |
| **Servidor SMTP (Host)** | `{{ smtp.host }}` |
| **Puerto** | `{{ smtp.port }}` |
| **Estado Habilitado (Enabled)** | `{{ smtp.enabled }}` |
| **Autenticación Habilitada (Auth)** | `{{ smtp.authentication }}` |
| **Cifrado TLS** | `{{ smtp.tls }}` |
| **Dirección Remitente (From)** | `{{ smtp.from }}` |

#### 2.2.2. Configuración de Autenticación LDAP / Controlador de Dominio (Active Directory)

Tabla resumen de la integración con LDAP / Active Directory para autenticación de usuarios:

| Parámetro LDAP / Active Directory | Valor Configurado |
| :--- | :--- |
| **Integración LDAP Habilitada** | `{{ ldap.enabled }}` |
| **Servidor Host LDAP / Controlador de Dominio** | `{{ ldap.host }}` |
| **Puerto** | `{{ ldap.port }}` |
| **Dominios Registrados** | {{ ldap.domains }} |
| **Auto-creación de Usuarios** | `{{ ldap.auto_create_users }}` |
| **Conexión Segura (SSL)** | `{{ ldap.ssl }}` |

---

## 3. Algoritmos de Consulta de Archivo TXT (`Secure Lookup` / `Name`)

Tabla resumen de los algoritmos sencillos basados en archivos de texto de valores de reemplazo:

{% if simple_algorithms %}
| Algoritmo | Framework | Archivo TXT Utilizado | Motor / Engine | Descripción |
| :--- | :--- | :--- | :--- | :--- |
{% for algorithm in simple_algorithms %}
| **{{ algorithm.name }}** | {{ algorithm.framework }} | `{{ algorithm.lookup_file }}` | {{ algorithm.engine }} | {{ algorithm.description }} |
{% endfor %}
{% else %}
_No se encontraron algoritmos simples con el prefijo indicado._
{% endif %}

---

## 3. Algoritmos Compuestos (`FullName`)

Tabla detallada del algoritmo compuesto `FullName` y los algoritmos sencillos que lo integran:

{% if composite_algorithms %}
| Algoritmo Compuesto | Framework | Componente Nombres (First Name) | Archivo TXT Nombres | Componente Apellidos (Last Name) | Archivo TXT Apellidos | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for algorithm in composite_algorithms %}
| **{{ algorithm.name }}** | FullName | **{{ algorithm.first_name }}** | `{{ algorithm.first_file }}` | **{{ algorithm.last_name }}** | `{{ algorithm.last_file }}` | {{ algorithm.description }} |
{% endfor %}
{% else %}
_No se encontraron algoritmos compuestos con el prefijo indicado._
{% endif %}

---

## 4. Dominios (Data Classes) y su Relación con Algoritmos

Tabla de relación entre los dominios (Data Classes) definidos y su algoritmo de enmascaramiento asignado:

{% if data_classes %}
| Dominio (Data Class) | Algoritmo Asignado | Motor / Engine |
| :--- | :--- | :--- |
{% for item in data_classes %}
| **{{ item.name }}** | {{ item.algorithm }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No se encontraron dominios con el prefijo indicado._
{% endif %}

---

## 5. Clasificadores de Profiling (Classifiers)

Desglose de clasificadores utilizados en las reglas de perfilado (Profiling), categorizados por tipo de Framework:

### 5.1. Clasificadores de Nombre de Columna y Expresión Regular (PATH / REGEX)

{% if classifiers_path_regex %}
| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Expresión Regular (Regex) | Motor / Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_path_regex %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No se encontraron clasificadores PATH / REGEX con el prefijo indicado._
{% endif %}

### 5.2. Clasificadores de Lista de Valores (LIST)

{% if classifiers_list %}
| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Nombre de Archivo TXT | Motor / Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_list %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No se encontraron clasificadores LIST con el prefijo indicado._
{% endif %}

### 5.3. Clasificadores de Tipo de Datos (DATA_TYPE)

{% if classifiers_data_type %}
| Clasificador (Classifier) | Framework | Dominio Asociado (Data Class) | Peso Relativo | Tipos de Datos Permitidos | Motor / Engine |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_data_type %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No se encontraron clasificadores DATA_TYPE con el prefijo indicado._
{% endif %}

---

## 6. Profile Sets (Discovery Policies) y Clasificadores Asignados

Relación entre el Profile Set de perfilado y la lista completa de clasificadores que lo componen:

{% if profile_sets %}
| Profile Set (Discovery Policy) | Lista de Clasificadores (Classifiers) |
| :--- | :--- |
{% for item in profile_sets %}
| **{{ item.name }}** | {{ item.classifiers ?? "-" }} |
{% endfor %}
{% else %}
_No se encontraron Profile Sets con clasificadores del prefijo indicado._
{% endif %}

---

## 7. Conexiones de Datos (Connectors) y Parámetros JDBC

### 7.1. Conexiones de Datos Definidas

Tabla resumen de las conexiones de datos (Connectors), incluyendo servidor, base de datos, esquema y usuario:

{% if connectors %}
| Conexión (Connector) | Servidor / Host | Base de Datos | Esquema | Usuario | Tipo / Plataforma | Motor / Engine |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in connectors %}
| **{{ item.name }}** | {{ item.host }} | {{ item.database }} | {{ item.schema }} | {{ item.user }} | {{ item.platform }} | {{ item.engine }} |
{% endfor %}
{% else %}
_No se encontraron conexiones de datos en la instancia actual._
{% endif %}

### 7.2. Parámetros de Driver JDBC Configurados

Tabla de parámetros del driver JDBC recuperados con valor configurado:

{% if jdbc_properties %}
| Conexión (Connector) | Parámetro Driver JDBC | Valor Configurado |
| :--- | :--- | :--- |
{% for item in jdbc_properties %}
| **{{ item.connector }}** | `{{ item.name }}` | `{{ item.value }}` |
{% endfor %}
{% else %}
_No se encontraron parámetros de driver JDBC para las conexiones actuales._
{% endif %}

---

## 8. Rule Sets, Tablas y Asignación de Algoritmos / Dominios

Relación de los Rule Sets definidos, sus tablas correspondientes, los elementos/columnas con algoritmos y dominios asignados, y sus llaves lógicas (Logical Keys):

{% if rule_columns %}
### 8.1. Rule Sets, Tablas y Asignación de Algoritmos / Dominios

| Rule Set | Tabla (Table) | Columna (Column) | Dominio (Data Class) | Algoritmo Asignado |
| :--- | :--- | :--- | :--- | :--- |
{% for item in rule_columns %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.column }}` | **{{ item.data_class }}** | {{ item.algorithm }} |
{% endfor %}
{% endif %}

{% if rule_tables %}
### 8.2. Tablas de Base de Datos y Llaves Lógicas (Logical Keys)

| Rule Set | Tabla (Table) | Llave Lógica (Logical Key) |
| :--- | :--- | :--- |
{% for item in rule_tables %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.logical_key }}` |
{% endfor %}
{% endif %}
{% if not rule_columns and not rule_tables %}
_No se encontraron Rule Sets._
{% endif %}


---

## 10. Definición de Trabajos de Perfilado y Enmascaramiento (Jobs)

{% if profiling_jobs %}
### 10.1. Trabajos de Perfilado (Profiling / Discovery Jobs)

Definición de los trabajos de perfilado (Discovery), asociación de Rule Set, Profile Set y atributos de ejecución:

| Trabajo (Job Name) | Tipo | Rule Set | Profile Set (Discovery Policy) | Conector / Plataforma | Tipo Ejecución | Motor / Engine | Ambiente / Aplicación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in profiling_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | **{{ item.profile_set }}** | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

{% if masking_jobs %}
### 10.2. Trabajos de Enmascaramiento (Masking Jobs)

Definición de los trabajos de enmascaramiento (Masking), asociación de Rule Set y atributos de enmascaramiento:

| Trabajo (Job Name) | Tipo | Rule Set | On-The-Fly | Truncar Tablas | Eliminar Índices | Conector / Plataforma | Tipo Ejecución | Motor / Engine | Ambiente / Aplicación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in masking_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | `{{ item.on_the_fly }}` | `{{ item.truncate }}` | `{{ item.drop_indexes }}` | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

---

## 11. Criterios de Configuración de Claves para el Rule Set (_In-Place Masking_)

Como criterio general de arquitectura para futuras implementaciones de **_In-Place Masking_**, la definición de la identificación de registros dentro del _Rule Set_ debe cumplir con las siguientes directrices:

**1. Uso de Clave Lógica (_Logical Key_):**
Siempre que exista una columna (o conjunto de columnas) que garantice unicidad, valor no nulo y cuyas columnas **no sean objeto de enmascaramiento**, debe definirse explícitamente como _Logical Key_ en el _Rule Set_. Esto permite a la herramienta ejecutar las sentencias de actualización (`UPDATE`) de forma directa y optimizada mediante los índices existentes en el motor de base de datos.

**2. Mecanismo por Columna Temporal (_Identity Column_):**
Cuando la tabla no disponga de una clave única con dichas características, o cuando la clave primaria/única existente esté compuesta por campos que requieran ser enmascarados, **no debe definirse ninguna _Logical Key_ en el _Rule Set_**. En estos escenarios, Delphix creará de forma automática una columna identidad temporal (`MASK_ROW_ID`) en la tabla destino para gestionar el puntero de enmascaramiento por lote, eliminándola automáticamente al concluir el _Job_.

### Resumen de Decisión (Matriz de Referencia)

| **Escenario de la Tabla** | **Acción en el Rule Set** | **Mecanismo de Update** |
| :--- | :--- | :--- |
| Tiene PK/UQ no nula y sus campos **no** se enmascaran | Definir **Logical Key** explícita | Búsqueda por índice existente |
| No tiene PK/UQ, o la clave existente **se enmascara** | **No definir** Logical Key | Columna identidad temporal (`MASK_ROW_ID`) |
