Vou te devolver um **modelo default** para normalizar qualquer fonte (relatório PDF, planilha de imobiliária, portal, etc.) em algo único.

Vou estruturar em dois níveis:

1. **Modelo relacional padrão (Postgres / NocoDB / BigQuery)**
2. **JSON padrão por imóvel**, para usar como “camada de staging” antes de gravar nas tabelas.

---

## 1. Modelo relacional padrão (SQL)

Pensado para: multi-family office, consolidação multi-carteira, multi-fonte.

### 1.1. Dimensão Família / Cliente

```sql
create table dim_familia (
    id_familia           uuid primary key,
    cod_familia          text not null,             -- ex: BNI_GESTAO_IMOBILIARIA
    nome_familia         text not null,
    cliente_raiz         text,                      -- se tiver holding / estrutura
    gestor_principal     text,                      -- multi-family office responsável
    created_at           timestamptz default now()
);
```

---

### 1.2. Dimensão Imóvel (core de tudo)

```sql
create table dim_imovel (
    id_imovel                uuid primary key,
    id_familia               uuid not null references dim_familia(id_familia),

    -- Identificação
    codigo_interno           text,                  -- código no seu sistema
    nome_imovel              text not null,         -- ex: "APTO 802 EDF.EMILIO BUMACHAR"
    tipo_ativo               text not null,         -- CASA, APARTAMENTO, TERRENO, GALPAO, LOJA, SALA...
    classificacao_setor      text,                  -- RESIDENCIAL, COMERCIAL, RURAL, INDUSTRIAL
    finalidade_principal     text,                  -- LOCACAO, VENDA, USO_PROPRIO, DESENVOLVIMENTO, VALORIZACAO

    -- Localização
    pais                     text default 'BR',
    uf                       char(2),
    cidade                   text,
    bairro                   text,
    logradouro               text,
    numero                   text,
    complemento              text,
    cep                      text,
    latitude                 numeric(10,7),
    longitude                numeric(10,7),

    -- Estrutura física / participação
    data_aquisicao           date,
    participacao_percent     numeric(5,2) default 100.00,  -- Part. % do relatório
    area_total_m2            numeric(14,2),
    area_privativa_m2        numeric(14,2),

    -- Status físico/jurídico
    status_obras             text,                  -- CONCLUIDO, EM_ANDAMENTO, PARADO
    situacao_ocupacao_atual  text,                  -- LOCADO, VAGO, PROPRIO, EM_OBRAS
    status_ativo             text default 'ATIVO',  -- ATIVO, DESINVESTIDO, EM_DUE_DILIGENCE...

    observacoes              text
);
```

---

### 1.3. Estratégia / Finalidade do imóvel (VENDA, LOCACAO, VALORIZACAO, DESENVOLVIMENTO)

Mapeia seções tipo: *Imóveis para Venda / Valorização / Desenvolvimento / Locação*.

```sql
create table rel_imovel_estrategia (
    id_imovel        uuid not null references dim_imovel(id_imovel),
    dt_inicio        date not null,
    dt_fim           date,
    tipo_estrategia  text not null,    -- VENDA, LOCACAO, VALORIZACAO, DESENVOLVIMENTO, USO_PROPRIO

    primary key (id_imovel, dt_inicio, tipo_estrategia)
);
```

---

### 1.4. Valuation (aquisição, mercado, aluguel de mercado, etc.)

Suporta:

* Valor aquisitivo
* Valor de mercado (venda)
* Valor de aluguel de mercado
* Valor m² (venda / aluguel)

```sql
create table fact_valuation_imovel (
    id_valuation       uuid primary key,
    id_imovel          uuid not null references dim_imovel(id_imovel),

    dt_referencia      date not null,
    tipo_valuation     text not null,      -- AQUISITIVO, MERCADO_VENDA, MERCADO_ALUGUEL
    valor              numeric(16,2) not null,
    moeda              char(3) default 'BRL',
    fonte              text,              -- RELATORIO_INTERNO, PORTAL_X, IMOBILIARIA_Y...

    valor_m2           numeric(16,2),     -- valor / área_privativa
    indicador_pct      numeric(8,4),      -- opcional (% valorização vs aquisitivo, etc.)

    created_at         timestamptz default now()
);

create index idx_valuation_imovel_data
    on fact_valuation_imovel (id_imovel, dt_referencia, tipo_valuation);
```

---

### 1.5. Contrato de Locação (gestão de carteira de locação)

Tabela para dados de “IMÓVEIS PARA LOCAÇÃO”, retornos, vencimentos de contratos etc.

