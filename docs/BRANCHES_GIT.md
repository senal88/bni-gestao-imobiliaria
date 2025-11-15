# 🌿 Guia de Branches Git - BNI Gestão Imobiliária

## 📋 Branches Atuais

### Branches Locais
- `teab` - Branch atual de desenvolvimento

### Branches Remotas
- `origin/teab` - Branch remota correspondente
- `origin/copilot/gestao-imobiliaria-bni` - Branch criada pelo GitHub Copilot
- `origin/main` ou `origin/master` - Branch principal (se existir)

## 🤔 O que é a branch "teab"?

A branch `teab` parece ser uma branch de desenvolvimento criada para trabalhar no projeto. O nome pode ser:
- Uma sigla ou código interno
- Um nome temporário de desenvolvimento
- Uma referência a algo específico do projeto

**Importante**: Esta não é necessariamente a branch padrão do repositório. A branch padrão geralmente é `main` ou `master`.

## 🔄 Qual Deve Ser a Branch Padrão?

### Convenções Padrão

1. **`main`** - Padrão moderno (recomendado)
   - Usado pela maioria dos repositórios novos
   - GitHub mudou o padrão de `master` para `main` em 2020

2. **`master`** - Padrão antigo
   - Ainda usado em muitos repositórios
   - Funcionalmente igual ao `main`

3. **`develop`** ou `dev`** - Para desenvolvimento
   - Usado em workflows Git Flow
   - Branch de desenvolvimento contínuo

### Para Este Projeto

Recomendamos usar **`main`** como branch padrão, seguindo as melhores práticas modernas.

## 🔧 Como Mudar para `main` como Branch Padrão

### Opção 1: Renomear Branch `teab` para `main`

```bash
# No seu Mac
cd ~/bni-gestao-imobiliaria

# Renomear branch local
git branch -m teab main

# Se já existe main, fazer merge primeiro
git checkout -b main
git merge teab

# Enviar nova branch para GitHub
git push origin main

# Definir como padrão no GitHub (via interface web ou CLI)
# Ou deletar teab remota
git push origin --delete teab
```

### Opção 2: Criar Branch `main` e Fazer Merge

```bash
# Criar branch main a partir de teab
git checkout -b main

# Fazer commit de todas as mudanças
git add .
git commit -m "feat: estrutura completa do projeto BNI Gestão Imobiliária"

# Enviar para GitHub
git push origin main

# Definir main como padrão no GitHub
# Settings > Branches > Default branch > main
```

### Opção 3: Manter `teab` e Criar `main` Separada

```bash
# Criar main a partir de teab
git checkout -b main teab

# Enviar main para GitHub
git push origin main

# Manter teab para desenvolvimento
git checkout teab
```

## 📊 Estrutura Recomendada de Branches

### Workflow Simples (Recomendado para este projeto)

```
main (produção)
  └── teab ou develop (desenvolvimento)
```

### Workflow Git Flow (Para projetos maiores)

```
main (produção)
  └── develop (desenvolvimento)
      ├── feature/nova-funcionalidade
      ├── feature/integracao-hf
      └── hotfix/correcao-urgente
```

## 🎯 Recomendação para Este Projeto

### Estrutura Sugerida

1. **`main`** - Branch principal (produção)
   - Código estável e testado
   - Deploy automático via GitHub Actions
   - Protegida contra push direto (opcional)

2. **`develop`** ou manter `teab`** - Branch de desenvolvimento
   - Desenvolvimento contínuo
   - Testes e validações
   - Merge para `main` quando estável

### Passos Recomendados

```bash
# 1. Criar branch main
git checkout -b main

# 2. Fazer commit de tudo
git add .
git commit -m "feat: estrutura completa do projeto BNI Gestão Imobiliária"

# 3. Enviar main para GitHub
git push origin main

# 4. No GitHub: Settings > Branches > Default branch > main

# 5. Atualizar GitHub Actions para usar 'main' em vez de 'teab'
# Editar .github/workflows/*.yml e trocar 'teab' por 'main'
```

## 🔍 Verificar Branch Padrão no GitHub

### Via Interface Web

1. Acesse: `https://github.com/senal88/bni-gestao-imobiliaria/settings/branches`
2. Veja qual branch está marcada como "Default branch"

### Via CLI

```bash
# Ver branch padrão remota
git remote show origin | grep "HEAD branch"

# Ou usar GitHub CLI
gh repo view senal88/bni-gestao-imobiliaria --json defaultBranchRef
```

## ⚙️ Atualizar GitHub Actions para Usar `main`

Se mudar para `main`, atualize os workflows:

```yaml
# Em .github/workflows/*.yml
on:
  push:
    branches:
      - main  # Trocar 'teab' por 'main'
      - master
```

## 📝 Resumo

- **`teab`** é uma branch de desenvolvimento atual
- **Não é necessariamente a branch padrão** do repositório
- **Recomendação**: Usar `main` como branch padrão
- **Ação**: Criar `main` e configurar como padrão no GitHub

## 🔗 Referências

- [Git Branching Guide](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows)
- [GitHub Default Branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch)

