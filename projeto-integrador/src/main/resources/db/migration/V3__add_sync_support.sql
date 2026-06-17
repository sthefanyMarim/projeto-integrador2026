ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE propriedades
    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE visitas_tecnicas
    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE encaminhamentos
    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS sync_sessions (
    sync_session_id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES usuarios (user_id) ON DELETE CASCADE,
    device_id VARCHAR(120) NOT NULL,
    status VARCHAR(40) NOT NULL,
    last_sync_token BIGINT,
    error_type VARCHAR(80),
    error_message TEXT,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMP,
    server_time TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_sessions_user_device
    ON sync_sessions (user_id, device_id, started_at DESC);

CREATE TABLE IF NOT EXISTS sync_operation_logs (
    id BIGSERIAL PRIMARY KEY,
    operation_id VARCHAR(120) NOT NULL UNIQUE,
    sync_session_id UUID NOT NULL REFERENCES sync_sessions (sync_session_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES usuarios (user_id) ON DELETE CASCADE,
    device_id VARCHAR(120) NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    action_type VARCHAR(60) NOT NULL,
    local_id VARCHAR(120),
    server_id BIGINT,
    base_version BIGINT,
    status VARCHAR(40) NOT NULL,
    error_code VARCHAR(80),
    message TEXT,
    request_payload TEXT,
    response_snapshot TEXT,
    entity_version BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_operation_logs_session
    ON sync_operation_logs (sync_session_id, id);

CREATE INDEX IF NOT EXISTS idx_sync_operation_logs_user_device
    ON sync_operation_logs (user_id, device_id, created_at DESC);

CREATE TABLE IF NOT EXISTS sync_change_logs (
    change_id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(40) NOT NULL,
    entity_id BIGINT NOT NULL,
    owner_user_id BIGINT REFERENCES usuarios (user_id) ON DELETE SET NULL,
    changed_by_user_id BIGINT REFERENCES usuarios (user_id) ON DELETE SET NULL,
    change_type VARCHAR(20) NOT NULL,
    entity_version BIGINT,
    snapshot TEXT,
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_change_logs_relevancia
    ON sync_change_logs (change_id, owner_user_id);

CREATE TABLE IF NOT EXISTS sync_device_state (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES usuarios (user_id) ON DELETE CASCADE,
    device_id VARCHAR(120) NOT NULL,
    last_sync_token BIGINT,
    last_session_id UUID,
    last_synced_at TIMESTAMP,
    app_version VARCHAR(40),
    UNIQUE (user_id, device_id)
);

CREATE TABLE IF NOT EXISTS sync_attachments (
    attachment_id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES usuarios (user_id) ON DELETE CASCADE,
    device_id VARCHAR(120) NOT NULL,
    client_attachment_id VARCHAR(120),
    purpose VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    storage_url VARCHAR(500) NOT NULL,
    content_type VARCHAR(120),
    file_size BIGINT,
    linked_entity_type VARCHAR(40),
    linked_entity_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    linked_at TIMESTAMP,
    UNIQUE (user_id, device_id, client_attachment_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_attachments_user_device
    ON sync_attachments (user_id, device_id, created_at DESC);
