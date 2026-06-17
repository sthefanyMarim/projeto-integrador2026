package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import tools.jackson.databind.JsonNode;

public record SyncOperationResult(
        String operationId,
        SyncEntityType entityType,
        SyncActionType action,
        String localId,
        Long serverId,
        Long entityVersion,
        SyncOperationStatus status,
        SyncErrorCode code,
        String message,
        JsonNode snapshot
) {
}
