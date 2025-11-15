# 🌿 Explicação sobre a Branch "teab"

## 🔍 Situação Atual

### O que descobrimos:

1. **Branch `teab` é a branch padrão no GitHub**
   - `origin/HEAD -> origin/teab` significa que `teab` está configurada como branch padrão
   - Isso aconteceu provavelmente quando o repositório foi criado

2. **Workflows GitHub Actions estão configurados para `main`/`master`**
   - Os workflows esperam pushes em `main` ou `master`
   - Mas a branch padrão é `teab`
   - **Resultado**: Os workflows não vão executar automaticamente!

3. **Histórico do repositório:**
   ```
   f96524f (origin/copilot/gestao-imobiliaria-bni) Initial plan
   081837f (HEAD -> teab, origin/teab, origin/HEAD) Initial commit
   ```

## 🤔 Por que "teab"?

O nome `teab` pode ser:
- Um código interno ou sigla
- Um nome temporário criado durante o desenvolvimento inicial
- Uma referência específica do projeto

**Não há problema em usar esse nome**, mas é melhor seguir convenções padrão.

## ⚠️ Problema Identificado

### Inconsistência Entre Branch Padrão e Workflows

- **Branch padrão**: `teab`
- **Workflows esperam**: `main` ou `master`
- **Consequência**: GitHub Actions não executam automaticamente em pushes para `teab`

## ✅ Soluções

### Opção 1: Renomear `teab` para `main` (Recomendado)

**Vantagens:**
- ✅ Segue convenções padrão
- ✅ Workflows já estão configurados para `main`
- ✅ Mais profissional e padrão da indústria

**Passos:**

```bash
# 1. Renomear branch local
git branch -m teab main

# 2. Fazer commit de todas as mudanças
git add .
git commit -m "feat: estrutura completa do projeto BNI Gestão Imobiliária"

# 3. Enviar main para GitHub
git push origin main

# 4. Definir main como padrão no GitHub
# Via web: Settings > Branches > Default branch > main > Update
# Ou via CLI:
gh api repos/senal88/bni-gestao-imobiliaria --method PATCH -f default_branch=main

# 5. Deletar branch teab remota (opcional)
git push origin --delete teab
```

### Opção 2: Atualizar Workflows para Usar `teab`

**Vantagens:**
- ✅ Mantém o nome atual
- ✅ Não precisa renomear branch

**Desvantagens:**
- ⚠️ Nome não segue convenções padrão
- ⚠️ Pode confundir colaboradores

**Passos:**

```bash
# Atualizar todos os workflows para incluir 'teab'
# Editar .github/workflows/*.yml e adicionar 'teab' nas branches
```

### Opção 3: Criar `main` e Manter `teab` para Desenvolvimento

**Vantagens:**
- ✅ Mantém histórico
- ✅ Separa desenvolvimento de produção

**Passos:**

```bash
# 1. Criar main a partir de teab
git checkout -b main

# 2. Fazer commit
git add .
git commit -m "feat: estrutura completa do projeto BNI Gestão Imobiliária"

# 3. Enviar main
git push origin main

# 4. Definir main como padrão no GitHub
# Via web: Settings > Branches > Default branch

# 5. Manter teab para desenvolvimento
git checkout teab
```

## 🎯 Recomendação Final

**Recomendo a Opção 1**: Renomear `teab` para `main`

**Motivos:**
1. ✅ Workflows já estão configurados para `main`
2. ✅ Segue convenções padrão da indústria
3. ✅ Mais fácil para colaboradores entenderem
4. ✅ GitHub Actions funcionarão automaticamente

## 📋 Checklist de Migração

Se escolher renomear para `main`:

- [ ] Renomear branch local: `git branch -m teab main`
- [ ] Fazer commit de todas as mudanças
- [ ] Enviar para GitHub: `git push origin main`
- [ ] Definir `main` como padrão no GitHub (via web ou CLI)
- [ ] Verificar workflows executando
- [ ] (Opcional) Deletar branch `teab` remota

## 🔧 Script de Migração Automática

Posso criar um script que faz tudo automaticamente. Quer que eu crie?

## 📚 Referências

- [GitHub: Changing the default branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch)
- [Conventional Commits](https://www.conventionalcommits.org/)

