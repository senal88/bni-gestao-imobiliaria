---
tags: [portfolio, bni, relatorio, dashboard]
tipo: dashboard
created: {{date}}
---

# Dashboard do Portfólio BNI

**Data de Atualização:** {{date}}

## Visão Geral

### Estatísticas Principais

- **Total de Propriedades:** {{total_properties}}
- **Valor Total do Portfólio:** R$ {{total_value}}
- **Renda Mensal Total:** R$ {{monthly_income}}
- **Renda Anual Projetada:** R$ {{annual_income}}
- **Taxa de Retorno Média:** {{average_yield}}%

### Status das Propriedades

- 🟢 **Ocupadas:** {{occupied_count}} ({{occupied_pct}}%)
- 🟡 **Vagas:** {{vacant_count}} ({{vacant_pct}}%)
- 🔵 **Em Reforma:** {{reform_count}}
- 🔴 **À Venda:** {{sale_count}}

## Distribuição por Tipo

| Tipo | Quantidade | Valor Total | Renda Mensal |
|------|------------|-------------|--------------|
| Residencial | {{res_count}} | R$ {{res_value}} | R$ {{res_income}} |
| Comercial | {{com_count}} | R$ {{com_value}} | R$ {{com_income}} |
| Industrial | {{ind_count}} | R$ {{ind_value}} | R$ {{ind_income}} |
| Terreno | {{ter_count}} | R$ {{ter_value}} | R$ {{ter_income}} |

## Distribuição Geográfica

| Estado | Quantidade | Valor Total |
|--------|------------|-------------|
{{#each states}}
| {{state}} | {{count}} | R$ {{value}} |
{{/each}}

## Top 5 Propriedades por Valor

1. [[{{top1_name}}]] - R$ {{top1_value}}
2. [[{{top2_name}}]] - R$ {{top2_value}}
3. [[{{top3_name}}]] - R$ {{top3_value}}
4. [[{{top4_name}}]] - R$ {{top4_value}}
5. [[{{top5_name}}]] - R$ {{top5_value}}

## Top 5 Propriedades por Renda Mensal

1. [[{{income_top1_name}}]] - R$ {{income_top1_value}}
2. [[{{income_top2_name}}]] - R$ {{income_top2_value}}
3. [[{{income_top3_name}}]] - R$ {{income_top3_value}}
4. [[{{income_top4_name}}]] - R$ {{income_top4_value}}
5. [[{{income_top5_name}}]] - R$ {{income_top5_value}}

## Ações Necessárias

### Propriedades Vagas
{{#each vacant_properties}}
- [[{{name}}]] - Vaga desde {{vacant_date}}
{{/each}}

### Contratos Próximos ao Vencimento
{{#each expiring_contracts}}
- [[{{name}}]] - Vence em {{expiration_date}}
{{/each}}

### Manutenção Pendente
{{#each maintenance_pending}}
- [[{{name}}]] - {{maintenance_type}}
{{/each}}

## Análise Financeira

### Performance Mensal
```chart
type: line
labels: [Jan, Fev, Mar, Abr, Mai, Jun, Jul, Ago, Set, Out, Nov, Dez]
series:
  - title: Renda Mensal
    data: [{{monthly_data}}]
```

### Valorização do Portfólio
- **Custo Total de Aquisição:** R$ {{total_acquisition}}
- **Valor Atual:** R$ {{total_current}}
- **Valorização Total:** R$ {{total_appreciation}} ({{appreciation_pct}}%)

## Links Úteis

- [[Relatórios IFRS]]
- [[Propriedades]]
- [[Contratos]]
- [[Manutenção]]
- [[Documentação]]

---

**Próxima Atualização:** {{next_update}}
**Gerado por:** BNI Real Estate Management System
