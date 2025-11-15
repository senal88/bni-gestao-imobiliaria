# 🔐 GH_TOKEN no 1Password

Documentação sobre o token GitHub (GH_TOKEN) configurado nos cofres do 1Password.

## 📋 Status Atual

✅ **GH_TOKEN oficializado em ambos os cofres:**

- **Cofre `1p_vps`**: Item "GitHub Personal Access Token" (ID: `6wyjxojyqsdblpbjypxwhkx43y`)
- **Cofre `1p_macos`**: Item "GH_TOKEN" (ID: `3wz5r6ujqtyeggfasdfns2rsli`)

## 🔍 Verificar Token

### No macOS

```bash
# Verificar se existe
op item list --vault 1p_macos | grep GH_TOKEN

# Obter token
op item get GH_TOKEN --vault 1p_macos --fields label=token

# Usar em variável de ambiente
export GH_TOKEN=$(op item get GH_TOKEN --vault 1p_macos --fields label=token)
```

### Na VPS

```bash
# Verificar se existe
op item list --vault 1p_vps | grep "GitHub Personal Access Token"

# Obter token
op item get "GitHub Personal Access Token" --vault 1p_vps --fields label=token

# Usar em variável de ambiente
export GH_TOKEN=$(op item get "GitHub Personal Access Token" --vault 1p_vps --fields label=token)
```

## 🚀 Uso Automático

O script `load_secrets_1p.sh` já está configurado para carregar o GH_TOKEN automaticamente:

```bash
# No macOS
./scripts/load_secrets_1p.sh
# O GH_TOKEN será carregado do cofre 1p_macos

# Na VPS
./scripts/load_secrets_1p.sh
# O GH_TOKEN será carregado do cofre 1p_vps
```

O token será adicionado ao arquivo `.env` automaticamente.

## 📝 Scripts Disponíveis

### `scripts/oficializar_gh_token.sh`

Verifica se o GH_TOKEN está disponível em ambos os cofres e fornece instruções.

```bash
./scripts/oficializar_gh_token.sh
```

### `scripts/criar_gh_token_macos.sh`

Cria o item GH_TOKEN no cofre `1p_macos` baseado no token do cofre `1p_vps`.

```bash
./scripts/criar_gh_token_macos.sh
```

## 🔄 Sincronizar Token

Se o token no cofre `1p_vps` for atualizado, você pode sincronizar para o cofre `1p_macos`:

```bash
# 1. Obter token atualizado do cofre VPS
TOKEN=$(op item get "GitHub Personal Access Token" --vault 1p_vps --fields label=token)

# 2. Atualizar item no cofre macOS
op item edit GH_TOKEN --vault 1p_macos field[label="token"][value]="$TOKEN"
```

Ou simplesmente execute:

```bash
./scripts/criar_gh_token_macos.sh
```

## 🎯 Uso em Scripts

### Scripts Enterprise (Branch Management)

Os scripts de gerenciamento de branches GitHub já estão preparados para usar o GH_TOKEN:

```bash
# Configurar token
export GH_TOKEN=$(op item get GH_TOKEN --vault 1p_macos --fields label=token)

# Executar scripts
./scripts/mudar_default_branch_enterprise.sh
./scripts/listar_repos_nao_main.sh
./scripts/corrigir_todos_repos.sh
```

### GitHub Actions

Para usar o token em GitHub Actions, adicione como secret:

1. Acesse: https://github.com/senal88/bni-gestao-imobiliaria/settings/secrets/actions
2. Clique em "New repository secret"
3. Nome: `GH_TOKEN`
4. Valor: Obtenha do 1Password:
   ```bash
   op item get GH_TOKEN --vault 1p_macos --fields label=token
   ```

## 🔒 Segurança

- ✅ Token armazenado de forma segura no 1Password
- ✅ Diferentes cofres para diferentes ambientes
- ✅ Não commitado no repositório
- ✅ Acesso controlado via 1Password CLI

## 📚 Referências

- [GitHub Personal Access Tokens](https://github.com/settings/tokens)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [Documentação de Automação em Escala](./AUTOMACAO_ESCALA.md)

