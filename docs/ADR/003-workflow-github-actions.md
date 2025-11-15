# ADR 003: Automação de Deploy com GitHub Actions

## Status

Aceito

## Contexto

O sistema precisa de automação para:

- Deploy automático em VPS PostgreSQL
- Sincronização periódica com Hugging Face
- Validação de dados antes de merge
- Geração de relatórios em horários agendados

## Decisão

Utilizamos **GitHub Actions** para automação completa de CI/CD e tarefas agendadas.

## Motivação

### Vantagens do GitHub Actions

1. **Integração Nativa**
   - Já integrado ao GitHub
   - Sem necessidade de serviços externos
   - Secrets management integrado

2. **Flexibilidade**
   - Suporte a múltiplos triggers (push, PR, schedule, manual)
   - Execução em diferentes sistemas operacionais
   - Customização completa dos workflows

3. **Custo**
   - Gratuito para repositórios públicos
   - 2000 minutos/mês para repositórios privados
   - Suficiente para nossas necessidades

4. **Facilidade de Uso**
   - YAML simples e legível
   - Grande biblioteca de actions pré-construídas
   - Documentação extensa

5. **Visibilidade**
   - Logs públicos para repositórios públicos
   - Status badges
   - Histórico completo de execuções

### Alternativas Consideradas

1. **Jenkins**
   - Rejeitado: Requer servidor próprio
   - Configuração mais complexa
   - Overhead de manutenção

2. **GitLab CI**
   - Considerado mas rejeitado: Repositório já está no GitHub
   - Migração desnecessária

3. **CircleCI / Travis CI**
   - Rejeitado: Custo adicional sem benefícios claros
   - GitHub Actions já atende todas as necessidades

4. **Cron Jobs no VPS**
   - Rejeitado: Menos visibilidade
   - Mais difícil de debugar
   - Sem integração com PRs

## Consequências

### Positivas

- ✅ Automação completa sem custos adicionais
- ✅ Integração nativa com GitHub
- ✅ Fácil de configurar e manter
- ✅ Logs e histórico completos
- ✅ Validação automática em PRs

### Negativas

- ⚠️ Dependência do GitHub (mitigado: código pode ser migrado)
- ⚠️ Limites de execução para repositórios privados (não aplicável: repositório público)

## Implementação

### Workflows Criados

1. **deploy-postgres.yml**
   - Deploy automático em VPS PostgreSQL
   - Trigger: push para main/master
   - Valida conexão antes de deploy
   - Usa SSH para conexão com VPS

2. **sync-huggingface.yml**
   - Sincronização com Hugging Face Dataset
   - Trigger: schedule diário + push manual
   - Valida schemas antes de upload
   - Gera resumo da sincronização

3. **validate-schemas.yml**
   - Validação de schemas CSV
   - Trigger: PRs e push para main
   - Bloqueia merge se validação falhar
   - Gera relatório de validação

### Secrets Configurados

- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `SSH_PRIVATE_KEY`, `SSH_HOST`, `SSH_USER`, `SSH_PORT`
- `HF_TOKEN`, `HF_DATASET_NAME`

### Estrutura de Workflows

```yaml
name: Workflow Name
on:
  push:
    branches: [main]
    paths: ['relevant/**']
  workflow_dispatch:

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Execute task
        run: python scripts/task.py
```

## Boas Práticas Aplicadas

1. **Validação Antes de Deploy**
   - Sempre validar antes de fazer deploy
   - Testes automáticos quando aplicável

2. **Paths Filtering**
   - Workflows só executam quando arquivos relevantes mudam
   - Economiza minutos de execução

3. **Secrets Management**
   - Nunca commitar credenciais
   - Usar GitHub Secrets para valores sensíveis

4. **Error Handling**
   - Notificações em caso de falha
   - Cleanup de recursos mesmo em caso de erro

5. **Documentação**
   - Comentários nos workflows
   - README com instruções de configuração

## Referências

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Best Practices for GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/best-practices)
