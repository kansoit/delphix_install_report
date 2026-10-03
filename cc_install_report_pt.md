# {{ client }} - Relatório de Configuração do Delphix Continuous Compliance

---

## 1. Resumo Executivo

Para a implementação do Delphix Continuous Compliance versão **{{ detected_version }}**, **{{ client }}** selecionou o banco de dados <**Nome do banco de dados**> no <**Nome do fabricante do banco de dados**> como caso piloto de mascaramento de dados sensíveis.

O objetivo principal deste relatório é consolidar a configuração aplicada no ambiente do cliente, incluindo algoritmos de mascaramento, classes de dados, classificadores de profiling, regras de mascaramento, conectores e jobs de execução.

---

## 2. Motores e Serviços do Delphix Continuous Compliance

### 2.1. Motores Delphix Continuous Compliance Registrados (Masking Engines)

Resumo dos motores de mascaramento registrados no Delphix DCT, incluindo versão, endereço IP/hostname, status da conexão e recursos alocados:

{% if engines %}
| Nome do Motor | Tipo | Versão | Status da Conexão | Cores de CPU | RAM | Armazenamento Total |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | {{ engine.type }} | `{{ engine.version }}` | {{ engine.status }} | {{ engine.cpu }} | {{ engine.memory }} | {{ engine.storage }} |
{% endfor %}
{% else %}
_Nenhum motor de Masking foi registrado na instância atual._
{% endif %}

| Nome do Motor | Parâmetro de Rede | Valor Configurado |
| :--- | :--- | :--- |
{% for engine in engines %}
| **{{ engine.name }}** | **Endereço IP / Hostname** | `{{ engine.hostname }}` |
| **{{ engine.name }}** | **Gateway** | <**Gateway**> |
| **{{ engine.name }}** | **Servidores DNS** | <**Servidores DNS**> |
| **{{ engine.name }}** | **Servidores NTP** | <**Servidores NTP**> |
{% endfor %}

### 2.2. Configuração dos Serviços de Infraestrutura (SMTP e Autenticação LDAP / Active Directory)

#### 2.2.1. Configuração do Servidor SMTP

Resumo da configuração do servidor SMTP utilizada para notificações de eventos e alertas:

| Parâmetro SMTP | Valor Configurado |
| :--- | :--- |
| **Servidor SMTP (Host)** | `{{ smtp.host }}` |
| **Porta** | `{{ smtp.port }}` |
| **Habilitado** | `{{ smtp.enabled }}` |
| **Autenticação Habilitada** | `{{ smtp.authentication }}` |
| **Criptografia TLS** | `{{ smtp.tls }}` |
| **Endereço do Remetente (From)** | `{{ smtp.from }}` |

#### 2.2.2. Configuração de Autenticação LDAP / Active Directory

Resumo da integração LDAP / Active Directory utilizada para autenticação de usuários:

| Parâmetro LDAP / Active Directory | Valor Configurado |
| :--- | :--- |
| **Integração LDAP Habilitada** | `{{ ldap.enabled }}` |
| **Host LDAP / Controlador de Domínio** | `{{ ldap.host }}` |
| **Porta** | `{{ ldap.port }}` |
| **Domínios Registrados** | {{ ldap.domains }} |
| **Criação Automática de Usuários** | `{{ ldap.auto_create_users }}` |
| **Conexão Segura (SSL)** | `{{ ldap.ssl }}` |

---

## 3. Algoritmos de Consulta de Arquivo TXT (`Secure Lookup` / `Name`)

Resumo dos algoritmos simples baseados em arquivos de texto com valores de substituição:

{% if simple_algorithms %}
| Algoritmo | Framework | Arquivo TXT | Motor | Descrição |
| :--- | :--- | :--- | :--- | :--- |
{% for algorithm in simple_algorithms %}
| **{{ algorithm.name }}** | {{ algorithm.framework }} | `{{ algorithm.lookup_file }}` | {{ algorithm.engine }} | {{ algorithm.description }} |
{% endfor %}
{% else %}
_Nenhum algoritmo simples foi encontrado com o prefixo especificado._
{% endif %}

---

## 3. Algoritmos Compostos (`FullName`)

