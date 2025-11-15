# ADR 001: Escolha do PostgreSQL como Banco de Dados

## Status

Aceito

## Contexto

O sistema de gestão imobiliária BNI precisa de um banco de dados robusto para armazenar informações sobre 38 propriedades, incluindo:

- Dados cadastrais das propriedades
- Histórico de transações financeiras
- Relatórios IFRS gerados
- Logs de sincronização com sistemas externos

## Decisão

Escolhemos o **PostgreSQL 14+** como banco de dados principal do sistema.

## Motivação

### Vantagens do PostgreSQL

1. **Robustez e Confiabilidade**
   - Sistema de banco de dados relacional maduro e estável
   - ACID compliance garantido
   - Suporte a transações complexas

2. **Recursos Avançados**
   - Suporte nativo a JSON/JSONB para dados semi-estruturados
   - Full-text search integrado
   - Extensões úteis (pg_trgm para busca de texto)
   - Views materializadas para performance

3. **Escalabilidade**
   - Suporta grandes volumes de dados
   - Replicação e alta disponibilidade
   - Particionamento de tabelas

4. **Integração**
   - Excelente integração com Python (psycopg2, SQLAlchemy)
   - Suporte a Docker/containers
   - Fácil deploy em VPS

5. **Custo**
   - Open source e gratuito
   - Sem custos de licenciamento
   - Grande comunidade e documentação

### Alternativas Consideradas

1. **MySQL/MariaDB**
   - Rejeitado: Menos recursos avançados, especialmente para JSON
   - Performance inferior em alguns cenários

2. **SQLite**
   - Rejeitado: Não adequado para múltiplos usuários simultâneos
   - Limitações em operações concorrentes

3. **MongoDB**
   - Rejeitado: Dados são principalmente relacionais
   - PostgreSQL com JSONB oferece melhor dos dois mundos

## Consequências

### Positivas

- ✅ Banco de dados robusto e confiável
- ✅ Excelente suporte a queries complexas
- ✅ Integração nativa com Python
- ✅ Fácil deploy e manutenção
- ✅ Suporte a dados estruturados e semi-estruturados

### Negativas

- ⚠️ Requer configuração e manutenção (mitigado com Docker)
- ⚠️ Pode ser overkill para pequenos volumes (mas permite crescimento)

## Implementação

- Schema inicial definido em `scripts/init.sql`
- Scripts Python para inicialização em `scripts/init_database.py`
- Docker Compose configurado para desenvolvimento local
- GitHub Actions para deploy automático em VPS

## Referências

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL vs MySQL](https://www.postgresql.org/about/)
- [JSONB Performance](https://www.postgresql.org/docs/current/datatype-json.html)
