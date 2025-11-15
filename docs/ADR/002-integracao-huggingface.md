# ADR 002: Integração com Hugging Face para Dataset Público

## Status
Aceito

## Contexto
O sistema precisa compartilhar dados do portfólio imobiliário de forma pública e versionada. Os dados devem estar acessíveis para:
- Análises externas
- Reprodução de relatórios
- Colaboração com pesquisadores
- Transparência pública

## Decisão
Utilizamos o **Hugging Face Hub** para hospedar um dataset público com os dados do portfólio BNI.

## Motivação

### Vantagens do Hugging Face

1. **Versionamento Automático**
   - Git-like versionamento de datasets
   - Histórico completo de alterações
   - Facilita reprodução de análises

2. **Acessibilidade**
   - Interface web amigável
   - API REST para acesso programático
   - Download direto via Python

3. **Integração com Python**
   - Biblioteca `datasets` bem documentada
   - Sincronização simples via scripts
   - Suporte a múltiplos formatos

4. **Gratuito para Datasets Públicos**
   - Sem custos para datasets públicos
   - Armazenamento generoso
   - CDN global para downloads rápidos

5. **Comunidade e Padrões**
   - Padrão reconhecido na comunidade ML/Data Science
   - Facilita colaboração
   - Integração com outras ferramentas

### Alternativas Consideradas

1. **GitHub LFS**
   - Rejeitado: Limitações de tamanho e performance
   - Não otimizado para datasets estruturados

2. **Google Drive / Dropbox**
   - Rejeitado: Sem versionamento adequado
   - Acesso programático limitado

3. **S3 Público**
   - Rejeitado: Requer configuração de infraestrutura
   - Sem interface amigável para usuários finais

4. **Zenodo / Figshare**
   - Considerado mas rejeitado: Mais focado em publicações acadêmicas
   - Menos integração com workflows de desenvolvimento

## Consequências

### Positivas
- ✅ Versionamento automático dos dados
- ✅ Acesso público facilitado
- ✅ Integração simples com Python
- ✅ Sem custos para datasets públicos
- ✅ Padrão reconhecido na comunidade

### Negativas
- ⚠️ Dados públicos (por design, mas requer atenção a privacidade)
- ⚠️ Dependência de serviço externo (mitigado com backups locais)

## Implementação

### Estrutura do Dataset

```
senal88/bni-gestao-imobiliaria
├── propriedades.csv      # Dados principais das propriedades
├── transacoes.csv       # Histórico de transações
└── README.md            # Documentação do dataset
```

### Scripts de Sincronização

- `scripts/sync_huggingface.py`: Script principal de sincronização
- GitHub Actions workflow: `sync-huggingface.yml` para sincronização automática
- Validação de schemas antes do upload

### Fluxo de Trabalho

1. Dados processados localmente
2. Validação de schemas
3. Upload para Hugging Face via script ou GitHub Actions
4. Versionamento automático no HF Hub

## Privacidade e Segurança

- Apenas dados agregados e não sensíveis são publicados
- Informações pessoais são removidas/anonimizadas
- Valores financeiros são agregados quando necessário
- Endereços completos podem ser parcialmente ocultos

## Referências

- [Hugging Face Datasets](https://huggingface.co/docs/datasets/)
- [Hugging Face Hub](https://huggingface.co/docs/hub/)
- [Dataset Card Template](https://github.com/huggingface/datasets/blob/main/templates/README.md)

