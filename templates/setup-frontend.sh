#!/usr/bin/env bash
# =========================================================
#  SETUP FRONTEND - BNI Gestão Imobiliária
#  Gera automaticamente o ambiente frontend completo
#  Compatível com macOS Silicon e Ubuntu VPS
# =========================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detecção de ambiente
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "ubuntu"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
PROJECT_NAME="bni-gestao-imobiliaria-frontend"
PROJECT_DIR="../frontend"

echo -e "${BLUE}🚀 Setup Frontend - BNI Gestão Imobiliária${NC}"
echo -e "${BLUE}===========================================${NC}"
echo -e "OS detectado: ${GREEN}${OS}${NC}"
echo ""

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js não encontrado${NC}"
    echo "Instale Node.js 18+ em: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✅ Node.js encontrado: ${NODE_VERSION}${NC}"

# Verificar npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm não encontrado${NC}"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo -e "${GREEN}✅ npm encontrado: ${NPM_VERSION}${NC}"

# Criar diretório do projeto
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  Diretório ${PROJECT_DIR} já existe${NC}"
    read -p "Deseja continuar e sobrescrever? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    rm -rf "$PROJECT_DIR"
fi

echo -e "${BLUE}📁 Criando estrutura do projeto...${NC}"
mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

# Inicializar projeto Vite + React + TypeScript
echo -e "${BLUE}⚙️  Inicializando projeto Vite + React + TypeScript...${NC}"
npm create vite@latest . -- --template react-ts

# Instalar dependências base
echo -e "${BLUE}📦 Instalando dependências...${NC}"
npm install

# Instalar dependências adicionais
echo -e "${BLUE}📦 Instalando dependências adicionais...${NC}"
npm install -D tailwindcss postcss autoprefixer
npm install zustand axios date-fns
npm install -D @types/node

# Configurar TailwindCSS
echo -e "${BLUE}🎨 Configurando TailwindCSS...${NC}"
npx tailwindcss init -p

# Criar estrutura de diretórios
echo -e "${BLUE}📂 Criando estrutura de diretórios...${NC}"
mkdir -p src/{api,components/{propriedades,layout,ui},context,hooks,pages,services,styles,utils}
mkdir -p public/assets/{icons,images}
mkdir -p docker
mkdir -p .github/workflows
mkdir -p .vscode

# Criar arquivos de configuração
echo -e "${BLUE}📝 Criando arquivos de configuração...${NC}"

# tailwind.config.js
cat > tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
      },
    },
  },
  plugins: [],
}
EOF

# .env.example
cat > .env.example <<'EOF'
# API Backend
VITE_API_URL=http://localhost:8000
VITE_API_BASE_PATH=/api/v1

# Ambiente
NODE_ENV=development
VITE_PORT=5173

# Features
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=true
EOF

# .gitignore
cat > .gitignore <<'EOF'
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Environment
.env
.env.local
.env.production
EOF

# Dockerfile
cat > docker/Dockerfile.frontend <<'EOF'
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# nginx.conf
cat > docker/nginx.conf <<'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: "3.9"

services:
  frontend:
    build:
      context: .
      dockerfile: docker/Dockerfile.frontend
    container_name: bni-frontend
    ports:
      - "5173:80"
    environment:
      - NODE_ENV=production
    labels:
      - "traefik.http.routers.frontend.rule=Host(`frontend.localhost`)"
      - "traefik.http.routers.frontend.entrypoints=web"
    networks:
      - bni-network

networks:
  bni-network:
    external: true
EOF

# GitHub Actions workflow
cat > .github/workflows/deploy-frontend.yml <<'EOF'
name: Deploy Frontend

on:
  push:
    branches: [ main ]
    paths:
      - 'frontend/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        working-directory: frontend
        run: npm ci
      
      - name: Build
        working-directory: frontend
        run: npm run build
      
      - name: Deploy to VPS
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USER: ${{ secrets.SSH_USER }}
          SSH_PORT: ${{ secrets.SSH_PORT || '22' }}
        run: |
          # Deploy steps aqui
          echo "Deploy configurado"
EOF

# VSCode settings
cat > .vscode/settings.json <<'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true
}
EOF

# VSCode extensions
cat > .vscode/extensions.json <<'EOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-typescript-next"
  ]
}
EOF

# Criar arquivos TypeScript básicos
echo -e "${BLUE}📝 Criando arquivos TypeScript básicos...${NC}"

# src/api/client.ts
cat > src/api/client.ts <<'EOF'
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
const API_BASE_PATH = import.meta.env.VITE_API_BASE_PATH || '/api/v1';

export const apiClient = axios.create({
  baseURL: `${API_URL}${API_BASE_PATH}`,
  headers: {
    'Content-Type': 'application/json',
  },
});

export default apiClient;
EOF

# src/api/propriedades.ts
cat > src/api/propriedades.ts <<'EOF'
import apiClient from './client';