Detalhamento do algoritmo composto `FullName` e dos algoritmos simples que o compõem:

{% if composite_algorithms %}
| Algoritmo Composto | Framework | Componente Nome | Arquivo TXT do Nome | Componente Sobrenome | Arquivo TXT do Sobrenome | Descrição |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for algorithm in composite_algorithms %}
| **{{ algorithm.name }}** | FullName | **{{ algorithm.first_name }}** | `{{ algorithm.first_file }}` | **{{ algorithm.last_name }}** | `{{ algorithm.last_file }}` | {{ algorithm.description }} |
{% endfor %}
{% else %}
_Nenhum algoritmo composto foi encontrado com o prefixo especificado._
{% endif %}

---

## 4. Classes de Dados e Associação de Algoritmos

Relação entre as Classes de Dados definidas e seus algoritmos de mascaramento atribuídos:

{% if data_classes %}
| Classe de Dados | Algoritmo Atribuído | Motor |
| :--- | :--- | :--- |
{% for item in data_classes %}
| **{{ item.name }}** | {{ item.algorithm }} | {{ item.engine }} |
{% endfor %}
{% else %}
_Nenhuma Classe de Dados foi encontrada com o prefixo especificado._
{% endif %}

---

## 5. Classificadores de Profiling

Detalhamento dos classificadores utilizados pelas regras de profiling, agrupados por tipo de framework:

### 5.1. Classificadores de Nome de Coluna e Expressão Regular (PATH / REGEX)

{% if classifiers_path_regex %}
| Classificador | Framework | Classe de Dados Associada | Peso Relativo | Expressão Regular | Motor |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_path_regex %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_Nenhum classificador PATH / REGEX foi encontrado com o prefixo especificado._
{% endif %}

### 5.2. Classificadores de Lista de Valores (LIST)

{% if classifiers_list %}
| Classificador | Framework | Classe de Dados Associada | Peso Relativo | Nome do Arquivo TXT | Motor |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_list %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_Nenhum classificador LIST foi encontrado com o prefixo especificado._
{% endif %}

### 5.3. Classificadores de Tipo de Dados (DATA_TYPE)

{% if classifiers_data_type %}
| Classificador | Framework | Classe de Dados Associada | Peso Relativo | Tipos de Dados Permitidos | Motor |
| :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in classifiers_data_type %}
| **{{ item.name }}** | {{ item.framework }} | **{{ item.data_class }}** | {{ item.weight }} | {{ item.values }} | {{ item.engine }} |
{% endfor %}
{% else %}
_Nenhum classificador DATA_TYPE foi encontrado com o prefixo especificado._
{% endif %}

---

## 6. Profile Sets (Discovery Policies) e Classificadores Atribuídos

Relação entre cada Profile Set de profiling e sua lista completa de classificadores:

{% if profile_sets %}
| Profile Set (Discovery Policy) | Lista de Classificadores |
| :--- | :--- |
{% for item in profile_sets %}
| **{{ item.name }}** | {{ item.classifiers ?? "-" }} |
{% endfor %}
{% else %}
_Nenhum Profile Set com classificadores do prefixo especificado foi encontrado._
{% endif %}

---

## 7. Conexões de Dados (Connectors) e Parâmetros JDBC

### 7.1. Conexões de Dados Definidas

Resumo das conexões de dados, incluindo servidor, banco de dados, schema e usuário:

{% if connectors %}
| Conexão | Servidor / Host | Banco de Dados | Schema | Usuário | Tipo / Plataforma | Motor |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in connectors %}
| **{{ item.name }}** | {{ item.host }} | {{ item.database }} | {{ item.schema }} | {{ item.user }} | {{ item.platform }} | {{ item.engine }} |
{% endfor %}
{% else %}
_Nenhuma conexão de dados foi encontrada na instância atual._
{% endif %}

### 7.2. Parâmetros do Driver JDBC Configurados

Parâmetros do driver JDBC recuperados com valores configurados:

