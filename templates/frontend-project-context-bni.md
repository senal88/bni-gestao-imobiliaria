# 🧠 FRONTEND PROJECT CONTEXT - BNI Gestão Imobiliária
> Documento de especificação parametrizada para automação completa do ambiente frontend de gestão imobiliária.

---

## 🔹 1. IDENTIFICAÇÃO DO PROJETO

**PROJECT_NAME:**
`bni-gestao-imobiliaria-frontend`

**PROJECT_DESCRIPTION:**
"Sistema frontend para gestão do portfólio imobiliário BNI: 38 propriedades integradas com PostgreSQL, filtros avançados, visualizações e relatórios dinâmicos."

**AUTHOR:**
`BNI Gestão Imobiliária`

**VERSION:**
`1.0.0`

---

## 🔹 2. AMBIENTE DE EXECUÇÃO

| Variável | Valor | Observação |
|-----------|--------|------------|
| **HOST_ENV** | `macos-silicon / ubuntu-vps` | Suporte para desenvolvimento local e produção |
| **CLOUD_PROVIDER** | `none` | Self-hosted na VPS |
| **DEPLOY_TARGET** | `docker-traefik` | Estratégia de deploy com Traefik |
| **MONITORING** | `none` | Observabilidade futura |
| **AUTOMATION_TOOL** | `make` | Orquestração de automações |

---

## 🔹 3. STACK TECNOLÓGICA

| Componente | Valor | Detalhe |
|-------------|--------|----------|
| **STACK_TYPE** | `react` | Framework frontend |
| **LANGUAGE** | `ts` | TypeScript para type safety |
| **PKG_MANAGER** | `npm` | Gerenciador de pacotes |
| **STYLE_LIB** | `tailwind` | Framework de estilo utilitário |
| **STATE_MANAGEMENT** | `zustand` | Controle de estado leve |
| **BUILD_TOOL** | `vite` | Sistema de build rápido |
| **API_INTEGRATION** | `rest` | Integração com API REST PostgreSQL |

---

## 🔹 4. ESTRUTURA DE DIRETÓRIOS

```yaml
structure:
  - src/
    - api/
      - propriedades.ts          # API client para propriedades
      - client.ts                # Configuração axios/fetch
    - components/
      - propriedades/
        - PropertyCard.tsx       # Card de propriedade
        - PropertyTable.tsx      # Tabela de propriedades
        - PropertyFilters.tsx    # Filtros avançados
      - layout/
        - Header.tsx
        - Sidebar.tsx
        - Footer.tsx
      - ui/
        - Button.tsx
        - Input.tsx
        - Select.tsx
        - Modal.tsx
    - context/
      - AppContext.tsx           # Contexto global
    - hooks/
      - useProperties.ts         # Hook para propriedades
      - useFilters.ts            # Hook para filtros
    - pages/
      - Dashboard.tsx            # Dashboard principal
      - Properties.tsx           # Lista de propriedades
      - PropertyDetail.tsx       # Detalhes da propriedade
      - Reports.tsx              # Relatórios
    - services/
      - propertyService.ts      # Lógica de negócio
    - styles/
      - globals.css             # Estilos globais
      - tailwind.css            # Tailwind imports
    - utils/
      - formatCurrency.ts       # Formatação de moeda
      - formatDate.ts           # Formatação de datas
      - constants.ts             # Constantes do sistema
  - public/
    - assets/
      - icons/
      - images/
  - docker/
    - Dockerfile.frontend
    - nginx.conf
  - .github/workflows/
    - deploy-frontend.yml
  - .vscode/
    - settings.json
    - extensions.json
```

---

## 🔹 5. VARIÁVEIS DE AMBIENTE

```env
# API Backend
VITE_API_URL=http://localhost:8000
VITE_API_BASE_PATH=/api/v1

# Ambiente
NODE_ENV=development
VITE_PORT=5173

# PostgreSQL (via API)
VITE_POSTGRES_HOST=localhost
VITE_POSTGRES_PORT=5432

# Features
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=true
```

---

## 🔹 6. CI/CD E PIPELINES

