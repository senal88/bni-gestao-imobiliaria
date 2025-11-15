-- ============================================
-- BNI Gestão Imobiliária - Schema PostgreSQL
-- ============================================
-- Script de inicialização do banco de dados
-- Este arquivo é executado automaticamente pelo Docker Compose

-- ============================================
-- Extensões
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Para busca de texto

-- ============================================
-- Tabela: propriedades
-- ============================================
CREATE TABLE IF NOT EXISTS propriedades (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    codigo_cc VARCHAR(50),
    nome VARCHAR(500) NOT NULL,
    endereco TEXT,
    cidade VARCHAR(100),
    estado VARCHAR(2),
    cep VARCHAR(10),
    tipo_propriedade VARCHAR(50),
    tipo_estoque VARCHAR(50),
    area_total DECIMAL(10, 2),
    area_construida DECIMAL(10, 2),
    valor_avaliacao DECIMAL(12, 2),
    valor_2023 DECIMAL(12, 2),
    valor_2024 DECIMAL(12, 2),
    preco_promessa DECIMAL(12, 2),
    status VARCHAR(100) DEFAULT 'Concluído',
    data_aquisicao DATE,
    data_habite_se_prevista DATE,
    observacoes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_valor_positivo CHECK (valor_avaliacao IS NULL OR valor_avaliacao >= 0),
    CONSTRAINT chk_area_positiva CHECK (area_total IS NULL OR area_total >= 0 AND area_construida IS NULL OR area_construida >= 0)
);

-- ============================================
-- Tabela: transacoes
-- ============================================
CREATE TABLE IF NOT EXISTS transacoes (
    id SERIAL PRIMARY KEY,
    propriedade_id INTEGER NOT NULL REFERENCES propriedades(id) ON DELETE CASCADE,
    tipo_transacao VARCHAR(50) NOT NULL,
    valor DECIMAL(12, 2) NOT NULL,
    data_transacao DATE NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_tipo_transacao CHECK (tipo_transacao IN ('compra', 'venda', 'aluguel', 'manutencao', 'reforma', 'outro'))
);

-- ============================================
-- Tabela: relatorios_ifrs
-- ============================================
CREATE TABLE IF NOT EXISTS relatorios_ifrs (
    id SERIAL PRIMARY KEY,
    periodo VARCHAR(20) NOT NULL,
    tipo_relatorio VARCHAR(100) NOT NULL,
    arquivo_path VARCHAR(500),
    arquivo_hash VARCHAR(64), -- SHA-256
    parametros JSONB DEFAULT '{}',
    data_geracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pendente',

    CONSTRAINT chk_status CHECK (status IN ('pendente', 'processando', 'concluido', 'erro'))
);

-- ============================================
-- Tabela: sincronizacoes
-- ============================================
CREATE TABLE IF NOT EXISTS sincronizacoes (
    id SERIAL PRIMARY KEY,
    origem VARCHAR(50) NOT NULL, -- 'huggingface', 'obsidian', 'api'
    tipo_sincronizacao VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pendente',
    registros_processados INTEGER DEFAULT 0,
    registros_inseridos INTEGER DEFAULT 0,
    registros_atualizados INTEGER DEFAULT 0,
    registros_erro INTEGER DEFAULT 0,
    mensagem_erro TEXT,
    metadata JSONB DEFAULT '{}',
    iniciado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    concluido_em TIMESTAMP,

    CONSTRAINT chk_origem CHECK (origem IN ('huggingface', 'obsidian', 'api', 'manual')),
    CONSTRAINT chk_status_sync CHECK (status IN ('pendente', 'processando', 'concluido', 'erro'))
);

-- ============================================
-- Índices
-- ============================================

