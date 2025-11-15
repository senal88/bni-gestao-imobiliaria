# 📱 Frontend - BNI Gestão Imobiliária

Documentação completa para desenvolvimento do frontend do sistema de gestão imobiliária.

## 📋 Visão Geral

O frontend é construído com **React + TypeScript + Vite + TailwindCSS**, totalmente integrado com o backend PostgreSQL e os dados reais do portfólio BNI.

## 🎯 Objetivos

- **Gestão Visual**: Interface intuitiva para visualizar e gerenciar 38 propriedades
- **Filtros Avançados**: Filtros por tipo, status, cidade, valor, etc.
- **Relatórios Dinâmicos**: Geração de relatórios em tempo real
- **Responsivo**: Funciona perfeitamente em desktop e mobile
- **Type-Safe**: TypeScript completo para segurança de tipos

## 🏗️ Arquitetura

```
frontend/
├── src/
│   ├── api/              # Clientes API REST
│   ├── components/       # Componentes React reutilizáveis
│   │   ├── propriedades/ # Componentes específicos de propriedades
│   │   ├── layout/       # Layout (Header, Sidebar, Footer)
│   │   └── ui/           # Componentes UI básicos
│   ├── context/          # Context API (se necessário)
│   ├── hooks/            # Custom React hooks
│   ├── pages/            # Páginas da aplicação
│   ├── services/          # Lógica de negócio
│   ├── styles/           # Estilos globais e Tailwind
│   └── utils/            # Funções utilitárias
├── public/               # Assets estáticos
├── docker/               # Configuração Docker
└── .github/workflows/    # CI/CD
```

## 🚀 Setup Inicial

### Pré-requisitos

- **Node.js**: 18+ (recomendado 20 LTS)
- **npm**: 9+ ou **yarn** ou **pnpm**
- **Git**: Para versionamento

### Instalação Rápida

```bash
# 1. Execute o script de setup
cd templates
./setup-frontend.sh

# 2. Configure variáveis de ambiente
cd ../frontend
cp .env.example .env
# Edite .env com suas configurações

# 3. Inicie o servidor de desenvolvimento
make dev
# ou
npm run dev
```

### Setup Manual

Se preferir setup manual:

```bash
# 1. Criar projeto Vite
npm create vite@latest bni-gestao-imobiliaria-frontend -- --template react-ts

# 2. Instalar dependências
cd bni-gestao-imobiliaria-frontend
npm install

# 3. Instalar dependências adicionais
npm install -D tailwindcss postcss autoprefixer
npm install zustand axios date-fns

# 4. Configurar TailwindCSS
npx tailwindcss init -p

# 5. Criar estrutura de diretórios
mkdir -p src/{api,components/{propriedades,layout,ui},context,hooks,pages,services,styles,utils}
```

## 📦 Dependências Principais

### Produção

- **react**: ^18.2.0
- **react-dom**: ^18.2.0
- **typescript**: ^5.0.0
- **zustand**: ^4.4.0 (gerenciamento de estado)
- **axios**: ^1.6.0 (cliente HTTP)
- **date-fns**: ^2.30.0 (manipulação de datas)

### Desenvolvimento

- **vite**: ^5.0.0 (build tool)
- **tailwindcss**: ^3.4.0 (framework CSS)
- **@types/react**: ^18.2.0
- **@types/node**: ^20.0.0
- **vitest**: ^1.0.0 (testes)

## 🔧 Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` baseado em `.env.example`:

```env
# API Backend
VITE_API_URL=http://localhost:8000
VITE_API_BASE_PATH=/api/v1

# Ambiente
NODE_ENV=development
VITE_PORT=5173

# Features
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=true
```

### TailwindCSS

O TailwindCSS está configurado com tema customizado:

```js
// tailwind.config.js
theme: {
  extend: {
    colors: {
      primary: {
        // Paleta de cores primária
      }
    }
  }
}
```

## 📊 Estrutura de Dados

### Interface Propriedade

Baseado em `data/raw/propriedades.csv`:

```typescript
interface Propriedade {
  id: number;
  codigo: string;
  codigo_cc: string;
  nome: string;
  tipo_estoque: 'Concluídos' | 'De Terceiros' | 'N/D';
  valor_2023?: number;
  valor_2024?: number;
  status: string;
  // ... outros campos
}
```

## 🎨 Componentes Principais

### PropertyCard

Card visual para exibir uma propriedade:

```tsx
<PropertyCard 
  propriedade={propriedade}
  onViewDetails={() => {}}
/>
```

### PropertyTable

Tabela completa com filtros e ordenação:

```tsx
<PropertyTable 
  propriedades={propriedades}
  filtros={filtros}
  onFilterChange={handleFilter}
/>
```

### PropertyFilters

Componente de filtros avançados:

```tsx
<PropertyFilters 
  filtros={filtros}
  onFilterChange={handleFilter}
/>
```

## 🔌 Integração com API

### Cliente API

```typescript
import { propriedadesApi } from './api/propriedades';

// Buscar todas as propriedades
const propriedades = await propriedadesApi.getAll();

// Buscar com filtros
const filtradas = await propriedadesApi.getAll({
  tipo_estoque: 'Concluídos',
  cidade: 'Vila Velha'
});

// Buscar por ID
const propriedade = await propriedadesApi.getById(1);
```

## 🧪 Testes

```bash
# Executar testes
npm run test

# Testes em modo watch
npm run test:watch

# Coverage
npm run test:coverage
```

## 🐳 Docker

### Build

```bash
make docker-build
# ou
docker build -f docker/Dockerfile.frontend -t bni-frontend:latest .
```

### Executar

```bash
make docker-run
# ou
docker compose up -d
```

## 📱 Deploy

### VPS com Traefik

O frontend está configurado para deploy automático via GitHub Actions e Traefik.

### Variáveis de Ambiente em Produção

Configure no servidor:

```bash
VITE_API_URL=https://api.bni-gestao.com
VITE_API_BASE_PATH=/api/v1
NODE_ENV=production
```

## 🔍 Debugging

### Modo Debug

Ative o modo debug no `.env`:

```env
VITE_ENABLE_DEBUG=true
```

### DevTools

- **React DevTools**: Extensão do navegador
- **Redux DevTools**: Se usar Redux (não necessário com Zustand)

## 📚 Recursos Adicionais

- **Documentação React**: https://react.dev
- **Documentação Vite**: https://vitejs.dev
- **Documentação TailwindCSS**: https://tailwindcss.com
- **Documentação TypeScript**: https://www.typescriptlang.org

## 🤝 Contribuindo

1. Crie uma branch para sua feature
2. Faça suas alterações
3. Execute testes e lint
4. Abra um Pull Request

## 📝 Notas Importantes

- **Sempre use dados reais**: Nunca use dados fictícios
- **Código de família**: `BNI_GESTAO_IMOBILIARIA`
- **Nome da família**: `BNI Gestão Imobiliária`
- **TypeScript**: Mantenha type safety completo
- **Responsivo**: Mobile-first sempre

## 🆘 Suporte

Para dúvidas ou problemas:

1. Consulte `frontend-project-context-bni.md`
2. Verifique os logs do console
3. Abra uma issue no GitHub

---

**Última atualização**: 2025-01-15

