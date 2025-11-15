# 🧠 FRONTEND PROJECT CONTEXT
> Documento de especificação parametrizada para automação completa do ambiente frontend.

---

## 🔹 1. IDENTIFICAÇÃO DO PROJETO

**PROJECT_NAME:**
`my-awesome-frontend-app`

**PROJECT_DESCRIPTION:**
“Um aplicativo frontend moderno construído com React e Vite, com TailwindCSS para estilização e Docker/Traefik para deploy em um ambiente VPS.”

**AUTHOR:**
`Gemini CLI`

**VERSION:**
`0.1.0`

---

## 🔹 2. AMBIENTE DE EXECUÇÃO

| Variável | Valor | Observação |
|-----------|--------|------------|
| **HOST_ENV** | `ubuntu-vps` | Onde o projeto será executado |
| **CLOUD_PROVIDER** | `none` | Integração com cloud |
| **DEPLOY_TARGET** | `docker-traefik` | Estratégia de deploy |
| **MONITORING** | `none` | Observabilidade |
| **AUTOMATION_TOOL** | `make` | Orquestração de automações |

---

## 🔹 3. STACK TECNOLÓGICA

| Componente | Valor | Detalhe |
|-------------|--------|----------|
| **STACK_TYPE** | `react` | Framework frontend |
| **LANGUAGE** | `ts` | Linguagem base |
| **PKG_MANAGER** | `npm` | Gerenciador de pacotes |
| **STYLE_LIB** | `tailwind` | Framework de estilo |
| **STATE_MANAGEMENT** | `none` | Controle de estado |
| **BUILD_TOOL** | `vite` | Sistema de build |
| **API_INTEGRATION** | `rest` | Integração com backend |

---

## 🔹 4. ESTRUTURA DE DIRETÓRIOS (Opcional)
> Se quiser definir manualmente, liste os diretórios que o repositório deve conter.
> Caso contrário, será gerado automaticamente conforme o `STACK_TYPE`.

```yaml
structure:
  - src/
    - api/
    - components/
    - context/
    - hooks/
    - pages/
    - services/
    - styles/
    - utils/
  - public/
  - docker/
  - .github/workflows/
  - .vscode/
```

---

## 🔹 5. VARIÁVEIS DE AMBIENTE

```env
# API
API_URL=https://api.my-awesome-frontend-app.com
API_KEY=your_api_key_here

# Ambiente
NODE_ENV=development
PORT=5173

# Cloud
GCP_PROJECT_ID=
GCP_REGION=

# Observabilidade
GRAFANA_URL=
PROMETHEUS_ENDPOINT=
```

---

## 🔹 6. CI/CD E PIPELINES

| Parâmetro | Valor |
| --- | --- |
| **CI\_PROVIDER** | `github-actions` |
| **TEST\_RUNNER** | `vitest` |
| **DEPLOY\_BRANCH** | `main` |
| **AUTOMATED\_TESTS** | `true` |
| **AUTO\_DEPLOY** | `false` |

---

## 🔹 7. CONTAINERS E ORQUESTRAÇÃO

```yaml
containers:
  frontend:
    build: docker/Dockerfile.frontend
    ports:
      - "5173:5173"
    env_file: .env
  traefik:
    image: traefik:v3.1
    ports:
      - "80:80"
      - "8080:8080"
  monitoring:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

---

## 🔹 8. INTEGRAÇÕES OPCIONAIS

| Integração | Status | Observações |
| --- | --- | --- |
| **Dify / Langchain** | `disabled` | Agente de IA |
| **N8n** | `disabled` | Automação de workflows |
| **Appsmith** | `disabled` | Painel low-code para APIs |
| **PostgreSQL / Pgvector** | `disabled` | Armazenamento de embeddings |
| **Grafana / Prometheus** | `disabled` | Monitoramento em tempo real |

---

## 🔹 9. SCRIPTS AUTOMATIZADOS (Makefile)

```makefile
PROJECT=my-awesome-frontend-app

setup:
	mkdir -p src/{api,components,context,hooks,pages,services,styles,utils}
	$(PKG_MANAGER) install
	cp .env.example .env

dev:
	$(PKG_MANAGER) run dev

build:
	$(PKG_MANAGER) run build

docker-run:
	docker compose up -d
```

---

## 🔹 10. METADADOS

| Campo | Valor |
| --- | --- |
| **REPOSITORY\_URL** | `https://github.com/your-org/my-awesome-frontend-app` |
| **LICENSE** | `MIT` |
| **CREATED\_AT** | `2025-11-15` |
| **UPDATED\_AT** | `2025-11-15` |

---

## ✅ **STATUS**

**READY\_FOR\_AUTOMATION:** `true`
*(Se “true”, o repositório será gerado automaticamente com base neste contexto.)*