-- Propriedades
CREATE INDEX IF NOT EXISTS idx_propriedades_codigo ON propriedades(codigo);
CREATE INDEX IF NOT EXISTS idx_propriedades_status ON propriedades(status);
CREATE INDEX IF NOT EXISTS idx_propriedades_cidade ON propriedades(cidade);
CREATE INDEX IF NOT EXISTS idx_propriedades_tipo ON propriedades(tipo_propriedade);
CREATE INDEX IF NOT EXISTS idx_propriedades_valor ON propriedades(valor_avaliacao);
CREATE INDEX IF NOT EXISTS idx_propriedades_metadata ON propriedades USING GIN(metadata);

-- Transações
CREATE INDEX IF NOT EXISTS idx_transacoes_propriedade ON transacoes(propriedade_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_data ON transacoes(data_transacao);
CREATE INDEX IF NOT EXISTS idx_transacoes_tipo ON transacoes(tipo_transacao);
CREATE INDEX IF NOT EXISTS idx_transacoes_categoria ON transacoes(categoria);

-- Relatórios IFRS
CREATE INDEX IF NOT EXISTS idx_relatorios_periodo ON relatorios_ifrs(periodo);
CREATE INDEX IF NOT EXISTS idx_relatorios_status ON relatorios_ifrs(status);
CREATE INDEX IF NOT EXISTS idx_relatorios_tipo ON relatorios_ifrs(tipo_relatorio);

-- Sincronizações
CREATE INDEX IF NOT EXISTS idx_sincronizacoes_origem ON sincronizacoes(origem);
CREATE INDEX IF NOT EXISTS idx_sincronizacoes_status ON sincronizacoes(status);
CREATE INDEX IF NOT EXISTS idx_sincronizacoes_data ON sincronizacoes(iniciado_em);

-- ============================================
-- Funções e Triggers
-- ============================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at em propriedades
DROP TRIGGER IF EXISTS update_propriedades_updated_at ON propriedades;
CREATE TRIGGER update_propriedades_updated_at
    BEFORE UPDATE ON propriedades
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Views Úteis
-- ============================================

-- View: Resumo do Portfólio
CREATE OR REPLACE VIEW vw_resumo_portfolio AS
SELECT
    COUNT(*) as total_propriedades,
    COUNT(CASE WHEN status = 'ativa' THEN 1 END) as propriedades_ativas,
    SUM(valor_avaliacao) as valor_total_portfolio,
    AVG(valor_avaliacao) as valor_medio_propriedade,
    SUM(area_total) as area_total_portfolio,
    SUM(area_construida) as area_construida_total
FROM propriedades;

-- View: Propriedades por Cidade
CREATE OR REPLACE VIEW vw_propriedades_por_cidade AS
SELECT
    cidade,
    estado,
    COUNT(*) as quantidade,
    SUM(valor_avaliacao) as valor_total,
    AVG(valor_avaliacao) as valor_medio
FROM propriedades
WHERE cidade IS NOT NULL
GROUP BY cidade, estado
ORDER BY quantidade DESC;

-- View: Transações Recentes
CREATE OR REPLACE VIEW vw_transacoes_recentes AS
SELECT
    t.id,
    t.tipo_transacao,
    t.valor,
    t.data_transacao,
    p.codigo as propriedade_codigo,
    p.nome as propriedade_nome
FROM transacoes t
JOIN propriedades p ON t.propriedade_id = p.id
ORDER BY t.data_transacao DESC, t.created_at DESC
LIMIT 100;

-- ============================================
-- Dados Iniciais (Opcional)
-- ============================================

-- Comentários nas tabelas
COMMENT ON TABLE propriedades IS 'Cadastro completo das propriedades do portfólio BNI';
COMMENT ON TABLE transacoes IS 'Registro de todas as transações financeiras relacionadas às propriedades';
COMMENT ON TABLE relatorios_ifrs IS 'Controle de geração e armazenamento de relatórios IFRS';
COMMENT ON TABLE sincronizacoes IS 'Log de sincronizações com sistemas externos';

-- ============================================
-- Fim do Schema
-- ============================================