export interface Propriedade {
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
  status: string;
  data_aquisicao?: string;
  data_habite_se_prevista?: string;
  observacoes?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface FiltrosPropriedades {
  tipo_estoque?: string;
  status?: string;
  cidade?: string;
  estado?: string;
  valor_min?: number;
  valor_max?: number;
}

export const propriedadesApi = {
  getAll: async (filtros?: FiltrosPropriedades): Promise<Propriedade[]> => {
    const { data } = await apiClient.get('/propriedades', { params: filtros });
    return data;
  },

  getById: async (id: number): Promise<Propriedade> => {
    const { data } = await apiClient.get(`/propriedades/${id}`);
    return data;
  },
};
EOF

# src/utils/formatCurrency.ts
cat > src/utils/formatCurrency.ts <<'EOF'
export const formatCurrency = (value: number | null | undefined): string => {
  if (value === null || value === undefined) return 'N/A';
  
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};
EOF

# src/utils/formatDate.ts
cat > src/utils/formatDate.ts <<'EOF'
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

export const formatDate = (date: string | null | undefined): string => {
  if (!date) return 'N/A';
  
  try {
    return format(new Date(date), 'dd/MM/yyyy', { locale: ptBR });
  } catch {
    return 'N/A';
  }
};
EOF

# src/utils/constants.ts
cat > src/utils/constants.ts <<'EOF'
export const COD_FAMILIA = 'BNI_GESTAO_IMOBILIARIA';
export const NOME_FAMILIA = 'BNI Gestão Imobiliária';

export const TIPOS_ESTOQUE = ['Concluídos', 'De Terceiros', 'N/D'] as const;

export const STATUS_PROPRIEDADE = [
  'Concluído',
  'Locado',
  'Vendido/Reclassificado',
  'Concluído/Locado',
  'Promessa_Compra_Venda',
  'Aporte SCP',
] as const;
EOF

# Atualizar src/main.tsx
cat > src/main.tsx <<'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './styles/index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# Criar App.tsx básico
cat > src/App.tsx <<'EOF'
import { useState, useEffect } from 'react'
import { propriedadesApi, Propriedade } from './api/propriedades'
import { formatCurrency } from './utils/formatCurrency'

function App() {
  const [propriedades, setPropriedades] = useState<Propriedade[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadPropriedades = async () => {
      try {
        const data = await propriedadesApi.getAll()
        setPropriedades(data)
      } catch (error) {
        console.error('Erro ao carregar propriedades:', error)
      } finally {
        setLoading(false)
      }
    }

    loadPropriedades()
  }, [])

  if (loading) {
    return <div className="p-8">Carregando...</div>
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4">
          <h1 className="text-3xl font-bold text-gray-900">
            BNI Gestão Imobiliária
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Gestão do portfólio imobiliário - {propriedades.length} propriedades
          </p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 px-4">
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Código
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Nome
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Valor 2024
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {propriedades.map((prop) => (
                <tr key={prop.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {prop.codigo_cc}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {prop.nome}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {prop.status}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatCurrency(prop.valor_2024)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  )
}

export default App
EOF

# Atualizar src/styles/index.css
cat > src/styles/index.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;

  color-scheme: light dark;
  color: rgba(255, 255, 255, 0.87);
  background-color: #242424;

  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

#root {
  width: 100%;
  margin: 0 auto;
  text-align: left;
}
EOF

# Criar Makefile
cat > Makefile <<'EOF'
.PHONY: setup dev build test lint docker-build docker-run

setup:
	npm install
	cp .env.example .env

dev:
	npm run dev

build:
	npm run build

test:
	npm run test

lint:
	npm run lint

docker-build:
	docker build -f docker/Dockerfile.frontend -t bni-frontend:latest .

docker-run:
	docker compose up -d
EOF

# Criar README.md
cat > README.md <<'EOF'
# BNI Gestão Imobiliária - Frontend

Sistema frontend para gestão do portfólio imobiliário BNI.

## 🚀 Início Rápido

```bash
# Instalar dependências
make setup

# Desenvolvimento
make dev

# Build para produção
make build
```

## 📋 Requisitos

- Node.js 18+
- npm ou yarn

## 🛠️ Tecnologias

- React 18
- TypeScript
- Vite
- TailwindCSS
- Zustand
- Axios

## 📁 Estrutura

```
src/
├── api/              # Clientes API
├── components/        # Componentes React
├── hooks/            # Custom hooks
├── pages/            # Páginas
├── services/         # Serviços de negócio
├── utils/            # Utilitários
└── styles/           # Estilos globais
```

## 🔧 Variáveis de Ambiente

Copie `.env.example` para `.env` e configure:

- `VITE_API_URL`: URL da API backend
- `VITE_API_BASE_PATH`: Caminho base da API

## 🐳 Docker

```bash
make docker-build
make docker-run
```

## 📚 Documentação

Consulte `templates/frontend-project-context-bni.md` para detalhes completos.
EOF

echo ""
echo -e "${GREEN}✅ Setup concluído com sucesso!${NC}"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo -e "1. cd ${PROJECT_DIR}"
echo -e "2. cp .env.example .env"
echo -e "3. Configure as variáveis de ambiente em .env"
echo -e "4. make dev"
echo ""
echo -e "${GREEN}🎉 Frontend pronto para desenvolvimento!${NC}"

