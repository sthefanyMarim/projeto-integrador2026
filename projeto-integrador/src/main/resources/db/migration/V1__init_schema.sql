CREATE TYPE tipo_usuario AS ENUM ('ADMIN', 'TECNICO');
CREATE TYPE tipo_visita AS ENUM ('ROTINA', 'DIAGNOSTICO', 'ACOMPANHAMENTO', 'RETORNO', 'EMERGENCIAL');
CREATE TYPE status_visita AS ENUM ('AGENDADA', 'CONCLUIDA', 'CANCELADA', 'ATRASADA');
CREATE TYPE urgencia_tipo AS ENUM ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA');
CREATE TYPE criticidade_tipo AS ENUM ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA');
CREATE TYPE verificacao_tipo AS ENUM ('VISITA', 'LIGACAO', 'EMAIL', 'OUTRO');
CREATE TYPE prioridade_tipo AS ENUM ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA');
CREATE TYPE status_encaminhamento AS ENUM ('PENDENTE', 'ATRASADO', 'CONCLUIDO', 'CANCELADO');

CREATE TABLE usuarios (
    user_id       BIGSERIAL    PRIMARY KEY,
    nome          VARCHAR(150) NOT NULL,
    matricula     VARCHAR(20)  NOT NULL UNIQUE,
    email         VARCHAR(150) NOT NULL UNIQUE,
    senha         VARCHAR(255) NOT NULL,
    telefone      VARCHAR(20),
    tipo          tipo_usuario NOT NULL,
    foto_url      VARCHAR(500),
    ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMP    NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP
);

CREATE TABLE refresh_tokens (
    id        BIGSERIAL                PRIMARY KEY,
    token     VARCHAR(512)             NOT NULL UNIQUE,
    user_id   BIGINT                   NOT NULL REFERENCES usuarios (user_id) ON DELETE CASCADE,
    expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
    revogado  BOOLEAN                  NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE propriedades (
    prop_id           BIGSERIAL      PRIMARY KEY,
    nome              VARCHAR(150)   NOT NULL,
    nome_proprietario VARCHAR(150)   NOT NULL,
    telefone          VARCHAR(20),
    endereco          VARCHAR(255),
    municipio         VARCHAR(100),
    estado            VARCHAR(2)     NOT NULL DEFAULT 'RS',
    latitude          NUMERIC(10, 7),
    longitude         NUMERIC(10, 7),
    tipo_producao     VARCHAR(100),
    ativa             BOOLEAN        NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMP      NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMP
);

CREATE TABLE visitas_tecnicas (
    visita_id      BIGSERIAL     PRIMARY KEY,
    user_id        BIGINT        NOT NULL REFERENCES usuarios (user_id),
    prop_id        BIGINT        NOT NULL REFERENCES propriedades (prop_id),
    data_visita    DATE          NOT NULL,
    hora_visita    TIME          NOT NULL,
    tipo_visita    tipo_visita   NOT NULL,
    tema_principal VARCHAR(200),
    observacoes    TEXT,
    status_visita  status_visita NOT NULL DEFAULT 'AGENDADA',
    urgencia       urgencia_tipo NOT NULL DEFAULT 'BAIXA',
    criado_em      TIMESTAMP     NOT NULL DEFAULT NOW(),
    atualizado_em  TIMESTAMP
);

CREATE TABLE diagnosticos (
    diagnostico_id BIGSERIAL        PRIMARY KEY,
    visita_id      BIGINT           NOT NULL REFERENCES visitas_tecnicas (visita_id) ON DELETE CASCADE,
    categoria      VARCHAR(100)     NOT NULL,
    criticidade    criticidade_tipo NOT NULL DEFAULT 'BAIXA',
    observacoes    TEXT,
    criado_em      TIMESTAMP        NOT NULL DEFAULT NOW()
);

CREATE TABLE encaminhamentos (
    encaminhamento_id BIGSERIAL             PRIMARY KEY,
    visita_id         BIGINT                NOT NULL REFERENCES visitas_tecnicas (visita_id) ON DELETE CASCADE,
    acao_realizada    TEXT                  NOT NULL,
    responsavel       VARCHAR(150),
    prazo             DATE,
    verificacao       verificacao_tipo,
    prioridade        prioridade_tipo       NOT NULL DEFAULT 'MEDIA',
    status            status_encaminhamento NOT NULL DEFAULT 'PENDENTE',
    concluido_em      TIMESTAMP,
    criado_em         TIMESTAMP             NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMP
);

CREATE TABLE audit_logs (
    id            BIGSERIAL    PRIMARY KEY,
    tabela        VARCHAR(100) NOT NULL,
    registro_id   BIGINT       NOT NULL,
    acao          VARCHAR(10)  NOT NULL,
    dados_antigos JSONB,
    dados_novos   JSONB,
    alterado_por  BIGINT REFERENCES usuarios (user_id) ON DELETE SET NULL,
    alterado_em   TIMESTAMP    NOT NULL DEFAULT NOW(),
    ip_origem     VARCHAR(45)
);

CREATE INDEX idx_refresh_tokens_token   ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_user    ON refresh_tokens (user_id);
CREATE INDEX idx_propriedades_nome      ON propriedades (nome);
CREATE INDEX idx_propriedades_municipio ON propriedades (municipio);
CREATE INDEX idx_visitas_usuario        ON visitas_tecnicas (user_id);
CREATE INDEX idx_visitas_propriedade    ON visitas_tecnicas (prop_id);
CREATE INDEX idx_visitas_data           ON visitas_tecnicas (data_visita);
CREATE INDEX idx_visitas_status         ON visitas_tecnicas (status_visita);
CREATE INDEX idx_diagnosticos_visita    ON diagnosticos (visita_id);
CREATE INDEX idx_encaminhamentos_visita ON encaminhamentos (visita_id);
CREATE INDEX idx_encaminhamentos_status ON encaminhamentos (status);
CREATE INDEX idx_encaminhamentos_prazo  ON encaminhamentos (prazo);
CREATE INDEX idx_audit_tabela           ON audit_logs (tabela);
CREATE INDEX idx_audit_registro_id      ON audit_logs (registro_id);
CREATE INDEX idx_audit_alterado_por     ON audit_logs (alterado_por);
CREATE INDEX idx_audit_alterado_em      ON audit_logs (alterado_em DESC);
CREATE INDEX idx_audit_dados_novos      ON audit_logs USING gin (dados_novos);
CREATE INDEX idx_audit_dados_antigos    ON audit_logs USING gin (dados_antigos);

CREATE VIEW vw_audit_logs AS
SELECT al.id,
       al.tabela,
       al.registro_id,
       al.acao,
       al.dados_antigos,
       al.dados_novos,
       u.nome AS alterado_por_nome,
       u.matricula AS alterado_por_matricula,
       al.alterado_em,
       al.ip_origem
FROM audit_logs al
LEFT JOIN usuarios u ON u.user_id = al.alterado_por;
