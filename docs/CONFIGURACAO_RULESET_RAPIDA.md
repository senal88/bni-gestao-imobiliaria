# ⚡ Configuração Rápida - GitHub Ruleset para `main`

## 🎯 Configuração Mínima Recomendada

### Passo a Passo na Interface do GitHub

1. **Ruleset Name**: `Proteção Branch Main`

2. **Enforcement status**: ✅ **Active**

3. **Target branches**:
   - Selecione: **Branch name pattern**
   - Digite: `main`

4. **Rules** (marcar apenas estes):

   ✅ **Require a pull request before merging**
   - Require approvals: `1`
   - ✅ Dismiss stale pull request approvals when new commits are pushed

   ✅ **Require status checks to pass**
   - Adicionar: `validate-schemas`

   ✅ **Block force pushes**

   ✅ **Restrict deletions**

5. **Bypass list**:
   - Deixar vazio (ou adicionar `senal88` se quiser bypass para você)

6. **Criar Ruleset**

## 📋 Checklist Rápido

- [ ] Ruleset Name: `Proteção Branch Main`
- [ ] Enforcement: Active
- [ ] Target: `main`
- [ ] ✅ Require PR before merging (1 approval)
- [ ] ✅ Require status checks (`validate-schemas`)
- [ ] ✅ Block force pushes
- [ ] ✅ Restrict deletions
- [ ] Bypass list: vazio ou seu usuário

## ⚠️ Importante

- Configure **após** mudar a branch padrão para `main`
- Teste os workflows antes de torná-los obrigatórios
- Se trabalha sozinho, considere adicionar-se ao bypass list

