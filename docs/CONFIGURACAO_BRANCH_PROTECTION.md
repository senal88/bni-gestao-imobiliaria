# 🔒 Configuração de Proteção de Branch - GitHub Rulesets

Guia para configurar proteções na branch `main` usando GitHub Rulesets.

## 🎯 Configuração Recomendada para Branch `main`

### Ruleset Name
```
Proteção Branch Main
```

### Enforcement status
- ✅ **Active** (ativado)

### Target branches
- **Branch targeting criteria**: `main`
- Ou usar padrão: `refs/heads/main`

## ✅ Regras Recomendadas para Este Projeto

### 1. Require a pull request before merging ✅
**Recomendado**: Ativar

**Configurações:**
- ✅ Require approvals: **1**
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners (se tiver CODEOWNERS)
- ⚠️ Require last push approval (opcional)

**Por quê**: Garante que mudanças sejam revisadas antes de merge.

### 2. Require status checks to pass ✅
**Recomendado**: Ativar

**Status checks obrigatórios:**
- `validate-schemas` (workflow de validação)
- `deploy-postgres` (opcional, pode ser não-bloqueante)

**Por quê**: Garante que validações passem antes de merge.

### 3. Block force pushes ✅
**Recomendado**: Ativar

**Por quê**: Previne perda de histórico.

### 4. Require linear history ⚠️
**Recomendado**: Desativar (para este projeto)

**Por quê**: Permite merge commits, mais flexível para desenvolvimento.

### 5. Restrict deletions ✅
**Recomendado**: Ativar

**Por quê**: Previne exclusão acidental da branch principal.

### 6. Restrict updates ⚠️
**Recomendado**: Desativar (ou ativar se quiser forçar PRs sempre)

**Por quê**: Se ativado, força que TODAS as mudanças sejam via PR.

### 7. Require signed commits ⚠️
**Recomendado**: Desativar (opcional)

**Por quê**: Requer configuração de GPG, pode ser complexo.

### 8. Require deployments to succeed ⚠️
**Recomendado**: Desativar (para este projeto)

**Por quê**: Deploy pode falhar por razões externas, não deve bloquear merge.

## 📋 Configuração Mínima Recomendada

Para começar, configure pelo menos:

1. ✅ **Require a pull request before merging**
   - Require approvals: 1

2. ✅ **Require status checks to pass**
   - Adicionar: `validate-schemas`

3. ✅ **Block force pushes**

4. ✅ **Restrict deletions**

## 🔧 Configuração Via GitHub CLI

Se preferir configurar via CLI:

```bash
# Autenticar no GitHub CLI
gh auth login

# Criar ruleset (exemplo básico)
gh api repos/senal88/bni-gestao-imobiliaria/rulesets \
  --method POST \
  -f name="Proteção Branch Main" \
  -f target="branch" \
  -f enforcement="active" \
  -f conditions='{"ref_name":{"include":["refs/heads/main"]}}' \
  -f rules='[{"type":"pull_request","parameters":{"required_approving_review_count":1}},{"type":"non_fast_forward"},{"type":"deletion"}]'
```

## 📝 Exemplo de Configuração Completa

### Ruleset Name
```
Proteção Branch Main - BNI Gestão Imobiliária
```

### Target branches
- Padrão: `main`
- Ou: `refs/heads/main`

### Rules (Marcar)

- ✅ **Require a pull request before merging**
  - Require approvals: **1**
  - Dismiss stale approvals: ✅

- ✅ **Require status checks to pass**
  - Status checks: `validate-schemas`

- ✅ **Block force pushes**

- ✅ **Restrict deletions**

- ❌ Require linear history (desmarcar)
- ❌ Restrict updates (desmarcar - permite push direto se necessário)
- ❌ Require signed commits (desmarcar)
- ❌ Require deployments to succeed (desmarcar)

### Bypass list
- Deixar vazio (ou adicionar seu usuário se quiser bypass)

## 🎯 Workflow Após Configuração

Com essas proteções ativas:

1. **Desenvolvimento**: Trabalhar em branches feature
2. **Pull Request**: Criar PR para `main`
3. **Validação**: GitHub Actions executam automaticamente
4. **Aprovação**: Pelo menos 1 aprovação necessária
5. **Merge**: Apenas após aprovação e checks passarem

## ⚠️ Importante

- **Bypass list**: Se você for o único desenvolvedor, pode adicionar seu usuário ao bypass para agilidade
- **Status checks**: Certifique-se de que os workflows estão funcionando antes de torná-los obrigatórios
- **Aprovações**: Se trabalha sozinho, pode configurar auto-approval ou adicionar-se ao bypass

## 🔗 Referências

- [GitHub Rulesets Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/managing-a-branch-protection-rule)