{% if jdbc_properties %}
| Conexão | Parâmetro do Driver JDBC | Valor Configurado |
| :--- | :--- | :--- |
{% for item in jdbc_properties %}
| **{{ item.connector }}** | `{{ item.name }}` | `{{ item.value }}` |
{% endfor %}
{% else %}
_Nenhum parâmetro de driver JDBC foi encontrado para as conexões atuais._
{% endif %}

---

## 8. Rule Sets, Tabelas e Associação de Algoritmos / Classes de Dados

Relação entre os Rule Sets definidos, suas tabelas, algoritmos e Classes de Dados atribuídos, e suas Logical Keys:

{% if rule_columns %}
### 8.1. Rule Sets, Tabelas e Associação de Algoritmos / Classes de Dados

| Rule Set | Tabela | Coluna | Classe de Dados | Algoritmo Atribuído |
| :--- | :--- | :--- | :--- | :--- |
{% for item in rule_columns %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.column }}` | **{{ item.data_class }}** | {{ item.algorithm }} |
{% endfor %}
{% endif %}

{% if rule_tables %}
### 8.2. Tabelas de Banco de Dados e Logical Keys

| Rule Set | Tabela | Logical Key |
| :--- | :--- | :--- |
{% for item in rule_tables %}
| **{{ item.rule_set }}** | **{{ item.table }}** | `{{ item.logical_key }}` |
{% endfor %}
{% endif %}
{% if not rule_columns and not rule_tables %}
_Nenhum Rule Set foi encontrado._
{% endif %}


---

## 10. Jobs de Profiling e Masking

{% if profiling_jobs %}
### 10.1. Jobs de Profiling (Profiling / Discovery Jobs)

Definição dos jobs de profiling, incluindo Rule Set, Profile Set e atributos de execução:

| Nome do Job | Tipo | Rule Set | Profile Set (Discovery Policy) | Connector / Plataforma | Tipo de Execução | Motor | Ambiente / Aplicação |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in profiling_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | **{{ item.profile_set }}** | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

{% if masking_jobs %}
### 10.2. Jobs de Masking

Definição dos jobs de masking, incluindo Rule Set e atributos de mascaramento:

| Nome do Job | Tipo | Rule Set | On-The-Fly | Truncar Tabelas | Excluir Índices | Connector / Plataforma | Tipo de Execução | Motor | Ambiente / Aplicação |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{% for item in masking_jobs %}
| **{{ item.name }}** | {{ item.type }} | **{{ item.rule_set }}** | `{{ item.on_the_fly }}` | `{{ item.truncate }}` | `{{ item.drop_indexes }}` | {{ item.connector }} | {{ item.execution }} | {{ item.engine }} | {{ item.environment }} / {{ item.application }} |
{% endfor %}
{% endif %}

---

## 11. Critérios de Configuração de Logical Keys para o Rule Set (_In-Place Masking_)

Como critério geral de arquitetura para futuras implementações de **_In-Place Masking_**, a identificação de registros dentro do _Rule Set_ deve seguir estas diretrizes:

**1. Uso de uma Logical Key:**
Sempre que uma coluna ou conjunto de colunas garantir unicidade, não for nulo e **não** estiver sujeito a mascaramento, deverá ser definido explicitamente como _Logical Key_ no _Rule Set_. Isso permite executar instruções `UPDATE` de forma direta e eficiente usando os índices existentes no banco de dados.

**2. Mecanismo de Coluna de Identidade Temporária:**
Quando a tabela não possuir uma chave única adequada, ou quando a chave primária/única existente contiver campos que precisam ser mascarados, **nenhuma _Logical Key_ deverá ser definida no _Rule Set_**. Nesses cenários, o Delphix criará automaticamente uma coluna de identidade temporária (`MASK_ROW_ID`) na tabela de destino para gerenciar o mascaramento em lote e a removerá ao concluir o _Job_.

### Resumo da Decisão

| **Cenário da Tabela** | **Ação no Rule Set** | **Mecanismo de Update** |
| :--- | :--- | :--- |
| Possui PK/UQ não nula cujos campos **não** são mascarados | Definir uma **Logical Key** explícita | Busca usando o índice existente |
| Não possui PK/UQ adequada, ou a chave existente **é** mascarada | **Não definir** uma Logical Key | Coluna de identidade temporária (`MASK_ROW_ID`) |