```sql
create table fact_locacao_contrato (
    id_contrato                   uuid primary key,
    id_imovel                     uuid not null references dim_imovel(id_imovel),

    codigo_contrato               text,
    locatario_nome                text,
    locatario_tipo                text,             -- PF, PJ
    administrador_imobiliaria     text,             -- Calil, Dalton, Direto, etc.

    data_inicio                   date not null,
    data_fim_prevista             date,
    data_fim_efetiva              date,
    situacao_contrato             text,             -- ATIVO, ENCERRADO, EM_NEGOCIACAO, SEM_CONTRATO

    valor_aluguel_mensal_bruto    numeric(16,2),
    valor_aluguel_mensal_liquido  numeric(16,2),
    valor_aluguel_mercado_mensal  numeric(16,2),

    indice_reajuste               text,             -- IGP-M, IPCA, etc.
    periodicidade_reajuste_meses  integer,
    dia_vencimento                integer,

    retorno_aluguel_pct           numeric(8,4),     -- % retorno aluguel / valor mercado

    created_at                    timestamptz default now()
);
```

Se quiser granularidade mensal de receita / vacância:

```sql
create table fact_locacao_fluxo_mensal (
    id_fluxo          uuid primary key,
    id_contrato       uuid not null references fact_locacao_contrato(id_contrato),

    competencia       date not null,           -- use sempre 1º dia do mês
    receita_bruta     numeric(16,2),
    receita_liquida   numeric(16,2),
    dias_vagos        integer,
    inadimplente      boolean,

    created_at        timestamptz default now()
);

create index idx_fluxo_contrato_mes
    on fact_locacao_fluxo_mensal (id_contrato, competencia);
```

---

### 1.6. Due Diligence / Regularização

Aqui entram: SPU, matrícula individualizada, vistoria, débitos IPTU, Habite-se, etc.

```sql
create table fact_due_diligence_imovel (
    id_due            uuid primary key,
    id_imovel         uuid not null references dim_imovel(id_imovel),

    dt_referencia     date not null,
    tipo_item         text not null,  -- TITULARIDADE_SPU, MATRICULA, HABITE_SE, VISTORIA, IPTU, OUTROS
    descricao         text,
    status            text not null,  -- EM_ANDAMENTO, CONCLUIDO, PENDENTE, PARADO
    criticidade       text,           -- URGENTE, MEDIA, BAIXA
    responsavel       text,           -- Lidderar, Escritório X, Cliente, etc.
    dt_prazo          date,
    dt_conclusao      date,
    observacoes       text,

    created_at        timestamptz default now()
);

create index idx_due_imovel_ref
    on fact_due_diligence_imovel (id_imovel, dt_referencia, tipo_item);
```

---

### 1.7. Marketing / Movimentação Comercial (visualizações, visitas, propostas)

Reflete “MOVIMENTAÇÃO DA CARTEIRA IMOBILIÁRIA”, “DETALHAMENTO DAS MOVIMENTAÇÕES”.

```sql
create table fact_marketing_imovel (
    id_marketing       uuid primary key,
    id_imovel          uuid not null references dim_imovel(id_imovel),

    dt_referencia      date not null,
    finalidade         text not null,      -- VENDA, LOCACAO
    qtd_imobiliarias   integer,           -- nº de imobiliárias anunciando
    plataformas        text,              -- lista de portais / canais

    visualizacoes      integer,
    visitas            integer,
    propostas          integer,
    propostas_aceitas  integer,

    status_negociacao  text,              -- AGUARDANDO_PROPOSTAS, EM_NEGOCIACAO, CONCLUIDA, CANCELADA

    created_at         timestamptz default now()
);

create index idx_marketing_imovel_ref
    on fact_marketing_imovel (id_imovel, dt_referencia, finalidade);
```

---

### 1.8. Snapshot de carteira / visão consolidada

Para replicar seções tipo “SÍNTESE DOS INVESTIMENTOS IMOBILIÁRIOS / COMPOSIÇÃO POR SETOR”.

```sql
create table fact_portfolio_snapshot (
    id_snapshot                 uuid primary key,
    id_familia                  uuid not null references dim_familia(id_familia),

    dt_referencia               date not null,      -- ex: 2021-12-31

    qtd_imoveis_total           integer,
    qtd_cidades                 integer,

    valor_mercado_total         numeric(16,2),
    valor_receita_locacao_total numeric(16,2),

    valor_mercado_residencial   numeric(16,2),
    valor_mercado_rural         numeric(16,2),
    valor_mercado_comercial     numeric(16,2),
    valor_mercado_industrial    numeric(16,2),

    receita_locacao_residencial numeric(16,2),
    receita_locacao_rural       numeric(16,2),
    receita_locacao_comercial   numeric(16,2),
    receita_locacao_industrial  numeric(16,2),

    created_at                  timestamptz default now()
);
```

---

### 1.9. Movimentações de portfólio (aquisição, venda, etc.) – opcional

```sql
create table fact_movimentacao_imovel (
    id_movimentacao    uuid primary key,
    id_imovel          uuid not null references dim_imovel(id_imovel),

    dt_movimentacao    date not null,
    tipo_movimentacao  text not null,    -- AQUISICAO, VENDA, NOVA_LOCACAO, ENCERRAMENTO_LOCACAO, REFORMA...
    descricao          text,
    valor              numeric(16,2),
    moeda              char(3) default 'BRL',

    created_at         timestamptz default now()
);
```

---

## 2. JSON padrão por imóvel (camada de staging)

