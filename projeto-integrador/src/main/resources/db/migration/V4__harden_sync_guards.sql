ALTER TABLE sync_attachments
    ADD COLUMN IF NOT EXISTS content_hash VARCHAR(128);

ALTER TABLE sync_operation_logs
    DROP CONSTRAINT IF EXISTS sync_operation_logs_operation_id_key;

ALTER TABLE sync_operation_logs
    ADD CONSTRAINT uq_sync_operation_logs_device_operation
        UNIQUE (user_id, device_id, operation_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_sync_sessions_active_per_device
    ON sync_sessions (user_id, device_id)
    WHERE status IN ('STARTED', 'PROCESSING_OPERATIONS', 'PULLING_SERVER_CHANGES');
