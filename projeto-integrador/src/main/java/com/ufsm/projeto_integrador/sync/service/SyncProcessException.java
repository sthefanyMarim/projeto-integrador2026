package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import lombok.Getter;
import tools.jackson.databind.JsonNode;

@Getter
public class SyncProcessException extends RuntimeException {

    private final SyncOperationStatus status;
    private final SyncErrorCode code;
    private final Long serverId;
    private final Long entityVersion;
    private final JsonNode snapshot;

    private SyncProcessException(
            SyncOperationStatus status,
            SyncErrorCode code,
            String message,
            Long serverId,
            Long entityVersion,
            JsonNode snapshot
    ) {
        super(message);
        this.status = status;
        this.code = code;
        this.serverId = serverId;
        this.entityVersion = entityVersion;
        this.snapshot = snapshot;
    }

    public static SyncProcessException conflict(
            SyncErrorCode code,
            String message,
            Long serverId,
            Long entityVersion,
            JsonNode snapshot
    ) {
        return new SyncProcessException(
                SyncOperationStatus.CONFLICT,
                code,
                message,
                serverId,
                entityVersion,
                snapshot
        );
    }

    public static SyncProcessException failed(SyncErrorCode code, String message) {
        return new SyncProcessException(
                SyncOperationStatus.FAILED,
                code,
                message,
                null,
                null,
                null
        );
    }
}
