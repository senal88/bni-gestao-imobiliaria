# 🚀 Automação em Escala - Padronização de Branches

Scripts enterprise-grade para padronizar branches em todos os seus repositórios.

## 📋 Scripts Disponíveis

### 1. `mudar_default_branch_enterprise.sh`
**Uso**: Corrigir um repositório específico (este projeto)

```bash
export GH_TOKEN=seu_token_aqui
./scripts/mudar_default_branch_enterprise.sh
```

**O que faz:**
- ✅ Muda default branch para `main`
- ✅ Deleta branch `teab` remota
- ✅ Deleta branch `teab` local
- ✅ Não trava em caso de erro

### 2. `listar_repos_nao_main.sh`
**Uso**: Listar todos os repositórios que não usam `main` como padrão

```bash
export GH_TOKEN=seu_token_aqui
./scripts/listar_repos_nao_main.sh
```

**O que faz:**
- ✅ Lista todos os seus repositórios
- ✅ Identifica quais não usam `main` como padrão
- ✅ Mostra estatísticas

### 3. `corrigir_todos_repos.sh`
**Uso**: Corrigir TODOS os repositórios de uma vez

```bash
export GH_TOKEN=seu_token_aqui
./scripts/corrigir_todos_repos.sh
```

**⚠️ ATENÇÃO**: Este script modifica TODOS os seus repositórios!

**O que faz:**
- ✅ Lista todos os repositórios
- ✅ Verifica se `main` existe em cada um
- ✅ Muda default branch para `main` onde aplicável
- ✅ Pula repositórios que já usam `main`
- ✅ Pula repositórios onde `main` não existe

## 🔐 Configurar Token do GitHub

### Obter Token

1. Acesse: https://github.com/settings/tokens
2. Clique em "Generate new token" → "Generate new token (classic)"
3. Nome: `branch-standardization`
4. Permissões: `repo` (todas)
5. Generate token
6. **Copie o token** (só aparece uma vez!)

### Configurar Token

```bash
# Opção 1: Temporário (apenas esta sessão)
export GH_TOKEN=ghp_seu_token_aqui

# Opção 2: Permanente (adicionar ao ~/.zshrc)
echo 'export GH_TOKEN=ghp_seu_token_aqui' >> ~/.zshrc
source ~/.zshrc

# Opção 3: Usar GitHub CLI (mais seguro)
gh auth login
# O GitHub CLI gerencia o token automaticamente
```

## 🎯 Fluxo Recomendado

### Passo 1: Listar Repositórios

```bash
export GH_TOKEN=seu_token
./scripts/listar_repos_nao_main.sh
```

### Passo 2: Revisar Lista

Verifique quais repositórios precisam de correção.

### Passo 3: Corrigir Este Repositório

```bash
cd ~/bni-gestao-imobiliaria
./scripts/mudar_default_branch_enterprise.sh
```

### Passo 4: (Opcional) Corrigir Todos

```bash
# CUIDADO: Isso vai modificar TODOS os seus repositórios!
./scripts/corrigir_todos_repos.sh
```

## 🔒 Segurança

### Boas Práticas

- ✅ Use token com escopo mínimo necessário (`repo`)
- ✅ Revise a lista antes de corrigir todos
- ✅ Teste em um repositório primeiro
- ✅ Mantenha backup do token em lugar seguro
- ✅ Revogue tokens não utilizados

### Verificar Token

```bash
# Verificar se token está configurado
echo $GH_TOKEN | cut -c1-10

# Testar token
curl -H "Authorization: token $GH_TOKEN" https://api.github.com/user
```

## 📊 Exemplo de Saída

### Listar Repositórios

```
🔍 Listando repositórios onde default branch ≠ 'main'...
========================================================

📦 senal88/bni-gestao-imobiliaria
   Default branch: teab

📦 senal88/outro-projeto
   Default branch: master

========================================================
📊 Resumo:
   Total de repositórios: 15
   Com default ≠ 'main': 2

⚠️  2 repositório(s) precisam de correção
```

## 🛠️ Troubleshooting

### Erro: "GH_TOKEN não configurado"

```bash
export GH_TOKEN=seu_token_aqui
```

### Erro: "Bad credentials"

Token inválido ou expirado. Gere um novo token.

### Erro: "Repository not found"

Verifique o nome do repositório e permissões do token.

### Branch 'main' não existe

Crie a branch `main` primeiro:
```bash
git checkout -b main
git push origin main
```

## 🔗 Referências

- [GitHub API - Repositories](https://docs.github.com/en/rest/repos/repos)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