Formato default para você normalizar qualquer fonte (PDF, Excel, API) **antes** de gravar nas tabelas.

```json
{
  "familia": {
    "cod_familia": "BNI_GESTAO_IMOBILIARIA",
    "nome_familia": "BNI Gestão Imobiliária"
  },
  "imovel": {
    "codigo_interno": "51001",
    "nome_imovel": "APTO 802 EDF.EMILIO BUMACHAR",
    "tipo_ativo": "APARTAMENTO",
    "classificacao_setor": "RESIDENCIAL",
    "finalidade_principal": "VENDA",
    "localizacao": {
      "pais": "BR",
      "uf": "ES",
      "cidade": "Vila Velha",
      "bairro": null,
      "logradouro": null,
      "numero": null,
      "cep": null,
      "latitude": null,
      "longitude": null
    },
    "participacao_percent": 100.0,
    "area_total_m2": 163.43,
    "area_privativa_m2": 139.25,
    "data_aquisicao": "2018-02-07",
    "status_obras": "CONCLUIDO",
    "situacao_ocupacao_atual": "VENDA",
    "status_ativo": "ATIVO",
    "observacoes": null
  },
  "estrategias": [
    {
      "tipo_estrategia": "VENDA",
      "dt_inicio": "2018-02-07",
      "dt_fim": null
    }
  ],
  "valuations": [
    {
      "tipo_valuation": "AQUISITIVO",
      "dt_referencia": "2018-02-07",
      "valor": 150000.00,
      "moeda": "BRL",
      "fonte": "AQUISICAO",
      "valor_m2": 1077.37,
      "indicador_pct": null
    },
    {
      "tipo_valuation": "MERCADO_VENDA",
      "dt_referencia": "2021-12-31",
      "valor": 952471.18,
      "moeda": "BRL",
      "fonte": "RELATORIO_INTERNO",
      "valor_m2": 6840.01,
      "indicador_pct": 5.3923
    }
  ],
  "locacao": {
    "contrato": null,
    "fluxos_mensais": []
  },
  "due_diligence": [
    {
      "dt_referencia": "2021-12-31",
      "tipo_item": "TITULARIDADE_SPU",
      "status": "EM_ANDAMENTO",
      "criticidade": "MEDIA",
      "descricao": "Transferência de titularidade de contribuinte SPU.",
      "responsavel": "Lidderar",
      "dt_prazo": null,
      "dt_conclusao": null,
      "observacoes": null
    }
  ],
  "marketing": [
    {
      "dt_referencia": "2021-12-31",
      "finalidade": "VENDA",
      "qtd_imobiliarias": 2,
      "plataformas": "Portais diversos",
      "visualizacoes": 15,
      "visitas": 2,
      "propostas": 0,
      "propostas_aceitas": 0,
      "status_negociacao": "AGUARDANDO_PROPOSTAS"
    }
  ]
}
```

> A partir desse JSON, o ETL só faz:
>
> * `dim_imovel` ⟵ `imovel`
> * `rel_imovel_estrategia` ⟵ `estrategias`
> * `fact_valuation_imovel` ⟵ `valuations`
> * `fact_locacao_*` ⟵ `locacao`
> * `fact_due_diligence_imovel` ⟵ `due_diligence`
> * `fact_marketing_imovel` ⟵ `marketing`

---

## 3. Encaixe direto com as seções do relatório que você mandou

* **IMÓVEIS PARA VENDA / VALORIZAÇÃO / DESENVOLVIMENTO**

  * `dim_imovel` + `rel_imovel_estrategia` (VENDA / VALORIZACAO / DESENVOLVIMENTO)
  * `fact_valuation_imovel` (AQUISITIVO + MERCADO_VENDA)

* **IMÓVEIS PARA LOCAÇÃO**

  * `dim_imovel`
  * `rel_imovel_estrategia` (LOCACAO)
  * `fact_locacao_contrato` (valores de aluguel, retorno, situação)
  * `fact_valuation_imovel` (MERCADO_VENDA, MERCADO_ALUGUEL se tiver)

* **RETORNOS HISTÓRICOS / COMPOSIÇÃO CARTEIRA**

  * Métricas derivadas de `fact_locacao_fluxo_mensal` + `fact_valuation_imovel`
  * Snapshot consolidado em `fact_portfolio_snapshot`

* **DUE DILIGENCE / DOCUMENTOS EM ANDAMENTO / PENDÊNCIAS URGENTES**

  * `fact_due_diligence_imovel`

* **MOVIMENTAÇÃO IMOBILIÁRIA / VISUALIZAÇÕES / PROPOSTAS**

  * `fact_marketing_imovel`
  * Se quiser eventos pontuais (venda efetivada, nova locação) → `fact_movimentacao_imovel`

---

Se quiser, no próximo passo te devolvo:

* script de **CREATE SCHEMA + CREATE TABLE** completo com `schema` (ex.: `imob`)
* * um **script Python** ou **dbt model** que recebe esse JSON padrão e faz o insert nas tabelas do Postgres/BigQuery.
