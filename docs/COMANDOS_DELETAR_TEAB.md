# 🗑️ Comandos para Deletar Branch 'teab' via CLI

## ⚠️ Problema

Não é possível deletar `teab` porque ainda é a branch padrão no GitHub.

## ✅ Solução: Mudar Branch Padrão Primeiro

### Opção 1: Usar GitHub CLI (Recomendado)

```bash
# 1. Instalar GitHub CLI (se não tiver)
brew install gh

# 2. Autenticar
gh auth login

# 3. Executar script automatizado
./scripts/mudar_branch_padrao_e_deletar_teab.sh
```

**OU manualmente:**

```bash
# Mudar branch padrão
gh api repos/senal88/bni-gestao-imobiliaria --method PATCH -f default_branch=main

# Aguardar alguns segundos
sleep 3

# Deletar branch teab
git push origin --delete teab

# Verificar
git remote show origin | grep "HEAD branch"
```

### Opção 2: Usar curl com Token

```bash
# 1. Obter token em: https://github.com/settings/tokens
#    Permissões: repo

# 2. Configurar token
export GITHUB_TOKEN=seu_token_aqui

# 3. Executar script
./scripts/mudar_branch_padrao_curl.sh
```

**OU manualmente:**

```bash
# Configurar token
export GITHUB_TOKEN=seu_token_aqui

# Mudar branch padrão
curl -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"default_branch":"main"}' \
  https://api.github.com/repos/senal88/bni-gestao-imobiliaria

# Aguardar
sleep 3

# Deletar branch teab
git push origin --delete teab
```

### Opção 3: Comandos Diretos (GitHub CLI)

```bash
# Tudo em um comando
gh api repos/senal88/bni-gestao-imobiliaria --method PATCH -f default_branch=main && \
sleep 3 && \
git push origin --delete teab && \
echo "✅ Branch padrão mudada e 'teab' deletada!"
```

## 🔍 Verificação

Após executar, verificar:

```bash
# Ver branch padrão remota
git remote show origin | grep "HEAD branch"
# Deve mostrar: HEAD branch: main

# Ver branches remotas
git branch -r
# Não deve aparecer origin/teab
```

## 📝 Troubleshooting

### Erro: "refusing to delete the current branch"

**Causa**: Branch ainda é a padrão no GitHub.

**Solução**: Mudar branch padrão primeiro (veja comandos acima).

### Erro: "GitHub CLI não encontrado"

**Solução**: 
```bash
brew install gh
gh auth login
```

### Erro: "Not authenticated"

**Solução**:
```bash
gh auth login
# Ou configurar token:
export GITHUB_TOKEN=seu_token
```

## ✅ Checklist

- [ ] Branch padrão mudada para `main` no GitHub
- [ ] Branch `teab` deletada remotamente
- [ ] Verificação: `git remote show origin` mostra `HEAD branch: main`
- [ ] GitHub Actions configurados para `main`