| Parâmetro | Valor |
| --- | --- |
| **CI_PROVIDER** | `github-actions` |
| **TEST_RUNNER** | `vitest` |
| **DEPLOY_BRANCH** | `main` |
| **AUTOMATED_TESTS** | `true` |
| **AUTO_DEPLOY** | `true` |

---

## 🔹 7. CONTAINERS E ORQUESTRAÇÃO

```yaml
containers:
  frontend:
    build: docker/Dockerfile.frontend
    ports:
      - "5173:5173"
    env_file: .env
    depends_on:
      - backend
  traefik:
    image: traefik:v3.1
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

---

## 🔹 8. INTEGRAÇÕES OPCIONAIS

| Integração | Status | Observações |
| --- | --- | --- |
| **PostgreSQL** | `enabled` | Via API REST |
| **Hugging Face** | `enabled` | Sincronização de dados |
| **Obsidian** | `disabled` | Exportação futura |
| **Grafana / Prometheus** | `disabled` | Monitoramento futuro |

---

## 🔹 9. DADOS E MODELOS

### 9.1. Estrutura de Propriedade

Baseado em `data/raw/propriedades.csv` e `scripts/init.sql`:

```typescript
interface Propriedade {
  id: number;
  codigo: string;
  codigo_cc: string;
  nome: string;
  endereco?: string;
  cidade?: string;
  estado?: string;
  cep?: string;
  tipo_propriedade?: string;
  tipo_estoque: 'Concluídos' | 'De Terceiros' | 'N/D';
  area_total?: number;
  area_construida?: number;
  valor_avaliacao?: number;
  valor_2023?: number;
  valor_2024?: number;
  preco_promessa?: number;
  status: 'Concluído' | 'Locado' | 'Vendido/Reclassificado' | 'Concluído/Locado' | 'Promessa_Compra_Venda' | 'Aporte SCP';
  data_aquisicao?: string;
  data_habite_se_prevista?: string;
  observacoes?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

### 9.2. Filtros Disponíveis

- **Tipo de Estoque**: Concluídos, De Terceiros, N/D
- **Status**: Todos os status disponíveis
- **Cidade**: Filtro por cidade
- **Estado**: Filtro por UF
- **Valor**: Range de valores (2023, 2024)
- **Data**: Range de datas (aquisição, habite-se)

---

## 🔹 10. SCRIPTS AUTOMATIZADOS (Makefile)

```makefile
PROJECT=bni-gestao-imobiliaria-frontend
PKG_MANAGER=npm

setup:
	mkdir -p src/{api,components/{propriedades,layout,ui},context,hooks,pages,services,styles,utils}
	$(PKG_MANAGER) install
	cp .env.example .env

dev:
	$(PKG_MANAGER) run dev

build:
	$(PKG_MANAGER) run build

test:
	$(PKG_MANAGER) run test

lint:
	$(PKG_MANAGER) run lint

docker-build:
	docker build -f docker/Dockerfile.frontend -t $(PROJECT):latest .

docker-run:
	docker compose up -d
```

---

## 🔹 11. METADADOS

| Campo | Valor |
| --- | --- |
| **REPOSITORY_URL** | `https://github.com/senal88/bni-gestao-imobiliaria` |
| **LICENSE** | `MIT` |
| **CREATED_AT** | `2025-01-15` |
| **UPDATED_AT** | `2025-01-15` |

---

## ✅ **STATUS**

**READY_FOR_AUTOMATION:** `true`
*(Se "true", o repositório será gerado automaticamente com base neste contexto.)*

---

## 📋 **REQUISITOS ESPECÍFICOS**

1. **Dados Reais**: Sempre usar dados de `data/raw/propriedades.csv`
2. **Código de Família**: `BNI_GESTAO_IMOBILIARIA`
3. **Nome da Família**: `BNI Gestão Imobiliária`
4. **Compatibilidade**: macOS Silicon e Ubuntu VPS
5. **TypeScript**: Type safety completo
6. **Responsivo**: Mobile-first design
7. **Acessibilidade**: WCAG 2.1 AA mínimo

